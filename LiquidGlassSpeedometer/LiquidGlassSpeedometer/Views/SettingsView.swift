import SwiftUI

/// 设置界面：地图 API key、单位、背景颜色等
struct SettingsView: View {
    @AppStorage("amap_api_key") private var amapApiKey: String = ""
    @AppStorage("unit_system") private var unitSystem: String = "km"
    @AppStorage("keep_screen_on") private var keepScreenOn: Bool = true
    @AppStorage("auto_pause") private var autoPause: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.35),
                         Color(red: 0.12, green: 0.14, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("地图 API", systemImage: "map.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        TextField("高德地图 API Key", text: $amapApiKey, prompt: Text("请输入您的高德地图 API Key"))
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(.white)
                            .padding(12)
                            .liquidGlass(radius: 16, fill: .ultraThinMaterial)
                        Text("设置 API Key 后应用将使用高德地图进行路径规划与地理编码（需引入 AMap SDK）。")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("显示", systemImage: "eye")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Toggle(isOn: $keepScreenOn) {
                            Text("保持屏幕常亮")
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .cyan))
                        .padding(12)
                        .liquidGlass(radius: 16, fill: .ultraThinMaterial)

                        Toggle(isOn: $autoPause) {
                            Text("静止时自动暂停")
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .cyan))
                        .padding(12)
                        .liquidGlass(radius: 16, fill: .ultraThinMaterial)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("单位", systemImage: "ruler")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Picker("速度单位", selection: $unitSystem) {
                            Text("公里/小时 (km/h)").tag("km")
                            Text("英里/小时 (mph)").tag("mi")
                        }
                        .pickerStyle(.segmented)
                        .padding(12)
                        .liquidGlass(radius: 16, fill: .ultraThinMaterial)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("关于", systemImage: "info.circle")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Liquid Glass Speedometer")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("版本 1.0.0 · 使用 GPS 与加速度传感器记录行驶数据")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(12)
                        .liquidGlass(radius: 16, fill: .ultraThinMaterial)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
