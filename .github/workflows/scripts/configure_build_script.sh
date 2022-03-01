#!/usr/bin/env bash

## TODO
# - Use more modern configuration files as a base?

# Setup error handling
shopt -s extdebug
declare -F wttr
set -eE -o functrace
failure() {
  local lineno=$1
  local code=$2
  local func=$3
  local msg=$4
  if [ "$CI" = true ]; then
    echo "::error line=$lineno::$msg"
  else
    if [ "${msg}" != "false" ]; then
      echo "^ $3() - line $lineno: $msg"
    else
      echo "^ $3() - line $lineno"
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

# Add GNU tools to path if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"
  PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# Functions for enabling an option
#
# Example:
#   sed -i "s/[^ ]*#define STATUS_MESSAGE_SCROLLING/#define STATUS_MESSAGE_SCROLLING/g" Marlin/Configuration_adv.h
#
configEnable() {
  local option=$1
  local config=$2

  echo "Enabling ${option} in ${config}"

  # Validate function arguments
  if [ -z "$option" ]; then
    echo "configEnable: option is required"
    return 1
  fi

  sed -E -i "s/([^ ]*)(#define ${option})( .*|$)/\2\3/g w /tmp/marlin_patch.log" ${config}
  if [ ! -s /tmp/marlin_patch.log ]; then
    echo "Failed to enable ${option} in ${config}"
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

  echo "Disabling ${option} in ${config}"

  # Validate function arguments
  if [ -z "${option}" ]; then
    echo "configDisable: option is required"
    # return 1
    false
  fi
  if [ -z "${config}" ]; then
    echo "configDisable: config is required"
    # return 1
    false
  fi

  sed -E -i "s/([^ ]*)(#define ${option})( .*|$)/\1\/\/\2\3/g w /tmp/marlin_patch.log" ${config}
  if [ ! -s /tmp/marlin_patch.log ]; then
    echo "Failed to disable ${option} in ${config}"
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

  echo "Setting ${key} to ${value} in ${config}"

  # Validate function arguments
  if [ -z "${key}" ]; then
    echo "configValue: key is required"
    # return 1
    false
  fi
  if [ -z "${value}" ]; then
    echo "configValue: value is required"
    # return 1
    false
  fi
  if [ -z "${config}" ]; then
    echo "configValue: config is required"
    # return 1
    false
  fi

  sed -E -i "s/([^ \n]?)(#define ${key}[ ]+)(\".*\"|\(.*\)|\{.*\}|[-0-9a-zA-Z_.]*)+?([ ]?.*)/\1\2${value}\4/g w /tmp/marlin_patch.log" ${config}
  # set -x
  if [ ! -s /tmp/marlin_patch.log ]; then
    echo "Failed to set ${key} to ${value} in ${config}"
    # return 1
    false
  fi

  ## TODO: This may or may not cause issues, so long as we keep this in mind..
  # Check if the option is already enabled
  if grep -Eiq "[\/]+#define ${key}( +)" ${config}; then
    # Forcibly enable the option
    echo "> NOTICE: ${key} in ${config} is disabled, forcibly enabling"
    configEnable ${key} ${config}
  fi
}

# Function for setting up the configuration files
setupConfigs() {
  # Copy the latest default Ender 3 V2 config files in place
  echo "Applying default configuration files"

  # Download the latest default configuration files for the current branch
  if [[ ! -d "Configurations" ]]; then
    # If running in CI, use the branch from there, otherwise use the current branch
    if [ "$CI" = true ]; then
      local branch=${{ env.TARGET_BRANCH }}
    else
      # local branch=$(git rev-parse --abbrev-ref HEAD)
      local branch="bugfix-2.0.x"
    fi
    git clone --quiet --branch ${branch} --depth 1 https://github.com/MarlinFirmware/Configurations.git Configurations
  fi

  cp "Configurations/config/examples/Creality/Ender-3 V2/CrealityV422/CrealityUI/Configuration.h" Marlin/Configuration.h
  cp "Configurations/config/examples/Creality/Ender-3 V2/CrealityV422/CrealityUI/Configuration_adv.h" Marlin/Configuration_adv.h
}

# Function for patching the build details
patchBuildDetails() {
  echo "Patching build details"

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

# Function for patching DWIN support with Jyers UI
patchDWIN() {
  # Check if the error is already disabled
  if ! grep -Eiq "[\/]+(#error \"DWIN_CREALITY_LCD requires a custom cable.*)( .*|$)" Marlin/src/pins/stm32g0/pins_BTT_SKR_MINI_E3_V3_0.h; then
    echo "Patching DWIN support"

    # Disable the error about requiring a custom cable for the DWIN display
    sed -i -E "s/([^ ]*)(#error \"DWIN_CREALITY_LCD requires a custom cable.*)( .*|$)/\1\/\/\2\3/g" Marlin/src/pins/stm32g0/pins_BTT_SKR_MINI_E3_V3_0.h
    if [ ! -s /tmp/marlin_patch.log ]; then
      echo "Failed to patch DWIN support"
      # return 1
      false
    fi
  fi

  # Fix the DWIN LCD check to take into account Jyers UI
  sed -E -i "s/#if EITHER\(DWIN_CREALITY_LCD, IS_DWIN_MARLINUI\)/#if HAS_DWIN_E3V2 \|\| IS_DWIN_MARLINUI/g" Marlin/src/pins/stm32g0/pins_BTT_SKR_MINI_E3_V3_0.h
}

# Function for patching sane configuration defaults
patchDefaults() {
  echo "Patching sane configuration defaults"

  # Set the author
  configValue STRING_CONFIG_H_AUTHOR \"\(Didstopia,\ BTT-SKR-Mini-E3-V3.0\)\" Marlin/Configuration.h

  # Fix the serial port
  configValue SERIAL_PORT -1 Marlin/Configuration.h
  
  # Change to the correct motherboard
  configValue MOTHERBOARD BOARD_BTT_SKR_MINI_E3_V3_0 Marlin/Configuration.h
  
  # Change to the correct baud rate
  configValue BAUDRATE 250000 Marlin/Configuration.h
  
  # Set a custom machine name
  configValue CUSTOM_MACHINE_NAME \"Ender-3\ V2\ \(BTT\ SKR\ Mini\ E3\)\" Marlin/Configuration.h

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
  configDisable DWIN_CREALITY_LCD Marlin/Configuration.h
  configEnable DWIN_CREALITY_LCD_JYERSUI Marlin/Configuration.h

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

# Prepare the config files on startup
setupConfigs

# Apply sane defaults on startup
patchBuildDetails
patchDWIN
patchDefaults
