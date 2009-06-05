template<class T> inline Print &operator <<(Print &obj, T arg) { obj.print(arg); return obj; }

long previousMillis = 0;
int interval = 3000;

char msg[16] = {'\0'};
long imsg = 0;
int element = 0;

volatile long bit_holder = 0;
volatile int bit_count = 0;

void DATA0(void) {
    bit_count++;
    bit_holder = bit_holder << 1;
}

void DATA1(void) {
   bit_count++;
   bit_holder = bit_holder << 1;
   bit_holder |= 1;
}


void setup()
{
  Serial.begin(57600);
  
  clearinterrupts();
  
  attachInterrupt(0, DATA0, RISING);
  attachInterrupt(1, DATA1, RISING);
  delay(10);

  digitalWrite(13, HIGH);  // show Arduino has finished initilisation
  Serial.println("READER_0001");

}


void loop() {
  if (millis() - previousMillis > interval) {
    bit_count = 0; bit_holder = 0;
    previousMillis = millis();
  }  
  if (bit_count == 26) {
      previousMillis = millis();
      
      bit_holder = (bit_holder >> 1) & 0x7fff;
      Serial << "C: " << bit_holder << "\n";
      bit_count = 0; bit_holder = 0;
      delay(10);
    } 
    else if (bit_count && bit_count % 4 == 0 && bit_count <= 12) {
      previousMillis = millis();
      buildcode(bit_holder);
      Serial << "K: " << buildicode(bit_holder) << "\n";
      bit_count = 0;
      bit_holder = 0;
      delay(5);
    } 
    delay(50);
    //Serial << "B: " << bit_count << "\n";
}

char decodeByte(int x) { //too simple
  if (x == 10) return '*';
  if (x == 11) return '#';
  return x+48; //int to ascii
}

void buildcode(int buf) { //probably too complex for its own good
  msg[element++] = buf;
  if (buf == 11) {
    Serial.print("K: ");
    element = 0;
    while(msg[element++] != 11) {
      Serial.print(msg[element]);
      msg[element] = '\0';
    }
    element = 0;
    Serial.println();
  }
}

long buildicode(int buf) { //builds a DEC and returns when # detected
  if (buf == 11) return imsg;
  if (buf != 10) imsg = imsg * 10 + buf;
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
