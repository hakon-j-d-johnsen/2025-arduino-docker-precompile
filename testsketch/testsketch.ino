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
