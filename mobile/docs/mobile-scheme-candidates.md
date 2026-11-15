# SearchHop 移动端候选站点 Scheme 模板清单

状态：草案 v0.1（2026-11-14）。**所有模板均来自公开社区收集，未经真机验证**，上线前必须逐条实测。
用途：手机端"App 直达 + 网页兜底"双模板的数据源。`{query}` 占位符与桌面端 `url_builder.py` 保持一致。

## 编码规则

- 常规模板：关键词先百分号编码（`urllib.parse.quote`），再替换 `{query}`，与桌面端逻辑相同。
- **嵌套 JSON 模板（京东、什么值得买）例外**：需先把原始关键词代入 JSON，再对整个 `params` / `json` 值做一次百分号编码。现有 `url_builder` 的"先编码后替换"流程不适用，需要扩展（如按站点配置 `encode_mode: whole_params`）。
- 同一 scheme 在 iOS / Android 上路径通常一致，但需分端实测；iOS 拉起会弹确认框，Android 可用 PackageManager 检测是否安装。

## 一、现有站点（9 个，对应 default_config.json）

| 站点 | app_template | 可信度 | 备注 |
|---|---|---|---|
| Bilibili | `bilibili://search?keyword={query}` | 高 | 多个独立来源一致 |
| 知乎 | `zhihu://search?q={query}` | 中 | 两个来源，收集时间较早，需验证新版 |
| 微博 | `sinaweibo://searchall?q={query}` | 中高 | 多来源；极速版 `weibolite://searchall?q={query}`、国际版 `weibointernational://searchall?q={query}` 同路径 |
| 百度 | —（保留网页版） | — | 未找到可靠的公开搜索 scheme；`baiduboxapp://browse?url=` 只是内置浏览器打开网页，不符合直达搜索页的目标 |
| 小红书 | `xhsdiscover://search/result?keyword={query}` | 高 | 多来源，含 2026 年实测文章；商品搜索另有 `xhsdiscover://instore_search/result?keyword={query}` |
| 抖音 | `snssdk1128://search?keyword={query}` | 中高 | 备选路径 `snssdk1128://search/tabs?keyword={query}`；极速版 scheme 为 `snssdk2329://`（搜索路径待验证） |
| 淘宝 | `taobao://s.taobao.com/?q={query}` | 中 | 部分版本可能需 tbopen 桥接（`tbopen://m.taobao.com/tbopen/index.html?h5Url=<编码后的搜索页URL>`）；淘宝特价版 `taobaolite://m.ltao.com/?q={query}` |
| 京东 | `openapp.jdmobile://virtual?params={"des":"productList","keyWord":"{query}","from":"search","category":"jump"}` | 中 | 嵌套 JSON，需整段编码（见编码规则） |
| 拼多多 | `pinduoduo://yangkeduo.com/search_result.html?search_key={query}` | 中低 | 单一来源且较旧，优先验证 |

## 二、新增候选（10 个）

| 站点 | app_template | 可信度 | 备注 |
|---|---|---|---|
| 快手 | `kwai://search?keyword={query}` | 中 | |
| 快手极速版 | `ksnebula://search?keyword={query}` | 中低 | |
| 豆瓣 | `douban:///search?q={query}` | 中 | 注意是三个斜杠 |
| YouTube | `youtube://results?search_query={query}` | 中高 | |
| X (Twitter) | `twitter://search?query={query}` | 中 | |
| 天猫 | `tmall://page.tm/search?q={query}` | 中 | |
| 美团 | `imeituan://www.meituan.com/search?q={query}` | 中 | |
| 大众点评 | `dianping://searchshoplist?keyword={query}` | 中 | 搜店为主 |
| 美团外卖 | `meituanwaimai://waimai.meituan.com/search?query={query}` | 中低 | |
| 什么值得买 | `smzdm://search?json={"channelName":"home","search_type":"1","keyWord":"{query}"}` | 低 | 嵌套 JSON，需整段编码 |

## 三、不收录 / 待考证

- **微信**：不开放外部搜索入口，仅 `weixin://` 拉起首页，不收录。
- **网易云音乐、QQ音乐、今日头条、百度 App**：未找到可靠的搜索页路径（只有首页/内容页 scheme），待反编译或抓包考证后再补。

## 四、Android 包名（用于"是否安装"检测，需真机核对）

| 站点 | 包名 |
|---|---|
| Bilibili | `tv.danmaku.bili` |
| 知乎 | `com.zhihu.android` |
| 微博 | `com.sina.weibo` |
| 小红书 | `com.xingin.xhs` |
| 抖音 | `com.ss.android.ugc.aweme` |
| 淘宝 | `com.taobao.taobao` |
| 京东 | `com.jingdong.app.mall` |
| 拼多多 | `com.xunmeng.pinduoduo` |
| 快手 | `com.smile.gifmaker` |
| 豆瓣 | `com.douban.frodo` |
| YouTube | `com.google.android.youtube` |
| X | `com.twitter.android` |
| 天猫 | `com.tmall.wireless` |
| 美团 | `com.sankuai.meituan` |
| 大众点评 | `com.dianping.v1` |
| 美团外卖 | `com.sankuai.meituan.takeoutnew` |
| 什么值得买 | `com.smzdm.client.android` |

## 五、建议的配置结构（移动端）

```json
{
  "name": "Bilibili",
  "url_template": "https://search.bilibili.com/all?keyword={query}",
  "app_template": "bilibili://search?keyword={query}",
  "android_package": "tv.danmaku.bili",
  "encode_mode": "query"
}
```

- `app_template` 可选；缺失时直接走网页版（百度即此情况）。
- `encode_mode`: `query`（默认，先编码关键词再替换）| `whole_params`（京东/什么值得买，代入后整段编码）。
- 跳转顺序：已安装 App → `app_template`；未安装或拉起失败 → `url_template` 交系统浏览器。
- iOS 无法可靠检测安装，可用 Universal Link（现有 https 模板在已安装且注册了 UL 的 App 上可能直接进 App）或"先试 scheme、失败回退"策略。

## 六、真机验证清单

1. Android 用 adb 逐条测试：`adb shell am start -a android.intent.action.VIEW -d "bilibili://search?keyword=测试"`
2. 关键词覆盖：纯中文、中英混合、含空格、含特殊字符（`&` `#` `%` `+`）。
3. 确认落地页是**搜索结果页**而非首页/推荐流（产品核心目标）。
4. 卸载目标 App 后验证兜底路径。
5. iOS 在 Safari 地址栏或快捷指令中测试，记录确认框行为；同时测试 https 模板是否触发 Universal Link。
6. 每条记录：App 版本号、系统版本、验证日期、结果（通过/失效/落首页）。

## 来源

- [axs66/URL-Scheme（应用内搜索章节，2024-10 更新）](https://github.com/axs66/URL-Scheme)
- [快捷指令｜各种搜索合集（百度知道，2025-07）](https://zhidao.baidu.com/question/886444911374057052.html)
- [含参数的 URL Scheme 收集（JamesHopbourn gist）](https://gist.github.com/JamesHopbourn/046bc341e7debfd0c86e3b388d983c53)
- [常用应用 URL Scheme 汇总整理（dodoo.co，2025-09）](https://dodoo.co/system/protocol)
- [小红书 Scheme 实测清单（CSDN，2026-05）](https://m.blog.csdn.net/weixin_30952535/article/details/95345579)
- [常用 URL Schemes 收集（gist 559033）](https://gist.github.com/559033/8c1d99717b8f9bbf05c570ecbed108fb)
- [小红书官方 Deeplink 文档（搜索章节确认 search/result?keyword= 格式）](https://pages.xiaohongshu.com/activity/deeplink)

## 七、真机反馈与修正（2026-11-14，v1.0.0 APK）

| 站点 | 真机现象 | 修正 |
|---|---|---|
| Bilibili | 只能打开网页 | launcher 改为直接尝试 `launchUrl`（见下）；scheme 不变，待复测 |
| 淘宝 | 唤起 App 但内容是 PC 端网页 | `app_template` 补 `/search` 路径：`taobao://s.taobao.com/search?q={query}`（裸域名被路由进 H5 容器） |
| 小红书 | 默认打开网页 | 同 Bilibili 的 launcher 修正；格式已获官方文档确认，待复测 |

技术说明：

- `canLaunchUrl`（url_launcher_android 6.3.33）底层是 `Intent.resolveActivity`，按 `MATCH_DEFAULT_ONLY` 匹配，对不含 DEFAULT category 的 intent-filter 会误报 false；`launchUrl` 直接 `startActivity`、失败返回 false，更可靠。launcher 不再以 `canLaunchUrl` 前置判断。
- 回退网页版时主界面提示「未唤起 App，已打开网页版」，便于真机区分「拉起失败」与「App 内部打开网页」。
- 复测仍失败的站点：USB 连接后 `adb shell dumpsys package <包名>` 查看 intent-filter 实际注册的 scheme/host/path，据此修模板；`adb shell am start -a android.intent.action.VIEW -d "<scheme>"` 逐条验证。

## 八、真机验证结果（2026-11-14，Redmi 23113RKC6C / HyperOS）

App 版本：Bilibili 9.17.0、淘宝 10.68.10、小红书 9.52.0。`am start -W` 路由 + 截图确认落地页：

| 站点 | 最终模板 | 落地 Activity | 结果 |
|---|---|---|---|
| Bilibili | `bilibili://search?keyword={query}` | `com.bilibili.search2.main.BiliMainSearchActivity` | ✅ 原生搜索结果页，关键词带入 |
| 小红书 | `xhsdiscover://search/result?keyword={query}` | `com.xingin.alioth.search.GlobalSearchActivity` | ✅ 原生搜索结果页，关键词带入 |
| 淘宝 | `taobao://main.m.taobao.com/search/index.html?q={query}` | `com.taobao.search.uniform.SearchActivity` | ✅ 原生搜索结果页，关键词带入 |

淘宝路由坑（dumpsys 实测）：

- `taobao://s.taobao.com/?q=` 与 `taobao://s.taobao.com/search?q=` 均被 `com.taobao.browser.BrowserActivity`（H5 容器，catch-all filter）接管 → PC 网页。原生 `MainSearchResultActivity` 虽注册了 `s.taobao.com/search`，但外部 intent 实际到不了它。
- 对外可用的原生入口是路由组件 `MainSearchRouteActivity`：host `main.m.taobao.com`、path `/search/index.html`，参数 `q`。

存储迁移：默认模板更新后 prefs key 升为 `searchhop.sites.v2`（旧设备上的 v1 缓存含坏模板，不迁移自定义数据）。

## 九、修正版 APK 端到端验证（2026-11-14 同日）

产物：`searchhop_mobile/build/app/outputs/flutter-apk/app-release.apk`（analyze 无问题、20/20 测试通过；签名与 v1.0.0 相同，可覆盖安装）。

- APK 内容核对（libapp.so AOT 快照）：含 `searchhop.sites.v2`、`main.m.taobao.com/search/index.html`、`widgetSearchMain` 三处关键字符串。
- 小组件弹窗：`am start -n com.searchhop.searchhop/.WidgetSearchActivity` 真机截图确认——半透明遮罩 + 白色卡片、站点下拉（默认 Bilibili）、输入框自动聚焦弹键盘、搜索按钮；截图 `build/device-dumps/shot-widget-dialog.png`。
- 小组件注册：`dumpsys appwidget` 列出 `com.searchhop.searchhop/.SearchHopWidgetProvider`（provider id 1043），桌面添加列表可见。
- 主界面：覆盖安装后截图确认 9 个站点卡片正常渲染（v2 默认模板生效）；截图 `shot-main-v2.png`。
- 包可见性：manifest `<queries>` 声明 8 个 scheme 的 VIEW intent，与目标 App intent-filter 匹配（shell 解析已证实），满足 Android 11+ 可见性规则；launcher 直接 `launchUrl` 不再受 `canLaunchUrl` 误报影响。
- 限制：HyperOS 未开「USB 调试（安全设置）」时 shell 无 INJECT_EVENTS，`input tap/text` 被 SecurityException 拒绝，故 App 内点击级 e2e 未代跑；路由级验证（am start + 截图）已覆盖三个站点的原生落地页。开启该开关后可用 input 注入补做点击级复测。
- 收尾：`stay_on_while_plugged_in` 已恢复 0。

## 十、点击级 e2e（2026-11-14，用户开启「USB 调试（安全设置）」后）

`input tap/text` + `uiautomator dump` 取坐标，7 条路径全部通过（落地 Activity + 截图双确认，关键词均带入原生结果页）：

| 入口 | Bilibili | 淘宝 | 小红书 |
|---|---|---|---|
| 小组件弹窗 | ✅ | ✅（下拉切换） | ✅（下拉切换） |
| 主界面 | ✅ | ✅（chip 切换） | ✅（chip 切换） |
| 桌面已放置小组件 | — | — | ✅（点击→弹窗→搜索） |

- 站点选择持久化 ✅：重开弹窗记住上次选择（其后的变化为用户手动切换）。
- 小组件经 launcher「添加小部件」流程放置到桌面第 9 屏（保留未删），点击 PendingIntent 正常唤起弹窗。截图 `e2e-*.png`、`picker-2.png`。
- 任务栈观察（非 bug，不改代码）：url_launcher 的 `launchUrl` 不加 `FLAG_ACTIVITY_NEW_TASK`，目标 App 叠在调用方任务上（返回键回搜跳，属正常回栈体验）。副作用：force-stop 搜跳后目标页仍留在该任务占位，自动化重启主界面需 `am start -f 0x10008000`（NEW_TASK|CLEAR_TASK）。
- 自动化要点：Git Bash 下 adb 的设备路径参数需 `MSYS_NO_PATHCONV=1`（否则 `/sdcard/...` 被转成本机路径）；MIUI 小部件选择器窗口 uiautomator 取不到节点，只能截图坐标操作；键盘弹起会压缩弹窗布局，点击前必须重新 dump 取坐标。
- 收尾：`svc power stayon false` 已恢复。

## 十一、v1.1.0 轮（2026-11-15）：网页兜底修复 / 多尺寸小组件 / UI 美化 / 图标 / 瘦身

**1. 网页兜底失效根因与修复（用户报「不能跳转网页」）**
- 根因：url_launcher_android 6.3.33 的 `launchUrl` 在无人处理 scheme 时**抛 `PlatformException(ACTIVITY_NOT_FOUND)`**（Java 层 catch ActivityNotFoundException 返回 false 后，Dart 层把 false 转成 throw），而不是返回 false。`launchSearch` 的 App 优先尝试未捕获该异常 → 未安装 App 的站点（如微博）直接中断，网页兜底永远执行不到；主界面与小组件弹窗均受影响（logcat：`ActivityStarterImpl … result code=-91` + Dart unhandled exception）。
- 修复：`lib/src/launcher.dart` 对 App 尝试与网页尝试分别 `on PlatformException` 捕获——App 失败落网页，网页也失败才抛 `LaunchFailure`。
- 回归：`test/launcher_test.dart` 用 fake `UrlLauncherPlatform` 模拟 throw 行为，4 条用例（兜底 / App 优先 / 纯网页 / 双失败）。全套 25/25 通过。
- 真机复测：微博（未安装）小组件弹窗与主界面两条路径均打开浏览器 s.weibo.com 结果页，弹窗自动关闭。截图 `fix-widget.png`、`fix-main.png`。

**2. 编辑器取消按钮**：`Navigator.pop(context, false)` 与 `showDialog<Site>` 类型不符导致 pop 中断（弹窗不关、误退上层）；改为 `Navigator.pop(context)`，回归用例并入 `manage_screen_test.dart`，真机确认。

**3. 多尺寸小组件**：三个 provider（2x1 / 4x1 / 4x2）各自 layout + appwidget-provider XML，receiver `android:label` 区分选择器条目。坑：RemoteViews **不支持 `android.widget.Space`**（inflate 失败→「载入窗口小部件时出现问题」），改用 `layout_marginTop`。真机：三种尺寸同屏渲染正常（`fix-home2.png`），大/小尺寸点击均唤起弹窗（`fix-large-tap.png`）。

**4. UI 美化**：主界面胶囊 chips + 输入框内放大镜 + 图标搜索按钮；管理页卡片化；弹窗圆角 20 + 投影；小组件改白色胶囊假输入框 + 绿色圆形搜索钮，4x2 带标题与说明行。

**5. 图标**：ImageGen 出稿带「AI生成」水印且 glyph 超自适应安全区 → Pillow 提取白色 glyph（阈值去水印）、缩放至 55% 画布、合成边缘纯色 `#167653` 径向渐变底（`assets/icon/searchhop.png`）；`flutter_launcher_icons` 生成各密度 mipmap + adaptive icon（background `#FF167653`，foreground 同图 inset 16%）。真机桌面图标确认。

**6. 瘦身**：fat APK 50,074,102 B → arm64  split APK 16,888,051 B（−66%）。手段：`--split-per-abi`（arm64-v8a / armeabi-v7a / x86_64 三包）、`--obfuscate --split-debug-info=build/symbols`、release `isShrinkResources = true`、删除未使用的 `cupertino_icons` 依赖与 `AppColors.greenDeepHover`、pubspec 模板注释清理。注意：`flutter build apk` **没有 `--strip` 选项**（AOT 的 DWARF 警告仅为提示）。交付包：`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`（versionCode 因 ABI split 自动 +2000）。

**7. 全渠道网页兜底真机验证（2026-11-15 同日，用户要求确认「没装 App 也能跳网页」）**
方法：`pm disable-user --user 0 <包名>` 临时禁用目标 App（模拟未安装，不卸载不动数据）→ 主界面选站点搜索 → logcat/前台 Activity 确认浏览器落地 URL → 立即 `pm enable` 恢复；结束核对 `pm list packages -d` 无残留（仅 MIUI 出厂禁用的系统组件）。

| 渠道 | 禁用包 | 浏览器实测落地 URL（关键词 hello） |
|---|---|---|
| Bilibili | tv.danmaku.bili | m.bilibili.com/search?keyword=hello |
| 知乎 | com.zhihu.android **+ com.zhihu.android.lite** | www.zhihu.com/signin?next=%2Fsearch%3Ftype%3Dcontent%26q%3Dhello |
| 微博 | （本机未安装） | s.weibo.com/weibo?q=hello |
| 百度 | 纯网页渠道 | www.baidu.com/s?wd=hello |
| 小红书 | com.xingin.xhs | www.xiaohongshu.com/search_result/?keyword=hello&source=web_explore_feed |
| 抖音 | com.ss.android.ugc.aweme | so.douyin.com/s?…keyword=hello |
| 淘宝 | com.taobao.taobao | s.taobao.com/search?q=hello |
| 京东 | com.jingdong.app.mall | search.jd.com/Search?keyword=hello&enc=utf8 → 京东风控验证页（returnurl 保留查询） |
| 拼多多 | com.xunmeng.pinduoduo | mobile.yangkeduo.com/search_result.html?search_key=hello → 拼多多登录页（from 保留查询） |

- 坑：知乎本机装有**极速版** `com.zhihu.android.lite`，其 intent-filter 同样接收 `zhihu://`；只禁完整版时 scheme 仍被极速版接走（App 优先属正确行为），须两包同禁才测到兜底。
- 知乎/京东/拼多多的网页版自身有登录墙/风控墙：浏览器已带查询打开对应 URL，登录后回跳搜索页；属目标站点行为，非跳转失败。
- 回归固化：`launcher_test.dart` 新增参数化用例，遍历 `defaultSites()` 断言 App 缺失时逐渠道回落到各自 url_template（26/26 通过）。