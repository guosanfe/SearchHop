"""Site manager dialog: drag-to-reorder, show/hide, add custom sites, reset defaults.

Every change applies live to the main window and is persisted to config.json.
"""

import tkinter

import customtkinter as ctk

import theme
from config import Site, load_default_sites
from naive_switch import NaiveSwitch
from url_builder import QUERY_PLACEHOLDER


class SiteManager(ctk.CTkToplevel):
    def __init__(self, app) -> None:
        super().__init__(app.root)
        self.app = app
        self.title("站点管理 · 搜跳")
        self.resizable(False, False)
        self.configure(fg_color=theme.BG)
        theme.center_window(self, 460, 560)
        theme.set_icon(self)
        self.transient(app.root)
        self.attributes("-topmost", bool(app.settings.get("always_on_top")))

        header = ctk.CTkFrame(self, fg_color="transparent")
        header.pack(fill="x", padx=16, pady=(14, 8))
        header.grid_columnconfigure(2, weight=1)
        ctk.CTkFrame(header, width=4, height=22, fg_color=theme.GREEN, corner_radius=2).grid(
            row=0, column=0, padx=(0, 8))
        ctk.CTkLabel(header, text="站点管理", font=theme.font(17, "bold"),
                     text_color=theme.TEXT).grid(row=0, column=1, sticky="w")

        ctk.CTkFrame(self, height=1, fg_color=theme.BORDER).pack(fill="x", padx=16)

        self.scroll = ctk.CTkScrollableFrame(
            self, fg_color="transparent",
            scrollbar_button_color=theme.BORDER, scrollbar_button_hover_color=theme.MUTED,
        )
        self.scroll.pack(fill="both", expand=True, padx=16, pady=(8, 8))

        add = ctk.CTkFrame(self, fg_color=theme.SURFACE, corner_radius=10,
                           border_width=1, border_color=theme.BORDER)
        add.pack(fill="x", padx=16, pady=(0, 8))
        add.grid_columnconfigure(1, weight=1)
        ctk.CTkLabel(add, text="添加自定义站点", font=theme.font(12, "bold"),
                     text_color=theme.LABEL).grid(row=0, column=0, columnspan=2,
                                                  sticky="w", padx=12, pady=(10, 6))
        ctk.CTkLabel(add, text="名称", font=theme.font(12), text_color=theme.LABEL).grid(
            row=1, column=0, sticky="w", padx=(12, 8), pady=(0, 6))
        self.name_entry = ctk.CTkEntry(add, font=theme.font(12), height=30, corner_radius=6,
                                       fg_color=theme.BG, border_color=theme.BORDER,
                                       text_color=theme.TEXT, placeholder_text="如：豆瓣")
        self.name_entry.grid(row=1, column=1, sticky="ew", padx=(0, 12), pady=(0, 6))
        ctk.CTkLabel(add, text="模板", font=theme.font(12), text_color=theme.LABEL).grid(
            row=2, column=0, sticky="w", padx=(12, 8), pady=(0, 6))
        self.tpl_entry = ctk.CTkEntry(add, font=theme.font(12), height=30, corner_radius=6,
                                      fg_color=theme.BG, border_color=theme.BORDER,
                                      text_color=theme.TEXT,
                                      placeholder_text="https://…?q={query}")
        self.tpl_entry.grid(row=2, column=1, sticky="ew", padx=(0, 12), pady=(0, 6))
        self.add_button = ctk.CTkButton(add, text="添加", font=theme.font(12, "bold"),
                                        height=30, corner_radius=6, fg_color=theme.GREEN_DEEP,
                                        hover_color=theme.GREEN_DEEP_HOVER, command=self.add_site)
        self.add_button.grid(row=3, column=0, columnspan=2, sticky="ew", padx=12, pady=(0, 10))
        self.msg = ctk.CTkLabel(add, text="", font=theme.font(11), text_color=theme.MUTED,
                                anchor="w")
        self.msg.grid(row=4, column=0, columnspan=2, sticky="ew", padx=12, pady=(0, 10))

        footer = ctk.CTkFrame(self, fg_color="transparent")
        footer.pack(fill="x", padx=16, pady=(0, 14))
        footer.grid_columnconfigure(0, weight=1)
        ctk.CTkButton(footer, text="恢复默认", font=theme.font(12), height=34, corner_radius=6,
                      fg_color="transparent", border_width=1, border_color=theme.BORDER,
                      text_color=theme.LABEL, hover_color=theme.GREEN_SOFT,
                      command=self.reset_defaults).grid(row=0, column=0, sticky="w")
        ctk.CTkButton(footer, text="完成", font=theme.font(12, "bold"), height=34,
                      corner_radius=6, fg_color=theme.GREEN_DEEP,
                      hover_color=theme.GREEN_DEEP_HOVER, command=self.close).grid(
            row=0, column=1, sticky="e")

        self._rows = []
        self._row_widgets = []
        self._drag_from = None
        self._drag_to = 0
        self._animating = False
        self._drag_after = None
        self._drag_cur = []
        self._drag_targets = []
        self._drag_top = 0
        self._drag_slot = 0
        self._grab_dy = 0
        self._press_index = None
        self._press_xy = (0, 0)
        self._drag_moved = False
        self.rebuild()
        self.protocol("WM_DELETE_WINDOW", self.close)
        self.after(60, lambda: theme.apply_titlebar(self))

    def rebuild(self) -> None:
        if self._drag_after is not None:
            self.after_cancel(self._drag_after)
            self._drag_after = None
        self._animating = False
        self._drag_from = None
        self._press_index = None
        self._drag_moved = False
        for child in self.scroll.winfo_children():
            child.destroy()
        self._rows = []
        self._row_widgets = []
        sites = self.app.sites
        for index, site in enumerate(sites):
            row = ctk.CTkFrame(self.scroll, fg_color=theme.SURFACE, corner_radius=8,
                               border_width=1, border_color=theme.BORDER)
            row.pack(fill="x", pady=3, padx=2)
            row.grid_columnconfigure(2, weight=1)

            grip = ctk.CTkLabel(row, text="⋮⋮", font=theme.font(13),
                                text_color=theme.LABEL, width=22)
            grip.grid(row=0, column=0, padx=(8, 0), pady=8)

            switch = NaiveSwitch(row, value=site.enabled,
                                 command=lambda s=site: self.toggle(s),
                                 press_command=lambda e, i=index: self._drag_press(e, i))
            switch.grid(row=0, column=1, padx=(8, 8), pady=8)
            switch.bind("<B1-Motion>", self._drag_motion, add="+")
            switch.bind("<ButtonRelease-1>", self._drag_release, add="+")

            name = ctk.CTkLabel(row, text=site.name, font=theme.font(13, "bold"),
                                text_color=theme.TEXT if site.enabled else theme.MUTED,
                                anchor="w")
            name.grid(row=0, column=2, sticky="w", padx=(0, 10))

            self._rows.append(row)
            self._row_widgets.append((row, switch, name, site))
            for widget in (grip, name, row):
                # CTkLabel's inner canvas keeps its requested (text) size, so the
                # outer frame needs cursor and bindings too to cover the whole row.
                tkinter.Frame.configure(widget, cursor="fleur")
                widget._canvas.configure(cursor="fleur")
                for seq, handler in (
                    ("<Button-1>", lambda e, i=index: self._drag_press(e, i)),
                    ("<B1-Motion>", self._drag_motion),
                    ("<ButtonRelease-1>", self._drag_release),
                ):
                    widget.bind(seq, handler)
                    tkinter.Frame.bind(widget, seq, handler)
        self.scroll.update_idletasks()
        self.scroll._parent_canvas.itemconfigure(
            self.scroll._create_window_id, height=self.scroll.winfo_reqheight())

    def _drag_press(self, event, index: int) -> None:
        if self._animating:
            return
        self._press_index = index
        self._press_xy = (event.x_root, event.y_root)
        self._drag_moved = False

    def _drag_motion(self, event) -> None:
        if self._press_index is None:
            return
        if not self._drag_moved:
            px, py = self._press_xy
            if abs(event.x_root - px) + abs(event.y_root - py) < 5:
                return
            self._drag_moved = True
            self._begin_drag_layout(event, self._press_index)
        n = len(self._rows)
        top, slot = self._drag_top, self._drag_slot
        py = event.y_root - self.scroll.winfo_rooty()
        drag_y = min(max(py - self._grab_dy, top), top + (n - 1) * slot)
        dst = min(max(round((drag_y - top) / slot), 0), n - 1)
        self._drag_to = dst
        self._drag_targets[self._drag_from] = drag_y
        j = 0
        for i in range(n):
            if i == self._drag_from:
                continue
            k = j if j < dst else j + 1
            self._drag_targets[i] = top + k * slot
            j += 1

    def _begin_drag_layout(self, event, index: int) -> None:
        rows = self._rows
        n = len(rows)
        geo = [(r.winfo_x(), r.winfo_y(), r.winfo_width(), r.winfo_height()) for r in rows]
        self._drag_top = geo[0][1]
        self._drag_slot = geo[0][3] + 6
        self._drag_cur = [g[1] for g in geo]
        self._drag_targets = list(self._drag_cur)
        self._grab_dy = event.y_root - rows[index].winfo_rooty()
        parent_w = max(self.scroll.winfo_width(), 1)
        for r, (x, y, w, _h) in zip(rows, geo):
            r.pack_forget()
            r.place(x=x, y=y, relwidth=w / parent_w)
        self.scroll._parent_canvas.itemconfigure(
            self.scroll._create_window_id, height=self._drag_top + n * self._drag_slot)
        rows[index].lift()
        rows[index].configure(border_color=theme.GREEN_DEEP)
        for _row, sw, _name, _site in self._row_widgets:
            sw._click_enabled = False
        self._drag_from = index
        self._drag_to = index
        self._animating = True
        self._drag_after = self.after(16, self._drag_tick)

    def _drag_release(self, _event) -> None:
        if self._press_index is None:
            return
        self._press_index = None
        if not self._drag_moved:
            return
        self._drag_moved = False
        src, dst = self._drag_from, self._drag_to
        self._drag_from = None
        if src != dst:
            sites = self.app.sites
            sites.insert(dst, sites.pop(src))
            self.app.on_sites_changed()
        n = len(self._rows)
        order = list(range(n))
        order.pop(src)
        order.insert(dst, src)
        new_index = {old: k for k, old in enumerate(order)}
        top, slot = self._drag_top, self._drag_slot
        self._drag_targets = [top + new_index[i] * slot for i in range(n)]

    def _drag_tick(self) -> None:
        self._drag_after = None
        if not self.winfo_exists():
            return
        settled = True
        for i, row in enumerate(self._rows):
            cur, target = self._drag_cur[i], self._drag_targets[i]
            if abs(target - cur) < 0.5:
                self._drag_cur[i] = target
            else:
                self._drag_cur[i] = cur + (target - cur) * 0.35
                settled = False
            row.place_configure(y=self._drag_cur[i])
        if self._drag_from is None and settled:
            self.rebuild()
            return
        self._drag_after = self.after(16, self._drag_tick)

    def _notify(self, text: str, kind: str = "ok") -> None:
        color = {"ok": theme.GREEN_DEEP, "error": theme.ERROR}.get(kind, theme.MUTED)
        self.msg.configure(text=text, text_color=color)

    def toggle(self, site: Site) -> None:
        site.enabled = not site.enabled
        for _row, _switch, name, s in self._row_widgets:
            if s is site:
                name.configure(text_color=theme.TEXT if site.enabled else theme.MUTED)
        self.app.on_sites_changed()
        self._notify(f"「{site.name}」已{'显示' if site.enabled else '隐藏'}")

    def add_site(self) -> None:
        name = self.name_entry.get().strip()
        template = self.tpl_entry.get().strip()
        if not name:
            self._notify("请输入站点名称", "error")
            return
        if QUERY_PLACEHOLDER not in template:
            self._notify(f"模板需包含 {QUERY_PLACEHOLDER} 占位符", "error")
            return
        if any(s.name == name for s in self.app.sites):
            self._notify("站点名已存在", "error")
            return
        self.app.sites.append(Site(name=name, url_template=template, enabled=True))
        self.app.on_sites_changed()
        self.name_entry.delete(0, "end")
        self.tpl_entry.delete(0, "end")
        self.rebuild()
        self._notify(f"已添加「{name}」")

    def reset_defaults(self) -> None:
        self.app.sites = load_default_sites()
        self.app.on_sites_changed()
        self.rebuild()
        self._notify("已恢复默认站点与顺序")

    def close(self) -> None:
        self.app.manager = None
        theme.activate_window(self.app.root)
        self.app.root.focus_set()
        self.destroy()