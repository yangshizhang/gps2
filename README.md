# Liquid Glass Speedometer · 液态玻璃风格 iOS 码表 App

一个使用 **SwiftUI** 开发的 iOS 码表 / 速度记录应用。界面采用苹果官方 **Liquid Glass（液态玻璃）** 风格，支持：

- 🚀 实时显示车速 / 海拔 / 指南针（圆盘仪表）
- 📍 同步记录 GPS 轨迹（实时绘制）
- 📊 记录行驶时长、平均速度、最高速度、距离
- ⚡️ 记录加速度传感器数据
- 🗂 历史记录列表 + 详情（缩略地图 + 车速曲线）
- ⚙️ 设置界面（高德地图 API Key、单位、屏幕常亮等）
- 🗺 预留高德地图 SDK 接入位置（可替换原生 MapKit）

## 工程结构

```
LiquidGlassSpeedometer/
├── LiquidGlassSpeedometer/
│   ├── App/
│   │   ├── LiquidGlassSpeedometerApp.swift   # App 入口
│   │   └── AppState.swift                    # 全局状态 / 会话管理
│   ├── Managers/
│   │   ├── LocationManager.swift             # GPS 管理
│   │   ├── MotionManager.swift               # 加速度管理
│   │   ├── DataStore.swift                   # CoreData 持久化
│   │   └── Session+Helpers.swift             # Session 扩展方法
│   ├── Views/
│   │   ├── LiquidGlass.swift                 # 液态玻璃 Style modifier
│   │   ├── SpeedometerDial.swift             # 圆盘仪表盘
│   │   ├── SpeedometerView.swift             # 主码表 Tab
│   │   ├── MapTrackView.swift                # 地图 Tab
│   │   ├── HistoryListView.swift             # 历史记录列表
│   │   ├── HistoryDetailView.swift           # 历史记录详情
│   │   └── SettingsView.swift                # 设置 Tab
│   └── Resources/
│       ├── Info.plist
│       ├── Assets.xcassets
│       └── TrackModel.xcdatamodeld           # CoreData 模型
└── LiquidGlassSpeedometer.xcodeproj/
```

## 环境要求

- Xcode 15+
- iOS 17.0+
- Swift 5.9+
- 需要真机运行（GPS / 加速度传感器）

## 构建方式

### 本地 Xcode 构建

```bash
cd LiquidGlassSpeedometer
open LiquidGlassSpeedometer.xcodeproj
# 在 Xcode 中选择 Scheme → Run
```

### xcodebuild 命令行构建（unsigned IPA）

```bash
cd LiquidGlassSpeedometer
xcodebuild \
  -project LiquidGlassSpeedometer.xcodeproj \
  -scheme LiquidGlassSpeedometer \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGN_ENTITLEMENTS="" \
  ARCHS="arm64" \
  build

# 打包成 IPA
mkdir -p Payload
cp -R build/Build/Products/Release-iphoneos/LiquidGlassSpeedometer.app Payload/
zip -r LiquidGlassSpeedometer-unsigned.ipa Payload
```

### GitHub Actions 自动构建

仓库已配置 `.github/workflows/build.yml`，在 `macos-15` runner 上自动构建并上传 `unsigned IPA` 工件（artifact），保留 30 天。

触发方式：

- push 到 `main` / `master`
- 手动在 Actions 页面触发 `workflow_dispatch`

## 高德地图 SDK 接入位置

当前地图功能使用 **Apple MapKit** 作为默认实现。如果需要切换为 **高德地图（AMap）**：

1. 在 [高德开放平台](https://lbs.amap.com/) 申请 API Key。
2. 进入应用设置 → 填写 `高德地图 API Key`。
3. 使用 CocoaPods / Swift Package 引入 `AMapFoundationKit`、`AMapLocationKit`、`AMapSearchKit`、`MAMapKit`。
4. 在 `MapTrackView.swift` 中将 `Map(...)` 替换为 `MAMapView` 对应 UIViewRepresentable 包装即可。
5. 在 `Info.plist` 中将 `AMapServicesApiKey` 字段值替换为你的 Key。

## 功能模块说明

| 模块 | 说明 |
| ---- | ---- |
| **AppState** | 全局会话控制器：开始 / 停止记录、维护当前速度、最高速度、平均速度、时长 |
| **LocationManager** | `CLLocationManager` 封装；实时回调速度 / 海拔 / 航向 |
| **MotionManager** | `CMMotionManager` 封装；读取加速度数据用于分析驾驶激烈程度 |
| **DataStore** | CoreData 容器（`Session` ↔ `TrackPoint` / `MotionPoint`） |
| **SpeedometerDial** | 圆盘仪表盘：外圈刻度、实时圆弧、指南针、海拔卡片 |
| **HistoryDetailView** | 展示单次记录：数据汇总 + 缩略地图 + 车速曲线 |

## 图标 / 资源

`Assets.xcassets` 目前为占位，请在 Xcode 中拖入 `AppIcon` 图片及自定义颜色后再构建。

## 许可

MIT
