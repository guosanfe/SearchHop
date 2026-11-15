# 搜跳 SearchHop 桌面端

Windows 桌面**搜索直达器**（不是浏览器）：选择站点、输入关键词，用**系统默认浏览器**直接打开该站点的**搜索结果页**，跳过首页推荐流，减少注意力被吸走。

- 技术栈：Python 3.11 + [CustomTkinter](https://github.com/TomSchimansky/CustomTkinter)（基于 tkinter 的现代外观库），Python 单体应用，**不引入 WebView / 前端框架**。
- 核心逻辑：读取配置 → 拼接搜索 URL（`urllib.parse.quote` 编码）→ `webbrowser.open` 打开。
- **不发起任何网络请求、不爬取页面、不内嵌浏览器、不登录账号。** 只负责打开正确的 URL。

## 功能与交互

- 紧凑小窗（约 400×190、居中启动），绿色主题（标题栏 `#00CC6A`、浅绿底 `#F4F6F1`、深绿按钮 `#167653`），Windows 11 原生标题栏染绿，中文友好字体（微软雅黑）。
- 关键词框默认聚焦（绿色描边），有内容时框内 **× 一键清空**并重新聚焦；按 **Enter** 或点击「搜索」打开结果页（单次回车只打开一个页面）。
- **置顶悬浮**于其它窗口之上，状态持久化。
- 站点选择器整块可点击，自定义箭头与圆角下拉菜单；移动窗口或点击窗口外时自动收起。
- **站点管理**：按住整行拖拽排序（拖动时其余行实时让位、被拖行跟随指针），Naive UI 风格开关控制显示/隐藏，添加自定义站点、恢复默认，实时生效并保存到 config.json。
- 主页无常驻提示，仅在实际出错（配置损坏、保存失败、打开浏览器失败等）时弹窗。

## 目录结构

```
desktop/
  app.py               # GUI 入口（CustomTkinter）
  site_manager.py      # 站点管理对话框（拖拽排序 / 显示隐藏 / 添加 / 恢复默认）
  site_selector.py     # 整块可点击的站点选择器 + 美化下拉菜单
  naive_switch.py      # Naive UI 风格开关（逐像素抗锯齿 + 滑动/变色动效）
  theme.py             # 共享绿色视觉语言 / 字体 / 标题栏染绿
  config.py            # 配置读写 / 校验 / 回退 / 持久化
  url_builder.py       # 纯函数：模板 + 关键词 → URL
  default_config.json  # 内置默认站点
  assets/icon.ico      # 窗口 / exe 图标
  requirements.txt     # 运行依赖 customtkinter + 打包依赖 pyinstaller
  build.bat            # PyInstaller 单文件打包脚本
  tests/               # unittest
```

## 运行（源码方式）

前置：Python 3.11（含 tkinter，Windows 官方安装包默认自带）。

```bat
cd desktop
pip install -r requirements.txt
python app.py
```

## 配置 config.json

- 位置：**打包后优先读取 exe 同目录**；源码运行时读取 `app.py` 所在目录。首次运行若不存在会自动生成默认配置。
- 结构：

```json
{
  "settings": { "always_on_top": false },
  "sites": [
    { "name": "Bilibili", "url_template": "https://search.bilibili.com/all?keyword={query}", "enabled": true }
  ]
}
```

- `sites` 数组顺序即下拉框显示顺序；`enabled` 控制显示/隐藏（缺省 `true`）；`settings.always_on_top` 持久化置顶开关。均可在「管理」对话框可视化调整，也可直接编辑文件。
- `{query}` 是关键词占位符，URL 编码后替换，可位于路径中（如抖音）或查询参数中。
- **自定义站点**：往 `sites` 数组追加一项即可，例如豆瓣：

```json
{ "name": "豆瓣", "url_template": "https://www.douban.com/search?q={query}" }
```

保存后重启程序生效。天猫、1688 等不在默认列表中，但都可这样自行添加。

- **容错**：config.json 损坏（非法 JSON、缺少 `sites` 数组、模板缺少 `{query}` 等）时 GUI 仍能启动，弹窗显示可理解的错误，并**自动回退到内置默认站点**。删除 config.json 后重启会重新生成。

## 默认站点

内容社区 / 媒体：Bilibili、知乎、微博、百度、小红书、抖音。
网购平台：淘宝、京东、拼多多。

## 测试

标准库 `unittest`，无需额外依赖。在 `desktop/` 目录下执行：

```bat
python -m unittest discover -s tests -v
```

覆盖：正常模板、中文关键词编码、抖音路径编码、模板缺少 `{query}` 的异常、保留字符编码等。

## 打包为单文件 exe

```bat
cd desktop
pip install -r requirements.txt
build.bat
```

等价于：

```bat
pyinstaller --noconfirm --onefile --windowed --noupx --name SearchHop --icon "assets/icon.ico" --collect-all customtkinter --exclude-module numpy --exclude-module PIL --exclude-module Pillow --add-data "default_config.json;." --add-data "assets/icon.ico;assets" app.py
```

产物为 `dist\SearchHop.exe`（单文件、无控制台窗口）。首次运行时在 **exe 同目录**生成可编辑的 config.json。

> 体积优化：CustomTkinter 的可选 `CTkImage` 会间接引入 numpy / Pillow，本程序完全不用它们（开关用 `tkinter.PhotoImage` 逐像素绘制），排除后单文件从约 27 MB 降到约 **14 MB**（仍内置 CustomTkinter 资源与 Tcl/Tk 运行时，属正常下限）。`--noupx` 表示不做二进制压缩；`--add-data` 分隔符在 Windows 上是 `;`。

## 已知限制

- **拼多多（实验性支持）**：默认使用移动端入口 `mobile.yangkeduo.com/search_result.html?search_key=...`，桌面浏览器中可能被重定向、要求登录或展示不完整。本工具只负责打开 URL，**不处理重定向 / 登录 / 反爬**，可在 config.json 中自行替换模板。
- **抖音**：关键词位于 URL **路径**中，已用 `quote` 编码；未登录时网页搜索可能展示不完整。
- **淘宝**：使用 `s.taobao.com/search?q=...`，未登录时可能跳转登录页或展示受限，属平台行为。
- **通用**：不保证任何平台在未登录状态下完整展示搜索结果；不做全局热键、安装器、自动更新、系统托盘、历史记录、多标签页、浏览器插件。
- 打开浏览器依赖系统已设置默认浏览器；`webbrowser.open` 失败会弹窗提示。