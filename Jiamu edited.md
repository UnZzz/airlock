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
