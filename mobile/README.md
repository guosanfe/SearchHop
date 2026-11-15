# 搜跳 SearchHop 移动端

Flutter 编写的搜跳移动端：**App 直达 + 网页兜底**。选择站点、输入关键词，优先拉起对应 App 的搜索页；未安装或拉起失败时自动改用系统浏览器打开网页搜索。跳过推荐流，搜完即走。

与桌面端同一产品边界：**不内嵌 WebView、不发起任何网络请求、无账号**，配置仅存本机（shared_preferences）。

## 功能

- 内置与桌面端一致的 9 个站点（Bilibili、知乎、微博、百度、小红书、抖音、淘宝、京东、拼多多），其中 8 个带 App scheme 模板（百度仅网页）。
- **App 直达**：以 externalApplication 模式拉起 scheme；失败或未安装时自动**网页兜底**。
- **站点管理**：添加 / 编辑 / 删除自定义站点、拖拽排序，本地持久化。
- **Android 桌面小组件**：三种尺寸，不打开 App 直接搜。
- 关键词为空时提示而不拉起。

## 运行

前置：Flutter SDK（Dart ^3.14）。

```bash
cd mobile
flutter pub get
flutter run
```

## 构建

```bash
flutter build apk --release
```

> 当前 release 使用 **debug 签名**（见 `android/app/build.gradle.kts` 中的 TODO），公开发布前请替换为自己的签名。

## 测试

```bash
flutter test
```

覆盖：URL 构建、站点模型、拉起/兜底逻辑、管理页与搜索页 widget、小组件搜索页。

## 目录结构

```
mobile/
  lib/
    main.dart
    src/
      search_screen.dart         # 主搜索页
      widget_search_screen.dart  # 小组件搜索页
      manage_screen.dart         # 站点管理
      launcher.dart              # App 直达 + 网页兜底
      site.dart                  # 站点模型
      site_store.dart            # 本地持久化
      default_sites.dart         # 内置站点与 scheme 模板
      url_builder.dart           # 模板 + 关键词 → URL
      theme.dart                 # 共享视觉语言
  android/                       # 含 SearchHopWidgetProvider（桌面小组件）
  ios/
  test/
  docs/mobile-scheme-candidates.md  # scheme 模板清单（草案）
```

## 已知限制

- App scheme 模板来自公开社区收集，**未经真机全量验证**（清单见 [docs/mobile-scheme-candidates.md](docs/mobile-scheme-candidates.md)）；个别站点可能拉起失败或落点不准，失败时网页兜底。
- 京东等嵌套 JSON 模板使用整段编码（`EncodeMode.wholeParams`）。
- iOS 拉起其它 App 会弹系统确认框。
- release 包当前为 debug 签名。