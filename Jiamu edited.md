# Jiamu edited

改动记录。起点是提交 `75f9d86 Update music`，依据是《角色功能与机制说明》（中文版，第 4 个角色是厨师 Chef）和 `文案.pdf`。
所有新代码都没有写注释。代码里唯一的注释 `#-1 means infinite duration`（`base_effect.gd`）是原来就有的，保留没动。
音乐系统（`music_system/`）是你自己在改的部分，这次没有碰。

---

## 一、游戏流程（现在已经能从头玩到结局）

```
开场 → 第 N 天日志 → 物资分配 → 事件（固定 / 随机 / 无）→ [Airlock 日] Airlock → 夜间结算（饥饿、伤势）→ 第 N+1 天日志 …
第 30 天结束 → 结局（存活 / 船长饿死 / 船长伤重死亡 / 叛变）
```

- Airlock 日：第 7、14、21、28 天
- 第 1 天按文案「固定无事件」处理

---

## 二、新增文件

| 文件 | 作用 |
|---|---|
| `story/story_zh.json` | **你的文案**（开场、第 1 天日志、物资分配标题、第 1 天固定无事件、第 2 天日志标题）。第一轮原样录入，第二轮经你同意改了 5 处，见第十节 |
| `story/system_text_zh.json` | 我写的所有界面文字和占位叙事文字，叙事类都带 `[占位]` 标记，可以直接替换 |
| `character_system/crew_member.gd` | 角色数据类 `CrewMember`：角色、状态（在船/流放/死亡）、饥饿天数、忠诚度、是否知道秘密、承诺、要求流放的目标、是否拒绝下次任务 |
| `character_system/crew.gd` + `Crew.tscn` | 新 autoload `Crew`：管理 5 个人、受伤/维持/治疗、死亡、流放、忠诚度/威慑/叛变、喂饭和饥饿 |
| `character_system/members/*.tres` | 5 个角色：船长、Mason Reed（罪犯）、Elias Ward（工人）、Dr. Helena Voss（医生）、Mara Quinn（厨师） |
| `journal_system/journal.gd` + `Journal.tscn` | 新 autoload `Journal`：读取文案和系统文本，管理每天日志和「第二天日志才揭示」的动态条目 |
| `airlock_system/airlock.gd` + `Airlock.tscn` | 新 autoload `Airlock`：被麻醉名单、流放 / 不流放、检查工人的承诺 |
| `game_flow/game_flow.gd` + `GameFlow.tscn` | 新 autoload `GameFlow`：上面那条流程的状态机，以及结局判定 |
| `effect_system/effects/critical.tres` | 新效果「重伤」 |
| `event_system/events/event_option.gd` | 事件选项类 `EventOption`：文字、结果文字、Food/漱口水变化、忠诚度变化、需要谁在场、是否可被威慑 |
| `event_system/events/dangerous_task_event.gd` | 危险任务事件类 `DangerousTaskEvent`：派人、受伤/死亡概率、工人谈判、威慑、违约处理 |
| `event_system/events/criminal_demand.tres` | [占位] Mason 的要求（测试忠诚度） |
| `event_system/events/doctor_demand.tres` | [占位] Helena 的条件（测试威慑医生） |
| `event_system/events/repair_leak.tres` | [占位] 危险任务：冷却管道破裂 |
| `event_system/events/salvage_cargo.tres` | [占位] 危险任务：舱外补给箱 |
| 各新脚本的 `.gd.uid` | Godot 自动生成 |
| `Jiamu edited.md` | 本文件 |

## 三、修改的已有文件

| 文件 | 改了什么 |
|---|---|
| `project.godot` | 新增 4 个 autoload：`Journal`、`Crew`、`Airlock`、`GameFlow`（排在原有 5 个后面） |
| `main.tscn` / `main.gd` | 原来是一个 `NEXT DAY` 按钮，现在换成完整界面：左边日期/资源/船员状态，右边标题/正文/选项。保留了你加的 `Music.play_playlist()` |
| `effect_system/spaceship_effect_list.gd` | 原来是空的。现在是按目标（角色 id 或 `ship`）挂效果，每天倒计时，到期自动变成 `next_effect`，并发出信号 |
| `effect_system/effects/base_effect.gd` | 新增 `display_name`、`next_effect`（到期后变成什么）、`is_fatal`（加上就死） |
| `effect_system/effects/injured.tres` | 加了显示名「受伤」；**duration 20 → 3**（意思是每 3 天要补 1 瓶漱口水）；到期后变成重伤 |
| `effect_system/effects/dead.tres` | 加了显示名「死亡」，`is_fatal = true` |
| `inventory_system/inventory.gd` | 新增 `inventory_changed` 信号，以及 `reset`、`can_afford`、`spend`、`apply_change`。第二轮把 **Food 10 → 30**，漱口水还是 10 |
| `timeline_manager/timeline.gd` | 新增 `current_day`、`on_airlock_day` 信号、`get_next_airlock_day()`。**修了两个差一问题**：原来要按 31 次才触发 `on_final_day`，原来第 8 天才是第一个 Airlock 日。删掉了 `seven_day_counter`，改用 `airlock_interval` 计算 |
| `event_system/events/base_event.gd` | `options` 从 `Array[String]` 改成 `Array[EventOption]`；新增 `event_id`、`title`、`required_members`、`in_random_pool`、`repeatable`，以及 `begin()` / `choose()` 流程 |
| `event_system/events/argument.tres` | 原来是空的，填了 [占位] 争执事件（Mason 和 Helena 吵架，测试忠诚度 ±1） |
| `event_system/event_manager.gd` / `.tscn` | 原来是空的。现在读取第 N 天的固定事件，没有固定事件时按 60% 概率从事件池随机抽一个 |

---

## 四、机制实现对照设计文档

**罪犯 Mason**
- 忠诚度上限 3，初始 1。到 3 时永久解锁威慑
- 威慑可用的条件：Mason 在船上，且忠诚度大于 0
- 曾经满过、后来掉到 0 → 叛变，游戏结束；从没满过的话掉到 0 没事
- 威慑可以绕过工人的条件，也可以绕过事件里标了 `intimidatable` 的医生条件：不付资源，但收益照拿

**工人 Elias**
- 普通人出危险任务：受伤 20%，死亡 5%；工人：受伤 5%，不会死
- 派工人时他随机提一个条件，可以接受、拒绝改派别人、放弃任务，或者威慑
- 条件池：
  - 1 Food
  - 1 漱口水
  - 「下次危险任务别派我」
  - 「下一个别是我」（对应 SPARE_NEXT_AIRLOCK；**至少有 1 人失踪过才会出现**，因为他不知道 Airlock 的事，只知道有人不见了）
  - 「告诉我一个秘密」（**至少有 1 人被流放过才会出现**，因为秘密内容是"之前失踪的船员"）
  - 知道秘密以后：「下次 Airlock 把某人流放」
- 已经有一个没兑现的承诺时，不会再提新的承诺类条件
- 知道秘密以后，每个 Airlock 日他都不吃晚餐，所以不会被麻醉，也就不能被流放
- 违约：
  - 违反「下次别派我」：派他时他当场拒绝
  - 违反「把某人流放」（流放了别人，或者谁都没流放）：他拒绝下一次任务，第二天日志会写出来
  - 要求的目标在 Airlock 前已经不在船上：承诺作废

**医生 Helena**
- 受伤 → 3 天后恶化成重伤 → 再过 2 天死亡
- 付 1 瓶漱口水可以把倒计时重置，倒计时已经是满的时候不能付
- 医生在船上、且自己不是重伤时，可以花 2 瓶漱口水直接治好，包括治她自己
- 医生**重伤时算作"不能行动"**，不能治疗任何人

**厨师 Mara**
- 在船上时，用餐消耗为人数 × 0.75，向上取整（5 人吃 4 份）
- Airlock 日由她在晚餐里下药；第一次 Airlock 有一段 [占位] 介绍
- Mara 不在以后，**船长自己下药，流放照常进行**（按你的回答）

---

## 五、我自己做的判断（第二轮你回复「你都可以改」，以下维持不变）

1. **物资分配**：你回答的是「文案」，我理解为照文案描述来做：
   - 每天逐人勾选吃不吃，另有「全员进食 / 全员不进食」快捷按钮
   - 连续 3 天没吃会饿死；船长饿死就游戏结束
   - 第 1 天大家 0 天未进食（对应文案"前一天大家都吃了一顿正常……的晚餐"）
2. **镇静剂在晚餐里**：所以 Airlock 日**只有当天吃了饭的人会被麻醉**。不喂某人，当晚就流放不了他。工人知道秘密后不吃饭，也是这个逻辑。
3. 船长**不会**被派去出危险任务；重伤的人也不能被派去。
4. 不是 Airlock 日也会有随机事件。

## 六、占位数值（都可以在 Inspector 里调）

| 位置 | 数值 |
|---|---|
| `Inventory` | Food 30（原值 10，第二轮调整）、漱口水 10 |
| `Crew` | 忠诚度上限 3、饿死天数 3、厨师系数 0.75、维持花费 1、治疗花费 2 |
| `mason.tres` | 初始忠诚度 1 |
| `injured.tres` / `critical.tres` | 恶化前 3 天 / 2 天 |
| `DangerousTaskEvent` | 受伤 0.2、死亡 0.05、工人受伤 0.05 |
| `EventManager` | 随机事件概率 0.6 |
| `Timeline` | 共 30 天、每 7 天一次 Airlock |

**平衡模拟（每档 200 局，玩法：谁饿到第 2 天就给谁吃饭，船长优先）**

| 初始 Food | 结果 |
|---|---|
| 10 | 船长全部饿死 |
| 20 | 存活约 18% |
| 30 | 存活约 82% |
| 40 | 存活约 99.5%（200 局里只有 1 局叛变） |

在 Food 10 的情况下，就算合理地玩也撑不过 30 天，所以第二轮改成了 30。

## 七、占位内容（都要换成正式文案）

- `story/system_text_zh.json` 里所有带 `[占位]` 的条目：
  - 工人的各种条件台词
  - 任务受伤/死亡
  - 日志里的失踪、饿死、伤重、秘密揭示、违约、威慑解锁
  - Airlock 介绍和结果
  - 结局
- 5 个占位事件：`.tres` 文件里的标题、描述、选项文字
- ~~第 2 天日志只有标题~~（第十二节已经补上第 2–4 天的文案）。没有文案的日子，正文显示「[占位] 本日日志待补充。」
- 没有文案的日子，日志标题按文案的格式自动生成（现在是第 5–30 天：「失事第05天 日志」……）

## 八、测试（测试脚本没有放进项目）

- 用本机 Godot 4.7.2 无界面运行，没有脚本错误
- 逻辑测试：66 项全部通过（第二轮增加到 68 项），覆盖文案读取、喂饭和饿死、受伤恶化死亡、维持和治疗、忠诚度/威慑/叛变、工人谈判全部分支、Airlock 和承诺检查、第 30 天结局
- 300 局随机模拟都能正常走到结局
- 界面测试：模拟点击跑完 5 局；截图确认中文显示正常
- 修了一个界面问题：横排按钮被压成竖线

## 九、还没做

- 正式事件和结局文案
- 多结局目前只区分：存活（列出幸存者）、船长饿死、船长伤重死亡、叛变
- 发布到其他电脑时建议放一个中文字体进项目。现在用的是系统字体回退，在本机显示正常

---

## 十、第二轮改动（你回复「你都可以改」之后）

**文案**（`story/story_zh.json`）
- 开场：「夺走**你**英明的决策力」→「夺走**您**英明的决策力」，和前面的「还有您」统一
- 开场：「Dragonbreath Ltd.**空格**托」→「Dragonbreath Ltd.托」，删掉多余空格，和其他英文名的写法保持一致
- 第 1 天日志：「愉快**的**看着」→「愉快**地**看着」
- 第 1 天日志：「一圈圈**的**晃悠」→「一圈圈**地**晃悠」
- 第 1 天日志：「过度盲目**的**相信」→「过度盲目**地**相信」

**机制**
- `dangerous_task_event.gd`：工人「下一个别是我」的条件改成**至少有 1 人失踪过才会出现**。原来游戏一开始就会出现，可那时他还不知道 Airlock 能用来流放人，剧情上说不通
- `system_text_zh.json`：这条条件的占位台词改成「我不管之前那些人是怎么不见的。下一个，别是我。」
- `inventory.gd`：初始 Food 从 10 改成 30

**维持不变**
- 逐人喂饭，连续 3 天不吃会饿死
- 没吃晚餐的人不会被麻醉
- 没有固定事件的日子按 60% 概率抽随机事件
- 第 2 天日志正文没有替你写，仍然显示占位（第十二节新文案已补上）

---

## 十一、第三轮：添加两个场景（背景图）

**你定的方案**
- 图 1（亮的房间）是白天场景：开场、日志、物资分配、事件、结局都用它
- 图 2（暗的、有光柱）是 Airlock 场景：只在 Airlock 那一幕用，包括选择和结果
- 背景铺满全屏，左栏和右边的文字、按钮放在半透明深色面板上，布局基本不变

**新增文件**

| 文件 | 作用 |
|---|---|
| `scene_system/backgrounds/cabin_day.webp` | 图 1，1955×1100，就是你发在聊天里的那张 |
| `scene_system/backgrounds/cabin_airlock.webp` | 图 2，1955×1100 |
| `scene_system/backgrounds/*.webp.import` | Godot 自动生成 |
| `scene_system/CabinDay.tscn` | 白天场景：一个铺满全屏的 `TextureRect`，按比例裁切填满窗口，不挡鼠标 |
| `scene_system/CabinAirlock.tscn` | Airlock 场景，结构同上 |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `main.tscn` | 最底层加了 `Background` 节点，用来放场景；左栏外面套了 `SidebarPanel`，右边内容外面套了 `ContentPanel`，两个都是半透明深色圆角面板；删掉了中间那条竖分隔线 `Divider`，因为两块面板已经分开了 |
| `main.gd` | 节点路径跟着改；每次切换阶段时，Airlock 阶段换成 `CabinAirlock`，其他阶段换成 `CabinDay`；切换时淡入 0.6 秒（`scene_fade_time`，可以在 Inspector 里调，设成 0 就是直接切） |

**可以调的地方**
- 面板透明度：`main.tscn` 里 `StyleBoxFlat_panel` 的 `bg_color`，现在是 `Color(0.07, 0.08, 0.11, 0.72)`，最后一个数越小越透明
- 聊天里收到的图是 webp 压缩过的。如果有原图，用同名文件直接覆盖就行；换成 png 的话，要在两个场景里重新选一下贴图

**测试**
- 无界面运行没有脚本错误
- 自动点击跑了 50 局，都正常走到结局：存活 20 局、船长饿死 27 局、叛变 3 局
- 有窗口运行并截图确认：开场和第 1 天物资分配是白天场景；第 7 天 Airlock 的选择和结果是 Airlock 场景；第 8 天日志切回白天场景

---

## 十二、第四轮：接入更新后的文案（`文案 (1).pdf`，开场到第 4 天）

**文案录入**（`story/story_zh.json`，整体按新 PDF 重新生成）
- 开场：没变
- 第 1 天：作者把「我更倾向于那是」改成了「我更倾向于**认定**那是」，已经同步
- 第 2 天日志：6 段；第 2 天固定事件：检查冷库余火（见下）
- 第 3 天日志：开头一段按第 2 天的选择显示（Elias / 其他人 / 什么都不做），后面 5 段所有人都一样；物资分配页显示「该分配物资了，船长。（也就是我）」；文案标了「可触发随机事件」
- 第 4 天日志：3 段
- 文案里的 `xxx` / `ta` 换成了模板变量 `{name}` / `{ta}`，游戏里会自动填成被派去的人和对应的他/她
- 第 2 天的「物资分配选项」和「固定事件」、第 3 天的「可触发随机事件」都是给程序看的标记，转成了数据，不会显示在游戏里

**文案修改**（新 PDF 是作者原稿，第二轮那几处又回来了，这次连同新文案里同一类的问题一起改）
- 开场：重新套用第二轮的 2 处（「您英明」、「Ltd.托」）
- 第 1 天：重新套用第二轮的 3 处（「愉快地」「一圈圈地」「盲目地」）
- 第 2 天：「没被充分**的**展现」→「充分**地**展现」
- 第 3 天：「然后说了声**空格**“船长」→ 删掉空格
- 第 3 天：「往冷冻**仓**看了一眼」→「冷冻**舱**」
- 第 3 天：「一个劲**的**问她」→「一个劲**地**问她」

**新增文件**

| 文件 | 作用 |
|---|---|
| `event_system/events/fire_check.tres` | 第 2 天固定事件：检查冷库余火。选项文字和顺序都按文案：Elias Ward / Mara Quinn / Dr. Voss / Mason Reed / 我们会没事的（不做处理）。派 Elias 会触发文案里的第二段：食物 / 漱口水 / 该死，随他去吧（Elias不会帮你） |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `character_system/crew_member.gd` | 新增 `short_name`（日志里用的简称）和 `pronoun`（他/她） |
| `character_system/members/*.tres` | 简称：Mason、Elias、Dr. Voss、Mara、船长；代词按文案：Mason 他、Elias 他、Dr. Voss 她、Mara 她 |
| `journal_system/journal.gd` | 新增剧情标记（`set_flag` / `get_flag`，开新局时清空）；日志段落可以写成 `{"if": {...}, "member": ..., "text": ...}`，满足条件才显示，并自动填入人名和代词；新增 `get_allocation_text()` 和「可触发随机事件」标记 `random` |
| `event_system/event_manager.gd` | 文案标 `random` 的日子，按随机事件规则抽 |
| `event_system/events/event_option.gd` | `action` 改成可以在数据里填（`accept` / `abandon`），固定谈判选项要用 |
| `event_system/events/dangerous_task_event.gd` | 新增可以按文案指定的内容：每个人的派遣按钮文字和顺序（`send_option_texts`）、放弃按钮文字、工人的固定谈判台词和选项、结果标记 `outcome_flag`（会记下 worker / other / nothing / died，以及派去的是谁）；`success_text` 为空时不再多出一个空段落 |
| `event_system/event_manager.tscn` | 事件列表里加上 `fire_check`。它不进随机池，只在第 2 天出现 |
| `main.gd` | 物资分配页显示当天的分配文案；事件没有标题时显示「事件」；事件结束且没有结果文字时直接进入下一步，因为文案里的结果写在第二天日志里。背景切换的逻辑没动 |
| `story/system_text_zh.json` | 新增 `event_title`「事件」；存活结局的占位文字从「补给船到了」改成「飞船抵达了那颗宜居星球」，对应第 4 天的新剧情 |

**第 2 天事件的数值和处理（文案没写的部分）**
- 派任何人都**不会受伤或死亡**：第 3 天日志里每种选择都写的是火已经灭了。这个事件的受伤和死亡概率在 `fire_check.tres` 里设成了 0
- 给 Elias「食物」扣 1 Food；给「漱口水」扣 1 瓶，对应文案里的「一整瓶」
- 选「该死，随他去吧」等于什么都不做，第 3 天显示「宁可承担……」那一段
- Mason 的威慑如果已经解锁，Elias 的谈判里也会出现威慑选项。不过第 2 天正常玩不可能解锁

**测试**
- 新增文案测试 100 项，全部通过：第 2 天 7 种选法分别对应第 3 天该显示的段落，人名和他/她替换正确，扣的资源正确，没人受伤，`fire_check` 不会被随机抽到
- 原来的逻辑测试 68 项、300 局随机模拟、界面自动点击 5 局：全部正常
- 有窗口截图确认：第 2 天事件、Elias 谈判、第 3 天日志（Elias 分支）、第 3 天物资分配页都显示正常

---

## 全游戏改成英文（2026-10-03）

**新增文件**

| 文件 | 作用 |
|---|---|
| `story/story_en.json` | `story_zh.json` 的英文翻译，结构和条件段落完全一样 |
| `story/system_text_en.json` | `system_text_zh.json` 的英文翻译；占位标记 `[占位]` 改成 `[TBD]` |

中文的 `story_zh.json` / `system_text_zh.json` 保留没删，想切回中文只要改 `journal.gd` 顶部两个路径。

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `journal_system/journal.gd` | 读取的文案文件改成 `story_en.json` / `system_text_en.json` |
| `main.gd` | 饥饿天数外面的全角括号「（）」改成读 `ui_hunger_suffix` |
| `game_flow/game_flow.gd`、`airlock_system/airlock.gd` | 名单分隔符「、」改成读 `list_separator`（英文是 `, `） |
| `story/system_text_zh.json` | 新增 `ui_hunger_suffix`「（{text}）」和 `list_separator`「、」，保证切回中文时显示不变 |
| `character_system/members/*.tres` | 船长名字改 Captain；代词改成 he / she |
| `effect_system/effects/*.tres` | 受伤 / 重伤 / 死亡 → Injured / Critical / Dead |
| `event_system/events/*.tres` | 所有事件标题、描述、选项、结果文字翻成英文（这几个 .tres 是单语言的，中文原文在 git 历史里） |

**翻译上的处理**
- 第 3 天「其他人去检查」那段，英文代词只用主格 `{ta}`（he / she），句子改写成不需要 him / her 的形式
- 日志标题「失事第01天 日志」→ `Wreck Log: Day 01`
- 漱口水统一译作 Mouthwash，Food 保持 Food

**测试**
- 三个 JSON 能正常解析，中英 system_text 的 key 完全一致
- Godot 无界面运行主场景 300 帧，没有脚本报错；单独加载事件 / 角色 / 状态 .tres 都正常

---

## 五个角色占位（2026-10-03）

**新增文件**

| 文件 | 作用 |
|---|---|
| `character_system/CrewStage.tscn` | 角色站位层，底部居中一排 |
| `character_system/crew_stage.gd` | 按 `Crew.members` 生成占位小人：圆头 + 圆角身体 + 名字（用 `short_name`），每个职业一个颜色 |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `main.tscn` | 在 `Background` 和 `Margin` 之间加了 `CrewStage` 实例，所以角色在背景之上、面板之下，点 Hide Panels 能完整看到 |

**行为 / 占位值**
- 监听 `Crew.crew_changed` 自动刷新：被驱逐的角色从画面消失，死亡的角色变灰半透明
- 颜色：船长蓝、Mason 红、Elias 黄、Helena 绿、Mara 紫；头 56px，身体 84×150，间距 56，都可以在 `crew_stage.gd` 的导出变量里调
- 没有新增任何文案

**测试**
- Godot 无界面运行无新报错（退出时的 ObjectDB 泄漏警告改动前就有）
- 录帧截图确认五个占位小人显示在底部

---

## 角色占位换成立绘（2026-10-03）

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `character_system/crew_stage.gd` | 不再画色块，改成读 `character/` 里的立绘 |
| `character_system/CrewStage.tscn` | 一排立绘直接贴住屏幕底边，间距改成 0 |

**规则**
- 编号：1 = Mason，2 = Elias，3 = Mara，4 = Helena（导出变量 `portrait_ids`）
- `X_1` 是重伤，`X_2` 是受伤，`X_3` 是健康。`X_3` 还没导入，健康时先用 `X_2`；放进 `character/X_3.png` 就会自动用上
- 不显示船长；没有立绘的角色都不显示
- 四个人用同一个缩放 `portrait_scale = 0.26`，按原图像素大小缩放，所以互相之间的比例不会变
- 受伤 / 重伤 / 治好后会自动换图；死亡变灰，被驱逐就消失

**测试**
- Godot 无界面运行无报错；录帧截图确认四张立绘按原始比例排在底部

---

## 角色改成场景里的独立节点，方便手动调大小（2026-10-03）

**新增文件**

| 文件 | 作用 |
|---|---|
| `character_system/character_portrait.gd` | 挂在每个角色节点上：按健康状态换图（健康 `X_3` / 受伤 `X_2` / 重伤 `X_1`），死亡变灰，被驱逐隐藏 |

**删除的文件**
- `character_system/crew_stage.gd`（及 `.uid`）：不再用代码生成角色

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `character_system/CrewStage.tscn` | 直接放了 4 个 `TextureRect` 节点：`Mason`、`Elias`、`Helena`、`Mara`，三张图在检查器里可以换 |

**怎么调**
- 打开 `CrewStage.tscn`（或在 `main.tscn` 里），选中角色节点直接拖位置、拖边框改大小
- 节点是"保持比例居中"，框改成什么形状图都不会变形；三种状态的图共用同一个框，换图时大小不变
- 初始大小按原图 × 0.26，锚在屏幕底边

**测试**
- Godot 无界面运行无新报错；录帧截图确认四个角色显示健康立绘

**固定译名（2026-10-03 追加）**
- 新增 `story/glossary_en.md`：中英固定译名表，以后所有英文文案都按它翻译。漂浮一律用 drift（不用 float），Airlock 一律写 `Airlock`（大写、不翻译）
- 按表核对现有英文：`system_text_en.json` 里三处 knocked out / drugged 统一成 sedated / unconscious；没有出现 float，Airlock 写法本来就统一
- 点题：英文里的门统一改成 airlock。`story_en.json` 第 1 天「关闭了连通冷冻区的舱门」、第 3 天「打开闸门」的 hatch → airlock；`criminal_demand.tres` 占位选项「关进储物间」改成 storage airlock，结果文字 closet door → airlock。译名表加了一条：飞船上的门 → airlock（小写），不用 door / hatch / gate

---

## 角色悬停变暗 + 像素字体（2026-10-03，参考 house-rules）

从 house-rules 只复制、没改它任何文件。

**新增文件**

| 文件 | 作用 |
|---|---|
| `ui/PixelFont.ttf` | 从 house-rules `Shared/PixelFont.ttf` 原样复制 |
| `ui/theme.tres` | 全局主题：默认字体 PixelFont，默认字号 20（占位值，可在检查器改） |
| `character_system/highlight.gdshader` | 照 house-rules `highlight.gdshader` 写的亮度着色器（乘亮度、上限 0.99，不会过曝） |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `character_system/character_portrait.gd` | 加悬停效果，逻辑照 house-rules `clickable_item.gd`：悬停的角色变亮 30%，其他角色变暗 50%，背景变暗 50%；变暗 0.15 秒、恢复 0.35 秒，Sine 缓动。只有不透明像素算悬停，透明边角不算，所以角色框重叠也不会误触 |
| `main.tscn` | `Background` 节点加入 `dimmable` 组（跟 house-rules 一样，组里的节点悬停时会变暗） |
| `project.godot` | `gui/theme/custom` 指向 `ui/theme.tres`，全游戏换像素字体 |

**参数**（每个角色节点的检查器里都能调）：`hover_strength` 0.3、`dim_strength` 0.5、`rise_time` 0.15、`fall_time` 0.35

**已知限制**
- 面板显示时会挡住鼠标，只有角色露出来的部分（或点 Hide Panels 后）才能触发悬停

**测试**
- 模拟鼠标移到 Mason 上：背景 modulate 变成 0.5，Mason 亮度 +0.3，其他人 -0.5；移开后都恢复 1.0
- 截图确认像素字体和变暗效果正常


---

## 第五轮：按最新文案同步（`Airlock文案 (2).pdf`，2026-10-03）

用户要求「最新 PDF 优先」，所以之前我自己改正过的写法（您、地、舱）全部改回 PDF 原文。Jason 事件（事件 5、6）用户说先不做，没有加。

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `story/story_zh.json` | 开场：Dragonbreath → **Firebreath**；「夺走您」→「夺走**你**」（「还有您。」PDF 里没变，保留）<br>第 1 天：「愉快地 / 一圈圈地 / 盲目地」→「的」<br>第 2 天：「充分地」→「充分的」；Dragonbreath → Firebreath<br>第 3 天：「漱口水还是**什么**这艘飞船」删掉「什么」；「冷冻舱」→「冷冻**仓**」；「英明的船长」→「**慈悲**的船长」；「一个劲地」→「一个劲的」<br>第 4 天：前 3 段按 PDF 改（加了 Tahiti、「抵达」、「先变成五具」），新增后 5 段（第三个好消息、Mason 的蜗牛、Elias、Mara）；新增物资分配页文字「那么，今晚该委屈谁来消灭这些难吃的叶子呢？」；标上 `event: random`（PDF 写了「可触发随机事件」） |
| `story/story_en.json` | 跟中文同步：Firebreath、wise → merciful、第 3 天 Elias 那句按删掉「什么」后的意思重译、第 4 天前 3 段改译、新增 5 段和分配页文字、`event: random` |
| `story/glossary_en.md` | 新增：Firebreath Ltd.、Tahiti、半人马座 → Centaurus |

**说明**
- 第 4 天加 `event: random` 不会改变游戏行为：没写 `event` 的日子本来就按随机事件规则抽
- PDF 里第 5 天及以后的日志还没接入

**测试**
- 脚本逐段比对 `story_zh.json` 和 PDF：除了 `{name}` / `{ta}` 模板变量，其他文字全部一致

---

## 点击角色对话 + 悬停显示名字（2026-10-03）

**新增文件**

| 文件 | 作用 |
|---|---|
| `dialogue_system/Dialogue.tscn`、`dialogue_system/dialogue.gd` | 对话框，仿 house-rules `dialogue.gd`：底部半透明黑框 + 细边框，左上角名字，打字机效果（40 字/秒，句号后停顿 0.22 秒、逗号后 0.08 秒），点击 / 回车先把这句打完，再点进入下一句；最后一句下面列选项，悬停的选项变白并加 `>`；选完显示角色的回答，再点一下关闭。对话时背景暗到 0.55，说话的角色亮、其他角色暗 |
| `story/dialogue_en.json` | 四个人的对话：开场 2 句 + 3 个选项，每个选项一句回答。**全部是我编的占位，带 `[TBD]`**，人设参考第 1 天日志 |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `character_system/character_portrait.gd` | 加 `class_name CharacterPortrait`；点击发 `clicked` 信号；悬停时头顶淡入短名（像素字体、描边，字号 `name_font_size` 24 可调）；对话期间停用悬停 |
| `main.gd` | 把每个角色的 `clicked` 接到对话框 |
| `main.tscn` | 最上层加 `Dialogue` 实例 |
| `ui/theme.tres` | 字体包了一层 FontVariation，空格加宽 3（house-rules 也这样处理：这个像素字体空格太窄，标点前后看起来像多了空格） |

**说明**
- 选项目前只有对白，不影响任何数值
- 死亡 / 被驱逐的角色点不了
- 只有英文版对话；`dialogue_zh.json` 还没做

**测试**
- 模拟点击 Mason：对话框打开 → 两句打完 → 出现 3 个选项 → 选第 2 个显示对应回答 → 再点关闭，背景恢复 1.0
- 截图确认对话框、选项、头顶名字显示正常


---

## 第六轮：面板改成手绘风（2026-10-03）

用户觉得圆角面板太 AI，要求参考背景画风自己做。背景是手绘、线条不规整、墙上贴着纸张/白板，窗框是米白粗线 + 深色描边，所以面板做成「贴在墙上的手绘框」。

**新增的文件**

| 文件 | 内容 |
|---|---|
| `ui/sketch_box.gd` | 自定义 StyleBox（`SketchBox`）：底色是略微歪斜的多边形；边框是三遍抖动的线（深色阴影线 + 米白主线 + 淡色虚影线），线头会超出角一点，像手画的；可选在顶边中间贴一条粉色胶带。随机种子由尺寸决定，所以不会闪 |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `ui/theme.tres` | PanelContainer 默认用 SketchBox（带胶带）；Button 的 normal / hover / pressed / disabled 都换成 SketchBox（无胶带、线更细），去掉 focus 框；HSeparator 改成淡米白线 |
| `main.tscn` | 删掉原来带 8px 圆角的 `StyleBoxFlat_panel` 和两个面板上的覆盖，让它们用主题 |
| `dialogue_system/dialogue.gd` | 对话框从 StyleBoxFlat 换成 SketchBox（没有胶带）；`border_color` 默认值改成更实的米白 `(0.86, 0.85, 0.79, 0.85)` |

**可调参数**（在 theme.tres 里点开样式就能改）：`fill_color`、`line_color`、`shade_color`、`line_width` 3、`wobble` 2.4、`overshoot` 6、`step` 36、`tape`、`tape_color`、`salt`

**测试**
- Godot 运行无新报错；录帧截图确认两个面板、Continue 按钮和胶带显示正常

---

## 生病状态（2026-10-03，效果是 Mumu 手调的）

**新增文件**

| 文件 | 作用 |
|---|---|
| `effect_system/effects/sick.tres` | 生病状态 `sick`，持续时间无限（没有倒计时，也不会变成别的状态） |
| `character_system/SickParticles.tscn` | Mumu 在 `CrewStage.tscn` 里调的粒子，原样搬出来做成可复用场景，参数一个没改 |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `character_system/crew.gd`、`Crew.tscn` | 新增 `sick_effect`、`is_sick()`、`make_sick()`、`cure_sickness()`。生病和受伤 / 重伤可以同时存在 |
| `character_system/character_portrait.gd` | 每个角色自带一份粒子；生病时角色变绿（`sick_tint`，就是 Mumu 调的颜色）+ 粒子开始飘，好了就恢复。绿色用 `self_modulate`，只染角色本身，不会把粒子和头顶名字也染绿。粒子位置 `sick_particles_anchor` = (0.5, 0.35)，按角色框比例算，换大小也会跟着走 |
| `character_system/CrewStage.tscn` | 删掉了 Mara 身上手调的绿色和那个单独的 GPUParticles2D 节点（已经搬进上面的脚本 / 场景，不删的话 Mara 会一直绿、粒子会一直飘） |

**还没做（等决定）**
- 什么情况会生病、怎么治好：现在没有任何地方调用 `make_sick`
- 左侧面板还不显示"生病"

**测试**
- 让 Helena 和 Mara 生病：两人变绿、粒子在飘，Mason 不受影响；治好 Mara 后粒子停止。截图确认

---

## 第七轮：7 个随机事件 + 事件弹窗（`Airlock文案 (3).pdf`，2026-10-03）

用户确认：8 条事件全做（含 Jason 两条）；事件用屏幕中间弹窗；旧的 5 个英文占位事件移出随机池；PDF 没写的数值我先填占位值。

**文案录入**
- `story/story_zh.json` / `story_en.json` 新增 `events` 段：木屑餐、小偷！、酒精提纯、他也算警卫吗？、我们的软体室友、居然有比他们四个还不正常的人？、我们真的受够了！、债务危机。中文按 PDF 原文，英文按译名表翻译（门 → airlock）
- `xxx` / `他` 换成模板变量 `{name}` / `{ta}`（英文另有 `{ta_obj}` him/her）
- PDF 里给程序看的说明（「前提：…」「（如果Mason死亡则删除）」「（不论如何选择，食物增加）」「四人和不作为选项」「选择船员则船员成为（流放）状态」等）转成了逻辑，不显示
- 木屑餐最后一段「如果你相信Elias……」当作给玩家的提示显示出来了
- PDF 没写的文字用 `[占位]` / `[TBD]`：受够了的「不作为」选项和赶走结果；债务危机的「抄起武器」选项、打退结果、Mara / Dr. Voss / Mason 的离开文字；Elias 离开文字后半句（PDF 里是拼音草稿 na jiu shi ta de sheng ming）

**新增文件**

| 文件 | 作用 |
|---|---|
| `event_system/event_popup.gd` + `EventPopup.tscn` | 事件弹窗：屏幕变暗，中间手绘框（SketchBox + 胶带），标题、正文（太长会滚动）、选项按钮。打开时角色不能点 |
| `event_system/events/story_event.gd` | 新事件的基类：文案从 story json 的 `events` 读，按 Elias / Mara / Dr. Voss / Mason 顺序列人 |
| `sawdust_meal_event.gd` / `.tres` | 木屑餐 |
| `thief_event.gd` / `.tres` | 小偷！ |
| `alcohol_distill_event.gd` / `.tres` | 酒精提纯（可重复） |
| `mason_guard_event.gd` / `.tres` | 他也算警卫吗？（没有选项，直接给结果） |
| `octopus.tres` | 我们的软体室友（用现有危险任务，Elias 走现有随机谈判） |
| `jason_knock_event.gd` / `.tres` | Jason 敲门 |
| `jason_fed_up_event.gd` / `.tres` | 我们真的受够了！ |
| `debt_crisis_event.gd` / `.tres` | 债务危机 |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `main.gd` / `main.tscn` | 事件改成弹窗显示；左侧资源栏在 Josan 在船上时多一行提示 |
| `journal_system/journal.gd` | `event_text()` 读事件文案（段落可以写 `if_on_board` 条件）、`member_args()` 给人名和代词 |
| `event_system/event_manager.gd` / `.tscn` | 注册 8 个新事件；Josan 在船状态（`guest_aboard`），每 2 天扣 1 漱口水（`guest_drink_interval` / `guest_drink_cost`） |
| `event_system/events/dangerous_task_event.gd` | 文案可以从 json 读；新增 `abandon_injure_all`（放弃时所有乘客受伤） |
| `character_system/crew.gd` / `crew_member.gd` | `heal()` 直接治好；`is_loyalty_full()`；`exile()` 可以带原因（债务危机 = `debt`）；记录累计挨饿天数 `hungry_day_count`、上次用漱口水的日子、酒精提纯是否触发过 |
| `game_flow/game_flow.gd` | 每天结束先算 Josan 喝漱口水；被债务带走的第二天日志用 `journal_exiled_debt` |
| `story/system_text_*.json` | 新增 `event_sick`、`journal_exiled_debt`、`ui_guest_aboard`（都是占位） |
| `argument` / `criminal_demand` / `doctor_demand` / `repair_leak` / `salvage_cargo.tres` | `in_random_pool = false`，文件保留 |

**占位数值**（都在对应 .tres 的检查器里能改）

| 事件 | 值 |
|---|---|
| 木屑餐 | Elias 方案 +3 Food，每个乘客 30% 生病；Dr. Voss 方案 +1 Food；补偿 Elias 1 Food 或 1 漱口水；「胡闹」Mason 忠诚 +1 |
| 小偷 | 触发：某乘客**累计** 3 天没吃饭（PDF「连续三次二级饥饿」在现有规则下做不到，连续 3 天不吃就饿死了）；武力 25% 小偷受伤；交换 -1 漱口水；放过 -2 Food；Mason 选项要忠诚满且小偷不是 Mason |
| 酒精提纯 | 今天或昨天给这个人用过漱口水维持伤势、Dr. Voss 能看病、病人不是 Dr. Voss；每人只触发一次；-2 漱口水 |
| 他也算警卫吗 | +2 Food；被抓的人 50% 受伤 |
| 章鱼 | 成功 +2 Food；Elias 受伤 15%；其他人受伤 60%、死亡 10%；放弃 = 所有乘客受伤（船长不算） |
| Jason 敲门 | 两个选项都 +2 Food；允许后从进舱那天起每 2 天 -1 漱口水 |
| 受够了 | 派任何人都能赶走 Josan，不受伤；不作为 = 继续留着 |
| 债务危机 | 派谁谁就变成「流放」；抄起武器 = 每个乘客 30% 受伤 |

**测试**
- 新增事件测试 122 项全部通过：每个事件的触发条件、选项、扣加资源、受伤 / 生病 / 治好 / 流放、Josan 每 2 天扣漱口水、旧事件不会再抽到、中英文 key 一致
- 300 局随机模拟没有卡住
- 有窗口截图：木屑餐弹窗（长文可滚动）、Elias 不满的第二页、选完后弹窗关闭进入下一步

---

## 开始界面（2026-10-03）

**新增文件**

| 文件 | 作用 |
|---|---|
| `start/StartScreen.tscn` | 开始界面：背景图 + 标题 "Airlock" + 「开始游戏」「退出」两个按钮（右下角，用现有主题的手绘按钮） |
| `start/start_screen.gd` | 进入时从黑屏淡入（`fade_in_time` 1.2 秒）；点开始后淡出到黑（`fade_out_time` 0.8 秒）再切到 `main.tscn`；网页版隐藏退出按钮；进来就开始放歌单 |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `start/start.png` → `start/start.webp` | 原文件其实是 WebP 格式只是后缀写成了 .png，Godot 导入失败，所以改了后缀，图片内容没动 |
| `project.godot` | 主场景改成 `res://start/StartScreen.tscn` |
| `story/system_text_zh.json`、`story/system_text_en.json` | 新增 `start_title`、`ui_start_game`、`ui_quit` |

**说明**
- 背景按屏幕铺满，顶边对齐（只裁下面），保证右上角的恐龙不会被切掉
- `main.gd` 里原来的 `Music.play_playlist()` 没删：歌单已经在播时再调用只会保持音量，不会重头放

**测试**
- 1600×900 录帧：淡入正常、恐龙完整、按钮文字正确；模拟点击开始后淡出并进入游戏的 Opening 页面

**第七轮补充（用户确认）**
- 敲门的人统一叫 **Josan**：`story_zh.json` / `story_en.json` 事件正文里的「Jason」改成「Josan」；译名表加了 Josan（不用 Jason）
- 小偷触发条件确定为「累计 3 天没吃饭」
- 木屑餐提示段落、章鱼 Mason 按钮文字、`[占位]` 文案保持现状

### 开始界面：星空粒子（2026-10-03）

照 until-someone-passes 里星空井 `well/well.tscn` 的 `Stars` 粒子搬过来：同一张柔光圆点贴图、同样的颜色（黄 / 白 / 淡蓝随机）、同样的“先变大变亮再消失”曲线、同样的旋转，寿命 4 秒。原作是 384×216 的画面，这里按 2048 宽的背景图把粒子大小放大约 5.3 倍（`scale` 0.27–1.07）。

只留一层 `Background/Sky/CoreStars`：银河中心周围，4 颗（Mumu 觉得铺满全图太多太杂，原来的全图 40 颗、银河外环 24 颗已删）

- `Sky` 跟着背景一起缩放，粒子位置都是按原图像素填的，换分辨率不会跑位
- 加了 `preprocess` 4 秒，一进界面就满天星，不用等它慢慢冒出来

**去掉了背景呼吸缩放（背景抖动的原因）**：粉笔画颗粒很细，每帧缩放一点点，颗粒就在像素之间来回跳，看起来像在抖；图片又没开 mipmap，缩小显示时会更闪。现在背景静止，动感交给星星；`start.webp.import` 打开了 mipmaps，`Background` 用 `texture_filter` = 线性 + mipmap，缩小也干净

**测试**
- 1600×900 录帧：星星位置正确、闪烁正常，背景不再抖，无报错

**第七轮补充二：Josan 的效果对玩家保密**
- 「允许」选项去掉效果说明：「允许（Josan入舱，每两天减少1漱口水）」→「允许（Josan入舱）」，英文同步
- 左侧资源栏不再显示 Josan 在船上的提示，删掉 `main.gd` 里那一行和 `ui_guest_aboard` 文本
- 扣漱口水的逻辑不变（每 2 天 -1），只是不告诉玩家，玩家只能从漱口水数量变少发现

### 修复：生病无法治愈（2026-10-03）

之前生病只能靠代码里的 `cure_sickness` 去掉，游戏里没有任何入口，角色一旦生病就一直病着。

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `character_system/crew.gd` | 新增可调参数 `sickness_cure_cost`（默认 1）；新增 `can_cure_sickness`、`cure_sickness_with_mouthwash`（扣漱口水并治好） |
| `main.gd` | 分配晚餐界面里，生病的角色那一行多一个「漱口水治病（-1）」按钮，漱口水不够时按钮变灰；左侧角色栏生病时显示「生病」 |
| `story/system_text_zh.json`、`story/system_text_en.json` | 新增 `ui_cure_sickness`、`ui_sick` |

**说明 / 假设**
- 治病花 1 瓶漱口水，不需要医生在船上（数值可在 Crew 的 Inspector 里改）
- 生病和受伤互相独立，又病又伤时两个按钮都会出现

**测试**
- Godot headless 启动与脚本检查无报错

**第七轮补充三：章鱼选项都写明风险**
- Mara / Dr. Voss / Mason 三个按钮都加上「（大概率受伤，小概率死亡）」/「(high chance of injury, small chance of death)」；Mason 原来的「三人大概率受伤……」改成同样写法。Elias 保持「（小概率受伤）」

---

## Josan 立绘 + 两套站位（2026-10-03）

Josan 节点和"有 Josan 时的站位"是 Mumu 在 `CrewStage.tscn` 里摆的，我只接逻辑。

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `event_system/event_manager.gd` | 新增信号 `guest_changed(aboard)`，在 `admit_guest` / `evict_guest` / `reset` 时发出 |
| `character_system/character_portrait.gd` | 新增 `is_guest` / `guest_name`：访客节点只在 `EventManager.guest_aboard` 时显示，不看健康 / 生病；新增 `get_display_name()`、`can_talk()`。新增 `offsets_without_guest`（左、上、右、下）：场景里摆的位置 = 有 Josan 时的站位，没有 Josan 时换成这组值；Josan 上船 / 被赶走时 0.4 秒滑过去（`layout_move_time`）。这组值是 0 的角色不动（Mason） |
| `character_system/CrewStage.tscn` | Josan 节点：`member_id` 改 `josan`、勾 `is_guest`、编辑器预览图换成 josan.png；Elias / Helena / Mara 填了 `offsets_without_guest` = 加 Josan 之前的位置 |
| `dialogue_system/dialogue.gd` | 名字和能否对话改用 `get_display_name()` / `can_talk()`，访客也能对话 |
| `story/dialogue_en.json` | 加 Josan 的占位对话（`[TBD]`，我编的） |

**怎么调**
- 有 Josan 的站位：直接在编辑器里拖
- 没 Josan 的站位：改各角色检查器里的 `offsets_without_guest`

**测试**
- 无 Josan → 上船 → 被赶走：Elias / Helena / Mara 位置在两套之间正确切换，Josan 显示 / 隐藏正确；点击 Josan 能打开对话

---

## 第八轮：完整接入第 01–28 天日志与流放剧情（2026-10-03）

把完整的 28 天航行日志、物资分配提示、流放对白及每日角色判定完整接入游戏，修护之前损坏的 JSON 语法，并将日志逻辑与底层系统全面打通。

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `story/story_en.json` | 修复此前文件底部两个独立 JSON 根对象导致的解析失败；完整合并录入第 01 到第 28 天全部日志条目、物资分配引导语与事件标记；录入 Elias、Mara、Dr. Voss、Mason 的离开对白（`departure_*`）；按《固定译名表》规范化文本（hatch → airlock、Centauri → Centaurus 等） |
| `journal_system/journal.gd` | 增强条件检查 `_matches()`：支持 `if_on_board`、`if_not_on_board`、角色状态（`alive` / `dead` / `exiled`）、Airlock 流放标记（`day7_exile`、`day14_exile` 等）；增强段落插值 `_fill_paragraph()`：支持 `{random_passenger}`（在场乘客随机填入）、`{exiled_name}`（被流放者姓名替换）、`any_passenger`（Mara 不在时代替听到储物间异响） |
| `airlock_system/airlock.gd` | 解决流放时记录流放状态标记：`day{N}_exile`（`yes` / `no`）、`last_airlock_target` 以及 `last_airlock_target_name`，供后续日志分支判定 |
| `event_system/event_manager.gd` | `pick_event_for_day` 对固定标记为 `none`、`airlock`、`ending` 的日子直接返回 `null`，不再报缺事件资源警告 |
| `timeline_manager/timeline.gd` | 总天数 `total_days` 设定为 28，`is_airlock_day` 增加 `day < total_days` 判断（第 28 天不触发 Airlock，当晚结算后直接进入 Tahiti 结局） |
| `game_flow/game_flow.gd` | 接入日志文案附带的剧情机制：第 6 天 Mason 暴乱导致 Elias 轻伤；第 12 天若 Dr. Voss 不在船上触发食物中毒几率致伤；第 16 天击杀蜘蛛获得食物（Food +5）；Airlock 流放不再追加多余的 `[TBD]` 占位提示 |

---

## Josan 微醺粒子（2026-10-03）

**新增文件**

| 文件 | 作用 |
|---|---|
| `character_system/TipsyParticles.tscn` | 微醺泡泡：空心小圆圈（中间透明、边缘亮），颜色在粉红 / 琥珀 / 淡粉之间，慢慢往上飘、带一点左右晃（turbulence），淡入淡出，16 个、寿命 2.6 秒，开场预热 2 秒（一出现就有泡泡） |

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `character_system/character_portrait.gd` | 新增 `idle_particles`（任意粒子场景，角色显示时一直播放）和 `idle_particles_anchor`（按角色框比例的位置） |
| `character_system/CrewStage.tscn` | Josan 节点挂上 `TipsyParticles.tscn`，位置 (0.62, 0.22)，大概在他脸那里 |

**测试**
- Josan 上船后截图：脸周围有粉色 / 琥珀色泡泡往上飘

---

## 开始界面语言切换（2026-10-03）

**修改的文件**

| 文件 | 改了什么 |
|---|---|
| `start/StartScreen.tscn` | Menu 里在「开始游戏」和「退出」之间加 `LanguageButton` |
| `start/start_screen.gd` | 点语言按钮在 en / zh 之间切换，并当场刷新开始界面文字 |
| `journal_system/journal.gd` | 新增 `language`、`set_language()`、`next_language()`、信号 `language_changed`；文本路径改成 `story_%s.json` / `system_text_%s.json`；选择存到 `user://settings.cfg`，下次启动沿用。中文里缺的 key 自动用英文补（先读 en，再用 zh 覆盖）。新增 `localize_member()`、`effect_name()` |
| `character_system/crew.gd` | `reset()` 复制角色后调用 `Journal.localize_member()` |
| `main.gd` | 伤病倒计时的状态名改用 `Journal.effect_name()` |
| `dialogue_system/dialogue.gd` | 读 `dialogue_<语言>.json`，没有就用 `dialogue_en.json` |
| `story/system_text_en.json` | 加 `ui_language`：「Language: English」 |
| `story/system_text_zh.json` | 加 `ui_language`：「语言：中文」；角色中文名 / 代词（船长、他 / 她，取自旧版 .tres，人名保持英文）；状态名 生病 / 受伤 / 重伤 / 死亡 |

**注意**
- 默认英文；按钮显示的是当前语言

**测试**
- Godot headless：切 zh / en，开始界面按钮、系统文字、船长名、代词、状态名、第 1 天 / 第 10 天日志标题都正确；切换结果写入 settings.cfg

**补充：对话中文版**
- 新增 `story/dialogue_zh.json`：五个角色（Mason / Elias / Dr. Voss / Mara / Josan）的对话按英文版翻成中文，结构和英文版一一对应。用词按 `glossary_en.md` 和 `story_zh.json`（Food、干粮、冷库、舱门、堆肥箱、漱口水；人名不翻）
- `story/dialogue_en.json`：去掉所有 `[TBD]` 前缀，内容没改
- 测试：Godot headless 下 zh / en 各加载一次对话，读到的是对应语言

**补充：事件中文版**
- 原因：`fire_check`（第 2 天查火）和 5 个随机事件（`argument` / `criminal_demand` / `doctor_demand` / `repair_leak` / `salvage_cargo`）的文字写死在 `.tres` 里，只有英文。其他剧情事件读 `story_zh.json`，本来就能切
- 新增 `story/event_text_zh.json`：按 event_id 存这 6 个事件的中文，内容是 git 历史（527c989）里这些 `.tres` 的中文原文，没改字，`[占位]` 保留
- `journal_system/journal.gd`：新增 `localize_event()`，中文时用 `event_text_zh.json` 覆盖事件和选项上的文字字段，切回英文时恢复 `.tres` 原文
- `event_system/event_manager.gd`：`start_event()` 里先 `Journal.localize_event(event)` 再 `begin()`
- 英文仍以 `.tres` 为准，改英文直接改 `.tres`；改中文改 `event_text_zh.json`
- 测试：Godot headless 下 zh → en → zh 切换，6 个事件的标题、描述、选项、结果文字都对应正确语言

**补充：中文日志第 05–28 天 + 离船台词**
- `story/story_zh.json` 加入第 05–28 天。文字取自编剧的《Airlock文案 (3).pdf》（2026-10-03 18:28 版），逐字照搬；条件分支（`if` / `member`）和 `story_en.json` 一一对应
- 只做了这些处理：去掉 PDF 里给程序看的标注（【Elias轻度受伤】【所有角色有概率受伤】【食物增加】「如果 Mara 已死就换其他人」等）；修了 PDF 里方向错乱的引号（第 6 天「一吓到就尖叫」「友谊」，第 23 天美食家那句）；第 8、9 天两句缺句号的补了句号；原文的错字没改（第 25 天「总是就是」）
- 第 22 天流放分支原文写的是「ta」，改成 `{ta}`，按被流放的人显示他 / 她（`member: last_airlock_target`）；英文版那句没用代词，不受影响
- 第 6 天英文多一句 "Her only condition: don't pick her."，PDF 中文没有，中文按 PDF；第 20 天「总不能让那个人空着肚子上路吧」在 PDF 里是两种情况共用的结尾，英文版放进了 Mara 不在船上的分支，中文跟着英文结构放
- 4 个离船事件 `departure_*`（第 8、15 天流放分支里也用同样的话）：PDF 里只有 Elias 开头一句（后半是拼音占位），其余是空的。中文是我照英文版翻的，Elias 那句开头用了 PDF 原文；Mason 那条英文本身是 `[TBD]`，中文对应写 `[占位] 原文缺失，需要原作者补一句`
- 第 02–04 天原来没有 `allocation_title`，切成中文后会回退成英文「Supply Allocation」，补成「物资分配」（和第 01 天一样）
- 测试：Godot headless 中文模式，模拟第 7 天流放 Mara、第 21 天流放，翻完第 1–28 天：每天都有内容，标题是中文，没有残留 `{}`，`{exiled_name}` / `{name}` / `{ta}` 都正确替换

## 修复：受伤 + 生病时物资分配面板被撑宽

**原因**：同一角色既受伤又生病时，分配行里有 勾选框 + 漱口水维持 + 医生治疗 + 漱口水治病 四个控件，横排 HBoxContainer 最小宽度 703px，把右侧 ContentPanel 撑出屏幕（1152 宽窗口下超出约 11px），名字勾选框也被挤窄。

| 文件 | 改动 |
| --- | --- |
| `main.gd` | `_build_allocation_row()` 的行容器从 `HBoxContainer` 改为 `HFlowContainer`，按钮放不下时自动换到下一行 |

**测试**
- Godot 1152×648 窗口：让一名角色受伤 + 生病、另一名受伤后进入分配阶段截图，面板不再超出屏幕，多出的「漱口水治病」按钮换行显示

## 漱口水维持按钮：倒计时满时显示「明天可用」

**背景**：规则是倒计时满的时候不能用漱口水维持。重伤第 1 天倒计时是 2/2，按钮是灰的，看起来像漱口水对重伤没用（刚受伤第 1 天也一样）。规则不变，只改提示。

| 文件 | 改动 |
| --- | --- |
| `character_system/crew.gd` | 新增 `is_injury_countdown_full()`；`can_maintain()` 改用它，判断结果不变 |
| `main.gd` | 倒计时满时，维持按钮文字用 `ui_maintain_full` |
| `story/system_text_zh.json` | 加 `ui_maintain_full`：「漱口水维持（明天可用）」 |
| `story/system_text_en.json` | 加 `ui_maintain_full`：「Mouthwash upkeep (available tomorrow)」 |

**测试**
- Godot 1152×648 窗口：一人刚转重伤（2/2）且生病，另一人受伤已过一天（2/3）。前者按钮显示「漱口水维持（明天可用）」并且是灰的，后者显示「漱口水维持（-1）」可以点
## 修复：Mara 厨师食物减免机制（2026-10-04）

**问题原因**
- 原实现为 `ceili(count * 0.75)`（按 75% 向上取整）。
  - 5 人时 `5 * 0.75 = 3.75` 向上取整为 4（看起来减少了 1 份）；
  - 3 人时 `3 * 0.75 = 2.25` 向上取整依然是 3（没有减免）。

**修改内容**
- `character_system/crew.gd`：
  - 新增配置项 `chef_food_reduction`（默认 1）与 `min_chef_meal_cost`（默认 1，防止 1 人用餐时 0 消耗白嫖）；
  - `meal_cost()` 计算公式改为 `max(min_chef_meal_cost, count - chef_food_reduction)`。
  - 效果：5 人吃 4 份、4 人吃 3 份、3 人吃 2 份、2 人吃 1 份、1 人吃 1 份、0 人吃 0 份。

## 新事件：天赋人权 / 事后追偿 + 工人谈判「叫 Mason 去处理吧」（2026-10-04）

文案来源：编剧《Airlock文案 (4).pdf》事件 9、事件 10，中文逐字照搬，「xxx」换成 `{name}`、「ta」换成 `{ta}`（随机挑一个在船上的非 Mason 乘客）。英文是我按术语表翻的。

| 文件 | 改动 |
| --- | --- |
| `event_system/events/mason_rights_event.gd` + `mason_rights.tres` | 新事件「天赋人权」：Mason 在船上且还有别的乘客时进随机池。绑起来 → Mason 流放（原因 `tied`）；再忍忍 → Mason 忠诚 +1 |
| `event_system/events/mason_redress_event.gd` + `mason_redress.tres` | 新事件「事后追偿」：Mason 在船上时进随机池。郑重道歉 → 漱口水 -1、忠诚 +1；叫他闭嘴 → 船长 50% 受伤 |
| `event_system/event_manager.tscn` | 两个事件加入事件列表 |
| `event_system/events/dangerous_task_event.gd` | 工人谈判（第 2 天查火 + 随机谈判）里原来的【威慑】换成「叫 Mason 去处理吧」，只有 Mason 忠诚满（3/3）才出现。效果和原来的威慑一样：Elias 直接去干活，不花资源，不扣忠诚。医生条件那里的威慑没动 |
| `story/story_zh.json` / `story_en.json` | `events` 里加 `mason_rights`、`mason_redress` |
| `story/system_text_zh.json` / `_en.json` | 加 `ui_worker_mason`（「叫{criminal}去处理吧」，沿用小偷事件的说法）；加 `journal_exiled_tied`（[占位] Mason 被绑起来后第二天的日志） |
| `story/system_text_zh.json` | 补回 10 个缺失的 key：`member_name_captain`、`member_short_captain`、4 个 `member_pronoun_*`、4 个 `effect_name_*`。HenryY842 的 db22f1a 把这个文件挪进了 `music_system/tracks/`，Un_Z 的 8e5dfbe 重新加回 `story/` 时少了这几个，导致中文模式下代词显示 he / she、船长显示 Captain。值从 `music_system/tracks/system_text_zh.json` 里抄的，那个文件没动 |
| `Jiamu edited.md` | 删掉合并时留下的冲突标记（`<<<<<<<` / `=======` / `>>>>>>>`），两边内容都保留 |

**数值（文案没写，先自己定的）**
- 「叫他闭嘴」船长受伤概率 50%（`silence_injury_chance`）
- 两个事件的忠诚 +1、道歉扣 1 瓶漱口水（文案写的是「一瓶」）
- 两个事件都不可重复

**测试**
- Godot headless，中英文各跑一遍：两个事件能触发、文字无残留 `{}`、代词正确（中文显示「她」）；忍 → 忠诚 +1；绑 → Mason 流放，之后两个事件都不再触发；道歉 → 漱口水 -1、忠诚 +1；闭嘴 200 次船长受伤 95 / 104 次
- 工人谈判：忠诚 1、或满过之后掉到 2，都不出现 Mason 选项；忠诚 3 时第 2 天查火和章鱼的谈判都出现「叫Mason去处理吧」，选了以后任务完成、不扣资源、忠诚仍是 3

## 补全占位 + 同步文案 (4) + 完整通关（2026-10-04）

**合并修复**
- 远端 `story/system_text_en.json` / `_zh.json` 里提交进了 `<<<<<<< Updated upstream` 冲突标记，JSON 读不出来，游戏里所有系统文字都会显示成 key。合并时保留了 upstream 那一侧（返回主菜单、游戏指南），再加上我这边的 key

**数值**
| 文件 | 改动 |
| --- | --- |
| `event_system/events/sawdust_meal_event.gd` | 木屑餐 Food 收益两个方案各 +2：Elias 方案 3 → 5，Dr. Voss 方案 1 → 3 |

**机制（按文案 (4) 和游戏指南）**
| 文件 | 改动 |
| --- | --- |
| `game_flow/game_flow.gd` | 乘客饿死或伤重死亡 → 进入坏结局 `uprising`（开场「不要让船员死在所有人的面前」+ 文案的坏结局 + 指南里的 "If any crew member dies from natural causes, the game ends"）。危险任务里死亡（`task`）不算，还是只写进第二天日志 |
| `game_flow/game_flow.gd` | 结局文字改成从 `story_*.json` 的 `endings` 读；好结局按谁在船上拼段落，Josan 在船上时加他那句；只剩船长时用「希望他们见到我的成就后……」；第 28 天流放了人时，结局开头先放这个人的流放固定文本 |
| `game_flow/game_flow.gd` | 日志阶段的剧情伤害（第 6、12 天）如果直接致死，立刻进结局，不再先显示日志 |
| `timeline_manager/timeline.gd` | 第 28 天也是气闸日（文案：资源分配 → 你当然还可以选择一个人流放 → 流放选择 → 进入结局） |
| `journal_system/journal.gd` | 新增 `get_ending()`、`get_airlock_text()` |
| `airlock_system/airlock.gd` | 气闸页面开头显示当天的 `airlock_text`（第 28 天那句） |
| `event_system/event_manager.tscn` | 5 个测试用的占位事件（争执、Mason 的要求、Helena 的条件、冷却管道破裂、舱外补给箱）移出事件池，只留文案里的事件 1–10 + 第 2 天查火。文件没删 |

**文案：照搬编剧原文（文案 (4)）**
- 开场加「不要让船员死在所有人的面前。」
- 船员流放固定文本（Elias / Mara / Dr. Voss / Mason）：`departure_*` 和第 8、15 天流放分支都换成 (4) 的原文；Mason 那段原来是占位
- 结局：好结局（含每人一句、Josan、只剩船长）、坏结局、船长饿死结局
- 第 28 天流放提示「你当然还可以选择一个人流放——如果你真的那么丧心病狂的话。」
- 木屑餐「这简直是胡闹！」后面加【忠诚度上涨】
- 英文是我按术语表翻的

**文案：我自己写的（原文没有，请编剧过目）**
- 结局：船长伤重死亡、Mason 叛变
- 债务危机：「抄起武器」选项、打跑之后的结果、4 个人各自跟 Firebreath 走时的一句
- 我们真的受够了：「随他去吧」选项、赶走 Josan 的结果
- 系统文字里所有原来带 `[占位]` / `[TBD]` 的：工人谈判的 6 种条件、工人拒绝、威慑、任务受伤 / 死亡、秘密揭示、失踪 / 死亡日志、违约、威慑解锁、气闸开场 / 结果、生病、被 Firebreath 带走、Mason 被绑、空日志
- 删掉了系统文字里不再使用的 `ending_*`（已移到 `story_*.json` 的 `endings`）
- 剩下的 `[占位]` 只在 `story/event_text_zh.json` 和那 5 个已移出事件池的测试事件 `.tres` 里，游戏里不会出现

**测试**
- Godot headless 自动打 800 局（中英文各 4 种玩法 × 100 局：只在快饿死时喂饭 / 宽松喂饭 × 不流放 / 每次都流放 / 优先流放 Mason；事件选项随机）。全部走到结局，没有卡住；所有日志、事件、选项、气闸、结局文字里没有 `{}`、`TBD`、`占位`
- 结局分布（事件选项是乱选的，真人玩会更好）：存活 56–83%，坏结局 15–42%，船长伤重 0–5%。坏结局大多是乱选导致的伤重死亡
- 5 种结局 + 只剩船长 + 第 28 天流放后的结局，中英文都单独渲染检查过
- 第 28 天确认是气闸日，开头显示那句流放提示

## 修复：有人饿死时结局页是空白（2026-10-04）

**原因**：Un_Z 的 60b6016 把「有人饿到第 3 天」改成发 `Crew.infighting` 信号，走他新加的 `infighting` 结局（文字在系统文字 `ending_infighting`）。同一时间我把结局文字改成从 `story_*.json` 的 `endings` 读，合并后 `endings` 里没有 `infighting`，所以只要有人饿死，结局页就是空的。而且船长饿死也走这条路，编剧写的「船长饿死结局」永远出不来。

| 文件 | 改动 |
| --- | --- |
| `game_flow/game_flow.gd` | `_on_infighting()`：饿死的是船长 → `captain_starvation`（编剧的船长饿死结局）；是乘客 → `uprising`（编剧的坏结局「你真是个蠢货……起义爆发了」）。Un_Z 的信号保留不动 |

- `ending_infighting` 这条系统文字现在没地方用了，没删，留给 Un_Z 决定

**测试**
- Godot headless 自动打 800 局（中英文 × 少喂 / 多喂 × 流放 / 不流放），全部走到结局，结局文字都不是空的，没有 `{}` / TBD / 占位 / 原文缺失
- 单独测：船长饿死 → 「这算是牺牲，还是……」；Mara 饿死 → 「你真是个蠢货……」，中英文都对

## 结局剧情接进 EndScreen + 内斗结局保留（2026-10-04）

**剧情**
| 文件 | 改动 |
| --- | --- |
| `game_flow/game_flow.gd` | `_on_infighting()`：船长饿死 → `captain_starvation`；乘客饿死 → `infighting`（Un_Z 的内斗结局）。乘客伤重死亡仍是 `uprising`（编剧的坏结局） |
| `story/story_zh.json` / `_en.json` | `endings` 加 `infighting`，文字是 Un_Z 写的原文，从系统文字挪过来 |
| `story/system_text_zh.json` / `_en.json` | 删 `ending_infighting`（已挪到 `endings`）；加 `ui_credits`：「制作人员」/ "Credits" |

**结局画面**
| 文件 | 改动 |
| --- | --- |
| `main.gd` | `_show_ending()` 不再在主界面显示结局文字，所有结局都直接进 `EndScreen`（原来只有好结局有「继续」按钮能进） |
| `scene_system/EndScreen.tscn` | 新增居中的 `StoryPanel`（标题「结局」+ 可滚动正文 + 「继续」按钮，深色半透明底）；新增全屏 `Dim` 遮罩；菜单加「重新开始」按钮；`Control` 四边边距都设成 64，面板居中 |
| `scene_system/end_screen.gd` | 先显示结局剧情，点「继续」后面板淡出，再按 Henry 原来的节奏淡入菜单；按钮文字改成走 `Journal.text`，能切中英文；加「重新开始」（回 `main.tscn` 开新局）；立绘只显示还在船上的人（原来死掉的也会显示）；非好结局时不显示立绘、背景压暗（现在只有一张 Tahiti 草地背景，坏结局用它不合适） |

**测试**
- Godot 1152×648 窗口截图：中文 / 英文好结局（流放 Mara + Josan 在船）、中文起义、英文内斗、中文叛变。面板文字正确，好结局只显示在船上的人的立绘，坏结局背景压暗、无立绘；点「继续」后面板淡出、出现「重新开始 / 返回主菜单 / 制作人员」
