FROM google/dart-runtime:1
LABEL maintainer="todd.mannherz@gmail.com"

RUN apt-get update && \
    apt-get install -y --no-install-recommends imagemagick poppler-utils && \
    ln -s $(which convert) /usr/local/bin/magick
