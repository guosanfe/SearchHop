"""A fully-clickable site selector with a custom chevron and styled dropdown.

The whole field (label + icon) opens the menu; the menu is a rounded,
hover-highlighted popup that closes on select, Escape, or an outside click.
"""

import customtkinter as ctk

import theme


class SiteSelector(ctk.CTkFrame):
    def __init__(self, master, values=(), command=None, font=None, height=32, **kwargs):
        super().__init__(master, fg_color=theme.SURFACE, border_width=1,
                         border_color=theme.BORDER, corner_radius=6, height=height, **kwargs)
        self.grid_propagate(False)
        self._values = list(values)
        self._value = ""
        self._command = command
        self._popup = None

        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)
        self._label = ctk.CTkLabel(self, text="", font=font or theme.font(12),
                                   text_color=theme.TEXT, anchor="w", height=24)
        self._label.grid(row=0, column=0, sticky="ew", padx=(10, 4))
        self._chevron = ctk.CTkCanvas(self, width=18, height=18,
                                      highlightthickness=0, bg=theme.SURFACE)
        self._chevron.grid(row=0, column=1, padx=(0, 8))
        self._draw_chevron(False)

        # CTkFrame.bind / CTkLabel.bind dispatch to their internal background
        # canvas, so these three cover the whole field. The chevron canvas is
        # named _chevron to avoid clobbering CTkFrame's own _canvas.
        for widget in (self, self._label, self._chevron):
            widget.bind("<Button-1>", self._on_click)
            widget.bind("<Enter>", self._on_enter)
            widget.bind("<Leave>", self._on_leave)
        self.bind("<Escape>", self._on_escape)

        if self._values:
            self.set(self._values[0])

    def _draw_chevron(self, opened: bool) -> None:
        self._chevron.delete("all")
        pts = (4, 11, 9, 6, 14, 11) if opened else (4, 7, 9, 12, 14, 7)
        self._chevron.create_line(*pts, fill=theme.GREEN_DEEP, width=2,
                                  capstyle="round", joinstyle="round")

    def configure(self, **kwargs):
        values = kwargs.pop("values", None)
        if values is not None:
            self._values = list(values)
            if self._value not in self._values:
                self.set(self._values[0] if self._values else "")
        if kwargs:
            super().configure(**kwargs)

    def get(self) -> str:
        return self._value

    def set(self, name: str) -> None:
        self._value = name if name in self._values else ""
        self._label.configure(text=self._value or "选择站点",
                              text_color=theme.TEXT if self._value else theme.MUTED)

    def _on_click(self, _event):
        self._toggle()
        return "break"

    def _on_enter(self, _event):
        self.configure(border_color=theme.GREEN_DEEP)

    def _on_leave(self, event):
        x, y = event.x_root, event.y_root
        fx, fy = self.winfo_rootx(), self.winfo_rooty()
        fw, fh = self.winfo_width(), self.winfo_height()
        if not (fx <= x < fx + fw and fy <= y < fy + fh):
            self.configure(border_color=theme.BORDER)

    def _toggle(self) -> None:
        if self._popup is not None:
            self._close()
        else:
            self._open()

    def _open(self) -> None:
        self._draw_chevron(True)
        top = self.winfo_toplevel()
        pop = ctk.CTkToplevel(top)
        pop.overrideredirect(True)
        pop.configure(fg_color=theme.SURFACE)
        pop.bind("<Escape>", self._on_escape)
        try:
            pop.attributes("-topmost", bool(top.attributes("-topmost")))
        except Exception:
            pass

        width = self.winfo_width()
        x = self.winfo_rootx()
        y = self.winfo_rooty() + self.winfo_height() + 4
        row_h = 32
        height = min(max(len(self._values) * row_h + 12, 44), 264)
        if y + height > self.winfo_screenheight():
            y = self.winfo_rooty() - height - 4
        pop.geometry(f"{width}x{height}+{x}+{y}")

        inner = ctk.CTkFrame(pop, fg_color=theme.SURFACE, corner_radius=10,
                             border_width=1, border_color=theme.BORDER)
        inner.pack(fill="both", expand=True)
        scroll = ctk.CTkScrollableFrame(
            inner, fg_color="transparent",
            scrollbar_button_color=theme.BORDER, scrollbar_button_hover_color=theme.MUTED)
        scroll.pack(fill="both", expand=True, padx=6, pady=6)
        for name in self._values:
            selected = name == self._value
            ctk.CTkButton(
                scroll, text=name, anchor="w", font=theme.font(12), height=row_h - 2,
                corner_radius=6, fg_color=theme.GREEN_SOFT if selected else "transparent",
                text_color=theme.GREEN_DEEP if selected else theme.TEXT,
                hover_color=theme.GREEN_SOFT, command=lambda n=name: self._select(n),
            ).pack(fill="x", pady=1)
        self._popup = pop

    def _select(self, name: str) -> None:
        self.set(name)
        if self._command:
            self._command(name)
        self._close()

    def _close(self) -> None:
        if self._popup is not None:
            self._popup.destroy()
            self._popup = None
        self._draw_chevron(False)

    def _on_escape(self, _event) -> None:
        if self._popup is not None:
            self._close()