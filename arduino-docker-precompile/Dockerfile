FROM debian:stable-slim

RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  ca-certificates \
  curl \
  libexpat1 \
  python3 \
  jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN \
  curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=/usr/bin sh \
  && arduino-cli update

# Install Arduino cores. ESP32 core is a huge download, so we give ourselves 10 min network timeout (instead of the default 1 min)
RUN arduino-cli config set network.connection_timeout 600
RUN arduino-cli core install arduino:avr
RUN arduino-cli core install esp32:esp32

# Let's set some caching preferences
RUN \
  arduino-cli config set build_cache.compilations_before_purge 0 && \
  arduino-cli config set build_cache.ttl 1000000h # 100 years...

# Let's precompile some cores
# (could possibly precompile all available ones, each one is just a couple MB)
COPY --chmod=755 precompile-cores.sh /bin/precompile-cores.sh
RUN precompile-cores.sh arduino:avr:uno esp32:esp32:esp32c3 esp32:esp32:esp32s3 esp32:esp32:esp32c3

# Now let's precompile some library combinations.
# This is much more granular, we compile specific combinations of core and set of library.
# THe python script loops through some few combinations of core and library.
COPY --chmod=755 precompile-libraries.py /bin/precompile-libraries.py
RUN precompile-libraries.py
# Add compilation script into the docker image
COPY --chmod=755 compile.sh /bin/compile.sh
ENTRYPOINT ["/bin/compile.sh"]