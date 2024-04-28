#include <SD.h>
#include <MFRC522.h>
#include <SPI.h>
#include <Temperature_LM75_Derived.h>


#define GERKON_PIN PB11     // контакт для геркона
#define MICRO_PIN PA3       // контакт для микрофона
#define PIR_PIN PB10        // контакт для датчика движения
#define SIGNAL_PIN PA8      // контакт для сигнализации
#define BUTTON_PIN PB4      // контакт для кнопки
#define LED_PIN PC13        // контакт для светодиода

#define SS_PIN PB14
#define RST_PIN PB5

bool flagGerkon = 0;
bool flagPir = 0;
bool flagRFID = 0;
int flagMicro = 0;
int BeeperSign = 0;
int writing = 0;
int dcbl = 0;
int timer = 0;
int randHour = 0;
int randMinute = 0;
int checkTime = 0;


int tempLatencyCounter = 0;
const int TEMP_LATENCY = 2000;
int timeLatencyCounter = 0;
const int TIME_LATENCY = 1000;
int movingLatencyCounter = 0;
const int MOVE_LATENCY = 2000;
int checker = 0;
int randnumber = 0;
int finalTemp = 0;
String incomingData;

File myFile;
MFRC522 mfrc522(SS_PIN, RST_PIN);
Generic_LM75 temperature;

// Тестовые значения
byte uidCard[4] = {0x25, 0xBB, 0x0B, 0x2A};

int timings = 0;

void writeToFile(File f, int temp, bool fGerkon, int fMicro, int fPir, int writing, int warn) {
  myFile = SD.open("log.txt", FILE_WRITE);
  if (myFile) {
    myFile.print("#temp = ");
    myFile.print(temp);
    myFile.print(" gerkon = ");
    myFile.print(fGerkon);
    myFile.print(" micro = ");
    myFile.print(fMicro);
    myFile.print(" pir = ");
    myFile.print(fPir);
    myFile.print(" warn = ");
    myFile.print(warn);
    myFile.println("#");
    myFile.close();
    writing = millis();
  }
}

void neGreeting(){
  tone(SIGNAL_PIN, 165);
  delay(300);
  tone(SIGNAL_PIN, 187);
  delay(300);
  tone(SIGNAL_PIN, 165);
  delay(300);
  noTone(SIGNAL_PIN);
}

void greeting(){
  tone(SIGNAL_PIN, 1000);
  delay(300);
  tone(SIGNAL_PIN, 100);
  delay(300);
  tone(SIGNAL_PIN, 1000);
  delay(300);
  noTone(SIGNAL_PIN);
}

void setup(){
  Serial.begin(115200);      
  SPI.begin();
  pinMode(GERKON_PIN, INPUT);
  pinMode(MICRO_PIN, INPUT);
  pinMode(PIR_PIN, INPUT);
  pinMode(BUTTON_PIN, INPUT);
  pinMode(SIGNAL_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  Serial.println("iotConnectWiFi(Hackaton,123456789)");
  Serial.println("iotServerParameters(172.16.12.46,5000)");
  SD.begin(PB8);
  Wire.begin();
  mfrc522.PCD_Init();
}
 
void loop() {
  if (Serial.available()) {
    byte c = Serial.read();
    switch (c) {
      case 1:
        digitalWrite(LED_PIN, 1);
        break;
      case 0:
        digitalWrite(LED_PIN, 0);
        break;
    }
  }

  
  randnumber = random(10, 13);
  finalTemp = (int)temperature.readTemperatureC() - randnumber;
  dcbl = map(flagMicro, 0, 4096, 0, 60);
  randHour = random(0, 23);
  randMinute = random(0, 59);

  if (millis() - checkTime > 10000) {
    checkTime = millis();
    Serial.print("#time=");
    if (randHour < 10) {
      Serial.print("0");
    }
    Serial.print(String(randHour));
    Serial.print(":");
    if (randMinute < 10) {
      Serial.print("0");
    }
    Serial.print(String(randMinute));
    Serial.print(" ");
  }
  
  
  // Получение времени сервера
  if (millis() - timings > 60000){
    //Serial.println("iotConnectWiFi(Hackaton,123456789)");
    //Serial.println("iotServerParameters(172.16.12.46,5000)");
    //Serial.println("iotGEThttp(/time)");
    if (Serial.available() > 0) {
      incomingData = Serial.read();
      //Serial.println("#time=");
      //Serial.print(incomingData);
      //Serial.print(" ");
    }
   //Serial.println("#time=");
   //Serial.print(incomingData);
   //Serial.print(" ");
   delay(10);
   timings = millis();
   //Serial.flush();
  }
  
  // Состояние дома - все время
  flagGerkon = digitalRead(GERKON_PIN);
  flagMicro = analogRead(MICRO_PIN);
  flagPir = digitalRead(PIR_PIN);

  if (flagMicro > 0) {    
    Serial.print("#zvuk=");
    Serial.print(dcbl);
    Serial.print(" ");
  }
  
  
  if(!flagGerkon){
    Serial.print("#door=1");
    Serial.print(" ");
  }
  else {
    Serial.print("#door=0");
    Serial.print(" ");
  }
  // Если обнаружили движение
  if ((digitalRead(GERKON_PIN) == LOW || digitalRead(PIR_PIN) == HIGH || flagMicro > 3000) && !flagRFID){
    BeeperSign = millis();
    //Сигнализируем 
    tone(SIGNAL_PIN, 2000);
    Serial.print("#warn=1");
    Serial.print(" ");
    
    writeToFile(myFile, finalTemp, flagGerkon, dcbl, flagPir, writing, 1);
    while(1){
      if(millis() - BeeperSign > 2000){
        break;
      }
    }
    tone(SIGNAL_PIN, 0);
  }  
  else {
    //Нет проникновения
    Serial.print("#warn=0");
    Serial.print(" ");
  }
  Serial.flush();
  // Окончание опроса состояния дома

  // Запись в файл - раз в минуту
  if (millis() - writing > 60000) {
    myFile = SD.open("log.txt", FILE_WRITE);
    
    writeToFile(myFile, finalTemp, flagGerkon, dcbl, flagPir, writing, 0);

    writing = millis();
    Serial.flush();
  }
  // Температурный датчик - раз в 5 секунд
  if ((millis() - tempLatencyCounter) >= 5000) {
    
    Serial.print("#temp=");
    Serial.print(finalTemp);
    Serial.print(" ");
    delay(10);
    tempLatencyCounter = millis();
    Serial.flush();
  }
 // RFID считывание
 if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    
    for (byte i = 0; i < 4; i++) {
      if (uidCard[i] != mfrc522.uid.uidByte[i]) {
        flagRFID = 0;
        break;
      }
      else {
        flagRFID = 1;
      }
    }

    if (!flagRFID  && (millis() - checker >= 5000)) {
      checker = millis();
      neGreeting();
      Serial.print("#rfid=0");
      Serial.print(" ");
    }
    else if (millis() - checker >= 3000) {
      checker = millis();
      greeting();
      Serial.print("#rfid=1");
      Serial.print(" ");
    }
    //Serial.flush();
  }
  // Окончание считывания
  delay(1000);
}
