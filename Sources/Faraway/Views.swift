import SwiftUI
import AppKit

extension Color {
    static let paper = Color(red: 0.96, green: 0.95, blue: 0.91)
    static let pine = Color(red: 0.13, green: 0.25, blue: 0.22)
    static let sage = Color(red: 0.58, green: 0.66, blue: 0.55)
    static let clay = Color(red: 0.78, green: 0.39, blue: 0.23)
}

struct Brand: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye").font(.system(size: 20, weight: .medium))
                .frame(width: 38, height: 38).background(Color.pine.opacity(0.07), in: .rect(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 2) {
                Text("远眺").font(.system(size: 16, weight: .semibold))
                Text("F A R A W A Y").font(.system(size: 8, weight: .medium))
            }
        }.foregroundStyle(Color.pine)
    }
}

struct Landscape: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(colors: [Color(red: 0.89, green: 0.91, blue: 0.84), .paper], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(red: 0.89, green: 0.65, blue: 0.40))
                    .frame(width: h * 0.23, height: h * 0.23).position(x: w * 0.66, y: h * 0.29)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.72))
                    p.addCurve(to: CGPoint(x: w, y: h * 0.58), control1: CGPoint(x: w * 0.44, y: h * 0.12), control2: CGPoint(x: w * 0.53, y: h * 0.97))
                    p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
                }.fill(Color(red: 0.66, green: 0.72, blue: 0.61))
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.8))
                    p.addCurve(to: CGPoint(x: w, y: h * 0.68), control1: CGPoint(x: w * 0.32, y: h * 0.97), control2: CGPoint(x: w * 0.64, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
                }.fill(Color(red: 0.37, green: 0.49, blue: 0.40))
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.87))
                    p.addCurve(to: CGPoint(x: w, y: h * 0.96), control1: CGPoint(x: w * 0.4, y: h * 0.64), control2: CGPoint(x: w * 0.7, y: h * 0.95))
                    p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
                }.fill(Color.pine)
                Path { p in
                    p.move(to: CGPoint(x: w * 0.56, y: h * 0.64))
                    p.addCurve(to: CGPoint(x: w * 0.47, y: h), control1: CGPoint(x: w * 0.37, y: h * 0.82), control2: CGPoint(x: w * 0.68, y: h * 0.85))
                }.stroke(Color.paper.opacity(0.35), style: StrokeStyle(lineWidth: max(1, w * 0.003), lineCap: .round))
            }.clipped()
        }.accessibilityHidden(true)
    }
}

struct PineButton: ButtonStyle {
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .medium))
            .frame(maxWidth: .infinity).padding(.vertical, 13)
            .foregroundStyle(filled ? Color.paper : Color.pine)
            .background(filled ? Color.pine : Color.pine.opacity(0.06), in: .rect(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct MenuView: View {
    let model: AppModel
    var settingsAction: (() -> Void)? = nil
    @Environment(\.openSettings) private var openSettings
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Brand()
                Spacer()
                Text(model.phase == .paused ? "已暂停" : "守护中")
                    .font(.system(size: 10, weight: .medium)).padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Color.pine.opacity(0.07), in: .capsule)
            }.padding(22)
            ZStack(alignment: .bottomLeading) {
                Landscape()
                VStack(alignment: .leading, spacing: 5) {
                    Text("给目光，一点远方。")
                        .font(.system(size: 22, weight: .medium, design: .serif))
                    Text("A LITTLE DISTANCE. A FRESH PERSPECTIVE.")
                        .font(.system(size: 7, weight: .medium)).tracking(1)
                }.foregroundStyle(Color.paper).padding(20)
            }.frame(height: 146).clipShape(.rect(cornerRadius: 16)).padding(.horizontal, 18)
            VStack(spacing: 9) {
                Text(model.phase == .paused ? "让时间慢下来" : model.phase == .resting ? "正在远眺休息" : "距离下一次远眺")
                    .font(.system(size: 12)).foregroundStyle(Color.pine.opacity(0.65))
                Text(model.menuTitle).font(.system(size: 53, weight: .light, design: .rounded)).monospacedDigit()
                    .contentTransition(.numericText()).accessibilityLabel("剩余时间 \(model.menuTitle)")
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.pine.opacity(0.08))
                        Capsule().fill(Color.sage).frame(width: geo.size.width * min(1, max(0, model.progress)))
                    }
                }.frame(height: 4).padding(.horizontal, 36)
                Text("每 \(model.intervalMinutes) 分钟 · 远眺 6 米外 · 休息 \(model.breakSeconds) 秒")
                    .font(.system(size: 10)).foregroundStyle(Color.pine.opacity(0.6)).padding(.top, 5)
            }.padding(.vertical, 23)
            HStack(spacing: 9) {
                Button { model.startBreak() } label: { Label("现在休息", systemImage: "leaf") }.buttonStyle(PineButton())
                Button { model.togglePause() } label: {
                    Label(model.phase == .paused ? "继续计时" : "暂停提醒", systemImage: model.phase == .paused ? "play" : "pause")
                }.buttonStyle(PineButton(filled: false)).disabled(model.phase == .resting)
            }.padding(.horizontal, 18)
            HStack {
                Label("今日已休息 \(model.completed) 次", systemImage: "checkmark.circle")
                    .font(.system(size: 11)).foregroundStyle(Color.pine.opacity(0.65))
                Spacer()
                Button {
                    if let settingsAction { settingsAction() } else { openSettings(); NSApp.activate(ignoringOtherApps: true) }
                } label: { Image(systemName: "slider.horizontal.3") }
                    .help("偏好设置").accessibilityLabel("偏好设置")
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
                    .padding(.leading, 10).help("退出远眺").accessibilityLabel("退出远眺")
            }.buttonStyle(.plain).padding(22)
        }.frame(width: 340).background(Color.paper).foregroundStyle(Color.pine).preferredColorScheme(.light)
    }
}

struct BreakView: View {
    let model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.paper
                Landscape().opacity(0.43).frame(height: geo.size.height * 0.59)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                VStack {
                    HStack {
                        Brand()
                        Spacer()
                        HStack(spacing: 7) {
                            Circle().fill(Color.clay).frame(width: 6, height: 6)
                            Text("留一点时间，给自己").font(.system(size: 12))
                        }.foregroundStyle(Color.pine.opacity(0.6))
                    }.padding(40)
                    Spacer(minLength: 10)
                    VStack(spacing: 22) {
                        Text("T H E   2 0 · 2 0 · 2 0   R I T U A L")
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(Color.clay)
                        Text("此刻，望向远方。")
                            .font(.system(size: min(58, geo.size.width * 0.055), weight: .light, design: .serif)).tracking(3)
                        Text("把视线从屏幕移开，找一个 6 米以外的地方。")
                            .font(.system(size: 16)).foregroundStyle(Color.pine.opacity(0.66))
                        ZStack {
                            Circle().stroke(Color.pine.opacity(0.07), lineWidth: 1)
                                .frame(width: 184, height: 184).scaleEffect(breathe && !reduceMotion ? 1.07 : 0.98)
                            Circle().stroke(Color.pine.opacity(0.1), lineWidth: 2)
                            Circle().trim(from: 0, to: min(1, Double(model.remaining) / Double(model.breakSeconds)))
                                .stroke(Color.pine.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(reduceMotion ? nil : .linear(duration: 0.2), value: model.remaining)
                            VStack(spacing: 0) {
                                Text("\(model.remaining)").font(.system(size: 64, weight: .ultraLight, design: .rounded)).monospacedDigit()
                                Text("秒后，轻松回来").font(.system(size: 10)).foregroundStyle(Color.pine.opacity(0.6))
                            }
                        }.frame(width: 160, height: 160).padding(.vertical, 17)
                        Text("放松肩膀，自然眨眼。\n不必盯着倒计时，结束时会自动收起。")
                            .font(.system(size: 13)).lineSpacing(6).multilineTextAlignment(.center)
                            .foregroundStyle(Color.pine.opacity(0.62))
                    }
                    Spacer(minLength: 20)
                    HStack {
                        Text("\(model.intervalMinutes) 分钟专注  /  \(model.breakSeconds) 秒休息  /  20 英尺远眺")
                            .font(.system(size: 10)).foregroundStyle(Color.pine.opacity(0.6))
                        Spacer()
                        Button { model.snooze() } label: {
                            HStack(spacing: 12) {
                                Text("5 分钟后提醒")
                                Text("esc").font(.system(size: 10, design: .monospaced)).padding(.horizontal, 5).padding(.vertical, 3)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.pine.opacity(0.2)))
                            }.font(.system(size: 12)).padding(.horizontal, 17).padding(.vertical, 11)
                                .background(Color.paper.opacity(0.65), in: .capsule)
                        }.buttonStyle(.plain).accessibilityHint("结束本次提醒，五分钟后再次提醒")
                    }.padding(40)
                }
            }.foregroundStyle(Color.pine)
        }.ignoresSafeArea()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { breathe = true }
            }
    }
}

struct PreferencesView: View {
    @Bindable var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Brand()
            VStack(alignment: .leading, spacing: 6) {
                Text("找到你的休息节奏").font(.system(size: 25, weight: .medium, design: .serif))
                Text("从 20–20–20 开始，让远眺成为习惯。")
                    .font(.system(size: 12)).foregroundStyle(Color.pine.opacity(0.65))
            }
            Form {
                Picker("提醒间隔", selection: $model.intervalMinutes) {
                    ForEach([20, 30, 45, 60], id: \.self) { Text("\($0) 分钟").tag($0) }
                }
                Picker("休息时长", selection: $model.breakSeconds) {
                    ForEach([20, 30, 60], id: \.self) { Text("\($0) 秒").tag($0) }
                }
                Toggle("结束时播放轻提示音", isOn: $model.soundEnabled)
                Toggle("登录 Mac 时启动", isOn: Binding(get: { model.loginEnabled }, set: { model.setLogin($0) }))
            }.formStyle(.grouped).scrollContentBackground(.hidden).frame(height: 210)
            if let error = model.loginError { Text(error).font(.caption).foregroundStyle(Color.clay).textSelection(.enabled) }
            Text("修改时长会重新计时。睡眠或锁屏时自动暂停，返回后继续。\n休息提醒覆盖所有屏幕，随时按 Esc 延后 5 分钟。")
                .font(.system(size: 11)).lineSpacing(5).fixedSize(horizontal: false, vertical: true).foregroundStyle(Color.pine.opacity(0.65))
            Link("了解 20–20–20 法则 ↗", destination: URL(string: "https://www.aao.org/eye-health/tips-prevention/should-you-be-worried-about-blue-light")!)
                .font(.system(size: 11)).tint(Color.pine)
        }.padding(30).frame(width: 450).background(Color.paper).foregroundStyle(Color.pine).preferredColorScheme(.light)
    }
}
