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