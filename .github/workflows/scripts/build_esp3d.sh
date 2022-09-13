#!/usr/bin/env bash

set -eo pipefail
# set -x

# Get the output directory from the current directory
OUTPUT_DIR=$(pwd)

# Create a temporary directory for the build
WORK_DIR=$(mktemp -d)

# Set the target versions
ESP3D_CHIP="esp8266" ## TODO: Make this user configurable?
ESP3D_VERSION="${1:-v2.1.2}"
ESP3D_WEBUI_VERSION="${2:-v2.1}"
echo "Targeting ESP3D version ${ESP3D_VERSION} and ESP3D-WEBUI version ${ESP3D_WEBUI_VERSION} ..."
echo

# Setup the error handler
trap 'catch' ERR
catch() {
  cleanup
  echo
  echo "Failure detected, aborting!"
  echo
  exit 1
}
cleanup() {
  echo "Cleaning up ..."
  rm -rf "${WORK_DIR}"
  echo
}
function pause(){
  read -s -n 1 -p "Press any key to continue ..."
  echo
}

# Switch to the working directory
echo "Switching to working directory (${WORK_DIR}) ..."
cd "${WORK_DIR}"
echo

# Checkout the specific ESP3D-WEBUI version to a temporary directory
echo "Cloning ESP3D-WEBUI repository ..."
ESP3D_WEBUI_DIR="${WORK_DIR}/esp3d-webui"
git clone --depth 1 --branch "${ESP3D_WEBUI_VERSION}" https://github.com/luc-github/ESP3D-WEBUI.git "${ESP3D_WEBUI_DIR}"
echo

# Switch to the ESP3D-WEBUI directory
echo "Switching to ESP3D-WEBUI directory (${ESP3D_WEBUI_DIR}) ..."
cd "${ESP3D_WEBUI_DIR}"
echo

# Build the ESP3D-WEBUI
echo "Building ESP3D-WEBUI ..."
rm -f index.html.gz
npm install
#npx gulp package
gulp package --lang en
echo

## TODO: Can't we somehow bundle this with the firmware, so it doesn't need to be uploaded separately?!
# Copy the firmware to the output directory
echo "Copying index.html.gz from built ESP3D-WEBUI to output directory ..."
cp -f "${ESP3D_WEBUI_DIR}"/index.html.gz "${GITHUB_WORKSPACE:-${OUTPUT_DIR}}/"
echo

# Checkout the specific ESP3D version to a temporary directory
echo "Cloning ESP3D repository ..."
ESP3D_DIR="${WORK_DIR}/esp3d"
git clone --depth 1 --branch "${ESP3D_VERSION}" https://github.com/luc-github/ESP3D.git "${ESP3D_DIR}"
echo

# Switch to the ESP3D directory
echo "Switching to ESP3D directory (${ESP3D_DIR}) ..."
cd "${ESP3D_DIR}"
echo

## TODO: Figure out how to optionally change the ESP3D default IP address and/or WiFi SSID and/or WiFi password?!
# esp3d/config.h:
#   const char DEFAULT_AP_SSID []  PROGMEM =        "ESP3D";
#   const char DEFAULT_AP_PASSWORD [] PROGMEM = "12345678";
#   const char DEFAULT_STA_SSID []  PROGMEM =       "ESP3D";
#   const char DEFAULT_STA_PASSWORD [] PROGMEM =    "12345678";
#   const byte DEFAULT_IP_VALUE[]   =           {192, 168, 0, 1};
#   const byte DEFAULT_MASK_VALUE[]  =          {255, 255, 255, 0};
#   const long DEFAULT_BAUD_RATE =          115200;
#   const int DEFAULT_WEB_PORT =            80;
#   const int DEFAULT_DATA_PORT =           8888;
#   const char DEFAULT_ADMIN_PWD []  PROGMEM =  "admin";
#   const char DEFAULT_USER_PWD []  PROGMEM =   "user";
#   const char DEFAULT_ADMIN_LOGIN []  PROGMEM =    "admin";
#   const char DEFAULT_USER_LOGIN []  PROGMEM = "user";
#   const char DEFAULT_TIME_SERVER1 []  PROGMEM =   "1.pool.ntp.org";
#   const char DEFAULT_TIME_SERVER2 []  PROGMEM =   "2.pool.ntp.org";
#   const char DEFAULT_TIME_SERVER3 []  PROGMEM =   "0.pool.ntp.org";
#
# Change
# #define DEFAULT_WIFI_MODE           AP_MODE
# to
# #define DEFAULT_WIFI_MODE           CLIENT_MODE
#
# Change
# const char DEFAULT_STA_SSID []  PROGMEM =       "ESP3D";
# to
# const char DEFAULT_STA_SSID []  PROGMEM =       "WIFI_SSID";
#
# Change
# const char DEFAULT_STA_PASSWORD [] PROGMEM =    "12345678";
# to
# const char DEFAULT_STA_PASSWORD [] PROGMEM =    "WIFI_PASSWORD";
#
# Change
# #define DEFAULT_AUTH_TYPE           AUTH_WPA_PSK
# to
# #define DEFAULT_AUTH_TYPE           AUTH_WPA2_PSK
#
pause

## TODO: Can't we somehow bundle this with the firmware, so it doesn't need to be uploaded separately?!
# Copy the firmware to the output directory
echo "Copying index.html.gz from built ESP3D-WEBUI to ESP3D data directory ..."
cp -f "${ESP3D_WEBUI_DIR}"/index.html.gz "${ESP3D_DIR}/esp3d/data/index.html.gz"
echo

# Build the ESP3D firmware
echo "Building ESP3D firmware ..."
pio run -e ${ESP3D_CHIP}
echo

# Copy the firmware to the output directory
echo "Copying firmware to output directory ..."
cp -f "${ESP3D_DIR}"/.pioenvs/${ESP3D_CHIP}/*bin "${GITHUB_WORKSPACE:-${OUTPUT_DIR}}/"
echo

# Cleanup
cleanup

echo "Done!"
exit 0
