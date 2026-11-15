"""Shared visual language for SearchHop (green design).

Central palette, typography and native-window helpers so the main window and
the site-manager dialog stay visually consistent.
"""

import sys
from pathlib import Path

import customtkinter as ctk

from config import get_config_dir

FONT_FAMILY = "Microsoft YaHei UI"

GREEN = "#00CC6A"          # title bar / accent bar
GREEN_DEEP = "#167653"     # primary button / focus ring / status
GREEN_DEEP_HOVER = "#0F5C40"
GREEN_SOFT = "#E3EFE7"     # badge / hover tint
BG = "#F4F6F1"             # window background
SURFACE = "#FFFFFF"        # fields / cards
TEXT = "#1E2822"
LABEL = "#405147"
MUTED = "#7A8C80"
BORDER = "#D8E0D6"
ERROR = "#D64545"


def font(size: int, weight: str = "normal") -> ctk.CTkFont:
    return ctk.CTkFont(family=FONT_FAMILY, size=size, weight=weight)


def icon_path() -> Path:
    if getattr(sys, "frozen", False):
        base = Path(getattr(sys, "_MEIPASS", str(get_config_dir())))
    else:
        base = Path(__file__).resolve().parent
    return base / "assets" / "icon.ico"


def apply_titlebar(root) -> None:
    """Color the native Windows 11 caption green; degrade silently elsewhere."""
    try:
        import ctypes
        from ctypes import wintypes

        hwnd = ctypes.windll.user32.GetParent(root.winfo_id()) or root.winfo_id()

        def colorref(hexstr: str) -> int:
            hexstr = hexstr.lstrip("#")
            r, g, b = (int(hexstr[i:i + 2], 16) for i in (0, 2, 4))
            return (b << 16) | (g << 8) | r

        for attr, color in ((34, GREEN), (35, GREEN), (36, "#FFFFFF")):
            val = wintypes.DWORD(colorref(color))
            ctypes.windll.dwmapi.DwmSetWindowAttribute(
                hwnd, attr, ctypes.byref(val), ctypes.sizeof(val)
            )
    except Exception:
        pass


def activate_window(root) -> None:
    """Hand Windows foreground back to root; without this the first click
    after a dialog closes can be eaten as an activation click."""
    try:
        import ctypes

        hwnd = ctypes.windll.user32.GetParent(root.winfo_id()) or root.winfo_id()
        ctypes.windll.user32.SetForegroundWindow(hwnd)
    except Exception:
        pass


def is_foreground(root) -> bool:
    """True when root's native window currently holds the Windows foreground."""
    try:
        import ctypes

        hwnd = ctypes.windll.user32.GetParent(root.winfo_id()) or root.winfo_id()
        return ctypes.windll.user32.GetForegroundWindow() == hwnd
    except Exception:
        return True


def center_window(root, width: int, height: int) -> None:
    root.update_idletasks()
    x = (root.winfo_screenwidth() - width) // 2
    y = (root.winfo_screenheight() - height) // 2
    root.geometry(f"{width}x{height}+{x}+{y}")


def set_icon(root) -> None:
    try:
        root.iconbitmap(str(icon_path()))
    except Exception:
        pass