# 沙丘语输入法（DuneSpeak CN）

把候选词改写成《未知伤亡》（Casualties Unknown）角色 **Dune（沙丘 [SAW-12]）** 说话方式的
RIME 输入方案。词库来自游戏语言文件中 594 条原版台词 + 8 则手写纸条的实测统计。

打 `woele`，出来的不是「我饿了」，而是——

> 咯嗯... 沙—丘 饿—饿...

## 安装

### 方式一：东风破（plum）一键安装

前置条件：已安装 [小狼毫](https://rime.im/)（Windows）或 fcitx-rime / ibus-rime，
并且有 [Git](https://git-scm.com/)（plum 依赖 git-bash）。

```
rime-install <你的GitHub用户名>/rime-dunespeak
```

安装完成后：

1. 右键输入法托盘图标 →「重新部署」；
2. 打开输入法设定（方案选单），把「沙丘语」加入启用列表；
3. 切换到沙丘语，开打。

> 注意：plum 默认不安装 lua 脚本，本包通过 `recipe.yaml` 显式安装
> `lua/dune.lua`，请勿删掉这个文件，否则沙丘语会变回普通拼音。

### 方式二：手动安装

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
- 强度三档：编辑 `dunespeak.custom.yaml` 里的 `dune/strength`
  （1 = 只换词汇，2 = 换词 + 断字 + 拟声词【默认】，3 = 加重口吃），改完重新部署。

## 卸载

删除用户目录里的 `dunespeak.schema.yaml`、`dunespeak.custom.yaml`、`lua\dune.lua`，
从 `default.custom.yaml` 移除对应条目，重新部署。

## 致谢与来源

- 词库整理自游戏《Casualties Unknown》zh-CN 语言文件；
- 方案基于 [RIME](https://rime.im/) / 中州韵输入法引擎，Lua 扩展依赖 librime-lua。

## License

MIT —— 见 [LICENSE](LICENSE)。
