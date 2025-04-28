FROM debian:stable-slim

RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  ca-certificates \
  curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN \
  curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=/usr/bin sh \
  && arduino-cli update

# Install Arduino core for Uno
RUN arduino-cli core install arduino:avr
RUN arduino-cli config set network.connection_timeout 0
RUN arduino-cli core install esp32:esp32

# Add hello sketch
RUN mkdir -p /sketches/hello
COPY <<EOF /sketches/hello/hello.ino
void setup() {
  Serial.begin(9600);
  delay(1000);
}

void loop() {
  Serial.println("Hello, Arduino!");
  delay(1000);
}
EOF


# Compile hello sketch for Arduino Uno

# Add servo library
RUN arduino-cli lib install Servo

# Add the line dot_a_linkage=true to the end of /root/Arduino/libraries/Servo/library.properties
#RUN echo "dot_a_linkage=true" >> /root/Arduino/libraries/Servo/library.properties

RUN arduino-cli compile --fqbn arduino:avr:uno /sketches/hello
RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  libexpat1 python3 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN echo "hei2"
COPY precompile.py /precompile.py
RUN python3 -u /precompile.py esp32:esp32:esp32c6 ESP32Servo U8g2
RUN python3 -u /precompile.py esp32:esp32:esp32c3 ESP32Servo U8g2
RUN python3 -u /precompile.py arduino:avr:uno Servo U8g2

RUN echo "hei4"

# Add compiler script
COPY compile.sh /compile.sh
RUN chmod +x /compile.sh

#RUN mkdir -p /root/.cache/arduino/sketches/DC194EB12F56A555113D984A86944D8F/libraries
#RUN cp -r /root/.cache/arduino/sketches/00D5792ADC117BF96770888FC77C2A5D/libraries /root/.cache/arduino/sketches/DC194EB12F56A555113D984A86944D8F
#RUN find /root/.cache/arduino/sketches/DC194EB12F56A555113D984A86944D8F/ -name "*.d" -exec sed -i 's/00D5792ADC117BF96770888FC77C2A5D/DC194EB12F56A555113D984A86944D8F/g' {} \;

#RUN arduino-cli compile -v --fqbn arduino:avr:uno /sketches/servo2
