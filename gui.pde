 import controlP5.*;
import processing.serial.*;

Serial serial;
ControlP5 cp5;
Toggle lightToggle;  // Переключатель для света
Toggle DoorToggle;  // Переключатель для света
Toggle WindowToggle;  // Переключатель для света
Chart myChart;

String receivedData = "";  // Переменная для хранения принятых данных
String prevtemperature = "22";  // Переменная для хранения предыдущей температуры
String prevtime = "12:44";  // Переменная для хранения предыдущей температуры
String prevpir = "Открыто";  // Переменная для хранения предыдущей температуры
String prevwarn = "0";
String prevsignal = "0";
String prevrfid = "0";
String lastReceivedData = "";  // Переменная для хранения последних принятых данных
boolean newData = false; 
int currentIndex = 0;

void setup() {
  size(750, 600);  // Размер окна
  serial = new Serial(this, "COM9", 115200);
  cp5 = new ControlP5(this);
  
  // Создаем скругленный переключатель для света
  lightToggle = cp5.addToggle("led")
                  .setPosition(92, 500)
                  .setSize(75, 40)
                  .setMode(ControlP5.SWITCH)
                  .setColorActive(color(#46d3a9))
                  .setColorBackground(color(#73879d))
                  .setCaptionLabel("")
                  .setValue(false);  // Изначально выключен
                  
  myChart = cp5.addChart("dataflow")
               .setPosition(550, 55)
               .setSize(150, 100)
               .setRange(15, 35)
               .setCaptionLabel("")
               .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
               .setStrokeWeight(1.5)
               .setLabelVisible(true)
               .setColorBackground(color(#1f274c))
               ;
               
  myChart.addDataSet("incoming");
  myChart.setData("incoming", new float[100]);
  myChart.push("incoming", 22.0);  
  // Добавляем кнопку для включения/выключения отопления
  /*cp5.addButton("Heating")
     .setPosition(40, 350)
     .setColorForeground(color(#2f3b52))
     .setSize(150, 100);*/
}

void draw() {
  /*-----------Дизайн---------------*/
  setGradient(0, 0, 750, 600, color(51,53,100), color(34,35,64), 2);
  noStroke();
  setGradient(400, 25, 320, 150, color(58,60,114), color(29,36,59), 1);
  setGradient(15, 465, 230, 120, color(58,60,114), color(29,36,59), 1);
  setGradient(260, 465, 230, 120, color(58,60,114), color(29,36,59), 1);
  setGradient(505, 465, 230, 120, color(58,60,114), color(29,36,59), 1);
  
    // Надписи
      fill(0);
  textSize(20);
  text("Свет", 107, 487);
  text("Температура", 507, 47);  
  text("Дверь", 356, 487);
  text("Уровень шума", 557, 487); 
  fill(255);
  textSize(20);
  text("Свет", 105, 485);
  text("Температура", 505, 45);
  text("Дверь", 354, 485);
  text("Уровень шума", 555, 485); 
  
  /*---------------------------------------*/
  /*-----Обработка данных с Serial--------*/

  while (serial.available() > 0) {
    char incomingChar = serial.readChar();
    // Если пришел пробел, обрабатываем принятые данные
    if (incomingChar == ' ') {
      // Сохраняем последние принятые данные
      lastReceivedData = receivedData;
      
      // Проверка на температуру
      if (receivedData.startsWith("#temp=")) {
        String temperature = receivedData.substring(6).trim();
        prevtemperature = temperature;
        myChart.push("incoming", Float.parseFloat(prevtemperature)); 
        textSize(40); 
        fill(0);
        text(temperature + "°C", 432, 117);
        fill(255);
        text(temperature + "°C", 430, 115);
      }
      
      if (receivedData.startsWith("#zvuk=")) {
        String signal = receivedData.substring(6);
        prevsignal = signal;
        textSize(40);
        fill(0);   
        text(signal + "Дб", 587, 532);
        fill(255);
        text(signal + "Дб", 585, 530);
      }
      
      if (receivedData.startsWith("#rfid=")) {                                              ////////////////добавилось ли то, что пользовательв доме или нет?
        String rfid = receivedData.substring(6);
        prevrfid = rfid;
        textSize(40);
        fill(0);   
        text(access(rfid), 222, 442);
        fill(255);
        text(access(rfid), 220, 440);
      }
      
      if (receivedData.startsWith("#door=")) {
        String door = receivedData.substring(6).trim();
        String pir = isOpen(door);
        prevpir = pir;
        textSize(40);
        fill(0);
        text(pir, 307, 532);
        fill(255);
        text(pir, 305, 530);
      }
      
      // Проверка на время
      if (receivedData.startsWith("#time=")) {
        String time = receivedData.substring(6).trim();
        if (((time.charAt(0) - '0') * 10 + time.charAt(1) - '0') >= 18) {
          lightToggle.setValue(true);
        }
        else {
          lightToggle.setValue(false);
        }
        prevtime = time;
        // Отображение времени
        textSize(40);
        fill(0);
        text(time, 632, 452);
        fill(255);
        text(time, 630, 450);
      }
      
      if (!receivedData.startsWith("#temp=") && !receivedData.startsWith("#time=") && !receivedData.startsWith("#door=") &&  !receivedData.startsWith("#rfid=") && !receivedData.startsWith("#zvuk=")) {
        textSize(40); 
        fill(0);
        text(prevtemperature + "°C", 432, 117);
        text(prevtime, 632, 452);
        text(access(prevrfid), 222, 442);
        text(prevpir, 307, 532);
        text(prevsignal + "Дб", 587, 532);
        fill(255);
        text(prevtemperature + "°C", 430, 115);
        text(prevtime, 630, 450);
        text(access(prevrfid), 220, 440);
        text(prevpir, 305, 530);  
        text(prevsignal + "Дб", 585, 530);
        
        if (prevwarn == "опасность!") {
          setGradient(200, 200, 350, 135, color(253,52,0), color(214,0,28), 2);
          textSize(40);
          fill(0);
          text("Проникновение!!!", 222, 272);
          fill(255);
          text("Проникновение!!!", 220, 270);
        }
      }
      
      if (receivedData.startsWith("#warn=")) {
        String warn = alarm(receivedData.substring(6).trim());
        prevwarn = warn;
        if (warn == "опасность!") {
          setGradient(200, 200, 350, 135, color(253,52,0), color(214,0,28), 2);
          textSize(40);
          fill(0);
          text("Проникновение!!!", 222, 272);
          fill(255);
          text("Проникновение!!!", 220, 270);
        }
      }
      // Очистка принятых данных для следующей посылки
      receivedData = "";
    } 
    
    else {
      receivedData += incomingChar;  // Добавляем символ к принятым данным
    }
  }

  // Если новые данные еще не пришли, отображаем последние принятые данные
  if (receivedData == "" && lastReceivedData != "") {
    textSize(40); 
    fill(0);
    text(prevtemperature + "°C", 432, 117);
    text(prevtime, 632, 452);
    text(access(prevrfid), 222, 442);
    text(prevpir, 307, 532);
    text(prevsignal + "Дб", 587, 532);
    fill(255);
    text(prevtemperature + "°C", 430, 115);
    text(prevtime, 630, 450);
    text(access(prevrfid), 220, 440);
    text(prevpir, 305, 530);  
    text(prevsignal + "Дб", 585, 530);
    if (prevwarn == "опасность!") {
      setGradient(200, 200, 350, 135, color(253,52,0), color(214,0,28), 2);
          textSize(40);
          fill(0);
          text("Проникновение!!!",222, 272);
          fill(255);
          text("Проникновение!!!", 220, 270);
        }
  }
  /*--------------------------------------*/
}

String isOpen(String i) {
  if (i.equals("1")) {
      return "Открыто";
  } 
  else {
      return "Закрыто";
  }
}

String access(String i) {
  if (i.equals("1")) {
      return "Доступ разрешен!";
  } 
  else {
      return "Доступ запрещен!";
  }
}

String alarm(String i) {
  if (i.equals("1")) {
      return "опасность!";
  } 
  else {
      return "норм!";
  }
}


void setGradient(int x, int y, float w, float h, color c1, color c2, int axis ) {

  noFill();

  if (axis == 1) {  // Top to bottom gradient
    for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(x, i, x+w, i);
    }
  }  
  else if (axis == 2) {  // Left to right gradient
    for (int i = x; i <= x+w; i++) {
      float inter = map(i, x, x+w, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(i, y, i, y+h);
    }
  }
}
 
/*-------обработчики нажатий------*/

void led(int val) {  
  serial.write(val);
}
