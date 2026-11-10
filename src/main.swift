import AppKit

// MARK: - 配置

struct Config: Codable {
    var mode: Int = 0              // 0月薪 1日薪 2时薪
    var amount: Double = 9800
    var payDaysPerMonth: Double = 21.75
    var startText: String = "09:00"
    var endText: String = "18:00"
    var lunchDeduct: Bool = true
    var lunchStartText: String = "12:00"
    var lunchEndText: String = "14:00"
    var workdays: [Bool] = [true, true, true, true, true, false, false] // 周一..周日
    var overtime: Bool = false
    var otRate: Double = 1.5
    var payday: Int = 15
    var decimals: Int = 3
    var opacity: Double = 0.92
    var theme: Int = 1              // 0深色 1白色
    var mini: Bool = false
    var posX: Double = 60
    var posY: Double = 80
}

extension Config {
    static func load() -> Config {
        let d = UserDefaults.standard.data(forKey: "niuma_config")
        if let d = d, let c = try? JSONDecoder().decode(Config.self, from: d) { return c }
        return Config()
    }
    func save() {
        if let d = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(d, forKey: "niuma_config")
        }
    }
    func parseTime(_ s: String) -> (Int, Int) {
        let p = s.split(separator: ":").compactMap { Int($0) }
        if p.count >= 2 { return (min(max(p[0], 0), 23), min(max(p[1], 0), 59)) }
        if p.count == 1 { return (min(max(p[0], 0), 23), 0) }
        return (0, 0)
    }
}

// MARK: - 计薪逻辑

/// 法定节假日（国务院办公厅 2026-11-05 通知，含 2026 / 2027 两年）
let legalHolidays: Set<String> = [
    // 2026 元旦 1/1-1/3
    "2026-01-01", "2026-01-02", "2026-01-03",
    // 2026 春节 2/15-2/23
    "2026-02-15", "2026-02-16", "2026-02-17", "2026-02-18", "2026-02-19",
    "2026-02-20", "2026-02-21", "2026-02-22", "2026-02-23",
    // 2026 清明 4/4-4/6
    "2026-04-04", "2026-04-05", "2026-04-06",
    // 2026 劳动节 5/1-5/5
    "2026-05-01", "2026-05-02", "2026-05-03", "2026-05-04", "2026-05-05",
    // 2026 端午 6/19-6/21
    "2026-06-19", "2026-06-20", "2026-06-21",
    // 2026 中秋 9/25-9/27
    "2026-09-25", "2026-09-26", "2026-09-27",
    // 2026 国庆 10/1-10/7
    "2026-10-01", "2026-10-02", "2026-10-03", "2026-10-04", "2026-10-05",
    "2026-10-06", "2026-10-07",

    // 2027 元旦 1/1-1/3
    "2027-01-01", "2027-01-02", "2027-01-03",
    // 2027 春节 2/5-2/13（除夕至正月初八，共 9 天）
    "2027-02-05", "2027-02-06", "2027-02-07", "2027-02-08", "2027-02-09",
    "2027-02-10", "2027-02-11", "2027-02-12", "2027-02-13",
    // 2027 清明 4/3-4/5
    "2027-04-03", "2027-04-04", "2027-04-05",
    // 2027 劳动节 5/1-5/5
    "2027-05-01", "2027-05-02", "2027-05-03", "2027-05-04", "2027-05-05",
    // 2027 端午 6/9
    "2027-06-09",
    // 2027 中秋 9/15
    "2027-09-15",
    // 2027 国庆 10/1-10/7
    "2027-10-01", "2027-10-02", "2027-10-03", "2027-10-04", "2027-10-05",
    "2027-10-06", "2027-10-07",
]

/// 调休上班日（落在周末但正常上班）
let makeupWorkdays: Set<String> = [
    // 2026
    "2026-01-04", // 周日
    "2026-02-14", "2026-02-28", // 周六
    "2026-05-09", // 周六
    "2026-09-20", // 周日
    "2026-10-10", // 周六
    // 2027
    "2027-01-31", // 周日
    "2027-02-14", // 周日
    "2027-05-08", // 周六
    "2027-09-26", // 周日
    "2027-10-09", // 周六
]

let dayKeyFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone.current
    return f
}()

func dayKey(_ d: Date) -> String { dayKeyFormatter.string(from: d) }

/// 某天是否计薪工作日：法定节假日不算；调休上班日算；其余按用户设置的周工作日
func isWorkingDay(_ date: Date, config: Config, cal: Calendar) -> Bool {
    let key = dayKey(date)
    if legalHolidays.contains(key) { return false }
    if makeupWorkdays.contains(key) { return true }
    let wd = (cal.component(.weekday, from: date) + 5) % 7
    return config.workdays[wd]
}

/// 发薪日：遇周末或法定节假日则提前到最近的一个工作日
func paydayDate(year: Int, month: Int, config: Config, cal: Calendar) -> Date? {
    let day = min(max(config.payday, 1), 28)
    guard var d = cal.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else { return nil }
    var step = 0
    while step < 20 && !isWorkingDay(d, config: config, cal: cal) {
        guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
        d = prev
        step += 1
    }
    return d
}

struct CalcResult {
    var status: String = "休息中"
    var earned: Double = 0
    var speedPerSec: Double = 0
    var speedPerMin: Double = 0
    var workedHours: Double = 0
    var totalHours: Double = 8
    var countdown: String = ""
    var monthTotal: Double = 0
    var daysToPayday: Int = 0
    var fullDay: Double = 0
}

func calc(config: Config, now: Date = Date()) -> CalcResult {
    var r = CalcResult()
    let cal = Calendar.current
    let comp = cal.dateComponents([.year, .month, .day, .weekday, .hour, .minute, .second], from: now)
    let isWorkday = isWorkingDay(now, config: config, cal: cal)

    let (sh, sm) = config.parseTime(config.startText)
    let (eh, em) = config.parseTime(config.endText)
    let (ls, lsm) = config.parseTime(config.lunchStartText)
    let (le, lem) = config.parseTime(config.lunchEndText)

    let startSec = sh * 3600 + sm * 60
    let endSec = eh * 3600 + em * 60
    var paidSec = max(endSec - startSec, 0)
    var lunchSec = 0
    if config.lunchDeduct {
        lunchSec = max(le * 3600 + lem * 60 - (ls * 3600 + lsm * 60), 0)
        // 午休必须落在工作时段内，超出部分不扣
        lunchSec = min(lunchSec, paidSec)
        paidSec -= lunchSec
    }
    if paidSec < 300 { paidSec = 300 }

    let paidHours = Double(paidSec) / 3600.0
    var hourly: Double
    switch config.mode {
    case 0: hourly = config.amount / max(config.payDaysPerMonth, 1) / paidHours
    case 1: hourly = config.amount / paidHours
    default: hourly = config.amount
    }
    if hourly < 0 { hourly = 0 }
    r.totalHours = paidHours
    r.fullDay = hourly * paidHours
    r.speedPerSec = hourly / 3600
    r.speedPerMin = hourly / 60

    let nowSec = comp.hour! * 3600 + comp.minute! * 60 + comp.second!
    let inLunch = config.lunchDeduct && lunchSec > 0 && nowSec >= ls * 3600 + lsm * 60 && nowSec < le * 3600 + lem * 60

    if !isWorkday {
        r.status = "休息中"
        r.countdown = "今天不上班，好好休息"
    } else if nowSec < startSec {
        r.status = "上班前"
        let d = startSec - nowSec
        r.countdown = String(format: "距离上班还有 %d:%02d:%02d", d / 3600, (d % 3600) / 60, d % 60)
    } else if inLunch {
        r.status = "午休中"
        // 上半段已赚
        let lunchStart = ls * 3600 + lsm * 60
        var worked = lunchStart - startSec
        worked = max(worked, 0)
        r.earned = hourly * Double(worked) / 3600
        r.workedHours = Double(worked) / 3600
        let d = le * 3600 + lem * 60 - nowSec
        r.countdown = String(format: "午休结束还有 %d:%02d:%02d", d / 3600, (d % 3600) / 60, d % 60)
    } else if nowSec < endSec {
        r.status = "上班中"
        var worked = nowSec - startSec
        if config.lunchDeduct {
            let cs = ls * 3600 + lsm * 60, ce = le * 3600 + lem * 60
            let overlap = min(nowSec, ce) - cs
            if overlap > 0 { worked -= min(overlap, lunchSec) }
        }
        worked = max(worked, 0)
        r.earned = hourly * Double(worked) / 3600
        r.workedHours = Double(worked) / 3600
        let d = endSec - nowSec
        r.countdown = String(format: "距离下班还有 %d:%02d:%02d", d / 3600, (d % 3600) / 60, d % 60)
    } else {
        if config.overtime {
            r.status = "加班中"
            let worked = paidSec
            let ot = Double(nowSec - endSec) * config.otRate
            r.earned = hourly * (Double(worked) + ot) / 3600
            r.workedHours = Double(worked) / 3600
            r.countdown = "加班计薪中，倍率 ×\(config.otRate)"
        } else {
            r.status = "已下班"
            r.earned = hourly * Double(paidSec) / 3600
            r.workedHours = paidHours
            r.countdown = "今天辛苦啦"
        }
    }

    // 本期累计：从最近一个发薪日（含当天）到今天的计薪工作日 + 今天已赚
    let y = comp.year!, m = comp.month!, day = comp.day!
    let todayNoon = cal.date(from: DateComponents(year: y, month: m, day: day, hour: 12))!
    var periodStart = paydayDate(year: y, month: m, config: config, cal: cal)
    if let ps = periodStart, ps > todayNoon {
        let pm = m == 1 ? 12 : m - 1
        let py = m == 1 ? y - 1 : y
        periodStart = paydayDate(year: py, month: pm, config: config, cal: cal)
    }
    var total = 0.0
    if let ps = periodStart {
        var d = cal.startOfDay(for: ps)
        let todayStart = cal.startOfDay(for: now)
        var guardCount = 0
        while d < todayStart && guardCount < 40 {
            if isWorkingDay(d, config: config, cal: cal) { total += r.fullDay }
            d = cal.date(byAdding: .day, value: 1, to: d)!
            guardCount += 1
        }
    }
    total += r.earned
    r.monthTotal = total

    // 距发薪日（遇周末 / 法定节假日提前到最近工作日）
    var payDate = paydayDate(year: y, month: m, config: config, cal: cal)
    if let p = payDate, p < todayNoon {
        let nm = m == 12 ? 1 : m + 1
        let ny = m == 12 ? y + 1 : y
        payDate = paydayDate(year: ny, month: nm, config: config, cal: cal)
    }
    if let p = payDate {
        r.daysToPayday = cal.dateComponents([.day], from: todayNoon, to: p).day ?? 0
    }
    return r
}

// MARK: - 配色

struct Palette {
    var bg: NSColor
    var border: NSColor
    var title: NSColor
    var date: NSColor
    var status: NSColor
    var money: NSColor
    var speed: NSColor
    var quote: NSColor
    var progressText: NSColor
    var track: NSColor
    var bar: NSColor
    var sep: NSColor
    var gridTitle: NSColor
    var gridValue: NSColor

    static func of(_ theme: Int, opacity: Double) -> Palette {
        if theme == 1 {
            return Palette(
                bg: NSColor(calibratedWhite: 1.0, alpha: CGFloat(opacity)),
                border: NSColor(calibratedWhite: 0.0, alpha: 0.12),
                title: NSColor(calibratedWhite: 0.12, alpha: 1),
                date: NSColor(calibratedWhite: 0.45, alpha: 1),
                status: NSColor(calibratedRed: 0.10, green: 0.44, blue: 0.86, alpha: 1),
                money: NSColor(calibratedRed: 0.93, green: 0.42, blue: 0.08, alpha: 1),
                speed: NSColor(calibratedWhite: 0.38, alpha: 1),
                quote: NSColor(calibratedWhite: 0.50, alpha: 1),
                progressText: NSColor(calibratedWhite: 0.28, alpha: 1),
                track: NSColor(calibratedWhite: 0.0, alpha: 0.10),
                bar: NSColor(calibratedRed: 0.93, green: 0.42, blue: 0.08, alpha: 1),
                sep: NSColor(calibratedWhite: 0.0, alpha: 0.09),
                gridTitle: NSColor(calibratedWhite: 0.50, alpha: 1),
                gridValue: NSColor(calibratedWhite: 0.15, alpha: 1)
            )
        }
        return Palette(
            bg: NSColor(calibratedWhite: 0.10, alpha: CGFloat(opacity)),
            border: NSColor(calibratedWhite: 1.0, alpha: 0.10),
            title: NSColor(calibratedWhite: 0.92, alpha: 1),
            date: NSColor(calibratedWhite: 0.62, alpha: 1),
            status: NSColor(calibratedRed: 0.42, green: 0.72, blue: 1.0, alpha: 1),
            money: NSColor(calibratedRed: 1.0, green: 0.54, blue: 0.24, alpha: 1),
            speed: NSColor(calibratedWhite: 0.66, alpha: 1),
            quote: NSColor(calibratedWhite: 0.50, alpha: 1),
            progressText: NSColor(calibratedWhite: 0.78, alpha: 1),
            track: NSColor(calibratedWhite: 1.0, alpha: 0.14),
            bar: NSColor(calibratedRed: 1.0, green: 0.54, blue: 0.24, alpha: 1),
            sep: NSColor(calibratedWhite: 1.0, alpha: 0.12),
            gridTitle: NSColor(calibratedWhite: 0.55, alpha: 1),
            gridValue: NSColor(calibratedWhite: 0.90, alpha: 1)
        )
    }
}

// MARK: - 进度条

class ProgressBar: NSView {
    var fraction: CGFloat = 0 { didSet { needsDisplay = true } }
    var trackColor: NSColor = NSColor(white: 1.0, alpha: 0.14)
    var barColor: NSColor = NSColor(calibratedRed: 0.30, green: 0.56, blue: 0.95, alpha: 1)
    override func draw(_ dirtyRect: NSRect) {
        let track = NSBezierPath(roundedRect: bounds, xRadius: 3.5, yRadius: 3.5)
        trackColor.setFill()
        track.fill()
        let f = max(0, min(fraction, 1))
        if f > 0 {
            let w = max(bounds.width * f, 7)
            let fill = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: w, height: bounds.height), xRadius: 3.5, yRadius: 3.5)
            barColor.setFill()
            fill.fill()
        }
    }
}

// MARK: - 卡片视图

class CardView: NSView {
    var corner: CGFloat = 16
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        let p = Palette.of(AppDelegate.shared.config.theme, opacity: AppDelegate.shared.config.opacity)
        let rect = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: corner, yRadius: corner)
        p.bg.setFill()
        rect.fill()
        p.border.setStroke()
        rect.lineWidth = 1
        rect.stroke()
    }
}

// MARK: - 主控制器

let quotes = [
    "只要我不努力，老板就过不上他想要的生活。",
]

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate = AppDelegate()
    var config: Config
    var panel: NSPanel!
    var card: CardView!
    var labels: [String: NSTextField] = [:]
    var progress: ProgressBar!
    var progressLabel: NSTextField!
    var progressHours: NSTextField!
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?
    var timer: Timer?
    var quoteIdx = 0

    override init() {
        config = Config.load()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        buildPanel()
        buildStatusBar()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        tick()

        // 开发用：打印几何参数（缩放调试）
        if ProcessInfo.processInfo.environment["MIAOBIAO_DUMP"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let c = self.card!
                print("DUMP panel=\(self.panel.frame) cont=\(self.panel.contentView!.frame) card=\(c.frame) bounds=\(c.bounds) pos=\(String(describing: c.layer?.position)) anchor=\(String(describing: c.layer?.anchorPoint)) scale=\(self.scale)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { NSApp.terminate(nil) }
            }
        }

        // 自检：模拟“打开设置→保存”，验证不会崩溃（仅开发用）
        if ProcessInfo.processInfo.environment["NIUMA_SELFTEST"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                SettingsWindowController.shared.show()
                SettingsWindowController.shared.saveSettings()
                print("SELFTEST_SAVE_OK frame=\(self.panel.frame) opacity=\(self.config.opacity)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
            }
        }
    }

    func buildStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⏱"
        let menu = NSMenu()
        menu.addItem(withTitle: "显示 / 隐藏卡片", action: #selector(togglePanel), keyEquivalent: "")
        let miniItem = NSMenuItem(title: "极简模式", action: #selector(toggleMini), keyEquivalent: "")
        miniItem.state = config.mini ? .on : .off
        menu.addItem(miniItem)
        menu.addItem(withTitle: "缩小 / 复原卡片", action: #selector(toggleScale), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "设置…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出", action: #selector(quitApp), keyEquivalent: "q")
        statusItem.menu = menu
    }

    func buildPanel() {
        panel = NSPanel(contentRect: NSRect(x: Int(config.posX), y: Int(config.posY), width: 300, height: 320),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false

        rebuildContent()
        panel.orderFrontRegardless()
    }

    func rebuildContent() {
        guard let panel = panel else { return }
        // 缩放系数：布局尺寸与字号一起按比例缩放，任意比例下文字都清晰、不被裁切
        let k = CGFloat(max(0.5, min(scale, 1.0)))
        func S(_ v: CGFloat) -> CGFloat { (v * k).rounded() }
        let oldTop = panel.frame.origin.y + panel.frame.height
        let oldLeft = panel.frame.origin.x

        let baseW: CGFloat = config.mini ? 280 : 300
        let baseH: CGFloat = config.mini ? 58 : 320
        let W = S(baseW), H = S(baseH)

        card = CardView(frame: NSRect(x: 0, y: 0, width: W, height: H))
        card.corner = S(16)
        card.wantsLayer = true
        card.layer?.cornerRadius = S(16)
        labels.removeAll()
        let p = Palette.of(config.theme, opacity: config.opacity)

        if config.mini {
            let money = Label(text: "¥ 0.000", size: S(20), bold: true, color: p.money)
            money.frame = NSRect(x: S(14), y: S(14), width: S(140), height: S(30))
            money.autoresizingMask = []
            let cd = Label(text: "", size: S(11), color: p.status)
            cd.alignment = .right
            cd.frame = NSRect(x: S(140), y: S(19), width: S(126), height: S(20))
            labels["mini_money"] = money
            labels["mini_cd"] = cd
            card.addSubview(money)
            card.addSubview(cd)
        } else {
            let title = Label(text: "⏱ 打工人的秒表", size: S(13), bold: true, color: p.title)
            title.frame = NSRect(x: S(14), y: S(16), width: S(170), height: S(20))
            let dateL = Label(text: "", size: S(11), color: p.date)
            dateL.alignment = .right
            dateL.frame = NSRect(x: S(120), y: S(18), width: S(166), height: S(18))
            let statusL = Label(text: "上班中", size: S(12), bold: true, color: p.status)
            statusL.frame = NSRect(x: S(14), y: S(44), width: S(140), height: S(18))
            let cdL = Label(text: "", size: S(11), color: p.speed)
            cdL.alignment = .right
            cdL.frame = NSRect(x: S(112), y: S(44), width: S(174), height: S(18))
            let earnTitle = Label(text: "今日已赚", size: S(11), color: p.date)
            earnTitle.frame = NSRect(x: S(14), y: S(70), width: S(180), height: S(16))
            let money = Label(text: "¥ 0.000", size: S(32), bold: true, color: p.money)
            money.frame = NSRect(x: S(14), y: S(90), width: S(272), height: S(40))
            let speed = Label(text: "", size: S(11), color: p.speed)
            speed.frame = NSRect(x: S(14), y: S(132), width: S(272), height: S(16))

            progressLabel = Label(text: "", size: S(11), color: p.progressText)
            progressLabel.frame = NSRect(x: S(14), y: S(156), width: S(170), height: S(16))
            progressHours = Label(text: "", size: S(11), color: p.progressText)
            progressHours.alignment = .right
            progressHours.frame = NSRect(x: S(150), y: S(156), width: S(136), height: S(16))
            progress = ProgressBar(frame: NSRect(x: S(14), y: S(174), width: S(272), height: max(S(7), 4)))
            progress.wantsLayer = true
            progress.trackColor = p.track
            progress.barColor = p.bar

            let sep = NSView(frame: NSRect(x: S(14), y: S(194), width: S(272), height: 1))
            sep.wantsLayer = true
            sep.layer?.backgroundColor = p.sep.cgColor

            let grid: [(String, CGFloat, Int)] = [
                ("本期累计", 212, 0), ("距发薪日", 212, 1),
                ("时薪 · 分薪", 244, 0), ("今日满勤可得", 244, 1),
            ]
            for (title2, yy, col) in grid {
                let x0 = col == 0 ? S(14) : S(148)
                let t = Label(text: title2, size: S(10), color: p.gridTitle)
                t.frame = NSRect(x: x0, y: S(yy), width: S(130), height: S(14))
                let v = Label(text: "-", size: S(11), bold: true, color: p.gridValue)
                v.frame = NSRect(x: x0, y: S(yy + 14), width: S(138), height: S(16))
                labels["g_" + title2] = v
                card.addSubview(t)
                card.addSubview(v)
            }
            let quote = Label(text: "", size: S(10), color: p.quote)
            quote.alignment = .center
            quote.frame = NSRect(x: S(14), y: S(288), width: S(272), height: S(14))
            labels["date"] = dateL
            labels["status"] = statusL
            labels["cd"] = cdL
            labels["money"] = money
            labels["speed"] = speed
            labels["quote"] = quote
            for sub in [title, dateL, statusL, cdL, earnTitle, money, speed, quote, progressLabel, progressHours, progress, sep] as [NSView] {
                card.addSubview(sub)
            }
        }
        card.autoresizingMask = []
        panel.contentView = card
        panel.setContentSize(NSSize(width: W, height: H))
        panel.setFrameOrigin(NSPoint(x: oldLeft, y: oldTop - H))

        // 双击切换极简模式
        let dbl = NSClickGestureRecognizer(target: self, action: #selector(toggleMini))
        dbl.numberOfClicksRequired = 2
        card.addGestureRecognizer(dbl)

        let menu = NSMenu()
        menu.addItem(withTitle: "设置…", action: #selector(openSettings), keyEquivalent: "")
        let miniItem = NSMenuItem(title: "极简模式", action: #selector(toggleMini), keyEquivalent: "")
        miniItem.state = config.mini ? .on : .off
        menu.addItem(miniItem)
        menu.addItem(withTitle: "缩小 / 复原卡片", action: #selector(toggleScale), keyEquivalent: "")
        menu.addItem(withTitle: "隐藏卡片", action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出", action: #selector(quitApp), keyEquivalent: "")
        card.menu = menu
    }

    func tick() {
        let r = calc(config: config)
        let df = DateFormatter()
        df.dateFormat = "M月d日 EEEE HH:mm:ss"
        df.locale = Locale(identifier: "zh_CN")
        let nowStr = df.string(from: Date())

        let fmtStr = "%.\(config.decimals)f"
        if config.mini {
            labels["mini_money"]?.stringValue = "¥ " + String(format: fmtStr, r.earned)
            labels["mini_cd"]?.stringValue = r.status + " · " + r.countdown
        } else {
            labels["date"]?.stringValue = nowStr
            labels["status"]?.stringValue = r.status
            labels["cd"]?.stringValue = r.countdown
            labels["money"]?.stringValue = "¥ " + String(format: fmtStr, r.earned)
            labels["speed"]?.stringValue = String(format: "当前赚钱速度 ¥%.4f/秒 · ¥%.2f/分钟", r.speedPerSec, r.speedPerMin)
            labels["quote"]?.stringValue = "“" + quotes[quoteIdx % quotes.count] + "”"
            labels["g_本期累计"]?.stringValue = "¥ " + String(format: "%.2f", r.monthTotal)
            labels["g_距发薪日"]?.stringValue = r.daysToPayday <= 0 ? "就是今天 🎉" : "还有 \(r.daysToPayday) 天"
            labels["g_时薪 · 分薪"]?.stringValue = String(format: "¥%.2f · ¥%.3f", r.speedPerMin * 60, r.speedPerMin)
            labels["g_今日满勤可得"]?.stringValue = "¥ " + String(format: "%.2f", r.fullDay)
            progressLabel.stringValue = String(format: "今日工时进度 %.1f%%", r.workedHours / max(r.totalHours, 0.01) * 100)
            progressHours.stringValue = String(format: "%.2f / %.2f 小时", r.workedHours, r.totalHours)
            progress.fraction = CGFloat(r.workedHours / max(r.totalHours, 0.01))
        }
    }

    @objc func togglePanel() {
        if panel.isVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    }
    @objc func toggleMini() {
        config.mini.toggle()
        rebuildContent()
        tick()
        config.save()
    }
    @objc func openSettings() { SettingsWindowController.shared.show() }
    @objc func quitApp() {
        savePosition()
        NSApp.terminate(nil)
    }
    func savePosition() {
        if let f = panel?.frame {
            config.posX = Double(f.origin.x)
            config.posY = Double(f.origin.y)
            config.save()
        }
    }

    // MARK: 缩放（单独存 UserDefaults，避免破坏旧 Config 的解码）
    var scale: Double {
        get {
            let v = UserDefaults.standard.double(forKey: "niuma_scale")
            return v == 0 ? 1.0 : v
        }
        set { UserDefaults.standard.set(newValue, forKey: "niuma_scale") }
    }

    /// 应用缩放：重建布局（尺寸与字号按比例缩放，左上角位置保持不动）
    func applyScale() {
        rebuildContent()
    }

    @objc func toggleScale() {
        scale = scale < 0.99 ? 1.0 : 0.85   // 0.85 ≈ 红框大小
        rebuildContent()
        tick()
    }
}

// MARK: - Label 快捷类

class Label: NSTextField {
    init(text: String, size: CGFloat, bold: Bool = false, color: NSColor) {
        super.init(frame: .zero)
        stringValue = text
        isBezeled = false
        isEditable = false
        isSelectable = false
        drawsBackground = false
        font = bold ? NSFont.systemFont(ofSize: size, weight: .semibold) : NSFont.systemFont(ofSize: size)
        textColor = color
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 设置窗口

class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()
    var window: NSWindow?
    var modePopup: NSPopUpButton!
    var amountField: NSTextField!
    var payDaysField: NSTextField!
    var startField: NSTextField!
    var endField: NSTextField!
    var lunchCheck: NSButton!
    var lunchStartField: NSTextField!
    var lunchEndField: NSTextField!
    var dayChecks: [NSButton] = []
    var otCheck: NSButton!
    var otRateField: NSTextField!
    var paydayField: NSTextField!
    var decimalsField: NSTextField!
    var themePopup: NSPopUpButton!
    var opacitySlider: NSSlider!
    var scaleSlider: NSSlider!

    func row(_ y: CGFloat, _ title: String) -> NSTextField {
        let l = NSTextField(labelWithString: title)
        l.frame = NSRect(x: 20, y: y, width: 90, height: 18)
        l.font = NSFont.systemFont(ofSize: 12)
        return l
    }
    func field(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ val: String) -> NSTextField {
        let t = NSTextField(string: val)
        t.frame = NSRect(x: x, y: y, width: w, height: 22)
        t.font = NSFont.systemFont(ofSize: 12)
        return t
    }
    func check(_ x: CGFloat, _ y: CGFloat, _ title: String, _ on: Bool) -> NSButton {
        let b = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        b.frame = NSRect(x: x, y: y, width: 60, height: 18)
        b.font = NSFont.systemFont(ofSize: 12)
        b.state = on ? .on : .off
        return b
    }

    func show() {
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 466),
                             styleMask: [.titled, .closable], backing: .buffered, defer: false)
            w.title = "打工人的秒表 · 设置"
            w.isReleasedWhenClosed = false
            w.center()
            let c = NSView(frame: w.contentView!.frame)
            var y: CGFloat = 431

            c.addSubview(row(y, "收入模式"))
            modePopup = NSPopUpButton(frame: NSRect(x: 115, y: y - 3, width: 90, height: 24))
            modePopup.addItems(withTitles: ["月薪", "日薪", "时薪"])
            modePopup.selectItem(at: AppDelegate.shared.config.mode)
            c.addSubview(modePopup)
            amountField = field(215, y - 3, 90, String(AppDelegate.shared.config.amount))
            c.addSubview(amountField)
            c.addSubview({ let l = NSTextField(labelWithString: "元"); l.frame = NSRect(x: 310, y: y, width: 60, height: 18); l.font = NSFont.systemFont(ofSize: 12); return l }())
            y -= 36

            c.addSubview(row(y, "每月计薪天数"))
            payDaysField = field(115, y - 3, 90, String(AppDelegate.shared.config.payDaysPerMonth))
            c.addSubview(payDaysField)
            y -= 36

            c.addSubview(row(y, "上下班时间"))
            startField = field(115, y - 3, 60, AppDelegate.shared.config.startText)
            endField = field(185, y - 3, 60, AppDelegate.shared.config.endText)
            c.addSubview(startField)
            c.addSubview(endField)
            c.addSubview({ let l = NSTextField(labelWithString: "格式 09:00"); l.frame = NSRect(x: 255, y: y, width: 120, height: 18); l.font = NSFont.systemFont(ofSize: 11); l.textColor = .secondaryLabelColor; return l }())
            y -= 36

            lunchCheck = check(20, y, "扣除午休", AppDelegate.shared.config.lunchDeduct)
            c.addSubview(lunchCheck)
            lunchStartField = field(115, y - 3, 60, AppDelegate.shared.config.lunchStartText)
            lunchEndField = field(185, y - 3, 60, AppDelegate.shared.config.lunchEndText)
            c.addSubview(lunchStartField)
            c.addSubview(lunchEndField)
            y -= 36

            c.addSubview(row(y, "工作日"))
            let names = ["一", "二", "三", "四", "五", "六", "日"]
            for i in 0..<7 {
                let b = check(115 + CGFloat(i) * 42, y, names[i], AppDelegate.shared.config.workdays[i])
                dayChecks.append(b)
                c.addSubview(b)
            }
            y -= 36

            otCheck = check(20, y, "加班计薪", AppDelegate.shared.config.overtime)
            c.addSubview(otCheck)
            otRateField = field(115, y - 3, 50, String(AppDelegate.shared.config.otRate))
            c.addSubview(otRateField)
            c.addSubview({ let l = NSTextField(labelWithString: "倍率"); l.frame = NSRect(x: 170, y: y, width: 60, height: 18); l.font = NSFont.systemFont(ofSize: 12); return l }())
            y -= 36

            c.addSubview(row(y, "发薪日(每月)"))
            paydayField = field(115, y - 3, 50, String(AppDelegate.shared.config.payday))
            c.addSubview(paydayField)
            c.addSubview(row(y, ""))
            y -= 36

            c.addSubview(row(y, "金额小数位"))
            decimalsField = field(115, y - 3, 50, String(AppDelegate.shared.config.decimals))
            c.addSubview(decimalsField)
            c.addSubview({ let l = NSTextField(labelWithString: "卡片配色"); l.frame = NSRect(x: 215, y: y, width: 70, height: 18); l.font = NSFont.systemFont(ofSize: 12); return l }())
            themePopup = NSPopUpButton(frame: NSRect(x: 290, y: y - 3, width: 100, height: 24))
            themePopup.addItems(withTitles: ["深色", "白色"])
            themePopup.selectItem(at: AppDelegate.shared.config.theme)
            c.addSubview(themePopup)
            y -= 36

            c.addSubview(row(y, "卡片不透明度"))
            opacitySlider = NSSlider(value: AppDelegate.shared.config.opacity, minValue: 0.4, maxValue: 1.0, target: nil, action: nil)
            opacitySlider.frame = NSRect(x: 115, y: y - 4, width: 240, height: 24)
            c.addSubview(opacitySlider)
            y -= 44

            c.addSubview(row(y, "界面缩放"))
            scaleSlider = NSSlider(value: AppDelegate.shared.scale, minValue: 0.5, maxValue: 1.0, target: nil, action: nil)
            scaleSlider.frame = NSRect(x: 115, y: y - 4, width: 200, height: 24)
            c.addSubview(scaleSlider)
            c.addSubview({ let l = NSTextField(labelWithString: "50% ~ 100%"); l.frame = NSRect(x: 322, y: y, width: 90, height: 18); l.font = NSFont.systemFont(ofSize: 11); l.textColor = .secondaryLabelColor; return l }())
            y -= 44

            let save = NSButton(title: "保存", target: self, action: #selector(saveSettings))
            save.frame = NSRect(x: 240, y: y, width: 76, height: 30)
            save.bezelStyle = .rounded
            save.keyEquivalent = "\r"
            let cancel = NSButton(title: "取消", target: self, action: #selector(closeWin))
            cancel.frame = NSRect(x: 330, y: y, width: 76, height: 30)
            cancel.bezelStyle = .rounded
            cancel.keyEquivalent = "\u{1b}"
            c.addSubview(save)
            c.addSubview(cancel)

            w.contentView = c
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func closeWin() { window?.orderOut(nil) }

    @objc func saveSettings() {
        let app = AppDelegate.shared
        var c = app.config
        c.mode = modePopup.indexOfSelectedItem
        c.amount = Double(amountField.stringValue) ?? c.amount
        c.payDaysPerMonth = Double(payDaysField.stringValue) ?? c.payDaysPerMonth
        c.startText = startField.stringValue
        c.endText = endField.stringValue
        c.lunchDeduct = lunchCheck.state == .on
        c.lunchStartText = lunchStartField.stringValue
        c.lunchEndText = lunchEndField.stringValue
        for i in 0..<7 { c.workdays[i] = dayChecks[i].state == .on }
        c.overtime = otCheck.state == .on
        c.otRate = Double(otRateField.stringValue) ?? c.otRate
        c.payday = Int(paydayField.stringValue) ?? c.payday
        c.decimals = min(max(Int(decimalsField.stringValue) ?? c.decimals, 0), 6)
        c.theme = themePopup.indexOfSelectedItem
        c.opacity = opacitySlider.doubleValue
        app.scale = scaleSlider.doubleValue
        app.savePosition()          // 把卡片当前位置写进旧 config
        c.posX = app.config.posX    // 保留位置
        c.posY = app.config.posY
        app.config = c
        c.save()
        app.rebuildContent()
        app.tick()
        closeWin()
    }
}

// MARK: - 入口

let app = NSApplication.shared
app.delegate = AppDelegate.shared
app.run()
