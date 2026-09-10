#!/usr/bin/env python3

"""Generate the nf-core/atacseq metro-map SVG asset.

The map is intentionally maintained as a small script so that additions to the
workflow summary can be made reproducibly without manual SVG editing.
"""

from pathlib import Path
from html import escape


ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "docs" / "images" / "nf-core-atacseq_metro_map_grey.svg"

W = 1800
H = 1040

GREEN = "#24B064"
BLUE = "#83B9E4"
PURPLE = "#7E57C2"
ORANGE = "#F28E2B"
GREY = "#D6D6D6"
DARK = "#111111"
MID = "#555555"
WHITE = "#FFFFFF"


def text(x, y, body, size=26, weight="700", anchor="middle", fill=DARK, extra=""):
    body = escape(str(body))
    return (
        f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" '
        f'font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" '
        f'fill="{fill}" {extra}>{body}</text>'
    )


def multiline(x, y, lines, size=24, weight="700", anchor="middle", line_height=30, fill=DARK):
    out = [
        f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" '
        f'font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" fill="{fill}">'
    ]
    for i, line in enumerate(lines):
        line = escape(str(line))
        dy = 0 if i == 0 else line_height
        out.append(f'<tspan x="{x}" dy="{dy}">{line}</tspan>')
    out.append("</text>")
    return "\n".join(out)


def box(x, y, w, h, label, fill=GREY):
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{fill}"/>\n'
        f'{text(x + 18, y + 36, label, size=26, anchor="start")}'
    )


def station(x, y, fill=WHITE, stroke=DARK, r=14, sw=5):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'


def square_station(x, y, fill=WHITE, stroke=DARK, size=28, sw=5):
    half = size / 2
    return (
        f'<rect x="{x - half}" y="{y - half}" width="{size}" height="{size}" '
        f'rx="6" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
    )


def line(points, color=GREEN, width=12):
    d = " ".join([("M" if i == 0 else "L") + f" {x} {y}" for i, (x, y) in enumerate(points)])
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'


def file_icon(x, y, label):
    return f"""
<g>
  <path d="M{x} {y} h72 l30 30 v82 h-102 z" fill="{WHITE}" stroke="{DARK}" stroke-width="5"/>
  <path d="M{x + 72} {y} v30 h30" fill="none" stroke="{DARK}" stroke-width="5"/>
  <rect x="{x - 10}" y="{y + 42}" width="122" height="46" rx="6" fill="{DARK}"/>
  {text(x + 51, y + 74, label, size=30, fill=WHITE)}
</g>"""


def main():
    parts = [
        f'<svg width="{W}" height="{H}" viewBox="0 0 {W} {H}" xmlns="http://www.w3.org/2000/svg">',
        f'<rect width="{W}" height="{H}" fill="{WHITE}"/>',
        box(120, 155, 270, 265, "Pre-processing"),
        box(430, 155, 560, 265, "Genome alignment"),
        box(1010, 155, 300, 265, "Alignment QC"),
        box(1325, 155, 350, 265, "Track generation"),
        box(430, 455, 880, 260, "Peak calling & accessibility QC"),
        box(1325, 455, 350, 260, "Standard enrichment"),
        box(430, 745, 560, 205, "Epigenetic layer", fill="#DDEFE6"),
        box(1010, 745, 665, 205, "Genetic layer", fill="#E3EEF8"),
        file_icon(20, 250, "fastq"),
        file_icon(1560, 255, "bigWig"),
        file_icon(1180, 35, "bam"),
        file_icon(1300, 35, "bai"),
        file_icon(145, 560, "html"),
        file_icon(315, 655, "xml"),
        file_icon(895, 720, "tab"),
        file_icon(1610, 730, "vcf"),
        file_icon(1715, 730, "rds"),
        line([(110, 315), (570, 315), (650, 315), (780, 315), (870, 315), (940, 315), (1085, 315), (1215, 315), (1390, 315), (1510, 315), (1675, 315)], GREEN),
        line([(880, 315), (880, 380), (1350, 380), (1400, 435), (1400, 580), (1280, 605), (1060, 605), (870, 605), (660, 605), (460, 605), (250, 605)], BLUE),
        line([(600, 315), (660, 245), (735, 245), (805, 315)], GREEN),
        line([(600, 315), (660, 385), (735, 385), (805, 315)], GREEN),
        line([(1000, 605), (1000, 820), (920, 820), (800, 820), (680, 820), (560, 820)], PURPLE),
        line([(1000, 605), (1120, 820), (1260, 820), (1400, 820), (1545, 820), (1710, 820)], ORANGE),
        station(140, 315, fill="#777777"),
        station(200, 315),
        station(275, 315),
        station(350, 315),
        square_station(690, 245),
        square_station(690, 315),
        square_station(690, 385),
        square_station(890, 315),
        square_station(920, 345),
        square_station(985, 250),
        station(1125, 315),
        station(1265, 315),
        square_station(1455, 370),
        square_station(1490, 370),
        station(1495, 510),
        station(500, 605),
        station(660, 605),
        square_station(820, 605),
        station(1120, 605),
        square_station(1280, 605),
        station(560, 820, stroke=PURPLE),
        station(680, 820, stroke=PURPLE),
        station(800, 820, stroke=PURPLE),
        station(920, 820, stroke=PURPLE),
        station(1120, 820, stroke=ORANGE),
        station(1260, 820, stroke=ORANGE),
        station(1400, 820, stroke=ORANGE),
        station(1545, 820, stroke=ORANGE),
        station(1710, 820, stroke=ORANGE),
        text(200, 275, "FastQC", size=21),
        text(275, 355, "Cutadapt", size=21),
        text(350, 275, "FastQC", size=21),
        text(620, 245, "Chromap", size=20),
        text(690, 210, "BWA", size=23),
        text(610, 410, "Bowtie2", size=20),
        text(690, 455, "STAR", size=22),
        text(840, 275, "Picard", size=22),
        text(985, 215, "Filtering", size=22),
        text(1125, 275, "preseq", size=22),
        multiline(1265, 345, ["Picard's", "CollectMultipleMetrics"], size=19, line_height=23),
        multiline(1465, 275, ["BEDTools", "genomecov"], size=21, line_height=25),
        text(1540, 415, "bedGraphToBigWig", size=20),
        text(1555, 515, "deepTools", size=22),
        text(1280, 565, "MACS3", size=22),
        text(1120, 565, "HOMER", size=22),
        multiline(820, 555, ["SAMtools", "+ BEDTools"], size=20, line_height=24),
        text(670, 665, "featureCounts", size=21),
        text(500, 575, "R + DESeq2", size=22),
        text(270, 560, "MultiQC", size=22),
        text(345, 660, "IGV", size=22),
        text(950, 710, "ataqv", size=22),
        text(560, 805, "ROSE", size=18, fill=PURPLE),
        text(680, 805, "TOBIAS", size=18, fill=PURPLE),
        text(800, 805, "chromVAR", size=18, fill=PURPLE),
        text(920, 805, "NucleoATAC", size=18, fill=PURPLE),
        text(1120, 805, "BWA/GATK", size=18, fill=ORANGE),
        text(1260, 805, "Variants", size=18, fill=ORANGE),
        text(1400, 805, "VCF in peaks", size=18, fill=ORANGE),
        text(1545, 805, "QDNAseq", size=18, fill=ORANGE),
        text(1710, 805, "TelomereHunter2", size=17, fill=ORANGE),
        text(750, 910, "chromatin accessibility and regulatory activity", size=19, weight="600", fill=PURPLE),
        text(1360, 910, "ATAC-derived genome variation analyses", size=19, weight="600", fill=ORANGE),
        text(58, 875, "nf-", size=74, anchor="start", fill=GREEN, weight="800"),
        text(200, 875, "core/", size=74, anchor="start", fill=DARK, weight="800"),
        text(58, 960, "atacseq", size=74, anchor="start", fill=DARK, weight="800"),
        station(1415, 915),
        text(1450, 923, "Optional", size=24, anchor="start"),
        square_station(1415, 965),
        text(1450, 973, "Mandatory", size=24, anchor="start"),
        f'<line x1="1585" y1="915" x2="1650" y2="915" stroke="{GREEN}" stroke-width="12" stroke-linecap="round"/>',
        text(1670, 923, "merged libraries", size=24, anchor="start"),
        f'<line x1="1585" y1="965" x2="1650" y2="965" stroke="{BLUE}" stroke-width="12" stroke-linecap="round"/>',
        text(1670, 973, "merged replicates", size=24, anchor="start"),
        f'<line x1="560" y1="870" x2="940" y2="870" stroke="{PURPLE}" stroke-width="8" stroke-linecap="round"/>',
        f'<line x1="1120" y1="870" x2="1710" y2="870" stroke="{ORANGE}" stroke-width="8" stroke-linecap="round"/>',
        text(1600, 1015, "License:", size=24, anchor="start"),
        text(1705, 1015, "CC0", size=24, anchor="start"),
        "</svg>",
    ]
    SVG.write_text("\n".join(parts) + "\n")


if __name__ == "__main__":
    main()
