#!/usr/bin/env python3
"""Generate the 6DOF arm wiring bench sheet (A4, 3 pages) and the pinout
SVG diagrams used by the docs site.

This is a living artifact: whenever wiring details change, edit this
script and hardware/wiring.md together, then regenerate with

    uv run --with reportlab python hardware/make_bench_sheet.py

Outputs:
    hardware/wiring-bench-sheet.pdf        (printable bench reference)
    docs/img/pca9685-header-diagram.svg    (docs site)
    docs/img/esp32-pinout-diagram.svg      (docs site)
"""

from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image,
    PageBreak, KeepTogether,
)

REPO = Path(__file__).resolve().parents[1]
IMG = str(REPO / "docs" / "img")
OUT = str(REPO / "hardware" / "wiring-bench-sheet.pdf")

styles = getSampleStyleSheet()
H1 = ParagraphStyle("H1", parent=styles["Title"], fontSize=20, spaceAfter=2)
H2 = ParagraphStyle("H2", parent=styles["Heading2"], fontSize=13,
                    spaceBefore=10, spaceAfter=4,
                    textColor=colors.HexColor("#1a3a5c"))
BODY = ParagraphStyle("BODY", parent=styles["Normal"], fontSize=9.5, leading=12)
SMALL = ParagraphStyle("SMALL", parent=BODY, fontSize=8.5, leading=10.5,
                       textColor=colors.HexColor("#444444"))
WARN = ParagraphStyle("WARN", parent=BODY, fontSize=10.5, leading=13.5,
                      textColor=colors.HexColor("#8a1111"))
MONO = ParagraphStyle("MONO", parent=BODY, fontName="Courier", fontSize=7.4,
                      leading=8.8)
CHECK = ParagraphStyle("CHECK", parent=BODY, fontSize=10.5, leading=16)

TBL = TableStyle([
    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a3a5c")),
    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
    ("FONTSIZE", (0, 0), (-1, -1), 9),
    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#999999")),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("ROWBACKGROUNDS", (0, 1), (-1, -1),
     [colors.white, colors.HexColor("#eef2f6")]),
    ("TOPPADDING", (0, 0), (-1, -1), 3),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
])


def P(text, style=BODY):
    return Paragraph(text, style)


def table(rows, widths):
    t = Table([[P(c, SMALL) if isinstance(c, str) else c for c in r]
               for r in rows], colWidths=widths)
    t.setStyle(TBL)
    # header row: white bold text
    hdr = ParagraphStyle("hdr", parent=SMALL, textColor=colors.white,
                         fontName="Helvetica-Bold")
    t._cellvalues[0] = [Paragraph(str(c.text if hasattr(c, 'text') else c), hdr)
                        for c in rows[0]]
    return t


story = []

# ----- Page 1: safety + power -----
story.append(P("6DOF Arm — Wiring Bench Sheet", H1))
story.append(P("ESP32 + PCA9685 + 6× MG996R · print & keep at the bench · "
               "full guide: hardware/wiring.md", SMALL))
story.append(Spacer(1, 6))

story.append(P("SAFETY RULES — read before plugging anything in", H2))
rules = [
    "<b>1. NEVER put 12&nbsp;V on the PCA9685 V+ terminal or any servo.</b> "
    "MG996Rs are rated 4.8–7.2&nbsp;V. The 12&nbsp;V supply feeds ONLY the converter input.",
    "<b>2. USB power = single-servo bench tests only.</b> Full-arm motion requires the 6&nbsp;V/10&nbsp;A rail.",
    "<b>3. Verify converter output ≈ 6.0&nbsp;V with a meter BEFORE first connection.</b> "
    "Re-check polarity at V+ — reverse polarity kills the PCA9685 instantly.",
    "<b>4. Converter → PCA9685 wires short and thick</b> (14–16&nbsp;AWG). Stalls can pull 15&nbsp;A+.",
    "<b>5. Power-up order:</b> ESP32 USB first (servos stay idle), then the 12&nbsp;V supply. Reverse to power down.",
    "<b>6. Pinch points:</b> on link loss the arm HOLDS (won't drop, won't yield). Kill 12&nbsp;V before handling.",
]
for r in rules:
    story.append(P(r, WARN))
    story.append(Spacer(1, 2))

story.append(P("Servo power path", H2))
story.append(P("12&nbsp;V/10&nbsp;A supply &rarr; buck converter (12–40&nbsp;V in, 6&nbsp;V/10&nbsp;A out) &rarr; PCA9685 V+ terminal", BODY))
story.append(Spacer(1, 4))

story.append(P("Converter wire colors — straight from the unit's label", H2))
story.append(table(
    [["Wire", "Role", "Connects to"],
     ["<b>Red</b>", "Input +", "12 V supply positive"],
     ["<b>Black</b> (paired w/ red)", "Input −", "12 V supply negative"],
     ["<b>Yellow</b>", "Output + (6 V)", "PCA9685 <b>V+</b> screw terminal"],
     ["<b>Black</b> (paired w/ yellow)", "Output −", "PCA9685 <b>GND</b> screw terminal"]],
    [42 * mm, 30 * mm, 90 * mm]))
story.append(Spacer(1, 3))
story.append(P("The two blacks are per-bundle negatives — use each with its own "
               "side. Red side drinks 12&nbsp;V; yellow side feeds the servos. The "
               "PCA9685's onboard 1000&nbsp;µF cap covers the rail; no extra cap needed.", BODY))
story.append(Spacer(1, 6))

imgs = Table([[Image(f"{IMG}/buck-converter-label.jpg", width=78 * mm, height=58 * mm),
               Image(f"{IMG}/dc-barrel-jack-adapter.jpg", width=78 * mm, height=58 * mm)]],
             colWidths=[82 * mm, 82 * mm])
story.append(imgs)
story.append(P("Left: the converter's own label (IN red/black, OUT yellow/black). "
               "Right: barrel-jack &rarr; screw-terminal adapter for the 12 V input — mind the +/− marks.", SMALL))

story.append(PageBreak())

# ----- Page 2: I2C, channels, checklist -----
story.append(P("Logic side: ESP32 ↔ PCA9685 (I2C)", H2))
story.append(P("PCA9685 header order, starting from the end AWAY from the silver "
               "capacitor: <b>GND, OE, SCL, SDA, VCC, V+</b> (V+ is always the pin "
               "beside the cap). Ribbon colors below are this build's harness as "
               "photographed. I2C address 0x40, jumpers open; board pull-ups are to "
               "VCC — which is why VCC must be 3.3 V.", BODY))
story.append(Spacer(1, 4))
story.append(table(
    [["Ribbon color", "PCA9685 pin", "ESP32 pin", "Notes"],
     ["brown/black (end pin)", "GND", "GND", "<b>Required</b> — the common-ground link; I2C is dead/flaky without it"],
     ["red", "OE", "<b>leave unplugged</b>", "Already pulled low (enabled); future kill-switch option"],
     ["orange", "SCL", "D22 (GPIO22)", "Arduino Wire default clock"],
     ["yellow", "SDA", "D21 (GPIO21)", "Arduino Wire default data"],
     ["green", "VCC", "3V3", "<b>3.3 V only</b> — never the 5 V/VIN pin"],
     ["blue (beside cap)", "V+", "<b>REMOVE — never to ESP32</b>", "<b>6 V servo rail!</b> Same net as the terminal block; kills the ESP32"]],
    [34 * mm, 24 * mm, 40 * mm, 64 * mm]))
story.append(Spacer(1, 3))
story.append(P("<b>ESP32 pin locations</b> (30-pin devkit): USB-C toward you, antenna "
               "away — right-hand row from the USB end reads 3V3, GND, D15, D2, D4, "
               "RX2, TX2, D5, D18, D19, <b>D21</b>, RX0, TX0, <b>D22</b>, D23. "
               "Green + brown at the near corner; yellow on D21 (11th); orange on D22 (14th).", BODY))

story.append(P("Servo plugs and channels", H2))
story.append(P("Column pin order from board edge inward: <b>GND (bottom), V+ (middle), "
               "PWM (top)</b>. MG996R leads: <b>brown = GND, red = V+, orange = signal</b> "
               "— brown faces the board edge.", BODY))
story.append(Spacer(1, 4))
story.append(table(
    [["Channel", "Joint", "Position on arm"],
     ["0", "joint1", "Base rotation (yaw)"],
     ["1", "joint2", "Shoulder pitch"],
     ["2", "joint3", "Elbow pitch"],
     ["3", "joint4", "Wrist pitch"],
     ["4", "joint5", "Wrist roll"],
     ["5", "joint6", "Gripper"],
     ["6–15", "—", "Spare"]],
    [24 * mm, 26 * mm, 112 * mm]))
story.append(Spacer(1, 2))
story.append(P("Wrong channel? Move the plug, don't edit firmware — keeps this table true.", SMALL))

story.append(P("Common ground — required, not optional", H2))
story.append(P("PSU(−) &rarr; converter IN(−) &rarr; converter OUT(−) &rarr; PCA9685 GND &rarr; "
               "ESP32 GND (via the I2C ground jumper). Beep-test all four points.", BODY))

story.append(P("Bench bring-up checklist", H2))
checklist = [
    "All grounds common (continuity-beep PSU−, converter−, PCA9685 GND, ESP32 GND)",
    "Converter output ≈ 6.0 V, verified with meter, no load",
    "I2C jumpers by color: green→3V3 · yellow→D21 · orange→D22 · brown→GND",
    "Red (OE) jumper parked; blue (V+) jumper REMOVED from ribbon",
    "ESP32 on USB: serial prints “PCA9685 initialized, all channels off”",
    "One servo on channel 0 — single-servo sweep (USB/bench power OK)",
    "Remaining servos on channels 1–5 per table",
    "Full-arm motion ONLY on converter power",
]
for c in checklist:
    # plain-text checkbox: every PDF viewer and printer renders this
    story.append(P('<font face="Courier-Bold">[&nbsp;&nbsp;]</font>&nbsp;&nbsp;' + c, CHECK))

# ----- Page 3: pinout diagrams -----
from reportlab.graphics.shapes import Drawing, Rect, String, Circle, Line, Group

RIBBON = {
    "brown": colors.HexColor("#7a4a1e"),
    "red": colors.HexColor("#cc2222"),
    "orange": colors.HexColor("#e07820"),
    "yellow": colors.HexColor("#d4b400"),
    "green": colors.HexColor("#2e8b2e"),
    "blue": colors.HexColor("#2255cc"),
}

def esp32_drawing():
    """Top view of the 30-pin devkit, USB-C at bottom; our 4 pins highlighted."""
    W, H = 300, 330
    d = Drawing(W, H)
    bx, by, bw, bh = 105, 18, 90, 290
    d.add(Rect(bx, by, bw, bh, rx=6, fillColor=colors.HexColor("#222831"),
               strokeColor=colors.black))
    # antenna block (top) and USB-C (bottom)
    d.add(Rect(bx + 18, by + bh - 16, bw - 36, 14, fillColor=colors.HexColor("#3a4750"),
               strokeColor=None))
    d.add(String(bx + bw / 2, by + bh - 12, "antenna", fontSize=6.5,
                 fillColor=colors.white, textAnchor="middle"))
    d.add(Rect(bx + bw / 2 - 12, by - 8, 24, 12, rx=3,
               fillColor=colors.HexColor("#888888"), strokeColor=colors.black))
    d.add(String(bx + bw / 2, by - 17, "USB-C (toward you)", fontSize=7,
                 textAnchor="middle"))
    left = ["EN", "VP", "VN", "D34", "D35", "D32", "D33", "D25", "D26", "D27",
            "D14", "D12", "D13", "GND", "VIN"]
    right = ["D23", "D22", "TX0", "RX0", "D21", "D19", "D18", "D5", "TX2",
             "RX2", "D4", "D2", "D15", "GND", "3V3"]
    hot = {"D22": ("orange", "SCL"), "D21": ("yellow", "SDA"),
           "GND": ("brown", "GND"), "3V3": ("green", "VCC")}
    top_pin_y = by + bh - 34
    pitch = (top_pin_y - (by + 14)) / 14.0
    for i, name in enumerate(left):
        y = top_pin_y - i * pitch
        d.add(Rect(bx - 7, y - 2, 7, 4, fillColor=colors.HexColor("#c8a018"),
                   strokeColor=None))
        d.add(String(bx - 11, y - 2.5, name, fontSize=6.5, textAnchor="end",
                     fillColor=colors.HexColor("#555555")))
    for i, name in enumerate(right):
        y = top_pin_y - i * pitch
        d.add(Rect(bx + bw, y - 2, 7, 4, fillColor=colors.HexColor("#c8a018"),
                   strokeColor=None))
        # only highlight the GND nearest the USB end (i == 13), not any other
        is_hot = name in hot and (name != "GND" or i == 13)
        col = RIBBON[hot[name][0]] if is_hot else colors.HexColor("#555555")
        d.add(String(bx + bw + 11, y - 2.5, name, fontSize=8 if is_hot else 6.5,
                     textAnchor="start", fillColor=col))
        if is_hot:
            cname, role = hot[name]
            d.add(Line(bx + bw + 34, y, bx + bw + 58, y,
                       strokeColor=RIBBON[cname], strokeWidth=3))
            d.add(String(bx + bw + 62, y - 3,
                         f"{cname} ({role})", fontSize=8,
                         fillColor=RIBBON[cname]))
    return d

def pca9685_drawing():
    """The 6-pin I2C header with ribbon colors; V+ beside the capacitor."""
    W, H = 470, 120
    d = Drawing(W, H)
    bx, by, bw, bh = 30, 26, 360, 44
    d.add(Rect(bx, by, bw, bh, rx=4, fillColor=colors.HexColor("#2f5d8a"),
               strokeColor=colors.black))
    pins = [("GND", "brown", "to ESP32 GND", False),
            ("OE", "red", "PARK (unplugged)", False),
            ("SCL", "orange", "to D22", False),
            ("SDA", "yellow", "to D21", False),
            ("VCC", "green", "to 3V3", False),
            ("V+", "blue", "REMOVE!", True)]
    pitch = bw / 7.0
    for i, (label, cname, note, danger) in enumerate(pins):
        x = bx + pitch * (i + 1)
        d.add(Rect(x - 2, by + bh, 4, 8, fillColor=colors.HexColor("#c8a018"),
                   strokeColor=None))
        d.add(String(x, by + bh / 2 - 3, label, fontSize=9, textAnchor="middle",
                     fillColor=colors.white))
        d.add(Line(x, by + bh + 8, x, by + bh + 26, strokeColor=RIBBON[cname],
                   strokeWidth=3.5))
        d.add(String(x, by + bh + 30, cname, fontSize=7.5, textAnchor="middle",
                     fillColor=RIBBON[cname]))
        d.add(String(x, by + bh + 39, note, fontSize=7,
                     textAnchor="middle",
                     fillColor=colors.HexColor("#8a1111") if danger or "PARK" in note
                     else colors.HexColor("#333333")))
        if danger:  # red X over the blue wire
            d.add(Line(x - 5, by + bh + 9, x + 5, by + bh + 25,
                       strokeColor=colors.red, strokeWidth=2))
            d.add(Line(x - 5, by + bh + 25, x + 5, by + bh + 9,
                       strokeColor=colors.red, strokeWidth=2))
    # capacitor marker at the V+ end
    cap_x = bx + bw + 28
    d.add(Circle(cap_x, by + bh / 2, 16, fillColor=colors.HexColor("#1b1b1b"),
                 strokeColor=colors.HexColor("#888888"), strokeWidth=1.5))
    d.add(String(cap_x, by + bh / 2 - 3, "cap", fontSize=7.5,
                 textAnchor="middle", fillColor=colors.white))
    d.add(String(cap_x, by - 12, "V+ is always the pin", fontSize=7,
                 textAnchor="middle"))
    d.add(String(cap_x, by - 21, "beside the capacitor", fontSize=7,
                 textAnchor="middle"))
    d.add(String(bx - 4, by - 14, "start counting here (away from cap)",
                 fontSize=7, textAnchor="start",
                 fillColor=colors.HexColor("#777777")))
    return d

story.append(PageBreak())
story.append(P("Pinout diagrams", H2))
story.append(P("PCA9685 I2C header — identify direction by the capacitor:", BODY))
story.append(pca9685_drawing())
story.append(Spacer(1, 8))
story.append(P("ESP32 (30-pin devkit) — the four connections, highlighted:", BODY))
esp_row = Table([[esp32_drawing(),
                  Image(f"{IMG}/esp32-pinout.jpg", width=62 * mm, height=82 * mm)]],
                colWidths=[112 * mm, 68 * mm])
esp_row.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "MIDDLE")]))
story.append(esp_row)
story.append(P("Left: schematic top view (USB-C toward you). Right: the actual board — "
               "match the silk labels; D-numbers are GPIO numbers.", SMALL))

doc = SimpleDocTemplate(OUT, pagesize=A4, topMargin=14 * mm,
                        bottomMargin=12 * mm, leftMargin=14 * mm,
                        rightMargin=14 * mm,
                        title="6DOF Arm — Wiring Bench Sheet")
doc.build(story)
print("wrote", OUT)

# SVG exports of the pinout diagrams for the docs site
from reportlab.graphics import renderSVG

for drawing, name in ((pca9685_drawing(), "pca9685-header-diagram.svg"),
                      (esp32_drawing(), "esp32-pinout-diagram.svg")):
    path = str(REPO / "docs" / "img" / name)
    renderSVG.drawToFile(drawing, path)
    print("wrote", path)
