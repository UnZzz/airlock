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
- 第 2 天日志只有标题，正文显示「[占位] 本日日志待补充。」
- 第 3–30 天的日志标题按文案的格式自动生成（「失事第03天 日志」……）

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
- 第 2 天日志正文没有替你写，仍然显示占位
