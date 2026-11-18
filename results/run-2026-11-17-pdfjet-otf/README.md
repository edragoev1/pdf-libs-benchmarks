# The run of 17 November 2026, PDFjet on the .otf files: the published one

PDFjet 9.1.9 (e60835489), in its four ports, read the .otf files of IBM Plex
Sans and Noto Sans; PDFBox 3.0.8, iText 9.8.0 and OpenPDF 3.0.5 read the
.ttf files (SPEC.md says why). run-all.sh, every step passed
(overnight.log), 23:28 to 23:51, right after the .ttf run.

The same files are in each port's results folder, which make-tables.py
reads: the report and pdfjet.com/benchmarks are made from this run.
