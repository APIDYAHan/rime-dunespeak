# 沙—丘 输 入 法 ...（DuneSpeak CN）

哦哦... 沙—丘 把候选词改成... 《未知伤亡》（Casualties Unknown）角色 **Dune（沙丘 [SAW-12]）**
说—话 方式 的 RIME 输入方案... 词 库 来 自 官方 中 文 语言 文件 ... 594 条 原 版 台 词 ...
8 则 手 写 纸 条 ...

打 `woele` ... 嗯嗯... 出来 不—是... 「我饿了」... 是——

> 咯嗯... 沙—丘 饿—饿...

哦哦... 看 不 明—白 沙—丘 话..？→ **[使 用 说 明.txt](使用说明.txt)** ... 那 里 有 正 经 版 ...（说 人—话 的 那 种 ...）


## 下—载 ...

（嗯姆... 文 件 都 在 Releases ... 就 右 边 ... 点 进 去 ...）

**https://github.com/APIDYAHan/rime-dunespeak/releases/latest**

三 条 路 ... 嗯嗯... 按 朋—友 情况挑 ...

| 朋—友 的 情 况 | 拿 哪 个 | 难 度 |
|---|---|---|
| 没 装 过 小 狼毫 | `DuneSpeak-Custom-Installer-0.17.4.exe`（沙丘语定制安装器） | 嗬嗯... 双击装完 就—好... |
| 已 经 装 着 官 方 小 狼毫 | `DuneSpeak-Schema-AddPack.zip`（沙丘语方案添加包） | 双 击 bat ... 点 两 下 |
| 会 用 Rime / plum | 本 仓 库 源 码 | `rime-install` 一 条 命 令 |

> 嗬嗯... GitHub 不 认 中 文 附 件 名 ... 下 载 到 的 名 字 是 英文 ... 嗯姆... 和 B—站 视 频 里 拿 到 的 东—西 ... 是 同 一 个 ...
> 嗯嗯... 朋—友 不 放心 ... 就 查 指 纹 ...（PowerShell 里 `Get-FileHash 文件名` ... 对 一 对 ...）

| 文件 | SHA256 |
|---|---|
| `DuneSpeak-Custom-Installer-0.17.4.exe` | `C3AA5C2455EC260C589A09E5845672F63EB8682305877763B1282228572BA14F` |
| `DuneSpeak-Schema-AddPack.zip` | `C3F3A66C345FECF783F6E1CC58EE27225EAED83E8D38B433280CB8C86FD53B5C` |
| `DuneSpeak-Installer-Source.zip` | `2A26ED3909C7585D1E1C5FF9225AC6A2A0250B90BC32D8414915F47B98FCDA07` |

> 仓 库 本 体 放 方 案 文 件（yaml + lua）和 两 份 说 明 ... 安 装 器 ... 添 加 包 ... 安 装 器 源 码 ...
> 都 是 Releases 附 件 ...


## 安—装 ...

### 一、嗯姆... 哦哦... 第一次装！（定制... 安装器... 沙—丘 推荐！）

1. 到 Releases 下载 `DuneSpeak-Custom-Installer-0.17.4.exe`；
2. 装 过 旧 小 狼毫 的 ... 先 卸 干 净 ！ 不—要 留 残 ...；
3. 嗬嗯... 敲 两 下... `DuneSpeak-Custom-Installer-0.17.4.exe`，选 好 安装—地址...，一路「下一步」；
4. 走到「方案选单设定」窗口 ... 头 一 个 就 是 「沙丘语·Dune」... 已 经 勾 好 ... 点 「确定」...
   （朋—友想 一—起 用 明 月 拼 音 ... 五 笔 ... 也可以勾上... 就—是切换起 来 麻烦...）；
5. 装 完 ... 重 启 ... 切 到 小 狼毫输入法 ... 能 说 了 ...

> 注意：嗯姆... 安装完 不—要 点...「自动更新」... 更 新 完 ... 大—概... 沙—丘 不 见 ...

### 二、嗬嗯... 有 小 狼毫...（添加包）

1. 朋—友到 Releases 下载 `DuneSpeak-Schema-AddPack.zip` 嗯姆... 并解压...；
2. 敲 两 下 「添加沙丘语.bat」... 点 「添加沙丘语方案」...；
3. 官 方 的 窗 开 ... 勾 「沙丘语·Dune」... 点 「确定」...；
4. 回 向 导 ... 点 「检查是否添加成功」... 看 「沙丘语已启用」... 就 成 ...

### 三、rime-install（plum，嗬嗯... 技术 朋—友...）

前置条件：已安装 [小狼毫](https://rime.im/)（Windows）或 fcitx-rime / ibus-rime，
并且有 [Git](https://git-scm.com/)（plum 依赖 git-bash）。

```
rime-install APIDYAHan/rime-dunespeak
```

安装完成后：右键托盘图标 →「重新部署」→ 方案选单里勾上「沙丘语」→ 开打。

> 注意：plum 默认不安装 lua 脚本，本包通过 `recipe.yaml` 显式安装
> `lua/dune.lua`，请勿删掉这个文件，否则沙丘语会变回普通拼音。

### 四、全手动安装...（不—用 plum 的 话...）

1. 把 `dunespeak.schema.yaml` 和 `dunespeak.custom.yaml` 复制到 Rime 用户目录
   （Windows 默认 `%APPDATA%\Rime`；小狼毫安装时可自定义）；
2. 把 `lua/dune.lua` 复制到用户目录下的 `lua\` 子目录（没有就新建）；
3. 在 `default.custom.yaml` 的 `schema_list` 里加入 `- {schema: dunespeak}`，
   或用「方案选单」勾选；
4. 重新部署。


## 开—口 说—话 ...

| 想 打 | 拼 音 键 序 |
|---|---|
| 沙—丘 饿—饿... | `woele` 后按空格（**整句连写，中途不要按空格**） |
| 沙—丘 让AI 做出来 | `worang` + `AI`（大写）+ 空格 + `zuochulai` + 空格 |

- **分词键**是单引号 `'`（如 `xi'an`），一般用不上；
- 打整段英文可按 Shift 切西文模式；
- 换方案：`Ctrl + \`` 或 `F4`；简繁切换：`Ctrl + Shift + 4`
  （嗯嗯... 沙—丘 只 实—验 过 ... 简 体 ...）；
- 味—道 太 淡 ... 太 重...？编辑 `dunespeak.custom.yaml` 里的 `dune/strength`
  （1 = 只换词汇，2 = 换词 + 断字 + 拟声词【默认】，3 = 加重口吃），
  存 好 ... 右 键 图 标 ... 点 「重新部署」... 新 的 味 才 生 效 ...


## 不—要 了 ...

- **用定制安装器装的**：系统设置 → 应用 → 卸载「小狼毫」...
  沙—丘 的 文 件 ... 一 并 清 掉 ...；
- **用添加包 / rime-install / 手动装的**：删除用户目录里的 `dunespeak.schema.yaml`、
  `dunespeak.custom.yaml`、`lua\dune.lua`，从 `default.custom.yaml` 移除对应条目，重新部署。


## 谁 做 的 ...

- 词库整理自游戏《Casualties Unknown》正式版的官方中文语言文件；
- 方案基于 [RIME](https://rime.im/) / 中州韵输入法引擎，Lua 扩展依赖 librime-lua；
- 定制安装器基于 [rime/weasel](https://github.com/rime/weasel) 0.17.4（GPL-3.0）重新打包，
  修改源码随 Releases 一并提供；
- 「鋄金雁翎」打 打 AI 做出来... 哔—哩—哔—哩 ... 和 Q—Q ... 一 样 名—字 ...


## License

MIT —— 见 [LICENSE](LICENSE)。

安装器（derivative of rime/weasel）遵循 GPL-3.0。

---

嗯嗯... 就 这 些 ... 嗯嗯... 朋—友 去—好 好 玩 ...
