// Configuration file for TFT_eSPI

#define GC9A01_DRIVER

#define TFT_SDA_READ      // This option is for ESP32 ONLY, tested with ST7789 and GC9A01 display only

#define TFT_WIDTH  240 // ST7789 240 x 240 and 240 x 320
#define TFT_HEIGHT 240 // GC9A01 240 x 240

// #define TFT_CS   PIN_D8  // Chip select control pin D8 -> GPIO15 (NodeMCU)
// #define TFT_DC   PIN_D3  // Data Command control pin -> GPIO0 (NodeMCU)
// #define TFT_RST  PIN_D4  // Reset pin (could connect to NodeMCU RST, see next line)
// #define TFT_RST  PIN_EN  // Reset pin (could connect to NodeMCU RST, see next line)
// #define TFT_RST  -1    // Set TFT_RST to -1 if the display RESET is connected to NodeMCU RST or 3.3V
//#define TFT_BL PIN_D1  // LED back-light (only for ST7789 with backlight control pin)
//#define TOUCH_CS PIN_D2     // Chip select pin (T_CS) of touch screen
//#define TFT_WR PIN_D2       // Write strobe for modified Raspberry Pi TFT only

#define TFT_MOSI 23 // In some display driver board, it might be written as "SDA" and so on.
#define TFT_SCLK 18
#define TFT_CS   22  // Chip select control pin
#define TFT_DC   16  // Data Command control pin
#define TFT_RST  4  // Reset pin (could connect to Arduino RESET pin)

#define LOAD_GLCD   // Font 1. Original Adafruit 8 pixel font needs ~1820 bytes in FLASH
#define LOAD_FONT2  // Font 2. Small 16 pixel high font, needs ~3534 bytes in FLASH, 96 characters
#define LOAD_FONT4  // Font 4. Medium 26 pixel high font, needs ~5848 bytes in FLASH, 96 characters
#define LOAD_FONT6  // Font 6. Large 48 pixel font, needs ~2666 bytes in FLASH, only characters 1234567890:-.apm
#define LOAD_FONT7  // Font 7. 7 segment 48 pixel font, needs ~2438 bytes in FLASH, only characters 1234567890:-.
#define LOAD_FONT8  // Font 8. Large 75 pixel font needs ~3256 bytes in FLASH, only characters 1234567890:-.
#define LOAD_GFXFF  // FreeFonts. Include access to the 48 Adafruit_GFX free fonts FF1 to FF48 and custom fonts

#define SMOOTH_FONT

#define SPI_FREQUENCY  66000000

#define SPI_READ_FREQUENCY  20000000

#define SPI_TOUCH_FREQUENCY  2500000
