"""Configuration loading / generation / persistence for SearchHop.

Schema (config.json):
    {
      "settings": { "always_on_top": false },
      "sites": [ { "name": ..., "url_template": ..., "enabled": true }, ... ]
    }

- ``sites`` array order is the display order; ``enabled`` controls visibility.
- ``settings.always_on_top`` persists the window pin state.
- Missing config.json -> built-in defaults are used and a config.json is written.
- Corrupt config.json -> GUI still starts, defaults are used, and a readable
  error is surfaced as a modal dialog.
"""

import json
import sys
from dataclasses import dataclass
from pathlib import Path

from url_builder import QUERY_PLACEHOLDER

CONFIG_FILENAME = "config.json"
DEFAULT_CONFIG_FILENAME = "default_config.json"


@dataclass
class Site:
    name: str
    url_template: str
    enabled: bool = True


def get_config_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent


def _get_resource_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(getattr(sys, "_MEIPASS", str(get_config_dir())))
    return Path(__file__).resolve().parent


def default_settings() -> dict:
    return {"always_on_top": False}


def _parse_sites(data: object) -> list[Site]:
    if not isinstance(data, dict) or not isinstance(data.get("sites"), list):
        raise ValueError("配置缺少 sites 数组")
    sites: list[Site] = []
    for item in data["sites"]:
        if not isinstance(item, dict):
            raise ValueError("sites 数组中存在非法条目")
        name = item.get("name")
        template = item.get("url_template")
        if not isinstance(name, str) or not name.strip():
            raise ValueError("存在缺少有效 name 的站点")
        if not isinstance(template, str) or QUERY_PLACEHOLDER not in template:
            raise ValueError(f"站点「{name}」的 url_template 缺少 {QUERY_PLACEHOLDER}")
        enabled = item.get("enabled", True)
        if not isinstance(enabled, bool):
            enabled = True
        sites.append(Site(name=name, url_template=template, enabled=enabled))
    if not sites:
        raise ValueError("sites 数组为空")
    return sites


def load_default_sites() -> list[Site]:
    path = _get_resource_dir() / DEFAULT_CONFIG_FILENAME
    return _parse_sites(json.loads(path.read_text(encoding="utf-8")))


def _serialize(sites: list[Site], settings: dict) -> dict:
    return {
        "settings": {
            "always_on_top": bool(settings.get("always_on_top", False)),
        },
        "sites": [
            {"name": s.name, "url_template": s.url_template, "enabled": s.enabled}
            for s in sites
        ],
    }


def _write_config(path: Path, sites: list[Site], settings: dict) -> None:
    path.write_text(
        json.dumps(_serialize(sites, settings), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def load_config() -> tuple[list[Site], str | None]:
    """Return (sites, error_message). error_message is None when all is well."""
    config_path = get_config_dir() / CONFIG_FILENAME

    if not config_path.exists():
        sites = load_default_sites()
        try:
            _write_config(config_path, sites, default_settings())
        except OSError as exc:
            return sites, f"无法生成 config.json：{exc}（已使用内置默认站点）"
        return sites, None

    try:
        data = json.loads(config_path.read_text(encoding="utf-8"))
        sites = _parse_sites(data)
    except (OSError, ValueError) as exc:
        return load_default_sites(), f"配置错误：{exc}（已回退到内置默认站点）"
    return sites, None


def load_settings() -> dict:
    config_path = get_config_dir() / CONFIG_FILENAME
    try:
        data = json.loads(config_path.read_text(encoding="utf-8"))
        settings = data.get("settings", {})
        if not isinstance(settings, dict):
            settings = {}
        return {"always_on_top": bool(settings.get("always_on_top", False))}
    except (OSError, ValueError):
        return default_settings()


def save_config(sites: list[Site], settings: dict) -> str | None:
    try:
        _write_config(get_config_dir() / CONFIG_FILENAME, sites, settings)
    except OSError as exc:
        return f"保存配置失败：{exc}"
    return None