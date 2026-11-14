"""A Naive-UI-style toggle switch: pill rail, white round knob with a soft shadow,
eased knob-slide + rail-color transition on toggle.

Shapes are rasterized per pixel from signed-distance fields (1px analytic
coverage), so edges stay smooth at any size — Tk's oval/font-glyph primitives
alias badly at switch scale.
"""

import math
import tkinter

import customtkinter as ctk

import theme


def _rgb(hex_color: str):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


_BG = _rgb(theme.SURFACE)
_SHADOW = _rgb("#B9BFC7")
_KNOB = (255, 255, 255)


class NaiveSwitch(ctk.CTkCanvas):
    def __init__(self, master, value=False, command=None, press_command=None,
                 width=40, height=22, **kwargs):
        super().__init__(master, width=width, height=height,
                         highlightthickness=0, bg=theme.SURFACE, **kwargs)
        self._sw = width
        self._sh = height
        self._r = (height - 4) // 2
        self._off_x = 2 + self._r
        self._on_x = width - 2 - self._r
        self._cy = height / 2
        self._value = bool(value)
        self._command = command
        self._press_command = press_command
        self._pressed = False
        self._click_enabled = True
        self._x = self._on_x if self._value else self._off_x
        self._rail = _rgb(theme.GREEN_DEEP if self._value else theme.BORDER)
        self._after = None
        self._img = tkinter.PhotoImage(width=width, height=height)
        self.create_image(0, 0, image=self._img, anchor="nw")
        self._rail_alpha = self._capsule_alpha()
        self.configure(cursor="hand2")
        self.bind("<Button-1>", self._on_press)
        self.bind("<ButtonRelease-1>", self._on_release)
        self._draw()

    def _on_press(self, event) -> None:
        self._pressed = True
        if self._press_command:
            self._press_command(event)

    def _on_release(self, _event) -> None:
        if self._pressed and self._click_enabled:
            self.toggle()
        self._pressed = False

    def _capsule_alpha(self):
        w, h = self._sw, self._sh
        end_r = h / 2
        half = w / 2 - end_r
        cy = h / 2
        alpha = []
        for py in range(h):
            dy = py + 0.5 - cy
            row = []
            for px in range(w):
                dx = max(abs(px + 0.5 - w / 2) - half, 0.0)
                row.append(min(max(end_r + 0.5 - math.hypot(dx, dy), 0.0), 1.0))
            alpha.append(row)
        return alpha

    def _draw(self) -> None:
        w, h, r, x, cy = self._sw, self._sh, self._r, self._x, self._cy
        rail = self._rail
        rows = []
        for py in range(h):
            dy = py + 0.5 - cy
            dy_sh = dy - 1.0
            rail_row = self._rail_alpha[py]
            line = []
            for px in range(w):
                dx = px + 0.5 - x
                a_k = min(max(r + 0.5 - math.hypot(dx, dy), 0.0), 1.0)
                a_sh = min(max(r + 0.5 - math.hypot(dx, dy_sh), 0.0), 1.0)
                a_r = rail_row[px]
                c = [_BG[i] + (rail[i] - _BG[i]) * a_r for i in range(3)]
                c = [c[i] + (_SHADOW[i] - c[i]) * a_sh for i in range(3)]
                c = [c[i] + (_KNOB[i] - c[i]) * a_k for i in range(3)]
                line.append("#%02x%02x%02x" % (int(c[0] + 0.5), int(c[1] + 0.5), int(c[2] + 0.5)))
            rows.append(line)
        self._img.put(rows)

    def toggle(self) -> None:
        self._value = not self._value
        self._animate()
        if self._command:
            self._command()

    def _animate(self) -> None:
        if self._after is not None:
            self.after_cancel(self._after)
            self._after = None
        target_x = self._on_x if self._value else self._off_x
        target_rail = _rgb(theme.GREEN_DEEP if self._value else theme.BORDER)
        start_x, start_rail = self._x, self._rail
        steps = 10

        def step(i):
            if not self.winfo_exists():
                return
            t = i / steps
            ease = 1 - (1 - t) ** 3
            self._x = start_x + (target_x - start_x) * ease
            self._rail = _lerp(start_rail, target_rail, ease)
            self._draw()
            if i < steps:
                self._after = self.after(16, lambda: step(i + 1))
            else:
                self._after = None

        step(0)