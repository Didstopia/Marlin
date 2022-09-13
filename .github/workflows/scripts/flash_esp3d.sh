#!/usr/bin/env bash

set -eo pipefail
# set -x

# Setup the error handler
trap 'catch' ERR
catch() {
  cleanup
  echo
  echo "Failure detected, aborting!"
  echo
  exit 1
}
function pause(){
  read -s -n 1 -p "Press any key to continue ..."
  echo
}

## TODO: Do we need to (or CAN we even) reset the ESP8266?

# Erase flash on the ESP8266
echo "Erasing flash on the ESP8266 ..."
esptool.py --chip esp8266 erase_flash
echo

# Flash the ESP8266 firmware
echo "Flashing ESP3D firmware ..."
# esptool.py --chip esp8266 --port /dev/ttyUSB0 write_flash -fm dio -fs 4MB 0x0 firmware.bin
esptool.py --chip esp8266 write_flash -fm dio -fs 4MB 0x0 firmware.bin
echo

## TODO: Do we need to (or CAN we even) reset the ESP8266?

## TODO: ESP should now show a WiFi AP named "ESP3D" with password "12345678", echo this to the user
echo "ESP3D firmware flashed successfully!"
echo
echo "ESP should now show a WiFi AP named 'ESP3D' with password '12345678'"
echo
echo "Connect to this AP and open up the following URL in your browser:"
echo "http://192.168.0.1"
echo
echo "Upload 'index.html.gz' to the SPIFFS filesystem using the web page uploader,"
echo "then continue configuring the ESP3D through the web interface."
echo
exit 0
