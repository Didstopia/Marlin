#pragma once

// User secrets, eg. for WiFi SSID and password etc.
#include "Secrets.h"

// Required for Arduino library support
#include <Arduino.h>

// Required for async web server support
#include <DNSServer.h>
#ifdef ESP32
#include <WiFi.h>
#include <AsyncTCP.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#include <ESPAsyncTCP.h>
#endif
#include "ESPAsyncWebServer.h"

#include <AsyncElegantOTA.h> // OTA update support

#include <SPI.h>
#include <TFT_eSPI.h>       // Hardware-specific library

#include <FS.h>
#include <SPIFFS.h>
// #include <LittleFS.h>

#include <SD.h>

// Adafruit Neopixel
#include <Adafruit_NeoPixel.h>
// TODO: Is this necessary on the ESP32?!
#ifdef __AVR__
  #include <avr/power.h>
#endif
#define NEOPIXEL_PIN    21    // ESP32 GPIO pin to connect Data-In to
#define NEOPIXEL_PIXELS 16    // Amount of LEDs on the Neopixel Ring
#define NEOPIXEL_DELAY 2000   // Total amount of time for each full animation cycle
