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

COPY precompile-cores.sh /bin/precompile-cores.sh
RUN chmod +x /bin/precompile-cores.sh
RUN precompile-cores.sh arduino:avr:uno esp32:esp32:esp32c3 esp32:esp32s2 esp32:esp32:esp32s3

COPY precompile.sh /bin/precompile.sh
RUN chmod +x /bin/precompile.sh
#RUN precompile.sh esp32:esp32:esp32c6 ESP32Servo
#RUN precompile.sh esp32:esp32:esp32c6 ESP32Servo:ESP32Servo.h
#RUN precompile.sh esp32:esp32:esp32c6 ArduinoJson:ArduinoJson.h ESP32Servo:ESP32Servo.h
RUN echo "hei"
RUN precompile.sh arduino:avr:uno Servo:Servo.h

RUN echo "hei4"

# Add compiler script
COPY compile.sh /bin/compile.sh
RUN chmod +x /bin/compile.sh