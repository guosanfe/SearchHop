import 'site.dart';
import 'url_builder.dart';

/// Same 9 sites as the desktop default_config.json, extended with app
/// scheme templates from docs/mobile-scheme-candidates.md (unverified).
List<Site> defaultSites() => [
      Site(
        name: 'Bilibili',
        urlTemplate: 'https://search.bilibili.com/all?keyword={query}',
        appTemplate: 'bilibili://search?keyword={query}',
        androidPackage: 'tv.danmaku.bili',
      ),
      Site(
        name: '知乎',
        urlTemplate: 'https://www.zhihu.com/search?type=content&q={query}',
        appTemplate: 'zhihu://search?q={query}',
        androidPackage: 'com.zhihu.android',
      ),
      Site(
        name: '微博',
        urlTemplate: 'https://s.weibo.com/weibo?q={query}',
        appTemplate: 'sinaweibo://searchall?q={query}',
        androidPackage: 'com.sina.weibo',
      ),
      Site(
        name: '百度',
        urlTemplate: 'https://www.baidu.com/s?wd={query}',
      ),
      Site(
        name: '小红书',
        urlTemplate:
            'https://www.xiaohongshu.com/search_result?keyword={query}&source=web_explore_feed',
        appTemplate: 'xhsdiscover://search/result?keyword={query}',
        androidPackage: 'com.xingin.xhs',
      ),
      Site(
        name: '抖音',
        urlTemplate: 'https://www.douyin.com/search/{query}',
        appTemplate: 'snssdk1128://search?keyword={query}',
        androidPackage: 'com.ss.android.ugc.aweme',
      ),
      Site(
        name: '淘宝',
        urlTemplate: 'https://s.taobao.com/search?q={query}',
        appTemplate: 'taobao://main.m.taobao.com/search/index.html?q={query}',
        androidPackage: 'com.taobao.taobao',
      ),
      Site(
        name: '京东',
        urlTemplate: 'https://search.jd.com/Search?keyword={query}&enc=utf8',
        appTemplate:
            'openapp.jdmobile://virtual?params={"des":"productList","keyWord":"{query}","from":"search","category":"jump"}',
        androidPackage: 'com.jingdong.app.mall',
        appEncodeMode: EncodeMode.wholeParams,
      ),
      Site(
        name: '拼多多',
        urlTemplate:
            'https://mobile.yangkeduo.com/search_result.html?search_key={query}',
        appTemplate:
            'pinduoduo://yangkeduo.com/search_result.html?search_key={query}',
        androidPackage: 'com.xunmeng.pinduoduo',
      ),
    ];