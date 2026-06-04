# SmartTrip 开发经验复盘：从 SwiftUI Demo 到 TestFlight 的完整踩坑记录

> 这份文档用于沉淀 SmartTrip 从初版 Demo 到 AI 接入、截图导入、Cloudflare 安全代理、TestFlight 上架过程中的经验。它不是单纯记录“做了什么”，而是重点整理每一步背后的判断过程、问题成因和后续可复用的方法。

## 一、项目背景

SmartTrip 是一个面向自由行用户的 iOS App。核心目标是帮助用户把自己喜欢的旅行攻略整合成一份更适合自己的行程。

当前 App 支持三种生成方式：

1. 导入多张攻略截图。
2. 粘贴攻略文字。
3. 不提供攻略，直接让 AI 根据目的地和偏好推荐行程。

用户输入的信息包括：

- 目的地
- 天数
- 住宿状态
- 已知住宿区域
- 旅游类型
- 旅行偏好

App 输出的信息包括：

- 住宿建议
- 美食推荐
- 地点分类
- 每日行程
- 每日交通详情
- 每日可调整版本，例如下雨、太累、想购物、想拍照等

## 二、阶段 1：SwiftUI 初版 Demo 跑通

### 当时的目标

先不追求完整产品，只需要让一个最小版本跑起来：

- 首页填写目的地、天数、住宿状态、旅行偏好。
- 下一页粘贴攻略。
- 结果页展示假数据。

### 遇到的问题

一开始容易把注意力放在“功能完整”上，但实际对新项目来说，第一目标应该是跑通完整路径。

当时最重要的不是 UI 多漂亮，而是验证：

1. Xcode 项目结构是否正确。
2. SwiftUI 页面跳转是否正常。
3. 表单状态是否能传到下一页。
4. 结果页是否能接收数据并展示。

### 思考过程

我当时的判断是：  
如果第一版直接接 AI、做复杂解析、做图片识别，出问题时很难知道问题来自哪里。所以先用假数据跑通完整链路，是更稳的方式。

### 经验沉淀

MVP 第一版应该优先验证链路，而不是验证智能程度。

对这种 AI App 来说，推荐开发顺序是：

1. 静态 UI。
2. 页面跳转。
3. 假数据结果页。
4. 表单校验。
5. AI 返回原始文本。
6. AI 返回 JSON。
7. JSON 解析到页面。
8. 真实用户体验优化。

## 三、阶段 2：Xcode 文件与 Git 问题

### 遇到的问题 1：新增 Swift 文件后 Build Failed

当时新增 `PasteGuideView` 后，Xcode 报：

```text
Unexpected input file
```

### 判断过程

这个错误不是 Swift 语法错，而是文件加入 Xcode 工程的方式有问题。  
很可能是创建文件时没有带 `.swift` 后缀，或者 Xcode 把一个目录/无后缀文件当成了源码输入。

### 经验

Xcode 里新增 Swift 文件时要确认：

- 文件后缀必须是 `.swift`
- 文件在项目导航栏里显示 Swift 图标
- 文件加入了正确的 target
- 不要把无后缀文件拖入 Compile Sources

### 遇到的问题 2：Git Commit 失败 / No Author

Xcode Source Control 里出现 `No Author`，后来又出现：

```text
fatal: could not open '.git/COMMIT_EDITMSG'
```

### 判断过程

`No Author` 本质是 Git 用户名和邮箱没有配置好。  
`COMMIT_EDITMSG` 报错则更像是 Xcode 和 Git 操作之间冲突，或者某个 Git 操作正在进行。

### 经验

新项目第一次提交前，要先设置：

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
```

如果 Git 状态显示 rebase / merge 正在进行，不要盲目点 Xcode 的 Commit。先用：

```bash
git status
```

看清楚当前 Git 处于什么状态。

## 四、阶段 3：从假数据到 AI 接入

### 初始 AI 接入方式

一开始使用 DeepSeek API，让 `PasteGuideView` 点击“生成行程”后调用 API。

第一步不是直接做 JSON，而是先把 AI 返回的文字显示出来。

### 为什么先显示原始文字

当时的判断是：  
如果一开始就要求 AI 返回严格 JSON，并直接解析到结果页，一旦失败，不知道是 API 调用失败、Prompt 失败、JSON 格式失败，还是 Swift 解码失败。

所以更稳的方式是分阶段验证：

1. URLSession 能不能请求成功。
2. DeepSeek 能不能返回内容。
3. Prompt 能不能让它返回结构化内容。
4. Swift 能不能 decode。
5. 页面能不能渲染。

### 经验

AI 接入不要一步到位。  
推荐分层验证：

- 网络层：能否请求成功。
- 文本层：能否拿到回答。
- 格式层：能否返回 JSON。
- 模型层：能否 decode。
- 产品层：用户看到的结果是否合理。

## 五、阶段 4：AI 返回内容不稳定的问题

### 遇到的问题

AI 接入后出现很多产品层面的错误：

1. 交通时间不准。
2. 调整说明和实际路线矛盾。
3. 地点分类不完整。
4. 旅行偏好没有明显影响结果。
5. 已知住宿区域永远被评价为“适合”。
6. 调整版本里出现“同标准版”。
7. 用户目的地和攻略内容不相关时仍然生成行程。

### 思考过程

这些问题表面上看是“AI 不够聪明”，但本质上是产品没有给 AI 足够明确的输出约束。

例如：

- 如果只说“生成下雨方案”，AI 可能只写一句说明，不改路线。
- 如果只说“考虑住宿区域”，AI 可能为了讨好用户，永远说适合。
- 如果不要求交通详情逐段填写，AI 可能写“同标准版”。

### 采取的策略

后续 Prompt 被逐步强化：

- 要求只返回 JSON。
- 要求字段名固定。
- 要求美食单独进入 `foodPlaces`。
- 要求调整方案必须包含完整 route、transportTime、transportDetails、steps、advice、adjustmentNote。
- 要求交通详情不能写“同标准版”。
- 要求如果目的地和攻略明显无关，先阻止生成。
- 要求住宿区域要客观评价，不适合就要说明并调整路线。

### 经验

AI 产品不能只靠一句“请帮我规划行程”。  
要把 Prompt 当成接口协议设计。

一个好的 AI Prompt 应该包含：

1. 角色和任务。
2. 输入信息。
3. 输出格式。
4. 字段含义。
5. 禁止行为。
6. 异常情况处理。
7. 结果一致性要求。

## 六、阶段 5：结果页从展示型变成可操作型

### 初始问题

结果页一开始只是展示行程，看起来像“AI 生成了一段内容”。  
老板/用户更希望它像 App，而不是静态报告。

### 产品判断

如果结果页只有文字，用户会觉得：

- 这只是 ChatGPT 的壳。
- 不能操作。
- 不能根据当天状态调整。

所以加入“一键调整”功能，让用户可以按当天状态切换路线。

### 具体做法

每一天都有调整按钮：

- 标准版
- 下雨了
- 起晚了
- 太累了
- 想购物
- 想拍照

后来又进一步优化：

- 调整只影响当天，不影响所有天。
- 机场到酒店这种纯移动日，只显示标准版。
- 第一天如果是下午到机场，不显示“起晚了”。
- 最后一天如果只有去机场，也只显示标准版。

### 经验

产品里的“智能”不一定只体现在生成内容上，也可以体现在交互上。

一个好的 AI 工具应该让用户感觉：

- 我能控制它。
- 我能调整它。
- 它知道我的临时状态。
- 它不是一次性生成完就结束。

## 七、阶段 6：从粘贴文字到导入截图

### 背景

老板认为复制粘贴攻略文字的成本太高。  
更自然的方式是让用户直接选择攻略截图，类似微信里“你可能想发送的图片”那种轻操作。

### 采取的方案

使用：

- `PhotosPicker`
- `Vision`
- `VNRecognizeTextRequest`

实现：

- 选择多张截图。
- OCR 识别文字。
- 把多张截图识别结果拼成多篇攻略文本。
- 不把 OCR 文本展示在输入框里，避免影响观感。
- 支持查看截图大图。
- 支持删除单张截图。
- 支持清空全部截图。

### 思考过程

截图导入的关键不是“能识别文字”这么简单，而是要考虑用户感受：

- 用户不想看到一大堆 OCR 文字。
- 用户想确认自己选了哪些图。
- 用户选错图后要能删除。
- 用户希望一次选多张攻略，而不是只选一张。

### 经验

从产品角度看，截图输入比文字输入更符合旅行攻略场景。  
因为用户平时收藏的攻略往往是小红书、朋友圈、公众号、聊天截图，而不是结构化文本。

## 八、阶段 7：AI Key 泄露与安全架构调整

### 遇到的问题

GitGuardian 邮件提示：

```text
DeepSeek API Key exposed on GitHub
```

这是非常严重的问题。  
只要 API Key 被推到 GitHub，就必须认为它已经泄露。

### 判断过程

一开始 App 可能通过 Xcode 环境变量或代码方式调用 DeepSeek。  
这在本地开发时方便，但对 TestFlight 和 GitHub 都不安全。

真实上线时，iOS App 里不能放 DeepSeek API Key。

### 最终方案

使用 Cloudflare Worker 作为后端代理：

```text
iOS App -> Cloudflare Worker -> DeepSeek API
```

iOS App 只知道 Worker 地址：

```text
https://smarttrip.zichenz7.workers.dev
```

DeepSeek API Key 只放在 Cloudflare Worker Secret：

```text
DEEPSEEK_API_KEY
```

### 经验

移动端 App 不能保存第三方 AI API Key。

安全原则：

- API Key 不进 Swift 代码。
- API Key 不进 Xcode Build Settings。
- API Key 不进 GitHub。
- API Key 不进 App Store Connect。
- API Key 只存在服务器端 Secret。

如果 Key 泄露：

1. 立即到 DeepSeek 后台撤销旧 Key。
2. 创建新 Key。
3. 放入 Cloudflare Secret。
4. 检查 GitHub 历史记录。

## 九、阶段 8：Cloudflare Worker 代理

### 当前 Worker 作用

Worker 接收 App 的请求，然后帮 App 调用 DeepSeek。

当前 Worker 地址：

```text
https://smarttrip.zichenz7.workers.dev
```

App 实际调用路径：

```text
POST https://smarttrip.zichenz7.workers.dev/chat/completions
```

### Worker 逻辑

1. 只接受 `POST /chat/completions`。
2. 检查是否有 `DEEPSEEK_API_KEY`。
3. 把请求转发给 DeepSeek。
4. 返回 DeepSeek 的响应。

### 思考过程

这里的核心不是“把请求转发一下”，而是把风险从客户端转移到服务端：

- 客户端暴露 Worker URL 没关系。
- 客户端不能暴露 DeepSeek Key。
- Worker 后续可以加限流、鉴权、日志、错误处理。

### 后续风险

当前 Worker 还比较基础。  
虽然 Key 不泄露了，但 Worker URL 是公开的，理论上别人也可以调用。

未来需要加：

- Rate limiting
- 简单 App Token
- 请求签名
- Cloudflare 防滥用策略
- 错误日志和监控

## 十、阶段 9：TestFlight 上架与真实手机问题

### 遇到的问题

模拟机能生成行程，但 TestFlight 真实手机不能生成。

报错：

```text
生成失败：AI 服务还没有配置完成，请稍后再试。
```

### 判断过程

这个错误不是 DeepSeek 请求失败。  
它说明 App 根本没有读到后端 Worker 地址。

进一步检查发现：

- Xcode Build Settings 看起来填了 Worker URL。
- 但 Archive 包里的 `Info.plist` 没有 `SMARTTRIP_API_BASE_URL`。

也就是说，真实上传的包里没有带上后端地址。

### 最终修复

在 `DeepSeekService.swift` 里加入安全兜底：

```swift
"https://smarttrip.zichenz7.workers.dev"
```

这不是 API Key，不是秘密。  
它只是 Cloudflare Worker 的公开地址。

同时把 build number 提升到 `5`，重新 Archive 上传。

### 经验

模拟机成功不代表 TestFlight 成功。

原因是：

- 模拟机通常跑 Debug。
- TestFlight 跑 Release。
- 模拟机可能读到本地环境变量。
- TestFlight 不能读本地环境变量。

以后遇到类似问题，要按这个顺序排查：

1. App 是否真的装了最新 build。
2. Release build 是否包含配置。
3. Archive 包里的 Info.plist 是否有目标字段。
4. Worker 是否部署成功。
5. Worker Secret 是否存在。
6. DeepSeek 是否返回正常。

## 十一、阶段 10：App Icon / Signing / Compliance 问题

### 遇到的问题

上传 App Store Connect 时出现：

- Missing app icon
- Missing `CFBundleIconName`
- iPad icon 152x152 missing
- Signing profiles / certificates 问题
- Missing Compliance

### 解决方向

App Icon：

- 在 `Assets.xcassets/AppIcon.appiconset` 里补齐 icon。
- Xcode target 里设置 `AppIcon`。
- Info.plist 需要有 `CFBundleIconName = AppIcon`。

Signing：

- 使用 Apple Developer Team。
- Automatically manage signing。
- Archive 用 `Any iOS Device (arm64)`。

Compliance：

- App 只使用系统 HTTPS，不实现自定义加密。
- 在 App Store Connect 的 encryption 问题中选择类似：
  - `None of the algorithms mentioned above`

### 经验

TestFlight 不是只看代码能不能跑。  
它还要求：

- 签名正确
- icon 完整
- bundle id 正确
- build number 唯一
- encryption compliance 填完
- archive 上传成功

## 十二、当前项目状态

截至 2026-06-02：

- App 已经能在 Xcode 模拟机跑。
- 已经接入 DeepSeek。
- 已经用 Cloudflare Worker 隐藏 API Key。
- 已经支持 TestFlight 上传。
- 当前 build number 已改为 `5`。
- 需要上传并安装 TestFlight build `1.0 (5)` 或之后版本，验证真实手机是否能生成。

核心文件：

```text
/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/ContentView.swift
/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/PasteGuideView.swift
/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/ResultView.swift
/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/TripModels.swift
/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/SmartTrip/DeepSeekService.swift
/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/Backend/cloudflare-worker.js
```

## 十三、最重要的经验总结

### 1. AI App 要先跑通链路，再追求智能

不要一开始就做完整 AI 功能。  
先用假数据跑通页面，再接 API，再做 JSON，再做结果页。

### 2. Prompt 本质上是接口协议

如果输出要进入 App 页面，Prompt 必须像接口文档一样严格。

必须写清楚：

- 字段名
- 字段类型
- 禁止 Markdown
- 禁止解释
- 异常情况
- 结果一致性

### 3. 用户不能为系统错误买单

如果 AI 返回路线和说明矛盾，不应该让用户“重新生成一次”。  
App 应该尽量自动修复、兜底、隐藏不合理按钮。

### 4. 模拟机成功不代表真实手机成功

尤其是环境变量、Build Settings、Info.plist、Release 配置。  
真实手机只认 TestFlight 包里的内容。

### 5. API Key 永远不要放客户端

iOS App 是客户端，不能保存第三方 AI Key。  
正确做法是：

```text
iOS App -> 自己的后端/Worker -> AI 服务
```

### 6. 输入方式决定产品体验

旅行攻略场景下，截图比复制文字更自然。  
用户不一定愿意整理内容，但愿意选择图片。

### 7. 结果页要可操作

如果结果页只是文字，就像 ChatGPT 输出。  
如果结果页能按当天状态调整，才更像 App。

### 8. 上架不是最后一步，而是另一套工程问题

TestFlight 涉及：

- 证书
- 签名
- icon
- build number
- compliance
- App Store Connect 处理
- 真实设备安装

这些都可能和代码无关，但会影响用户能不能用。

## 十四、后续建议

### 近期优先级

1. 确认 TestFlight build `1.0 (5)` 在真实手机可以生成行程。
2. 如果仍失败，检查 Cloudflare Worker Secret 和 logs。
3. 优化错误提示，不要把系统错误直接展示给用户。
4. 给 Worker 加基本限流。
5. 修复 `selectedPreferences` 初始值为空字符串数组的问题。

### 中期优先级

1. 增强 AI JSON 校验。
2. 增加保存行程功能。
3. 支持用户编辑某一天。
4. 支持只重新生成某一天。
5. 添加隐私说明和服务条款。

### 长期方向

1. 地图和真实交通时间接入。
2. 行程导出。
3. 个性化用户偏好记忆。
4. 更强的多攻略对比与整合能力。
5. 后端正式化，避免 Worker 被滥用。

## 十五、给后续 Codex 的提示

如果在新的 Codex 聊天窗口继续这个项目，可以先提供：

```text
/Users/zhuzichen/Documents/Codex/2026-05-26/ai-ios-app/SmartTrip/PROJECT_CONTEXT.md
```

然后说明：

```text
这是 SmartTrip 当前项目上下文。请先阅读它，再继续帮我处理当前问题。不要让我泄露 DeepSeek API Key。
```

如果继续处理 TestFlight 问题，优先检查：

1. 用户安装的是不是最新 build。
2. Archive 包里有没有 Worker URL。
3. Worker 是否 deployed。
4. Cloudflare Secret 是否叫 `DEEPSEEK_API_KEY`。
5. Worker logs 是否显示 DeepSeek 请求失败。

