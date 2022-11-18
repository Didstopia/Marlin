#include "Excalibur.h"

TFT_eSPI tft = TFT_eSPI();  // Invoke custom library

AsyncWebServer webServer(80);

// TODO: Configure this for the Neopixel Ring
Adafruit_NeoPixel pixels(NEOPIXEL_PIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);

bool shouldRender = false;

void setup () {
  initSerial();
  initDisplay();
  initNeopixel();
  initWiFi();
  initWebServer();
}

void loop() {
  // TODO: Refactor this and hopefully even make them async,
  //       so we can update them indepenently of each other!
  if (shouldRender) {
    Serial.println("Detected loop refresh request!");

    updateDisplay();
    updateNeopixel();

    shouldRender = false;
  } else {
    delay(100);
  }
}

void initSerial() {
  Serial.begin(115200);

  Serial.println("Serial initialized!");
}

void initDisplay() {
  Serial.println("Initializing display ...");

  // Initialize the TFT display
  tft.init();

  // Set the display rotation
  tft.setRotation(0);

  // Set the background color
  tft.fillScreen(TFT_BLACK);

  // Display a boot screen for 2 seconds
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  // tft.setTextSize(2); // 2x scale
  tft.setCursor((TFT_WIDTH / 2) - 64, (TFT_HEIGHT / 2) - 8, 4); // FIXME: Figure out how to dynamically center text, without using magic numbers
  tft.println("EXCALIBUR");
  delay(2 * 1000);

  // Signal the renderer that it can render
  shouldRender = true;

  Serial.println("Display initialized!");
}

void initNeopixel() {
  Serial.println("Initializing Neopixel ...");

  // TODO: Is this necessary on the ESP32?!
#if defined(__AVR_ATtiny85__) && (F_CPU == 16000000)
  clock_prescale_set(clock_div_1);
#endif

  // FIXME: This seems to crash it on the ESP32, not sure why!
  // Initialize the Neopixel Ring
  pixels.begin();

  // Reset the Neopixel
  // resetNeopixel();

  Serial.println("Neopixel initialized!");
}

void initWiFi() {
  Serial.println("Initializing WiFi ...");

  // Initialize the WiFi module and connect to the network
  WiFi.mode(WIFI_STA);
  WiFi.begin(wifiSSID, wifiPassword);

  // TODO: What about disconnecting and reconnecting?!
  // Wait until the connection is established
  Serial.print("Connecting to '" + String(wifiSSID) + "' ..");
  while (WiFi.status() != WL_CONNECTED) {
    // delay(500); // TODO: Doesn't this seem excessive?
    delay(250);
    Serial.print(".");
  }
  Serial.println("");

  // Print the WiFi SSID and our local client IP address
  Serial.print("Connected to '");
  Serial.print(wifiSSID);
  Serial.print("' with IP address ");
  Serial.println(WiFi.localIP());

  Serial.println("WiFi initialized!");
}

void initWebServer() {
  Serial.println("Initializing web server ...");

  //
  // TODO: Add an endpoint here that can be used to control
  //       both the display and the LED ring, so we can easily test both!
  //       An example of this can be seen at the end of this article:
  //       https://randomnerdtutorials.com/esp32-ota-over-the-air-vs-code/
  //

  // Setup the web server endpoints
  webServer.on("/", HTTP_GET, [](AsyncWebServerRequest *request) {
    request->send(200, "text/plain", "Merlin! What have I done?");
  });

  // Start OTA update server
  AsyncElegantOTA.begin(&webServer);

  // Start the web server
  webServer.begin();

  Serial.print("Web server initialized and ready to receive OTA updates at http://");
  Serial.print(WiFi.localIP());
  Serial.println("/update");
}

void updateDisplay() {
  Serial.println("Updating display ...");

  Serial.println("Display rendering ...");
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  // tft.setTextSize(1); // 1x scale
  tft.setCursor((TFT_WIDTH / 2) - 64, (TFT_HEIGHT / 2) - 8, 4); // FIXME: Figure out how to dynamically center text, without using magic numbers
  tft.println("Hello World");
  Serial.println("Display finished rendering!");
}

void updateNeopixel() {
  Serial.println("Updating Neopixel ...");

  // TODO: Figure out how to do a smooth spinning effect,
  //       with a fading brightness effect (eg. a "trail" effect)

  //
  // TODO: See the links below for more Neopixel examples:
  //
  //       https://randomnerdtutorials.com/esp32-status-indicator-sensor-pcb/
  //       https://learn.adafruit.com/bluetooth-le-midi-controller
  //

  //
  // TODO: Setup Neopixel wiring:
  //
  //       https://learn.adafruit.com/bluetooth-le-midi-controller/wiring
  //
  //       - Data-In from Neopixel to GPIO 6 on ESP32
  //       - 5V Power from Neopixel to 5V on ESP32
  //       - Ground from Neopixel to GND on ESP32
  //

  // Reset the Neopixel ring on every loop
  resetNeopixel();

  // TODO: This delay will ONLY work once we get async implemented and working!
  // Setup a per pixel delay, so we can match the animation speed with the boot screen delay
  int neopixelPerPixelDelay = NEOPIXEL_DELAY / NEOPIXEL_PIXELS;

  // Start the animation loop
  Serial.println("Neopixel animation running ...");
  for (int i = 0; i < NEOPIXEL_PIXELS; i++) {
    pixels.setPixelColor(i, pixels.Color(0, 150, 0));
    pixels.show();
    delay(neopixelPerPixelDelay);
  }

  Serial.println("Neopixel animation completed!");
}

void resetNeopixel() {
  Serial.println("Resetting Neopixel ...");

  pixels.clear();
  pixels.show();
}
