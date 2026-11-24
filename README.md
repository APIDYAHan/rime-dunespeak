# 沙丘语输入法（DuneSpeak CN）

把候选词改写成《未知伤亡》（Casualties Unknown）角色 **Dune（沙丘 [SAW-12]）** 说话方式的
RIME 输入方案。词库来自游戏官方中文语言文件中 594 条原版台词 + 8 则手写纸条的实测统计。

打 `woele`，出来的不是「我饿了」，而是——

> 咯嗯... 沙—丘 饿—饿...

## 下载

**所有文件都在 Releases 页：https://github.com/APIDYAHan/rime-dunespeak/releases/latest**

目前有三种装法，按自己的情况挑一条：

| 你的情况 | 用哪个 | 难度 |
|---|---|---|
| 没装过小狼毫 | `DuneSpeak-Custom-Installer-0.17.4.exe`（沙丘语定制安装器） | 双击装完就好 |
| 已经装着官方小狼毫 | `DuneSpeak-Schema-AddPack.zip`（沙丘语方案添加包） | 双击 bat，点两下 |
| 会用 Rime / plum | 本仓库源码 | `rime-install` 一条命令 |

> 仓库本体只放方案文件（yaml + lua），安装器、添加包、安装器源码都是 Releases 附件。
> 注：GitHub 附件不支持中文文件名，所以下载到的文件是英文名，对照如下。
> 下载后可用 `Get-FileHash 文件名` 核对指纹，确认是原包：

| 文件 | SHA256 |
|---|---|
| `DuneSpeak-Custom-Installer-0.17.4.exe` | `C3AA5C2455EC260C589A09E5845672F63EB8682305877763B1282228572BA14F` |
| `DuneSpeak-Schema-AddPack.zip` | `C3F3A66C345FECF783F6E1CC58EE27225EAED83E8D38B433280CB8C86FD53B5C` |
| `DuneSpeak-Installer-Source.zip` | `2A26ED3909C7585D1E1C5FF9225AC6A2A0250B90BC32D8414915F47B98FCDA07` |

## 安装

### 方式一：定制安装器（推荐，全新安装）

1. 到 Releases 下载 `DuneSpeak-Custom-Installer-0.17.4.exe`（沙丘语定制安装器）；
2. 装过旧版小狼毫的，先卸载干净；
3. 双击安装器，选好安装位置，一路「下一步」；
4. 走到「方案选单设定」窗口，第一项「沙丘语·Dune」已默认勾选，直接点「确定」
   （想同时用明月拼音、五笔，一起勾上即可）；
5. 装完按提示重启电脑，切到小狼毫就能打字。

>注意：装完不要点「自动更新」，更新后大概率见不到沙丘语。

### 方式二：添加包（已经装着官方小狼毫）

1. 到 Releases 下载 `DuneSpeak-Schema-AddPack.zip`（沙丘语方案添加包）并解压；
2. 双击 `添加沙丘语.bat`，点「添加沙丘语方案」；
3. 在弹出的官方窗口里勾「沙丘语·Dune」，点「确定」；
4. 回到向导点「检查是否添加成功」，看到「沙丘语已启用」就成了。


### 方式三：rime-install（plum，技术用户）

前置条件：已安装 [小狼毫](https://rime.im/)（Windows）或 fcitx-rime / ibus-rime，
并且有 [Git](https://git-scm.com/)（plum 依赖 git-bash）。

```
rime-install APIDYAHan/rime-dunespeak
```

安装完成后：

1. 右键输入法托盘图标 →「重新部署」；
2. 打开输入法设定（方案选单），把「沙丘语」加入启用列表；
3. 切换到沙丘语，开打。

> 注意：plum 默认不安装 lua 脚本，本包通过 `recipe.yaml` 显式安装
> `lua/dune.lua`，请勿删掉这个文件，否则沙丘语会变回普通拼音。

### 方式四：手动安装（不用 plum 的话）

1. 把 `dunespeak.schema.yaml` 和 `dunespeak.custom.yaml` 复制到 Rime 用户目录
   （Windows 默认 `%APPDATA%\Rime`；小狼毫安装时可自定义）；
2. 把 `lua/dune.lua` 复制到用户目录下的 `lua\` 子目录（没有就新建）；
3. 在 `default.custom.yaml` 的 `schema_list` 里加入 `- {schema: dunespeak}`，
   或用「方案选单」勾选；
4. 重新部署。

## 使用

| 想打 | 拼音键序 |
|---|---|
| 沙—丘 饿—饿... | `woele` 后按空格（**整句连写，中途不要按空格**） |
| 沙—丘 让AI 做出来 | `worang` + `AI`（大写）+ 空格 + `zuochulai` + 空格 |

- **分词键**是单引号 `'`（如 `xi'an`），一般用不上；
- 打整段英文可按 Shift 切西文模式；
- 换方案：`Ctrl + \`` 或 `F4`；简繁切换：`Ctrl + Shift + 4`；
- 强度三档：编辑 `dunespeak.custom.yaml` 里的 `dune/strength`
  （1 = 只换词汇，2 = 换词 + 断字 + 拟声词【默认】，3 = 加重口吃），改完重新部署。

## 卸载

- **用定制安装器装的**：系统设置 → 应用 → 卸载「小狼毫」，沙丘语的文件一并清掉；
- **用添加包 / rime-install / 手动装的**：删除用户目录里的 `dunespeak.schema.yaml`、
  `dunespeak.custom.yaml`、`lua\dune.lua`，从 `default.custom.yaml` 移除对应条目，重新部署。

## 致谢与来源

- 词库整理自游戏《Casualties Unknown》正式版的官方中文语言文件；
- 方案基于 [RIME](https://rime.im/) / 中州韵输入法引擎，Lua 扩展依赖 librime-lua；
- 定制安装器基于 [rime/weasel](https://github.com/rime/weasel) 0.17.4（GPL-3.0）重新打包，
  修改源码随 Releases 一并提供。

## License

MIT —— 见 [LICENSE](LICENSE)。

安装器（derivative of rime/weasel）遵循 GPL-3.0。
