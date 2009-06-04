#include <SoftwareSerial.h>

template<class T> inline Print &operator <<(Print &obj, T arg) { obj.print(arg); return obj; }

#define rxPin 5
#define txPin 4

volatile long bit_holder = 0;
volatile int bit_count = 0;

long previousMillis = 0;        // will store last time LED was updated
long interval = 5000;           // interval at which to reset display (milliseconds)

SoftwareSerial mySerial =  SoftwareSerial(rxPin, txPin);
boolean keypad_in_use = false;


void DATA0(void) {
    bit_count++;
    bit_holder = bit_holder << 1;
}

void DATA1(void) {
   bit_count++;
   bit_holder = bit_holder << 1;
   bit_holder |= 1;
}


void setup() {
  Serial.begin(57600);
  
  clearinterrupts();
  
  attachInterrupt(0, DATA0, RISING);
  attachInterrupt(1, DATA1, RISING);
  delay(10);

  InitializeLCD();
  
  digitalWrite(13, HIGH);  // show Arduino has finished initilisation
  Serial.println("READER_0001");
}


void loop() {
    if (millis() - previousMillis > interval) {
      bit_count = 0; bit_holder = 0; //in case something went wrong, clear the buffers
      previousMillis = millis();   // remember the last time we blinked the LED
      mySerial.print("?f?x04?y1Present Card?x04?y2or Enter Pin");
      keypad_in_use = false;
      
    }
    
    if (bit_count == 26) {
        mySerial.print("?f?x01?y1Card Scanned?x01?y2ID: ");
        bit_holder = (bit_holder >> 1) & 0x7fff;
        mySerial.print(bit_holder);
        //Serial << "C: " << bit_holder << "\n";
        bit_count = 0; bit_holder = 0;
        keypad_in_use = false;
        previousMillis = millis();
        delay(10);
    } 
    else if (bit_count && bit_count % 4 == 0 && bit_count <= 12) {
        if (!keypad_in_use) mySerial.print("?f?x01?y1Keypad Entry?x01?y2# ");
        keypad_in_use = true;
        if (keypad_in_use) mySerial.print(decodeByte(bit_holder));
        //Serial << "K: " << decodeByte(bit_holder) << "\n";
        bit_count = 0; bit_holder = 0;
        previousMillis = millis();
        delay(5);
    } 
    delay(50); //give it enough time to capture more data from the bus
    //if (bit_count) Serial << bit_count << " ";
}

char decodeByte(int x) {
  if (x == 10) return '*';
  if (x == 11) return '#';
  return x+48; //int to ascii
}

void clearinterrupts () {
    // the interrupt in the Atmel processor mises out the first negitave pulse as the inputs are already high,
  // so this gives a pulse to each reader input line to get the interrupts working properly.
  // Then clear out the reader variables.
  // The readers are open collector sitting normally at a one so this is OK
  for(int i = 2; i<4; i++){
    pinMode(i, OUTPUT);
    digitalWrite(i, HIGH); // enable internal pull up causing a one
    digitalWrite(i, LOW); // disable internal pull up causing zero and thus an interrupt
    pinMode(i, INPUT);
    digitalWrite(i, HIGH); // enable internal pull up
  }
  delay(10);
}


void InitializeLCD() {
  pinMode(txPin, OUTPUT);
  mySerial.begin(9600); 
  
  mySerial.print("?G420"); // set display size to 4x20
  delay(100);	           // pause to allow LCD EEPROM to program
  mySerial.print("?Bff");  // set backlight to 40 hex
  delay(100);              // pause to allow LCD EEPROM to program

  mySerial.print("?c0");   // turn cursor off
  delay(200);  
  
  mySerial.print("?f");    // clear display
  delay(100);
}
