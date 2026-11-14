import unittest

from url_builder import MissingQueryPlaceholderError, build_search_url


class BuildSearchUrlTests(unittest.TestCase):
    def test_normal_template(self):
        self.assertEqual(
            build_search_url("https://www.baidu.com/s?wd={query}", "hello"),
            "https://www.baidu.com/s?wd=hello",
        )

    def test_chinese_query_is_encoded(self):
        self.assertEqual(
            build_search_url(
                "https://search.bilibili.com/all?keyword={query}", "Python 入门"
            ),
            "https://search.bilibili.com/all?keyword=Python%20%E5%85%A5%E9%97%A8",
        )

    def test_douyin_path_segment_is_encoded(self):
        self.assertEqual(
            build_search_url("https://www.douyin.com/search/{query}", "猫咪 日常"),
            "https://www.douyin.com/search/%E7%8C%AB%E5%92%AA%20%E6%97%A5%E5%B8%B8",
        )

    def test_missing_placeholder_raises(self):
        with self.assertRaises(MissingQueryPlaceholderError):
            build_search_url("https://example.com/search?q=fixed", "anything")

    def test_missing_placeholder_is_value_error(self):
        with self.assertRaises(ValueError):
            build_search_url("https://example.com/", "anything")

    def test_reserved_characters_are_encoded(self):
        self.assertEqual(
            build_search_url("https://s.taobao.com/search?q={query}", "a&b=c d"),
            "https://s.taobao.com/search?q=a%26b%3Dc%20d",
        )

    def test_xiaohongshu_keeps_extra_params(self):
        self.assertEqual(
            build_search_url(
                "https://www.xiaohongshu.com/search_result?keyword={query}&source=web_explore_feed",
                "秋冬穿搭",
            ),
            "https://www.xiaohongshu.com/search_result?keyword=%E7%A7%8B%E5%86%AC%E7%A9%BF%E6%90%AD&source=web_explore_feed",
        )


if __name__ == "__main__":
    unittest.main()