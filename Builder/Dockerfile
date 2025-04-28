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


# Compile hello sketch for Arduino Uno with Servo library

RUN mkdir -p /sketches/servo
COPY <<EOF /sketches/servo/servo.ino
#include <Servo.h>
Servo myServo; 
void setup() {
  Serial.begin(9600);
  myServo.attach(9);
  delay(1000);
}
void loop() {
  Serial.println("Hello, Arduino!");
  myServo.write(90);
  delay(1000);
}
EOF
RUN echo "hei4"
RUN arduino-cli config set logging.level trace
RUN arduino-cli compile --log-level trace -v --fqbn arduino:avr:uno /sketches/servo
RUN arduino-cli compile --log-level trace -v --fqbn arduino:avr:uno /sketches/servo

RUN mkdir -p /sketches/servo2
COPY <<EOF /sketches/servo2/servo2.ino
#include <Servo.h>
Servo myServo; 
void setup() {
  Serial.begin(9600);
  myServo.attach(9);
  delay(1000);
}
void loop() {
  Serial.println("Hello, Arduino!");
  myServo.write(90);
  delay(1000);
}
EOF

RUN echo "hei4"

RUN mkdir -p /root/.cache/arduino/sketches/DC194EB12F56A555113D984A86944D8F/libraries
RUN cp -r /root/.cache/arduino/sketches/00D5792ADC117BF96770888FC77C2A5D/libraries /root/.cache/arduino/sketches/DC194EB12F56A555113D984A86944D8F
RUN find /root/.cache/arduino/sketches/DC194EB12F56A555113D984A86944D8F/ -name "*.d" -exec sed -i 's/00D5792ADC117BF96770888FC77C2A5D/DC194EB12F56A555113D984A86944D8F/g' {} \;

RUN arduino-cli compile -v --fqbn arduino:avr:uno /sketches/servo2

# Sketch cache is in /root/.cache/arduino/sketches/<md5_hash_of_sketch_path>
# E.g. echo -n "/sketches/servo" | md5sum