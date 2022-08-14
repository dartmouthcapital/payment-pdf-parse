# Payment PDF Parser

An HTTP API & CLI utility for parsing ProfitStars & FIS PDF files into individual check images named by reference number.

## Requirements

* imagemagick
* Poppler/xpdf (pdftotext, pdfimages)

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

## Windows Dev Setup

1. Install the Dark SDK: https://dart.dev/get-dart at version 1 & dependencies:
    ```
    choco install dart-sdk --version 1.24.3 -y
    choco pin add -n=dart-sdk --version 1.24.3
    choco install gcloudsdk imagemagick xpdf-utils -y
    ```
1. Run local server: `dart bin/server.dart`
1. HTTP post using Postman or similar:
    ```
    curl --location --request POST 'http://localhost:8080' \
        --header 'Content-Type: application/pdf' \
        --data-binary '@/path/to-file.pdf'
    ```

## Rebuilding & Pushing to GCR
1. Authenticate with Google Cloud:
    ```
    gcloud auth login
    gcloud config set project dc-magento
    gcloud auth configure-docker
    ```
1. Build, Tag, & Push Image
    ```
    docker build -t dartmouthcapital/payment-pdf-parse .
    docker tag dartmouthcapital/payment-pdf-parse gcr.io/dc-magento/payment-pdf-parse
    docker push gcr.io/dc-magento/payment-pdf-parse
    ```
1. Update remote container
    ```
    ssh dc-service1
    docker stop ppp
    docker container rm ppp

    # if auth has expired:
    docker-credential-gcr gcr-login
    docker-credential-gcr configure-docker

    docker pull gcr.io/dc-magento/payment-pdf-parse
    docker run --name ppp -itd -p 8090:8080 \
        --log-driver=gcplogs \
        --restart always \
        gcr.io/dc-magento/payment-pdf-parse
    ```
