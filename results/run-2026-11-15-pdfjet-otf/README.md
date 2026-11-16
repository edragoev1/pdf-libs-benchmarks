# The run of 15 November 2026: each library with the fonts it does best with

PDFjet's main at 812682b8a (9.1.9, not released yet), in its four ports,
read the .otf files of IBM Plex Sans 3.005 and Noto Sans 2.015; PDFBox
3.0.8, iText 9.8.0 and OpenPDF 3.0.5 read the .ttf files (SPEC.md says
why). run-all.sh, every step passed (overnight-2026-11-15.log). The machine
was not rebooted first, and its load average was 3.3 over the last 5
minutes when the run started.

The raw results of each port, as its results folder had them after the run,
are in java/, dotnet/, go/ and swift/. draft-report.pdf and .html are the
report made from them, not published: its text was not yet brought up to
date beyond the version of PDFjet, the font formats and the lines of
PDFjet's tables.

To compare: the same run with PDFjet on the .ttf files too, every library
reading the same files (TODO.md of PDFjet).
