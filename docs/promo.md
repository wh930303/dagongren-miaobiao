# 打工人的秒表 · 推广文案包

> 项目地址：https://github.com/wh930303/dagongren-miaobiao
> 下载：https://github.com/wh930303/dagongren-miaobiao/releases/latest
>
> **核心叙事（所有渠道都要带上）**：这个 Mac App 不是手写的——**全程由 WorkBuddy 直接生成**。我一句自然语言描述需求，它写 Swift、编译、打包 DMG、传到 GitHub，没有一行代码是我敲的。
>
> 其他事实：macOS 13+、874 KB、MIT 开源、纯本地零联网、未签名（首次需右键打开）

---

## 0. 一句话 slogan（挑一个用）

- 我没写一行代码，WorkBuddy 给了我一个 Mac App。
- 跟 WorkBuddy 说了句"给我做个工资秒表"，它直接给我上架了。
- 一句话需求 → 一个能装的 Mac App，全程在对话框里完成。
- 你的工资，正在按秒到账。（纯产品向，不带 AI 叙事时用）
- 把工资装进一个会跳动的数字里。

---

## 1. 朋友圈 / 微信群（走心 + 反差，约 150 字）

最近干了件挺魔幻的事：我没写一行代码，做出了一个 Mac App。

过程是这样的——我打开 WorkBuddy，打了段话："给我做个 Mac 上的工资秒表，屏幕角落挂个小卡片，工资按秒跳，能看下班倒计时、工时进度，午休不算钱，节假日显示休息中，发薪日撞周末要提前。"

然后它就开始写 Swift、编译、画图标、打包 DMG、开 GitHub 仓库、传 Release。中途我说"卡片太宽了"、"调完不透明度点保存窗口会消失"、"加个缩放"，它就自己改代码重新编译。

现在这个 App 叫「打工人的秒表」，开源免费，874KB。

它不鸡汤，也不催你努力。它只是把"我今天又白干了"这种模糊的委屈，变成了一个具体的数字。

---

## 2. 小红书（标题 + 正文 + 标签）

**标题备选**

1. 没写一行代码，我让AI给我做了个Mac App
2. 跟AI说了句话，它把我的工资做成了跳表
3. AI帮我做了个Mac小工具，全程我只说了三句话
4. 打工人自救：让工资在屏幕上按秒涨（这个是我让AI做的）

**正文**

先说结论：**这个 Mac App 我一行代码都没写，全程是 WorkBuddy 直接生成的。**

我做的事只有一件——用中文把需求说清楚：

> "给我做个 macOS 上的工资计时卡片。屏幕角落悬浮，工资按秒往上跳，显示下班倒计时和工时进度条。月薪九千八，九点上班六点下班，午休十二点到两点不算钱。节假日不上班，发薪日每月15号，撞周末或假期就提前到最近工作日。"

它就开始干活了：写 Swift + AppKit、用 NSPanel 做无 Dock 图标的悬浮窗、画 App 图标、编译成同时支持 M 芯片和 Intel 的通用二进制、打 DMG、建 GitHub 仓库、发 Release。

后面我又提了一堆修改——"卡片太宽"、"不透明度改完点保存窗口消失了"、"加个缩小和复原"、"2027年放假安排出了，加上去"。它每次都自己定位代码、改完重新编译，还会告诉我崩溃原因是两个 AppDelegate 实例打架。

现在这个小东西叫「打工人的秒表」👇

💰 今日已赚金额，每秒滚动
⏱ 离下班还有多久，精确到秒
📊 今天工时进度条，走到 100% 就自由
🗓 这个发薪周期攒了多少、距发薪日还有几天
☕ 午休自动不计薪，法定节假日显示"休息中"
🖥 双击变极简小条，只留金额和倒计时

挂在屏幕角落，不挡事，能拖到任何位置，深浅色主题都有，50%~100% 随便缩放。

最爽的是它不催你。它只是让你看见：这一小时，值多少钱。

Mac 13 以上可用，开源免费，GitHub 搜「打工人的秒表」。

**标签**

#AI编程 #WorkBuddy #Mac软件推荐 #打工人 #效率工具 #开源软件 #桌面小组件 #vibecoding #工资 #独立开发

---

## 3. 微博（约 145 字）

我没写一行代码，做了个 Mac App。

在 WorkBuddy 里说了句"给我做个工资秒表"，它写完 Swift 直接编译打包、还帮我传到了 GitHub。中途我说卡片太宽、说保存后会闪退，它自己改代码重新编译。

现在它叫「打工人的秒表」：工资按秒跳，带下班倒计时和工时进度，午休不算钱，节假日显示休息中。

874KB，开源免费。

---

## 4. V2EX / 少数派 / 掘金（技术向）

**标题**：一句需求生成一个 Mac App：我用 WorkBuddy 做了个工资秒表，从写代码到发 Release

**正文**

Windows 上有个挺火的小工具叫「牛马脱敏器」，把工资按秒可视化挂在桌面角落。我想在 Mac 上用，没找到体验一致的——于是我打开 WorkBuddy，把需求打了出来。

**这个项目从头到尾，代码都是它写的。**

我说的是自然语言："macOS 原生，屏幕角落悬浮，工资按秒跳，下班倒计时，工时进度条，月薪税后 9800，9:00–18:00，午休 12:00–14:00 不计薪，周一到周五，节假日不上班，发薪日 15 号遇周末或法定节假日提前到最近工作日，小数 3 位，白色卡片。"

它自己做的技术决策，我觉得挺靠谱：

- **Swift + AppKit 单文件**，`swiftc -O` 编译，零第三方依赖
- **`NSPanel` + `nonactivatingPanel` + `LSUIElement=true`**：不抢焦点、不进 Dock、不出现在 Cmd+Tab
- 每秒定时器刷新，等宽数字排版，避免数字每秒抖动
- **通用二进制**（`lipo` 合 x86_64 与 arm64），Apple 芯片和 Intel 都能跑
- 配置 `Codable` 存 UserDefaults；**缩放值单独存一个 key**，因为它判断加字段会破坏旧配置的解码

**它踩的坑也是自己修的**

- 系统 Python 的 Tk 8.5 在新系统上渲染空白 → 直接放弃 Python 方案改 Swift
- 缩放最早用 `layer.transform`，被 AppKit 布局覆盖，和字号对不上 → 改成"布局尺寸 + 字号按比例重排"
- 设置保存后崩溃 → 它定位到 `AppDelegate` 有两个实例，`shared` 指向的不是持有 panel 的那个
- 图标、icns、DMG、GitHub 仓库、Release 附件，全是它在对话里做掉的

我说过的话大概就这些："太宽了，调窄点"、"语录移到底部，换成这句"、"调完不透明度点保存窗口消失了"、"加个缩小和复原"、"2027 年放假安排出了，加上去"、"重新打开要恢复成放大状态"。

**功能**

实时计薪（附每秒/每分钟速度）、下班倒计时、工时进度条、本发薪周期累计、距发薪日（15 号撞周末/法定节假日自动提前）、时薪分薪折算、极简模式、50%~100% 缩放、深浅双主题、可调不透明度。内置 2026 与 2027 年国办公布的法定节假日和调休补班日。

**边界**

未签名未公证，首次打开要右键 → 打开。发薪日只支持 1–28 号。节假日数据硬编码，每年 11 月新安排公布后要手动补，欢迎 PR。

MIT，874 KB，纯本地零网络请求。

👉 https://github.com/wh930303/dagongren-miaobiao

---

## 5. X / Twitter（英文）

I didn't write a single line of code for this macOS app. **WorkBuddy built the whole thing** — I just described what I wanted in plain language.

"Dagongren Miaobiao" (Worker's Stopwatch): a floating card that ticks your salary up by the second, plus clock-out countdown, work-hours progress, pay-cycle total, and days until payday.

It picked the stack itself: Swift + AppKit, `NSPanel` non-activating panel, `LSUIElement` so there's no Dock icon, lipo'd universal binary. Then it drew the icon, built the DMG, created the repo, and published the release.

When I said "the card is too wide" or "saving settings makes the window vanish", it found the bug and rebuilt. The crash was two `AppDelegate` instances — its diagnosis, not mine.

874 KB, zero network calls, MIT. CN 2026/2027 holiday calendar built in; payday rolls back to the nearest workday if it lands on a weekend.

It doesn't tell you to hustle. It just shows you what an hour costs.

github.com/wh930303/dagongren-miaobiao

---

## 6. 即刻 / 短动态

在 WorkBuddy 里打了一段话，出来一个 Mac App。

我说：屏幕角落挂个卡片，工资按秒跳，带下班倒计时，午休不算钱，节假日显示休息中，发薪日撞周末提前。

它写完 Swift 自己编译、自己画图标、自己打包 DMG、自己建了 GitHub 仓库。中途我嫌卡片宽、说保存会闪退、要加缩放，它改完重新编译。代码我一行没碰。

这个 App 现在叫「打工人的秒表」。它不励志，甚至有点丧，但它治好了我"今天又白过了"的那种模糊焦虑——现在我知道今天值多少钱了。

开源，874KB，Mac 13+。

---

## 7. 15 秒口播 / 短视频脚本

| 时间 | 画面 | 台词 |
|---|---|---|
| 0–3s | 对话框里一段中文需求，镜头快速推到成品卡片 | "这段话发出去，三分钟后我得到一个 Mac App。" |
| 3–7s | 卡片数字快速跳动，倒计时、进度条 | "我没写一行代码。WorkBuddy 直接生成的——工资按秒往上跳，下面是离下班还有多久。" |
| 7–11s | 双击变极简条、拖动、切深色、改缩放 | "我说太宽了，它调窄；我说闪退，它自己找到 bug 修了。" |
| 11–15s | GitHub 页面 + 下载按钮 | "874KB，开源免费。搜「打工人的秒表」。" |

---

## 8. 常见质疑 & 应答（评论区备用）

**「AI 写的代码能信吗？」**
能跑，能装，能开源。874KB、MIT、零网络请求，代码在仓库里躺着，随便审。它自己踩过的坑也都留在了提交记录里。

**「真的是 AI 写的？还是你在吹？」**
整个过程就是对话。我说"调完不透明度点保存，窗口消失了"，它回答根因是两个 `AppDelegate` 实例、`shared` 指向错了对象，然后改代码、重新编译、重新打包。这种活我没法替它吹。

**「这不就是制造焦虑吗？」**
反过来。焦虑来自模糊——"我这么干到底图什么"。数字摆出来以后，你至少能算出这一小时值 46 块，然后决定值不值得为它多熬两小时。

**「会不会记录我的工资数据？」**
不会。零网络请求，配置只存在你自己的 UserDefaults 里。

**「Mac 上能装吗？要虚拟机吗？」**
原生 App，不需要虚拟机、不需要 Wine。macOS 13 以上，拖进应用程序就行。首次打开因为没做签名，右键 → 打开一次就好。

**「Windows 能用吗？」**
不能，这个只做 Mac。Windows 那边用原版「牛马脱敏器」。

**「为什么不做成菜单栏 App？」**
菜单栏要 mouseover 才看得到。这个是要"余光扫一眼就看见"，所以做常驻悬浮卡片。

---

## 9. 发布节奏建议

1. **先发朋友圈 + GitHub**：熟人是最早的 star 来源，star 数直接影响搜索结果排名。
2. **小红书主推「AI 一句话做 App」这个角度**：比"工资计时器"更有点击欲，配 3 张图（对话框里的需求原文、浅色卡片、深色卡片）。
3. **V2EX 发「分享创造」**：标题带上"一句需求生成一个 Mac App"，技术社区吃这套。
4. **即刻 / X 发短版**：反差感最强的两句留在开头。
5. 每个渠道都在正文里自然带上「牛马脱敏器 Mac 版」「上班鼓励器」「牛马计时器」——有人在搜这些词的 Mac 替代品。
