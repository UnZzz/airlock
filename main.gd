extends Control

const DAY_SCENE : PackedScene = preload("res://scene_system/CabinDay.tscn")
const AIRLOCK_SCENE : PackedScene = preload("res://scene_system/CabinAirlock.tscn")
const EXILE_SCENE : PackedScene = preload("res://scene_system/AirlockExile.tscn")

@export var scene_fade_time : float = 0.6

@onready var background : Control = $Background
@onready var panels : MarginContainer = $Margin
@onready var panel_toggle_button : Button = $PanelToggleButton
@onready var day_label : Label = $Margin/Layout/SidebarPanel/Sidebar/DayLabel
@onready var resource_label : Label = $Margin/Layout/SidebarPanel/Sidebar/ResourceLabel
@onready var crew_list : VBoxContainer = $Margin/Layout/SidebarPanel/Sidebar/CrewScroll/CrewList
@onready var title_label : Label = $Margin/Layout/ContentPanel/Content/TitleLabel
@onready var body_text : RichTextLabel = $Margin/Layout/ContentPanel/Content/BodyText
@onready var option_list : VBoxContainer = $Margin/Layout/ContentPanel/Content/OptionList

var current_scene : PackedScene = null
var fed_selection : Dictionary = {}
var cost_label : Label = null
var confirm_button : Button = null


func _ready() -> void:
	panel_toggle_button.pressed.connect(_toggle_panels)
	_update_panel_toggle_text()
	GameFlow.phase_changed.connect(_on_phase_changed)
	Inventory.inventory_changed.connect(_refresh_sidebar)
	Crew.crew_changed.connect(_refresh_sidebar)
	EffectSystem.effect_added.connect(func(_target_id, _effect): _refresh_sidebar())
	EffectSystem.effect_removed.connect(func(_target_id, _effect): _refresh_sidebar())
	Music.play_playlist()
	GameFlow.start_game()


func _toggle_panels() -> void:
	panels.visible = not panels.visible
	_update_panel_toggle_text()


func _update_panel_toggle_text() -> void:
	panel_toggle_button.text = Journal.text("ui_hide_panels" if panels.visible else "ui_show_panels")


func _on_phase_changed(phase: int) -> void:
	_refresh_sidebar()
	_set_scene(AIRLOCK_SCENE if phase == GameFlow.Phase.AIRLOCK else DAY_SCENE)
	match phase:
		GameFlow.Phase.OPENING:
			_show_opening()
		GameFlow.Phase.JOURNAL:
			_show_journal()
		GameFlow.Phase.ALLOCATION:
			fed_selection.clear()
			_show_allocation()
		GameFlow.Phase.EVENT:
			_show_event()
		GameFlow.Phase.AIRLOCK:
			_show_airlock()
		GameFlow.Phase.ENDING:
			_show_ending()


func _set_scene(scene: PackedScene) -> void:
	if scene == current_scene:
		return
	var first : bool = current_scene == null
	current_scene = scene
	var old_scenes : Array[Node] = background.get_children()
	var new_scene : CanvasItem = scene.instantiate()
	background.add_child(new_scene)
	if first or scene_fade_time <= 0.0:
		for old in old_scenes:
			old.queue_free()
		return
	new_scene.modulate.a = 0.0
	var tween : Tween = create_tween()
	tween.tween_property(new_scene, "modulate:a", 1.0, scene_fade_time)
	tween.tween_callback(func():
		for old in old_scenes:
			if is_instance_valid(old):
				old.queue_free()
	)


func _show_opening() -> void:
	var page : Dictionary = Journal.get_opening()
	_show_page(page["title"], page["paragraphs"])
	_add_button(Journal.text("ui_continue"), GameFlow.finish_opening)


func _show_journal() -> void:
	var page : Dictionary = Journal.get_day_page(Timeline.current_day)
	_show_page(page["title"], page["paragraphs"])
	_add_button(Journal.text("ui_continue"), GameFlow.finish_journal)


func _show_allocation() -> void:
	var hints : Array[String] = []
	var allocation_text : String = Journal.get_allocation_text(Timeline.current_day)
	if allocation_text != "":
		hints.append(allocation_text)
	if Timeline.is_time_to_kick_out:
		hints.append(Journal.text("ui_airlock_hint"))
	var chef : CrewMember = Crew.get_by_role(CrewMember.Role.CHEF)
	if chef != null and chef.is_on_board():
		hints.append(Journal.text("ui_chef_bonus", {"chef": chef.display_name}))
	_show_page(Journal.get_allocation_title(Timeline.current_day), hints)
	for member in Crew.on_board():
		option_list.add_child(_build_allocation_row(member))
	var shortcuts : HBoxContainer = HBoxContainer.new()
	shortcuts.add_child(_make_button(Journal.text("ui_feed_all"), _select_all_meals.bind(true)))
	shortcuts.add_child(_make_button(Journal.text("ui_feed_none"), _select_all_meals.bind(false)))
	option_list.add_child(shortcuts)
	cost_label = Label.new()
	option_list.add_child(cost_label)
	confirm_button = _add_button(Journal.text("ui_confirm_allocation"), _confirm_allocation)
	_update_allocation_cost()


func _build_allocation_row(member: CrewMember) -> HBoxContainer:
	var row : HBoxContainer = HBoxContainer.new()
	var box : CheckBox = CheckBox.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if Crew.refuses_meal(member):
		box.text = Journal.text("ui_refuses_food", {"name": member.display_name})
		box.disabled = true
	else:
		box.text = Journal.text("ui_feed_label", {"name": member.display_name})
		if member.days_without_food > 0:
			box.text += Journal.text("ui_hunger_suffix", {"text": Journal.text("ui_hunger", {"days": member.days_without_food})})
		box.button_pressed = fed_selection.get(member.member_id, false)
		box.toggled.connect(_on_meal_toggled.bind(member.member_id))
	row.add_child(box)
	var effect : BaseEffect = Crew.get_injury_effect(member.member_id)
	if effect != null:
		var maintain : Button = _make_button(Journal.text("ui_maintain", {"cost": Crew.maintenance_cost}), _on_maintain.bind(member.member_id))
		maintain.disabled = not Crew.can_maintain(member.member_id)
		row.add_child(maintain)
		if Crew.doctor_available():
			var treat : Button = _make_button(Journal.text("ui_treat", {"cost": Crew.treatment_cost}), _on_treat.bind(member.member_id))
			treat.disabled = not Crew.can_treat(member.member_id)
			row.add_child(treat)
	return row


func _on_meal_toggled(pressed: bool, member_id: String) -> void:
	fed_selection[member_id] = pressed
	_update_allocation_cost()


func _select_all_meals(pressed: bool) -> void:
	for member in Crew.on_board():
		if not Crew.refuses_meal(member):
			fed_selection[member.member_id] = pressed
	_show_allocation()


func _on_maintain(member_id: String) -> void:
	Crew.maintain(member_id)
	_show_allocation()


func _on_treat(member_id: String) -> void:
	Crew.treat(member_id)
	_show_allocation()


func _selected_meal_ids() -> Array[String]:
	var ids : Array[String] = []
	for member in Crew.on_board():
		if fed_selection.get(member.member_id, false) and not Crew.refuses_meal(member):
			ids.append(member.member_id)
	return ids


func _update_allocation_cost() -> void:
	var count : int = _selected_meal_ids().size()
	var cost : int = Crew.meal_cost(count)
	cost_label.text = Journal.text("ui_allocation_cost", {"count": count, "cost": cost, "food": Inventory.food_count})
	confirm_button.disabled = not Inventory.can_afford(cost, 0)


func _confirm_allocation() -> void:
	GameFlow.submit_allocation(_selected_meal_ids())


func _show_event() -> void:
	var event : BaseEvent = EventManager.current_event
	if event == null:
		return
	if event.is_finished and event.current_text.strip_edges() == "":
		GameFlow.finish_event()
		return
	_show_page(event.title if event.title != "" else Journal.text("event_title"), [event.current_text])
	if event.is_finished:
		_add_button(Journal.text("ui_continue"), GameFlow.finish_event)
		return
	for option in event.current_options:
		var button : Button = _add_button(option.text, _on_event_option.bind(option))
		button.disabled = not option.can_afford()


func _on_event_option(option: EventOption) -> void:
	GameFlow.choose_event_option(option)
	if GameFlow.phase == GameFlow.Phase.EVENT:
		_show_event()


func _show_airlock() -> void:
	var title : String = Journal.text("airlock_title")
	if Airlock.is_resolved:
		_show_page(title, [Airlock.result_text])
		_add_button(Journal.text("ui_continue"), GameFlow.finish_airlock)
		return
	_show_page(title, [Airlock.get_intro_text()])
	for member in Airlock.get_sedated():
		_add_button(Journal.text("ui_exile", {"name": member.display_name}), _on_airlock_choice.bind(member.member_id))
	_add_button(Journal.text("ui_exile_nobody"), _on_airlock_choice.bind(""))


func _on_airlock_choice(target_id: String) -> void:
	if Airlock.is_resolved:
		return
	var target : CrewMember = Crew.get_member(target_id)
	var was_on_board : bool = target != null and target.is_on_board()
	GameFlow.resolve_airlock(target_id)
	if was_on_board and target.status == CrewMember.Status.EXILED:
		_set_scene(EXILE_SCENE)
	_show_airlock()


func _show_ending() -> void:
	_show_page(Journal.text("ending_title"), [GameFlow.get_ending_text()])
	_add_button(Journal.text("ui_restart"), GameFlow.start_game)


func _show_page(title: String, paragraphs: Array) -> void:
	title_label.text = title
	body_text.text = "\n\n".join(paragraphs)
	body_text.scroll_to_line(0)
	for child in option_list.get_children():
		option_list.remove_child(child)
		child.queue_free()


func _make_button(text: String, callback: Callable) -> Button:
	var button : Button = Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button


func _add_button(text: String, callback: Callable) -> Button:
	var button : Button = _make_button(text, callback)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	option_list.add_child(button)
	return button


func _refresh_sidebar() -> void:
	if not is_node_ready():
		return
	var day_lines : Array[String] = [Journal.text("ui_day", {"day": Timeline.current_day, "total": Timeline.total_days})]
	if Timeline.is_time_to_kick_out:
		day_lines.append(Journal.text("ui_today_airlock"))
	elif Timeline.get_next_airlock_day() == -1:
		day_lines.append(Journal.text("ui_no_airlock"))
	else:
		day_lines.append(Journal.text("ui_next_airlock", {"day": Timeline.get_next_airlock_day()}))
	day_label.text = "\n".join(day_lines)
	resource_label.text = Journal.text("ui_resources", {"food": Inventory.food_count, "mouthwash": Inventory.bottle_of_mouthwash_count})
	for child in crew_list.get_children():
		crew_list.remove_child(child)
		child.queue_free()
	for member in Crew.members:
		var label : Label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = _describe_member(member)
		crew_list.add_child(label)


func _describe_member(member: CrewMember) -> String:
	var role_key : String = "ui_role_" + String(CrewMember.Role.keys()[member.role]).to_lower()
	var lines : Array[String] = [member.display_name + " · " + Journal.text(role_key)]
	match member.status:
		CrewMember.Status.EXILED:
			lines.append(Journal.text("ui_status_exiled"))
			return "\n".join(lines)
		CrewMember.Status.DEAD:
			lines.append(Journal.text("ui_status_dead"))
			return "\n".join(lines)
	var effect : BaseEffect = Crew.get_injury_effect(member.member_id)
	if effect == null:
		lines.append(Journal.text("ui_health_healthy"))
	else:
		lines.append(Journal.text("ui_injury_countdown", {"state": effect.display_name, "days": EffectSystem.get_remaining(member.member_id, effect.effect_name)}))
	if member.days_without_food > 0:
		lines.append(Journal.text("ui_hunger", {"days": member.days_without_food}))
	if member.role == CrewMember.Role.CRIMINAL:
		lines.append(Journal.text("ui_loyalty", {"value": member.loyalty, "max": Crew.max_loyalty}))
		if Crew.can_intimidate():
			lines.append(Journal.text("ui_intimidate_ready"))
	if member.knows_airlock_secret:
		lines.append(Journal.text("ui_knows_secret"))
	match member.current_promise:
		CrewMember.Promise.SKIP_NEXT_TASK:
			lines.append(Journal.text("ui_promise_skip_task"))
		CrewMember.Promise.SPARE_NEXT_AIRLOCK:
			lines.append(Journal.text("ui_promise_spare_airlock"))
		CrewMember.Promise.EXILE_TARGET:
			var target : CrewMember = Crew.get_member(member.requested_exile_target)
			lines.append(Journal.text("ui_promise_exile_target", {"name": target.display_name if target != null else ""}))
	if member.refuses_next_task:
		lines.append(Journal.text("ui_refuses_task"))
	return "\n".join(lines)
