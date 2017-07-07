# Payment PDF Parser

An HTTP API & CLI utility for parsing ProfitStars & FIS PDF files into individual check images named by reference number.

## Requirements

* imagemagick
* Poppler/xpdf (pdttotext, pdfimages)

## Server

Run `dart bin/server.dart`. By default, the HTTP server runs on `0.0.0.0:8080`. Set the ENV variables `SHELF_HTTP_HOST` and `SHELF_HTTP_PORT` to override.

#### Request
```
POST http://localhost:8080/?provider=ps|fis HTTP/1.1
Content-Type: application/pdf
Content-Length: [NUMBER_OF_BYTES_IN_FILE]

[PDF_DATA]
```

Binary ZIP file contents is returned.

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
* `-z, --zip`       - Zip up output images.

### Parse a directory

Usage: `bin/cli.dart directory [arguments]`
* `-d, --directory`   - Directory containing PDF files to parse.
* `-p, --provider`    - PDF Provider - "ps" or "fis".
* `-c, --clear`       - Clear output directory.
* `-z, --zip`         - Zip up output images.
