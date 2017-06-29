# Payment PDF Parser

A CLI utility for parsing ProfitStars & FIS PDF files into individual check images named by reference number.

## Requirements

* imagemagick
* xpdf (pdttotext, pdfimages)

## CLI

Usage: `bin/cli.dart <command> [arguments]`

Available commands:
* `directory`  - Parse a directory of PDFs.
* `file`       - Parse a single PDF file.
* `help`       - Display help information for ppp-cli.

### Parse a File

Usage: `bin/cli.dart file [arguments]`
* `-f, --file`      - Path of the PDF file to parse.
* `-p, --provider`  - PDF Provider - "ps" or "fis".
* `-c, --clear`     - Clear output directory.

### Parse a directory

Usage: `bin/cli.dart directory [arguments]`
* `-d, --directory`   - Directory containing PDF files to parse.
* `-p, --provider`    - PDF Provider - "ps" or "fis".
* `-c, --clear`       - Clear output directory.
