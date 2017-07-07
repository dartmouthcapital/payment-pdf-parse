# tmannherz/payment-pdf-parse
FROM google/dart-runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends imagemagick poppler-utils && \
    ln -s $(which convert) /usr/local/bin/magick
