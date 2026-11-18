# The run of 17 November 2026, PDFjet on the .ttf files

The same as run-2026-11-17-pdfjet-otf, but for PDFjet 9.1.9 reading the
.ttf files too, as the other libraries do (PDFJET_FONTS=ttf ./run-all.sh),
23:05 to 23:29, the machine rebooted about 1.5 hours before. Every step
passed (overnight.log).

The web page's switch to .ttf shows PDFjet's figures of this run beside the
other libraries' figures of the .otf run:

    PDFJET_TTF=../results/run-2026-11-17-pdfjet-ttf report/make-report.sh
