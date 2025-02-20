#!/usr/bin/env bash

# set -x

## TODO
# - Use more modern configuration files as a base?

SOURCE_ONLY="${1:-false}"
DISPLAY_TYPE="${2:-"MarlinUI"}"
# DISPLAY_TYPE="${2:-"CrealityUI"}"

# Define some colors for the terminal
COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_PURPLE="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_GRAY="\033[37m"
COLOR_DARK_GRAY="\033[90m"
COLOR_WHITE="\033[97m"

# Function for stripping terminal colors
stripColors() {
  echo "$@" | sed -r 's/\\033\[[0-9]{1,3}m//g'
}

# Setup error handling
shopt -s extdebug
# declare -F wttr
set -eE -o functrace
failure() {
  local lineno=$1
  local code=$2
  local func=$3
  local msg=$4
  ## FIXME: Somehow figure out the source file of the error,
  ##        eg. if it's this file or another file that calls/sources this file,
  ##        then log the file and line number in both CI and locally!
  if [ "$CI" = true ]; then
    msg=$(stripColors $msg)
    echo "::error line=$lineno::$msg"
  else
    if [ "${msg}" != "false" ]; then
      echo -e "${COLOR_RED}^ $3() - line $lineno: $msg${COLOR_RESET}"
    else
      echo -e "${COLOR_RED}^ $3() - line $lineno${COLOR_RESET}"
    fi
  fi
}
# BASH_SOURCE=([0]="./test_build_script.sh")
trap 'failure ${LINENO} $? ${FUNCNAME:-main} "$BASH_COMMAND"' ERR
# trap 'failure ${LINENO} $? ${FUNCNAME:-MAIN} "$BASH_COMMAND"' RETURN
# trap 'failure ${LINENO} $? "$BASH_COMMAND"' EXIT
# trap '( set -o posix ; set ) | less' ERR

# Ensure we are always at the root of the repository
cd $(realpath $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../../../)

# Detect if we're running in a CI environment
CI=${CI:-false}

# Function for logging "debug" messages
debug() {
  if [ "$CI" = true ]; then
    msg=$(stripColors $@)
    echo "::debug title=DEBUG::$msg"
  # else
  #   echo -e "  ${COLOR_DARK_GRAY}[DEBUG]${COLOR_RESET} $@"
  fi
  # Always print colored debug messages
  echo -e "  ${COLOR_DARK_GRAY}[DEBUG]${COLOR_RESET} $@"
}

# Function for logging "notice" messages
notice() {
  if [ "$CI" = true ]; then
    msg=$(stripColors $@)
    echo "::notice title=NOTICE::$msg"
  # else
  #   echo -e "  ${COLOR_WHITE}[NOTICE]${COLOR_RESET} $@"
  fi
  # Always print colored notice messages
  echo -e "  ${COLOR_WHITE}[DEBUG]${COLOR_RESET} $@"
}

# Function for logging "warning" messages
warning() {
  if [ "$CI" = true ]; then
    msg=$(stripColors $@)
    echo "::warning title=WARNING::$msg"
  else
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $@"
  fi
}

# Function for logging "error" messages
error() {
  if [ "$CI" = true ]; then
    msg=$(stripColors $@)
    echo "::error title=ERROR::$msg"
  else
    echo -e "  ${COLOR_RED}[ERROR]${COLOR_RESET} $@"
  fi
}

## FIXME: This stopped working for whatever reason, so needs fixing
# Fix environment variables when running locally
# if [ ! -z "${ACT}" ]; then
#   set -x
#   printenv
#   echo "GITHUB_ENV=${GITHUB_ENV}"
#   cat $GITHUB_ENV
#   TARGET_BRANCH=$(cat $GITHUB_ENV | grep TARGET_BRANCH | cut -d '=' -f2)
#   echo "ACT detected, setting TARGET_BRANCH to $TARGET_BRANCH"
#   set +x
# fi

# Figure out the target branch
# (mainly used for default configuration files)
TARGET_BRANCH=${TARGET_BRANCH:-bugfix-2.1.x}
if [ "$TARGET_BRANCH" = "2.1.x" ]; then
  warning "Target branch is 2.1.x, but this was renamed to import-2.1.x in Marlin configuration repository, so we'll use that instead!"
  ## FIXME: Marlin now complains that we should never build with the import-* branches, but use bugfix-* or release-* branches instead?!
  # TARGET_BRANCH="import-2.1.x"
  # TARGET_BRANCH="bugfix-2.1.x"
  TARGET_BRANCH="release-2.1"
elif [ ! "$TARGET_BRANCH" = "bugfix-2.1.x" ]; then
  warning "Unsupported branch detected: '$TARGET_BRANCH', defaulting to bugfix-2.1.x!"
  TARGET_BRANCH="bugfix-2.1.x"
fi

# Add GNU tools to path if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"
  PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"
  if [ ! -f "$(brew --prefix)/opt/gnu-sed/libexec/gnubin/sed" ]; then
    warning "GNU sed is missing! Attempting to install..."
    brew install -q gnu-sed || false
  fi
fi

# Functions for enabling an option
#
# Example:
#   sed -i "s/[^ ]*#define STATUS_MESSAGE_SCROLLING/#define STATUS_MESSAGE_SCROLLING/g" Marlin/Configuration_adv.h
#
configEnable() {
  local option=$1
  local config=$2

  debug "Enabling ${COLOR_GREEN}${option}${COLOR_RESET} in ${COLOR_CYAN}${config}${COLOR_RESET}"

  # Validate function arguments
  if [ -z "$option" ]; then
    error "configEnable: option is required"
    return 1
  fi

  sed -E -i "s/([^ ]*)(#define ${option})( .*|$)/\2\3/g w /tmp/marlin_patch.log" "$config"
  if [ ! -s /tmp/marlin_patch.log ]; then
    error "Failed to enable ${COLOR_GREEN}${option}${COLOR_RESET} in ${COLOR_CYAN}${config}${COLOR_RESET}"
    # return 1
    false
  fi
}

# Functions for disabling an option
#
# Example:
#   sed -i "s/[^ ]*#define UBL_SAVE_ACTIVE_ON_M500/\/\/#define UBL_SAVE_ACTIVE_ON_M500/g" Marlin/Configuration.h
#
configDisable() {
  local option=$1
  local config=$2

  debug "Disabling ${COLOR_GREEN}${option}${COLOR_RESET} in ${COLOR_CYAN}${config}${COLOR_RESET}"

  # Validate function arguments
  if [ -z "${option}" ]; then
    error "configDisable: option is required"
    # return 1
    false
  fi
  if [ -z "${config}" ]; then
    error "configDisable: config is required"
    # return 1
    false
  fi

  sed -E -i "s/([^ ]*)(#define ${option})( .*|$)/\1\/\/\2\3/g w /tmp/marlin_patch.log" "$config"
  if [ ! -s /tmp/marlin_patch.log ]; then
    error "Failed to disable ${COLOR_GREEN}${option}${COLOR_RESET} in ${COLOR_CYAN}${config}${COLOR_RESET}"
    # return 1
    false
  fi
}

# Functions for replacing an option's value
#
# Example:
#   sed -i "s/#define EXTRUDE_MINTEMP .*/#define EXTRUDE_MINTEMP 170/g" Marlin/Configuration.h
#
configValue() {
  local key=$1
  local value=$2
  local config=$3

  debug "Setting ${COLOR_GREEN}${key}${COLOR_RESET} to ${COLOR_YELLOW}${value}${COLOR_RESET} in ${COLOR_CYAN}${config}${COLOR_RESET}"

  # Validate function arguments
  if [ -z "${key}" ]; then
    error "configValue: key is required"
    # return 1
    false
  fi
  if [ -z "${value}" ]; then
    error "configValue: value is required"
    # return 1
    false
  fi
  if [ -z "${config}" ]; then
    error "configValue: config is required"
    # return 1
    false
  fi

  sed -E -i "s/([^ \n]?)(#define ${key}[ ]+)(\".*\"|\(.*\)|\{.*\}|[-0-9a-zA-Z_.]*)+?([ ]?.*)/\1\2${value}\4/g w /tmp/marlin_patch.log" "$config"
  # set -x
  if [ ! -s /tmp/marlin_patch.log ]; then
    error "Failed to set ${COLOR_GREEN}${key}${COLOR_RESET} to ${COLOR_YELLOW}${value}${COLOR_RESET} in ${COLOR_CYAN}${config}${COLOR_RESET}"
    # return 1
    false
  fi

  ## TODO: This may or may not cause issues, so long as we keep this in mind..
  # Check if the option is already enabled
  if grep -Eiq "[\/]+#define ${key}( +)" ${config}; then
    # Forcibly enable the option
    debug "Option ${COLOR_GREEN}${key}${COLOR_RESET} in ${COLOR_CYAN}${config}${COLOR_RESET} is disabled, forcibly enabling"
    configEnable ${key} ${config}
  fi
}

# Function for setting up the configuration files
setupConfigs() {
  # Copy the latest default Ender 3 V2 config files in place
  debug "Applying default configuration files"

  ## TODO: Actually check for updates to the configuration branch instead of just flat out deleting it and redownloading
  rm -rf Configurations

  # Download the latest default configuration files for the current branch
  if [[ ! -d "Configurations" ]]; then
    git clone --quiet --branch ${TARGET_BRANCH} --depth 1 https://github.com/MarlinFirmware/Configurations.git Configurations
  fi

  debug "Applying display configuration files for ${COLOR_YELLOW}${DISPLAY_TYPE}${COLOR_RESET}"
  cp -f "Configurations/config/examples/Creality/Ender-3 V2/BigTreeTech SKR Mini E3 v3/${DISPLAY_TYPE}/Configuration.h" Marlin/Configuration.h
  cp -f "Configurations/config/examples/Creality/Ender-3 V2/BigTreeTech SKR Mini E3 v3/${DISPLAY_TYPE}/Configuration_adv.h" Marlin/Configuration_adv.h

  # Apply custom boot screen stuff
  # cp -f ".github/workflows/resources/_Bootscreen.h" Marlin/_Bootscreen.h
  # configEnable SHOW_CUSTOM_BOOTSCREEN Marlin/Configuration.h
  # ## FIXME: This requires more work and research, as it requires "frames" of bitmaps setup in a specific way
  # # configEnable BOOT_MARLIN_LOGO_ANIMATED Marlin/Configuration_adv.h

  ## FIXME: Can't disable this, Marlin just wants to show dual boot screens with double the timeout..
  # Disable Marlin boot screen when using a custom boot screen
  # configDisable SHOW_BOOTSCREEN Marlin/Configuration.h

  # Adjust the boot screen timeout
  # configValue BOOTSCREEN_TIMEOUT 2000 Marlin/Configuration_adv.h
  # configValue BOOTSCREEN_TIMEOUT 1000 Marlin/Configuration_adv.h

  # Disable boot screen
  configDisable SHOW_BOOTSCREEN Marlin/Configuration.h
  configValue BOOTSCREEN_TIMEOUT 0 Marlin/Configuration_adv.h

  # Enable games
  # configEnable MARLIN_BRICKOUT Marlin/Configuration_adv.h
  # configEnable MARLIN_INVADERS Marlin/Configuration_adv.h
  # configEnable MARLIN_SNAKE Marlin/Configuration_adv.h
  # configEnable GAMES_EASTER_EGG Marlin/Configuration_adv.h
}

# Function for patching the build details
patchBuildDetails() {
  debug "Patching build details"

  # Patch build date
  local DIST_DATE=$( date +"%Y-%m-%d" )
  configValue STRING_DISTRIBUTION_DATE \"$DIST_DATE\" Marlin/src/inc/Version.h
  configValue STRING_DISTRIBUTION_DATE \"$DIST_DATE\" Marlin/Version.h

  # Patch build information
  configValue MACHINE_NAME \"Ender\ 3\ V2\" Marlin/src/inc/Version.h
  configValue SOURCE_CODE_URL \"github.com\\/Didstopia\\/Marlin\" Marlin/src/inc/Version.h
  configValue WEBSITE_URL \"Didstopia\\/Marlin\" Marlin/src/inc/Version.h

  ## TODO: Patch build number or version, somewhere, somehow?
}

# # Function for patching DWIN support with Jyers UI
# patchDWIN() {
#   # Check if the error is already disabled
#   if ! grep -Eiq "[\/]+(#error \".*DWIN_CREALITY_LCD requires a custom cable.*)( .*|$)" Marlin/src/pins/stm32g0/pins_BTT_SKR_MINI_E3_V3_0.h; then
#     debug "Patching DWIN support"

#     # Disable the error about requiring a custom cable for the DWIN display
#     sed -i -E "s/([^ ]*)(#error \".*DWIN_CREALITY_LCD requires a custom cable.*)( .*|$)/\1\/\/\2\3/g" Marlin/src/pins/stm32g0/pins_BTT_SKR_MINI_E3_V3_0.h
#     if [ ! -s /tmp/marlin_patch.log ]; then
#       error "Failed to remove DWIN custom cable error"
#       # return 1
#       false
#     fi
#   fi

#   ## TODO: Check if this is fixed, because it should now be?
#   ## FIXME: This can be removed once the following PR is merged to both bugfix-2.1.x and 2.1.x branches!
#   ##        https://github.com/MarlinFirmware/Marlin/pull/23879
#   # Fix Ender 3 V2 DWIN display bug, where it incorrectly shows the progress bar on startup
#   # sed -i -E "s/(.+, IS_DWIN_MARLINUI, EXTENSIBLE_UI)(\))(.*|$)/\1, HAS_DWIN_E3V2\2\3/g" Marlin/src/inc/Conditionals_post.h
#   # if [ ! -s /tmp/marlin_patch.log ]; then
#   #   error "Failed to patch DWIN progress bar bug"
#   #   # return 1
#   #   false
#   # fi

#   ## TODO: This should also be fixed now, so test to see if it is?
#   # Fix the DWIN LCD check to take into account Jyers UI
#   # sed -E -i "s/#if EITHER\(DWIN_CREALITY_LCD, IS_DWIN_MARLINUI\)/#if HAS_DWIN_E3V2 \|\| IS_DWIN_MARLINUI/g" Marlin/src/pins/stm32g0/pins_BTT_SKR_MINI_E3_V3_0.h
#   # if [ ! -s /tmp/marlin_patch.log ]; then
#   #     error "Failed to patch DWIN Jyers UI support"
#   #   # return 1
#   #   false
#   # fi
# }

## FIXME: Disable if/when our custom pull request/patch goes through!
# Function for adding the ability to disable the buzzer on the LCD
# patchBuzzer() {
#   debug "Patching Marlin to allow disabling the buzzer on the LCD"

#   ## FIXME: Temporary hack!
#   if ! grep -Eiq "DISABLE_BUZZER_DEFAULT" Marlin/Configuration.h; then
#     echo "//#define DISABLE_BUZZER_DEFAULT" >> Marlin/Configuration.h
#   fi

#   # # Add the ability to disable the buzzer on the LCD
#   # sed -i -E "s/^([ ]{2})??(TERN_\(SOUND_MENU_ITEM, ui\.buzzer_enabled = )(true)(\);.*)$/\1#ifdef DISABLE_BUZZER_DEFAULT\n\1\1\2false\4\n\1#else\n\1\1\2true\4\n\1#endif/" Marlin/src/module/settings.cpp
#   # if [ ! -s /tmp/marlin_patch.log ]; then
#   #   error "Failed to patch DWIN buzzer disabling support"
#   #   # return 1
#   #   false
#   # fi

#   # # Add the DISABLE_BUZZER_DEFAULT definition to the Marlin configuration
#   # grep -Eiwq "#define DISABLE_BUZZER_DEFAULT" Marlin/src/module/settings.cpp || \
#   # sed -i -E "s/([ ]*)[^ ]*(#define SOUND_MENU_ITEM.*)/\0\n\1\/\/#define DISABLE_BUZZER_DEFAULT    \/\/ Disable the buzzer by default/" Marlin/Configuration_adv.h
#   # if [ ! -s /tmp/marlin_patch.log ]; then
#   #   error "Failed to add DISABLE_BUZZER_DEFAULT definition"
#   #   # return 1
#   #   false
#   # fi
# }

## TODO: Check the status of this, if it's already been fixed properly upstream?
# # Function for patching the advance pause prompt so it doesn't hang in the UI
# patchAdvancedPausePrompt() {
#   debug "Patching advanced pause prompt UI hanging"

#   # Fix the advanced pause prompt UI hanging
#   sed -i -E 's/(.*[ ]*case PAUSE_MESSAGE_OPTION:[ ]*)(CrealityDWIN\.Popup_Handler\(PurgeMore\);)([ ]*)(break;)/\1pause_menu_response = PAUSE_RESPONSE_WAIT_FOR;\3\2\3\4/' Marlin/src/lcd/e3v2/jyersui/dwin.cpp
#   if [ ! -s /tmp/marlin_patch.log ]; then
#       error "Failed to patch advanced pause prompt UI hanging"
#     # return 1
#     false
#   fi
# }

# Function for patching sane configuration defaults
patchDefaults() {
  debug "Patching sane configuration defaults"

  # Set the author
  configValue STRING_CONFIG_H_AUTHOR \"\(Didstopia,\ BTT-SKR-Mini-E3-V3.0\)\" Marlin/Configuration.h

  # Fix the serial port
  configValue SERIAL_PORT -1 Marlin/Configuration.h
  
  # Change to the correct motherboard
  configValue MOTHERBOARD BOARD_BTT_SKR_MINI_E3_V3_0 Marlin/Configuration.h
  
  # Change to the correct baud rate
  # configValue BAUDRATE 250000 Marlin/Configuration.h
  configValue BAUDRATE 115200 Marlin/Configuration.h

  # Set a custom machine name
  configValue CUSTOM_MACHINE_NAME \"Rasputin\" Marlin/Configuration.h

  # Change the motor drivers
  configValue X_DRIVER_TYPE TMC2209 Marlin/Configuration.h
  configValue Y_DRIVER_TYPE TMC2209 Marlin/Configuration.h
  configValue Z_DRIVER_TYPE TMC2209 Marlin/Configuration.h
  configValue E0_DRIVER_TYPE TMC2209 Marlin/Configuration.h

  # Invert axis motor directions
  configValue INVERT_X_DIR true Marlin/Configuration.h
  configValue INVERT_Y_DIR true Marlin/Configuration.h
  configValue INVERT_Z_DIR false Marlin/Configuration.h
  configValue INVERT_E0_DIR true Marlin/Configuration.h

  # Switch from Creality UI to Jyers UI
  # configDisable DWIN_CREALITY_LCD Marlin/Configuration.h
  # configEnable DWIN_CREALITY_LCD_JYERSUI Marlin/Configuration.h

  # Configure default stepper motor driver currents
  configValue X_CURRENT 580 Marlin/Configuration_adv.h
  configValue Y_CURRENT 580 Marlin/Configuration_adv.h
  configValue Z_CURRENT 580 Marlin/Configuration_adv.h
  configValue E0_CURRENT 650 Marlin/Configuration_adv.h

  # Configure stepper motor driver currents when homing
  configValue X_CURRENT_HOME "X_CURRENT \/ 2" Marlin/Configuration_adv.h
  configValue Y_CURRENT_HOME "Y_CURRENT \/ 2" Marlin/Configuration_adv.h
  configValue Z_CURRENT_HOME "Z_CURRENT \/ 2" Marlin/Configuration_adv.h

  # Change the default chopper voltage from 12V to 24V
  configValue CHOPPER_TIMING CHOPPER_DEFAULT_24V Marlin/Configuration_adv.h
}

if [ "$SOURCE_ONLY" = false ]; then
  debug "Applying patches, source only option is disabled or not set"

  # Prepare the config files on startup
  setupConfigs

  # Apply sane defaults on startup
  patchBuildDetails

  # Patch the DWIN Jyers UI support
  # patchDWIN

  # Patch the ability to disable the buzzer on the LCD
  # patchBuzzer

  # Patch the advanced pause prompt UI hanging
  # patchAdvancedPausePrompt

  # Patch sane configuration defaults
  patchDefaults
else
  debug "Skipping patching of configuration files, source only option enabled"
fi
