"""搜跳 SearchHop — GUI entry point (CustomTkinter, green design).

A search直达器: pick a site, type a keyword, and the system default browser
opens that site's search-results page directly. No network requests, no
embedded browser, no login handling — this app only builds a URL and hands it
to webbrowser.open.

Controls: an always-on-top pin (persisted) and a site manager for drag-reordering /
showing / hiding / adding sites (persisted). The idle window stays compact with no
persistent status text; genuine failures surface as modal dialogs.
"""

import webbrowser
from tkinter import messagebox

import customtkinter as ctk

import theme
from config import load_config, load_settings, save_config
from site_manager import SiteManager
from site_selector import SiteSelector
from url_builder import MissingQueryPlaceholderError, build_search_url

WINDOW_WIDTH = 400
WINDOW_HEIGHT = 190
SITE_WIDTH = 112


class SearchHopApp:
    def __init__(self, root: ctk.CTk) -> None:
        self.root = root
        self.manager = None
        self._last_geo = None
        root.title("搜跳 SearchHop")
        root.resizable(False, False)
        root.configure(fg_color=theme.BG)
        theme.center_window(root, WINDOW_WIDTH, WINDOW_HEIGHT)
        theme.set_icon(root)

        self.sites, config_error = load_config()
        self.settings = load_settings()

        root.grid_columnconfigure(0, weight=0, minsize=SITE_WIDTH)
        root.grid_columnconfigure(1, weight=1)

        header = ctk.CTkFrame(root, fg_color="transparent")
        header.grid(row=0, column=0, columnspan=2, sticky="ew", padx=14, pady=(12, 6))
        header.grid_columnconfigure(3, weight=1)
        ctk.CTkFrame(header, width=4, height=20, fg_color=theme.GREEN, corner_radius=2).grid(
            row=0, column=0, sticky="w", padx=(0, 7))
        ctk.CTkLabel(header, text="搜跳", font=theme.font(18, "bold"),
                     text_color=theme.TEXT).grid(row=0, column=1, sticky="w")
        ctk.CTkLabel(header, text="SearchHop", font=theme.font(10), fg_color=theme.GREEN_SOFT,
                     text_color=theme.GREEN_DEEP, corner_radius=6, height=20).grid(
            row=0, column=2, sticky="w", padx=(7, 0))
        self.pin_button = ctk.CTkButton(header, text="置顶", width=50, height=26,
                                        corner_radius=6, font=theme.font(10),
                                        command=self.toggle_topmost)
        self.pin_button.grid(row=0, column=4, sticky="e", padx=(0, 5))
        ctk.CTkButton(header, text="管理", width=50, height=26, corner_radius=6,
                      font=theme.font(10), fg_color="transparent", border_width=1,
                      border_color=theme.BORDER, text_color=theme.LABEL,
                      hover_color=theme.GREEN_SOFT, command=self.open_manager).grid(
            row=0, column=5, sticky="e")

        ctk.CTkFrame(root, height=1, fg_color=theme.BORDER).grid(
            row=1, column=0, columnspan=2, sticky="ew", padx=14, pady=(0, 8))

        ctk.CTkLabel(root, text="站点", font=theme.font(11), text_color=theme.LABEL).grid(
            row=2, column=0, sticky="w", padx=(14, 8), pady=(0, 4))
        ctk.CTkLabel(root, text="关键词", font=theme.font(11), text_color=theme.LABEL).grid(
            row=2, column=1, sticky="w", padx=(8, 14), pady=(0, 4))

        self.site_selector = SiteSelector(root, font=theme.font(12), height=32, width=SITE_WIDTH)
        self.site_selector.grid(row=3, column=0, sticky="ew", padx=(14, 8), pady=(0, 10))

        self.query_entry = ctk.CTkEntry(
            root, font=theme.font(12), height=32, corner_radius=6, fg_color=theme.SURFACE,
            border_color=theme.BORDER, border_width=1, text_color=theme.TEXT,
            placeholder_text="输入关键词，回车直达", placeholder_text_color=theme.MUTED,
        )
        self.query_entry.grid(row=3, column=1, sticky="ew", padx=(8, 14), pady=(0, 10))
        self.query_entry.bind("<FocusIn>", self._on_entry_focus_in)
        self.query_entry.bind("<FocusOut>", lambda _e: self.query_entry.configure(
            border_color=theme.BORDER, border_width=1))
        self.query_entry.bind("<KeyRelease>", lambda _e: self._update_clear_button())

        self.clear_button = ctk.CTkButton(
            self.query_entry, text="×", width=20, height=20, corner_radius=10,
            font=theme.font(13, "bold"), fg_color=theme.SURFACE, hover_color=theme.GREEN_SOFT,
            text_color=theme.MUTED, command=self._clear_query,
        )
        self._update_clear_button()

        self._search_pressed = False
        self.search_button = ctk.CTkButton(
            root, text="搜索", font=theme.font(13, "bold"), height=36, corner_radius=6,
            fg_color=theme.GREEN_DEEP, hover_color=theme.GREEN_DEEP_HOVER,
            text_color="#FFFFFF", command=self._search_command,
        )
        self.search_button.grid(row=4, column=0, columnspan=2, sticky="ew", padx=14, pady=(0, 12))
        # CTkButton fires on <ButtonRelease-1> without tracking the press. The
        # dropdown overlaps this button, so a release that falls through the
        # popup must not run a search: require the press to have landed here too.
        self.search_button.bind("<Button-1>", lambda _e: setattr(self, "_search_pressed", True), add="+")
        self.search_button.bind("<ButtonRelease-1>", lambda _e: setattr(self, "_search_pressed", False), add="+")

        self.refresh_combo()
        # Bind Return on the entry only: a toplevel binding would also fire via
        # bindtags and open the browser twice for a single keypress.
        self.query_entry.bind("<Return>", lambda _e: self.on_search())
        self.query_entry.bind("<Escape>", lambda _e: self.site_selector._close())
        root.bind("<Button-1>", self._on_root_click)
        root.bind("<Configure>", self._on_root_configure)
        root.bind("<FocusOut>", self._on_root_focus_out)
        self.query_entry.focus_set()

        root.attributes("-topmost", bool(self.settings.get("always_on_top")))
        self._update_pin_button()

        if config_error:
            messagebox.showerror("配置错误", config_error)

        root.after(60, lambda: theme.apply_titlebar(root))

    def enabled_sites(self):
        return [s for s in self.sites if s.enabled]

    def refresh_combo(self) -> None:
        self.site_selector.configure(values=[s.name for s in self.enabled_sites()])

    def persist(self) -> None:
        error = save_config(self.sites, self.settings)
        if error:
            messagebox.showerror("保存失败", error)

    def on_sites_changed(self) -> None:
        self.refresh_combo()
        self.persist()

    def _update_pin_button(self) -> None:
        if self.settings.get("always_on_top"):
            self.pin_button.configure(text="已置顶", fg_color=theme.GREEN_DEEP,
                                      hover_color=theme.GREEN_DEEP_HOVER,
                                      text_color="#FFFFFF", border_width=0)
        else:
            self.pin_button.configure(text="置顶", fg_color="transparent",
                                      hover_color=theme.GREEN_SOFT,
                                      text_color=theme.LABEL, border_width=1,
                                      border_color=theme.BORDER)

    def toggle_topmost(self) -> None:
        self.site_selector._close()
        self.settings["always_on_top"] = not bool(self.settings.get("always_on_top"))
        self.root.attributes("-topmost", self.settings["always_on_top"])
        if self.manager is not None:
            self.manager.attributes("-topmost", self.settings["always_on_top"])
        self._update_pin_button()
        self.persist()

    def open_manager(self) -> None:
        self.site_selector._close()
        if self.manager is not None:
            self.manager.lift()
            return
        self.manager = SiteManager(self)

    def _on_entry_focus_in(self, _event) -> None:
        self.query_entry.configure(border_color=theme.GREEN_DEEP, border_width=2)
        # Activation-driven focus restoration (e.g. after the manager closes)
        # must not dismiss a dropdown the user just opened with the pointer.
        widget = self.root.winfo_containing(*self.root.winfo_pointerxy())
        if widget is not None and str(widget).startswith(str(self.query_entry)):
            self.site_selector._close()

    def _on_root_click(self, event) -> None:
        # The activation click can be reported against the toplevel rather than
        # the selector; closing here would dismiss the dropdown it just opened.
        x, y = event.x_root, event.y_root
        sel = self.site_selector
        if (sel.winfo_rootx() <= x < sel.winfo_rootx() + sel.winfo_width()
                and sel.winfo_rooty() <= y < sel.winfo_rooty() + sel.winfo_height()):
            return
        popup = sel._popup
        if popup is not None and (
                popup.winfo_rootx() <= x < popup.winfo_rootx() + popup.winfo_width()
                and popup.winfo_rooty() <= y < popup.winfo_rooty() + popup.winfo_height()):
            return
        self.site_selector._close()

    def _on_root_focus_out(self, _event) -> None:
        self.root.after(50, self._close_selector_if_focus_left)

    def _close_selector_if_focus_left(self) -> None:
        # Close only when the foreground genuinely left to another window AND
        # the pointer is not over the dropdown. Clicking an item activates the
        # overrideredirect popup; during that activation neither window may
        # report foreground yet, and destroying the popup then would let the
        # release fall through to the 搜索 button beneath the first row.
        popup = self.site_selector._popup
        if popup is None:
            return
        if theme.is_foreground(self.root) or theme.is_foreground(popup):
            return
        px, py = self.root.winfo_pointerxy()
        if (popup.winfo_rootx() <= px < popup.winfo_rootx() + popup.winfo_width()
                and popup.winfo_rooty() <= py < popup.winfo_rooty() + popup.winfo_height()):
            return
        self.site_selector._close()

    def _on_root_configure(self, _event) -> None:
        geo = self.root.geometry()
        if self._last_geo is not None and geo != self._last_geo:
            self.site_selector._close()
        self._last_geo = geo

    def _update_clear_button(self) -> None:
        if self.query_entry.get():
            self.clear_button.place(relx=1.0, x=-6, rely=0.5, anchor="e")
        else:
            self.clear_button.place_forget()

    def _clear_query(self) -> None:
        self.query_entry.delete(0, "end")
        self.query_entry.focus_set()
        self._update_clear_button()

    def _selected_site(self):
        name = self.site_selector.get()
        for site in self.enabled_sites():
            if site.name == name:
                return site
        return None

    def _search_command(self) -> None:
        if self._search_pressed:
            self.on_search()

    def on_search(self) -> None:
        self.site_selector._close()
        query = self.query_entry.get().strip()
        if not query:
            messagebox.showwarning("搜跳", "请输入关键词")
            return
        site = self._selected_site()
        if site is None:
            messagebox.showwarning("搜跳", "请选择站点")
            return
        try:
            url = build_search_url(site.url_template, query)
        except MissingQueryPlaceholderError as exc:
            messagebox.showerror("搜跳", f"站点配置错误：{exc}")
            return
        try:
            opened = webbrowser.open(url)
        except Exception as exc:  # webbrowser is a system boundary
            messagebox.showerror("搜跳", f"打开浏览器失败：{exc}")
            return
        if not opened:
            messagebox.showerror("搜跳", "未能打开系统默认浏览器")


def main() -> None:
    ctk.set_appearance_mode("light")
    ctk.set_default_color_theme("blue")
    root = ctk.CTk()
    SearchHopApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()