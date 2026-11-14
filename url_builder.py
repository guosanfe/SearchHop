"""Pure URL construction: template + keyword -> search URL.

Kept free of any GUI / IO so it can be unit-tested in isolation.
"""

from urllib.parse import quote

QUERY_PLACEHOLDER = "{query}"


class MissingQueryPlaceholderError(ValueError):
    """Raised when a site's url_template does not contain {query}."""


def build_search_url(template: str, query: str) -> str:
    """Return the search URL for ``query`` using ``template``.

    The keyword is percent-encoded with urllib.parse.quote so that Chinese
    characters, spaces and reserved characters are safe both in query
    parameters and in path segments (e.g. Douyin). ``str.replace`` is used
    instead of ``str.format`` so unrelated braces in a template are left
    untouched.
    """
    if QUERY_PLACEHOLDER not in template:
        raise MissingQueryPlaceholderError(
            f"URL 模板缺少 {QUERY_PLACEHOLDER} 占位符：{template}"
        )
    return template.replace(QUERY_PLACEHOLDER, quote(query))