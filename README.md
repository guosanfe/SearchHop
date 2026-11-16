# 搜跳 SearchHop

**注意力革命 · 夺回你的注意力**

> 不刷推荐流。搜一下 · 点一下 · 跳过去。

搜跳是一个跨桌面与移动端的**搜索直达器**：选择站点、输入关键词，直接用系统默认浏览器或对应 App 打开该站点的**搜索结果页**——跳过首页推荐流，不让注意力被算法吸走。

它不是浏览器、不是爬虫、不是内容聚合器：只负责打开正确的 URL，搜完即走。

## 界面预览

![桌面端](docs/screenshots/desktop.png)

<img src="docs/screenshots/mobile.png" width="280" alt="移动端" />

## 功能

- **搜索直达**：内置 9 个常用站点（Bilibili、知乎、微博、百度、小红书、抖音、淘宝、京东、拼多多），支持一键添加自定义站点。
- **Windows 桌面端**：置顶悬浮小窗、Enter 即搜、关键词一键清空；站点管理支持拖拽排序、显示/隐藏、恢复默认。
- **Android 移动端**：App 直达搜索页 + 未安装时自动网页兜底；站点管理（增删改、拖拽排序）；三种尺寸的桌面小组件，不打开 App 直接搜。
- **全程本地**：零网络请求、无账号、无跟踪、无分析；配置只保存在你自己的设备上。

## 隐私

搜跳本体**不发起任何网络请求**：不上传、不遥测、不登录。搜索行为发生在你被跳转到的系统浏览器或目标 App 中，受该平台隐私政策约束。全部源码开放，欢迎审查。

## 下载与安装

| 平台 | 方式 | 说明 |
|---|---|---|
| Windows | 源码运行 / 自行打包 exe | 见 [desktop/README.md](desktop/README.md) |
| Android | 源码构建 APK | 见 [mobile/README.md](mobile/README.md) |

预编译安装包将在 Releases 提供（筹备中）。

## 快速开始

桌面端（Python 3.11，含 tkinter）：

```bat
cd desktop
pip install -r requirements.txt
python app.py
```

移动端（Flutter SDK，Dart ^3.14）：

```bash
cd mobile
flutter pub get
flutter run
```

## 仓库结构

```
searchhop/
  desktop/          # Windows 桌面端：Python 3.11 + CustomTkinter
  mobile/           # Android / iOS：Flutter
  docs/screenshots/ # 界面截图
  LICENSE           # MIT
```

## 测试

```bat
cd desktop
python -m unittest discover -s tests -v
```

```bash
cd mobile
flutter test
```

## 开源

[MIT License](LICENSE)。「注意力革命」是本项目的口号——欢迎 fork，做出你自己的夺回注意力工具。