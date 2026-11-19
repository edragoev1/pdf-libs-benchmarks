#!/bin/bash
# Makes the report PDF: the tables of the article and the figures of the
# charts from the raw results (make-tables.py), then the PDF with PDFjet
# (Report.java): a page of bar charts and the article, landscape; and the
# same report as one web page (make-html.py).
#
#   ./make-report.sh [article.md]   (default ../ARTICLE.md)
#
# The web page has a switch between the .otf and the .ttf files. Its .otf
# side is the main run (run-all.sh), with the other libraries' figures taken
# from ALL_OTF if set: a run of every library on the .otf files (FONTS=otf
# run-all.sh, kept as results/run-*). Its .ttf side, with PDFJET_TTF set to a
# run of every library on the .ttf files (FONTS=ttf), has PDFjet's figures of
# that run beside the other libraries' .ttf figures of the main run. The PDF
# has the .otf side, and PDFjet's .ttf figures on two more pages.
set -e
cd "$(dirname "$0")"
ARTICLE=${1:-../ARTICLE.md}
PDFJET=${PDFJET:-$HOME/Projects/pdfjet}
TTF=${PDFJET_TTF:+$(realpath "$PDFJET_TTF")}
OTF=${ALL_OTF:+$(realpath "$ALL_OTF")}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# merge OUT FROM pdfjet|others: the main run's results copied to OUT, with the
# lines of PDFjet, or of the other libraries, in every file taken from FROM
merge() {
python3 - "$@" <<'EOF'
import os, shutil, sys
out, src, which = sys.argv[1:4]
def pdfjet(line, field):
    f = line.split()
    return len(f) > field and f[field].lower().startswith("pdfjet")
for port in ["java", "dotnet", "go", "swift"]:
    os.makedirs(os.path.join(out, port))
    main_dir = os.path.join("..", port, "results")
    for name in os.listdir(main_dir):
        shutil.copy2(os.path.join(main_dir, name), os.path.join(out, port, name))
    if which == "others" and port != "java":
        continue        # C#, Go and Swift: PDFjet alone
    for name, field in [("runs.txt", 1), ("first.txt", 1), ("memory.txt", 2)]:
        take = lambda l: pdfjet(l, field) == (which == "pdfjet")
        keep = [l for l in open(os.path.join(main_dir, name)) if not take(l)]
        new = [l for l in open(os.path.join(src, port, name)) if take(l)]
        assert new, (port, name)
        open(os.path.join(out, port, name), "w").write("".join(keep + new))
EOF
}
# The .otf side: with ALL_OTF, the other libraries on the .otf files too
MAIN=
if [ -n "$OTF" ]; then
    MAIN=$tmp/otf
    merge "$MAIN" "$OTF" others
fi
BENCH_RESULTS=$MAIN ../make-tables.py "$ARTICLE"
BENCH_RESULTS=$MAIN ../make-tables.py --charts charts.txt
# The article as published: without the draft's note, its open decisions and
# the markers of the generated tables
publish() {
python3 - "$1" "$2" <<'EOF'
import re, sys
s = open(sys.argv[1]).read()
if '\n---\n\n## Open decisions' in s:
    s = s[:s.index('\n---\n\n## Open decisions')]
# The tables of the results go to an appendix at the end, each with the
# paragraph that leads into it, as the charts show their figures
TITLES = {'java-plex': 'Time per document, IBM Plex Sans', 'java-noto': 'Time per document, Noto Sans',
          'first-pdf': 'The first PDF of a process', 'memory': 'Memory allocated per document',
          'sizes': 'The size of the PDFs', 'loc': 'Lines of code'}
moved = []
def move(m):
    moved.append('### ' + TITLES[m.group('id')] + '\n\n' + m.group(0))
    return '' if len(moved) > 1 else POINTER
POINTER = ('Every measurement is drawn as a chart on the first pages, and the tables of '
           'every figure, with PDFjet in C#, Go and Swift beside the four libraries, are '
           'in the appendix at the end.\n\n')
s = re.sub(r'(?:[^\n]+\n)+\n<!-- table (?P<id>java-plex|java-noto|first-pdf|memory|sizes|loc) -->\n.*?'
           r'<!-- end [a-z-]+ -->\n\n', move, s, flags=re.S)
assert len(moved) == 6, len(moved)
s = s.replace('tables above', 'tables in the appendix')
s = s.rstrip('\n') + '\n\n## Appendix: the tables\n\n' + ''.join(moved)
s = re.sub(r'<!-- (table|end) [a-z-]+ -->\n', '', s)
s = re.sub(r'\*DRAFT,.*?\*\n\n', '', s, flags=re.S)
# The first page has the title, so the article starts with its text
s = re.sub(r'\A# [^\n]*\n\n', '', s)
open(sys.argv[2], 'w').write(s)
EOF
}
publish "$ARTICLE" article.md
if [ -n "$TTF" ]; then
    # The main run's results, with PDFjet's lines in every file taken from
    # the .ttf run: the other libraries' figures stay those of the main run,
    # on the .ttf files
    merged=$tmp/ttf
    merge "$merged" "$TTF" pdfjet
    cp "$ARTICLE" "$merged/article.md"
    BENCH_RESULTS=$merged ../make-tables.py "$merged/article.md"
    BENCH_RESULTS=$merged ../make-tables.py --charts charts-ttf.txt
    publish "$merged/article.md" article-ttf.md
fi
rm -rf classes && mkdir classes
(cd "$PDFJET" && javac -O -encoding utf-8 -nowarn $(find com/pdfjet -name '*.java') -d "$OLDPWD/classes")
javac -nowarn -encoding utf-8 -cp classes -d classes Report.java
# The PDF has no switch: with the .ttf run, its charts of the time and the
# size and memory, PDFjet's figures of that run, are two more pages after
# the first two
PDF_CHARTS=charts.txt
if [ -n "$TTF" ]; then
    PDF_CHARTS=charts-pdf.txt
    python3 - charts.txt charts-ttf.txt "$PDF_CHARTS" <<'EOF'
import sys
main, ttf = (open(f, encoding="utf-8").read().split("\n") for f in sys.argv[1:3])
cut = main.index("#page|The first PDF of a fresh process")
end = ttf.index("#page|The first PDF of a fresh process")
size = ttf.index("#page|The size of the PDFs and memory")
extra = (["#page|PDFjet on the .ttf files: time per document"] + ttf[:size]
         + ["#page|PDFjet on the .ttf files: the size of the PDFs and memory"] + ttf[size + 1:end])
open(sys.argv[3], "w", encoding="utf-8").write("\n".join(main[:cut] + extra + main[cut:]))
EOF
fi
java -cp classes Report article.md "$PDF_CHARTS" pdf-libs-benchmarks.pdf
qpdf --check pdf-libs-benchmarks.pdf > /dev/null && echo "pdf-libs-benchmarks.pdf: $(pdfinfo pdf-libs-benchmarks.pdf | awk '/^Pages/ {print $2}') pages, qpdf ok"
# The same report as one web page, from the same files, with its fonts in
# fonts/ beside it: PDFjet's IBM Plex Sans and Cascadia Mono, subset to Latin
# and the signs the page uses, as WOFF2, with their licenses
mkdir -p fonts
for f in IBMPlexSans/IBMPlexSans-Regular IBMPlexSans/IBMPlexSans-SemiBold IBMPlexSans/IBMPlexSans-Italic \
         IBMPlexSans/IBMPlexSans-SemiBoldItalic CascadiaMono/CascadiaMono-Regular; do
    pyftsubset "$PDFJET/resources/fonts/$f.otf" --output-file="fonts/${f#*/}.woff2" --flavor=woff2 \
        --unicodes="U+0020-007E,U+00A0-017F,U+2010-2027,U+2030-203A,U+20AC,U+2190-2193,U+2212,U+2713" \
        --layout-features='kern,liga,calt' --no-hinting --drop-tables+=meta
done
cp -p "$PDFJET/resources/fonts/IBMPlexSans/license.txt" fonts/IBMPlexSans-license.txt
cp -p "$PDFJET/resources/fonts/CascadiaMono/LICENSE" fonts/CascadiaMono-license.txt
./make-html.py article.md charts.txt pdf-libs-benchmarks.html ${TTF:+article-ttf.md charts-ttf.txt}
echo "pdf-libs-benchmarks.html: $(grep -o 'class="chart"' pdf-libs-benchmarks.html | wc -l) charts"
