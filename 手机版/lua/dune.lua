-- -*- coding: utf-8 -*-
-- 沙丘语 RIME 过滤器 (librime-lua)
-- 把候选里的中文改写成《未知伤亡》角色 Dune（沙丘 [SAW-12]）的说话方式。
-- 词库来自游戏语言文件 zh-CN.json 里 594 条原版台词 + 8 则手写纸条的实测统计。
--
-- 设计要点：
--   1. 纯 Lua 5.4 标准库，不依赖 utf8 库（RIME 里可能被裁剪）。
--   2. 确定性伪随机：同一句话永远得到同一个结果，否则候选窗每次刷新都会跳字。
--   3. 两级模式：整句候选（sentence）走完整流程（含句首拟声词、句尾省略号）；
--      词/字候选只做词汇改写与断字，避免逐词上屏时满屏拟声词。

local M = {}

local DASH     = "\u{2014}"   -- 破折号 —
local MAX_LEN  = 60           -- 输出字符上限（聊天窗口友好）

-- ─────────────────────────────── 工具 ───────────────────────────────

local function uchars(s)
  local out, i, n = {}, 1, #s
  while i <= n do
    local c = s:byte(i)
    local step = 1
    if c >= 0xF0 then step = 4
    elseif c >= 0xE0 then step = 3
    elseif c >= 0xC0 then step = 2 end
    out[#out + 1] = s:sub(i, i + step - 1)
    i = i + step
  end
  return out
end

local function char_len(s)
  local n, i, len = 0, 1, #s
  while i <= len do
    local c = s:byte(i)
    if c >= 0xF0 then i = i + 4
    elseif c >= 0xE0 then i = i + 3
    elseif c >= 0xC0 then i = i + 2
    else i = i + 1 end
    n = n + 1
  end
  return n
end

local function is_cjk(ch)
  local c = ch:byte(1)
  return c ~= nil and #ch == 3 and c >= 0xE4 and c <= 0xE9
end

local function count_sub(s, sub)
  local n, i = 0, 1
  while true do
    local a, b = s:find(sub, i, true)
    if not a then break end
    n = n + 1
    i = b + 1
  end
  return n
end

-- 确定性随机：djb2 hash + 线性同余
local function seed_of(s)
  local h = 5381
  for i = 1, #s do
    h = (h * 33 + s:byte(i)) % 4294967296
  end
  return h
end

local function rng_of(seed)
  local state = seed % 2147483647
  if state <= 0 then state = state + 2147483646 end
  return function()
    state = (state * 1103515245 + 12345) % 2147483648
    return state / 2147483648
  end
end

-- ─────────────────────────────── 词库 ───────────────────────────────

-- 代词 / 高频名词：整体替换（沙丘的世界只有“沙丘、朋友、食物、怪物”）
local REWRITE = {
  ["我"] = "沙" .. DASH .. "丘",
  ["俺"] = "沙" .. DASH .. "丘",
  ["咱"] = "沙" .. DASH .. "丘",
  ["自己"] = "沙" .. DASH .. "丘",
  ["我们"] = "沙" .. DASH .. "丘",
  ["咱们"] = "沙" .. DASH .. "丘",
  ["大家"] = "沙" .. DASH .. "丘",

  ["你"] = "朋" .. DASH .. "友",
  ["您"] = "朋" .. DASH .. "友",
  ["你们"] = "朋" .. DASH .. "友",
  ["各位"] = "朋" .. DASH .. "友",
  ["兄弟"] = "朋" .. DASH .. "友",
  ["老哥"] = "朋" .. DASH .. "友",
  ["他"] = "朋" .. DASH .. "友",
  ["她"] = "朋" .. DASH .. "友",
  ["它"] = "朋" .. DASH .. "友",
  ["他们"] = "朋" .. DASH .. "友",
  ["别人"] = "朋" .. DASH .. "友",
  ["人家"] = "朋" .. DASH .. "友",
  ["队友"] = "朋" .. DASH .. "友",

  ["什么"] = "什" .. DASH .. "么",
  ["怎么"] = "怎" .. DASH .. "么",
  ["为什么"] = "为" .. DASH .. "什" .. DASH .. "么",
  ["哪里"] = "哪" .. DASH .. "里",
  ["哪儿"] = "哪" .. DASH .. "里",
  ["那里"] = "那" .. DASH .. "里",
  ["这边"] = "这" .. DASH .. "边",
  ["那边"] = "那" .. DASH .. "边",
  ["多少"] = "多" .. DASH .. "少",
  ["几个"] = "几",
  ["别"] = "不" .. DASH .. "要",
  ["不要"] = "不" .. DASH .. "要",
  ["没有"] = "没" .. DASH .. "有",
  ["不要动"] = "不" .. DASH .. "要 动",
  ["别动"] = "不" .. DASH .. "要 动",
  ["别过来"] = "不" .. DASH .. "要 来",
  ["这里有"] = "这" .. DASH .. "里 有",
  ["这里"] = "这" .. DASH .. "里",
  ["开枪"] = "砰" .. DASH .. "砰 响",
  ["打枪"] = "砰" .. DASH .. "砰 响",

  ["朋友"] = "朋" .. DASH .. "友",
  ["食物"] = "食" .. DASH .. "物",
  ["饭"] = "食" .. DASH .. "物",
  ["吃的"] = "食" .. DASH .. "物",
  ["食品"] = "食" .. DASH .. "物",
  ["粮食"] = "食" .. DASH .. "物",
  ["东西"] = "东" .. DASH .. "西",
  ["怪物"] = "怪" .. DASH .. "物",
  ["敌人"] = "怪" .. DASH .. "物",
  ["坏蛋"] = "坏 朋" .. DASH .. "友",
  ["尸体"] = "尸" .. DASH .. "体",
  ["死人"] = "尸" .. DASH .. "体",
  ["枪"] = "砰" .. DASH .. "砰 棍" .. DASH .. "子",
  ["手枪"] = "砰" .. DASH .. "砰 棍" .. DASH .. "子",
  ["步枪"] = "砰" .. DASH .. "砰 棍" .. DASH .. "子",
  ["武器"] = "砰" .. DASH .. "砰 棍" .. DASH .. "子",
  ["子弹"] = "子" .. DASH .. "弹",
  ["刀"] = "刀",
  ["手电筒"] = "亮" .. DASH .. "亮",
  ["手电"] = "亮" .. DASH .. "亮",
  ["灯"] = "亮" .. DASH .. "亮",
  ["名字"] = "名" .. DASH .. "字",
  ["伤口"] = "伤" .. DASH .. "口",
  ["钱"] = "东" .. DASH .. "西",
  ["礼物"] = "礼" .. DASH .. "物",
  ["位置"] = "位" .. DASH .. "置",
  ["地方"] = "地" .. DASH .. "方",
  ["洞穴"] = "洞" .. DASH .. "穴",
  ["实验室"] = "实" .. DASH .. "验" .. DASH .. "室",

  ["吃"] = "吃",
  ["吃饭"] = "吃",
  ["喝"] = "喝",
  ["饿"] = "饿" .. DASH .. "饿",
  ["饱"] = "饱" .. DASH .. "饱",
  ["睡"] = "睡",
  ["睡觉"] = "睡" .. DASH .. "觉",
  ["跑"] = "跑",
  ["逃跑"] = "跑",
  ["走"] = "走",
  ["离开"] = "走",
  ["来"] = "来",
  ["过来"] = "来",
  ["去"] = "去",
  ["回来"] = "回" .. DASH .. "来",
  ["看"] = "看",
  ["看见"] = "看",
  ["看到"] = "看",
  ["听"] = "听",
  ["听见"] = "听",
  ["说"] = "说",
  ["说话"] = "说" .. DASH .. "话",
  ["要"] = "要" .. DASH .. "要",
  ["想要"] = "要" .. DASH .. "要",
  ["需要"] = "需" .. DASH .. "要",
  ["给"] = "给",
  ["拿"] = "拿",
  ["取"] = "拿",
  ["买"] = "拿",
  ["卖"] = "给",
  ["杀"] = "杀",
  ["杀死"] = "杀",
  ["打死"] = "杀",
  ["咬"] = "咬",
  ["打"] = "打",
  ["攻击"] = "打",
  ["救"] = "帮" .. DASH .. "帮",
  ["救命"] = "帮" .. DASH .. "帮",
  ["帮"] = "帮" .. DASH .. "帮",
  ["帮忙"] = "帮" .. DASH .. "帮",
  ["帮助"] = "帮" .. DASH .. "帮",
  ["怕"] = "怕",
  ["害怕"] = "怕",
  ["恐惧"] = "怕",
  ["喜欢"] = "喜" .. DASH .. "欢",
  ["爱"] = "喜" .. DASH .. "欢",
  ["讨厌"] = "讨" .. DASH .. "厌",
  ["恨"] = "讨" .. DASH .. "厌",
  ["知道"] = "明" .. DASH .. "白",
  ["懂"] = "明" .. DASH .. "白",
  ["明白"] = "明" .. DASH .. "白",
  ["不懂"] = "不 明" .. DASH .. "白",
  ["谢谢"] = "谢" .. DASH .. "谢",
  ["多谢"] = "谢" .. DASH .. "谢",
  ["对不起"] = "对" .. DASH .. "不" .. DASH .. "起",
  ["抱歉"] = "对" .. DASH .. "不" .. DASH .. "起",
  ["等"] = "等",
  ["等待"] = "等",
  ["找"] = "找",
  ["寻找"] = "找",
  ["抱"] = "碰",
  ["拥抱"] = "碰",
  ["挖"] = "挖",
  ["追"] = "追",
  ["躲"] = "躲",

  ["好"] = "好",
  ["不好"] = "不" .. DASH .. "好",
  ["坏"] = "坏",
  ["危险"] = "危" .. DASH .. "险",
  ["安全"] = "安" .. DASH .. "全",
  ["快"] = "快",
  ["慢"] = "慢",
  ["大"] = "大",
  ["小"] = "小",
  ["多"] = "多" .. DASH .. "多",
  ["少"] = "少",
  ["冷"] = "冷" .. DASH .. "冷",
  ["热"] = "热",
  ["疼"] = "痛" .. DASH .. "痛",
  ["痛"] = "痛" .. DASH .. "痛",
  ["累"] = "累",
  ["困"] = "困",
  ["脏"] = "脏",
  ["臭"] = "臭" .. DASH .. "臭",
  ["重"] = "重",
  ["黑"] = "黑",
  ["暗"] = "黑",
  ["远"] = "远",
  ["近"] = "近",
  ["很多"] = "好" .. DASH .. "多 好" .. DASH .. "多",
  ["一点"] = "小" .. DASH .. "小",
  ["有点"] = "小" .. DASH .. "小",
  ["一起"] = "一" .. DASH .. "起",
}

-- 语料里真实出现过的断字词（破折号切在固定音节缝上）
local SPLIT = {
  ["沙丘"] = "沙" .. DASH .. "丘",
  ["你好"] = "你" .. DASH .. "好",
  ["更多"] = "更" .. DASH .. "多",
  ["受伤"] = "受" .. DASH .. "伤",
  ["邪恶"] = "邪" .. DASH .. "恶",
  ["走开"] = "走" .. DASH .. "开",
  ["棍子"] = "棍" .. DASH .. "子",
  ["声音"] = "声" .. DASH .. "音",
  ["感觉"] = "感" .. DASH .. "觉",
  ["停下"] = "停" .. DASH .. "下",
  ["出血"] = "出" .. DASH .. "血",
  ["味道"] = "味" .. DASH .. "道",
  ["暖和"] = "暖" .. DASH .. "和",
  ["摧毁"] = "摧" .. DASH .. "毁",
  ["现在"] = "现" .. DASH .. "在",
  ["过去"] = "过" .. DASH .. "去",
  ["一共"] = "一" .. DASH .. "共",
  ["上面"] = "上" .. DASH .. "面",
  ["下面"] = "下" .. DASH .. "面",
  ["里面"] = "里" .. DASH .. "面",
  ["外面"] = "外" .. DASH .. "面",
  ["前面"] = "前" .. DASH .. "面",
  ["后面"] = "后" .. DASH .. "面",
  ["回答"] = "回" .. DASH .. "答",
  ["吃饱"] = "吃" .. DASH .. "饱",
  ["饿死"] = "饿" .. DASH .. "死",
  ["攻击"] = "攻" .. DASH .. "击",
  ["保护"] = "保" .. DASH .. "护",
  ["发现"] = "发" .. DASH .. "现",
  ["找到"] = "找" .. DASH .. "到",
  ["醒来"] = "醒" .. DASH .. "来",
  ["告诉"] = "告" .. DASH .. "诉",
  ["可能"] = "可" .. DASH .. "能",
  ["应该"] = "应" .. DASH .. "该",
  ["不是"] = "不" .. DASH .. "是",
  ["包扎"] = "包" .. DASH .. "扎",
  ["赶快"] = "快" .. DASH .. "快",
  ["小心"] = "小" .. DASH .. "心",
}

-- 抽象概念降级：不能说“任务”“计划”，只能说“事情”
local CONCEPT = {
  ["任务"] = "事" .. DASH .. "情",
  ["计划"] = "事" .. DASH .. "情",
  ["集合"] = "来" .. DASH .. "来",
  ["等一下"] = "等 沙" .. DASH .. "丘",
  ["快点"] = "快" .. DASH .. "快",
  ["撤退"] = "走",
  ["前进"] = "走",
  ["左边"] = "左",
  ["右边"] = "右",
}

-- 虚词、连词、时间词、程度副词：全库几乎不出现，直接删
local DROP_LIST = {
  "的", "了", "吧", "啊", "呀", "哦", "嘛", "呢", "吗", "呗", "啦", "着", "过", "地",
  "个", "些", "种", "们", "很", "非常", "特别", "太", "真的", "其实", "好像", "大概",
  "也许", "可能", "应该", "一定", "肯定", "因为", "所以", "但是", "可是", "不过",
  "而且", "如果", "虽然", "然后", "就", "都", "也", "还", "又", "再", "才", "却",
  "并且", "以及", "和", "跟", "现在", "马上", "立刻", "今天", "明天", "昨天",
  "以前", "以后", "后来", "刚才", "待会", "等会", "一会", "已经", "终于", "突然",
  "事情", "问题", "感觉", "意思", "办法", "时候", "样子", "地方", "故意", "究竟",
  "只是",
}

-- 口吃叠字候选（“不—不”“好—好”）
local STUTTER = {
  "不", "好", "冷", "要", "吃", "看", "走", "拿", "帮", "水",
  "疼", "没", "去", "来", "睡", "怕", "饿", "痛",
}

-- 额外的分词词表（只影响切分粒度，不改变输出）
local EXTRA = {
  "有", "在", "是", "不", "没", "想", "能", "会", "开", "关", "光", "故意", "究竟",
  "一起", "现在", "怎么", "什么", "为什么", "哪里", "多少", "朋友", "队友", "敌人",
  "血量", "背包", "绷带", "物资", "地图", "提示", "联机", "房间", "队友们", "开门",
  "关门", "上去", "下去", "出来", "进去", "回来", "过来", "别动", "别过来", "快点",
  "集合", "准备", "开始", "结束", "小心", "注意", "确定", "不知道", "没看见",
  "打不过", "跑不掉", "吃不下", "睡一觉", "舒服", "安静", "吵", "停", "继续",
}

-- 情绪词（决定句首拟声词）
local MOODS = {
  { name = "pain",   words = { "痛", "疼", "伤", "流血", "出血", "骨折", "难受", "救命" } },
  { name = "fear",   words = { "怕", "恐怖", "吓", "危险", "逃", "跑", "救命", "别过来", "快跑" } },
  { name = "anger",  words = { "杀", "打死", "滚", "讨厌", "恨", "混蛋", "别打", "打你", "去死" } },
  { name = "hunger", words = { "饿", "吃", "食", "渴", "喝", "肉", "饭", "饱" } },
  { name = "joy",    words = { "谢谢", "开心", "喜欢", "哈哈", "太棒", "好吃", "找到" } },
}

-- 拟声词：按情绪分布，来自原版台词
local ONO = {
  calm   = { "嗯嗯", "嗯姆", "嗬嗯", "哦哦" },
  hunger = { "呐呃呃", "呐咯", "咯嗯", "咯呜" },
  fear   = { "咯呃", "嗯嗯", "嘎啊啊啊咔", "呐嗯" },
  anger  = { "咯呃", "呐咯啊啊啊", "嘎啊", "呐咯呃呃呃" },
  pain   = { "咯嗯", "咯呃", "咯咯", "嗬嗯", "哇哇" },
  joy    = { "嗯嗯", "呐咯", "嘎哈", "哈哈" },
  dizzy  = { "姆嗯", "姆呢呢", "唔唔" },
}

-- ─────────────────────────────── 索引构建 ───────────────────────────────

local VOCAB     = {}
local DROP_SET  = {}
local STUTTER_SET = {}
local MAX_WORD  = 1

local function add_vocab(w)
  if not w or w == "" then return end
  VOCAB[w] = true
  local n = char_len(w)
  if n > MAX_WORD then MAX_WORD = n end
end

for k in pairs(REWRITE) do add_vocab(k) end
for k in pairs(SPLIT) do add_vocab(k) end
for k in pairs(CONCEPT) do add_vocab(k) end
for _, w in ipairs(DROP_LIST) do add_vocab(w) end
for _, w in ipairs(EXTRA) do add_vocab(w) end
for _, w in ipairs(DROP_LIST) do DROP_SET[w] = true end
for _, w in ipairs(STUTTER) do STUTTER_SET[w] = true end

-- ─────────────────────────────── 标点 ───────────────────────────────

local PUNCT = {}
local PUNCT_ALL = "，。！？；：、,.!?;:…~～　"
for _, ch in ipairs(uchars(PUNCT_ALL)) do PUNCT[ch] = true end

local DROP_PUNCT = {}
for _, ch in ipairs(uchars("，、；：,;:")) do DROP_PUNCT[ch] = true end

local SPACE_CH = {}
for _, ch in ipairs(uchars("　 ")) do SPACE_CH[ch] = true end

-- 整字判断标点（不能按字节 find，见上方说明）
local function is_punct(ch)
  if ch == nil or ch == "" then return false end
  return PUNCT[ch] == true
end

local function first_char(s)
  if s == "" then return "" end
  local c = s:byte(1)
  local step = 1
  if c >= 0xF0 then step = 4
  elseif c >= 0xE0 then step = 3
  elseif c >= 0xC0 then step = 2 end
  return s:sub(1, step)
end

local function last_char(s)
  local i = #s
  if i == 0 then return "" end
  while i > 1 do
    local c = s:byte(i)
    if c < 0x80 or c >= 0xC0 then break end
    i = i - 1
  end
  return s:sub(i)
end

-- 注意：必须整字判断。按字节 find 会把「，」(EF BC 8C) 的末字节 0x8C
-- 和「里」(E9 87 8C) 混为一谈，导致空格丢失。
-- is_punct 定义在 PUNCT 表之后（见下方“标点”段）。

-- ─────────────────────────────── 分词 ───────────────────────────────

local function tokenize(text)
  local cs = uchars(text)
  local n = #cs
  local tokens, buf = {}, {}
  local i = 1

  local function flush()
    if #buf > 0 then
      tokens[#tokens + 1] = { text = table.concat(buf), kind = "unk" }
      buf = {}
    end
  end

  while i <= n do
    local ch = cs[i]
    if PUNCT[ch] then
      flush()
      tokens[#tokens + 1] = { text = ch, kind = "punct" }
      i = i + 1
    elseif SPACE_CH[ch] then
      flush()
      i = i + 1
    else
      local hit, hitsize = nil, 0
      local upper = math.min(MAX_WORD, n - i + 1)
      for size = upper, 1, -1 do
        local cand = table.concat(cs, "", i, i + size - 1)
        if VOCAB[cand] then
          hit, hitsize = cand, size
          break
        end
      end
      if hit then
        flush()
        tokens[#tokens + 1] = { text = hit, kind = "word" }
        i = i + hitsize
      else
        buf[#buf + 1] = ch
        i = i + 1
      end
    end
  end
  flush()
  return tokens
end

-- ─────────────────────────────── 词语风格化 ───────────────────────────────

local function style_word(word, strength)
  if word:find(DASH, 1, true) then return word end
  local cs = uchars(word)
  if not is_cjk(cs[1] or "") then return word end
  if strength >= 3 and #cs == 2 then
    return cs[1] .. DASH .. cs[2]
  end
  if strength >= 3 and #cs == 3 then
    return cs[1] .. DASH .. cs[2] .. cs[3]
  end
  return word
end

-- ─────────────────────────────── 主转换 ───────────────────────────────

local function detect_mood(raw)
  local best, best_score = "calm", 0
  for _, m in ipairs(MOODS) do
    local score = 0
    for _, w in ipairs(m.words) do
      score = score + count_sub(raw, w)
    end
    if score > best_score then
      best, best_score = m.name, score
    end
  end
  return best
end

local function transform(raw, strength, full)
  if not raw or raw == "" then return nil end
  if char_len(raw) > 60 then return nil end   -- 超长候选不转换，避免卡顿和撑窗

  local has_cjk = false
  for _, ch in ipairs(uchars(raw)) do
    if is_cjk(ch) then has_cjk = true; break end
  end
  if not has_cjk then return nil end

  local rnd = rng_of(seed_of(raw .. "|" .. tostring(strength) .. "|" .. tostring(full)))
  local mood = detect_mood(raw)

  local pieces = {}
  for _, tok in ipairs(tokenize(raw)) do
    local value = tok.text
    if tok.kind == "punct" then
      if DROP_PUNCT[value] then
        if strength == 1 then
          pieces[#pieces + 1] = { v = "，", kind = "punct" }
        end
      elseif (value == "。" or value == ".") and strength >= 2 then
        pieces[#pieces + 1] = { v = "...", kind = "punct" }
      else
        pieces[#pieces + 1] = { v = value, kind = "punct" }
      end
    elseif DROP_SET[value] then
      -- 丢弃
    else
      local out = REWRITE[value]
      if out == nil and strength >= 2 then out = SPLIT[value] end
      if out == nil and strength >= 2 then out = CONCEPT[value] end
      if out == nil then
        if value == "" then out = nil else out = value end
      end

      if out and out ~= "" then
        -- 口吃
        if strength >= 3 and STUTTER_SET[out] and rnd() < 0.35 then
          out = out .. DASH .. out
        end
        out = style_word(out, strength)
        pieces[#pieces + 1] = { v = out, kind = "word" }
      end
    end
  end

  -- 拼装：标点紧贴前一个词
  local buf = {}
  for _, p in ipairs(pieces) do
    if p.kind == "punct" then
      if #buf > 0 then
        buf[#buf] = buf[#buf] .. p.v
      else
        buf[#buf + 1] = p.v
      end
    else
      buf[#buf + 1] = p.v
    end
  end

  local parts = {}
  for _, v in ipairs(buf) do
    if #parts > 0 then
      local prev = parts[#parts]
      local fc = first_char(v)
      if fc ~= " " and not is_punct(last_char(prev)) and not is_punct(fc) then
        parts[#parts + 1] = " "
      end
    end
    parts[#parts + 1] = v
  end

  local body = table.concat(parts)
  body = body:gsub("^%s+", ""):gsub("%s+$", "")
  if body == "" then return nil end

  -- 句首拟声词（仅整句模式）
  if full and strength >= 2 then
    local pool = ONO[mood] or ONO.calm
    if strength >= 3 then
      -- 高强度取最长的两个
      local sorted = {}
      for _, w in ipairs(pool) do sorted[#sorted + 1] = w end
      table.sort(sorted, function(a, b) return #a > #b end)
      pool = { sorted[1], sorted[2] or sorted[1] }
    end
    local ono = pool[math.floor(rnd() * #pool) + 1]
    body = ono .. "... " .. body
  end

  -- 句尾
  if full and strength >= 2 then
    local has_q = false
    for _, q in ipairs({ "吗", "呢", "什么", "哪", "几", "怎么", "为什么", "多少", "谁" }) do
      if raw:find(q, 1, true) then has_q = true; break end
    end
    local cs = uchars(body)
    local last = cs[#cs] or ""
    local ends_dot = (last == "。" or last == ".")
    if ends_dot or body:sub(-3) == "..." then
      if has_q and not body:find("？", 1, true) then body = body .. "？" end
    elseif last == "！" or last == "？" or last == "!" or last == "?" then
      -- 保留原标点
    elseif has_q then
      body = body .. "？"
    elseif rnd() < 0.55 then
      body = body .. "..."
    end
  end

  -- 限长
  if char_len(body) > MAX_LEN then
    local cs = uchars(body)
    local cut = nil
    for i = MAX_LEN - 3, 10, -1 do
      if cs[i] == " " then cut = i; break end
    end
    cut = cut or (MAX_LEN - 3)
    body = table.concat(cs, "", 1, cut) .. "..."
  end

  return body
end

-- ─────────────────────────────── RIME 接口 ───────────────────────────────

M.convert = transform   -- 供离线测试调用

local CACHE = {}
local CACHE_N = 0

local function convert_cached(text, strength, full)
  local key = text .. "\1" .. strength .. "\1" .. tostring(full)
  local hit = CACHE[key]
  if hit ~= nil then
    if hit == false then return nil end
    return hit
  end
  local out = transform(text, strength, full)
  if CACHE_N > 800 then CACHE = {}; CACHE_N = 0 end
  CACHE[key] = out or false
  CACHE_N = CACHE_N + 1
  return out
end

function M.init(env)
  CACHE, CACHE_N = {}, 0
  local strength = 2
  local ok, v = pcall(function()
    return env.engine.schema.config:get_int("dune/strength")
  end)
  if ok and v then strength = v end
  if strength < 1 then strength = 1 end
  if strength > 3 then strength = 3 end
  M.strength = strength
end

function M.func(input, env)
  local strength = M.strength or 2
  local seen = {}
  local idx = 0
  for cand in input:iter() do
    local text = cand.text
    if text == nil or text == "" then
      yield(cand)
    else
      idx = idx + 1
      local n = char_len(text)
      -- 完整模式（句首拟声词 + 句尾省略号）适用于：
      --   RIME 标记为整句的候选 / 首位且不少于 3 字的候选 / 任何 6 字以上的长候选。
      -- 单字和双字候选走轻量模式，避免逐词上屏时满屏拟声词。
      local full = (cand.type == "sentence")
        or (idx == 1 and n >= 3)
        or (n >= 6)
      local out = convert_cached(text, strength, full)
      if out and out ~= text then
        if not seen[out] then
          seen[out] = true
          local hint = "〔" .. text .. "〕"
          if n > 16 then
            hint = "〔" .. table.concat(uchars(text), "", 1, 15) .. "…〕"
          end
          local ctype = cand.type
          if ctype == nil or ctype == "" then ctype = "phrase" end
          yield(ShadowCandidate(cand, ctype, out, hint))
        end
      else
        yield(cand)
      end
    end
  end
end

return M
