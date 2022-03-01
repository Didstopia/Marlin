#!/usr/bin/env bash

# Ensure we are always at the root of the repository
cd $(realpath $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../../../)

## TODO: Supposedly "-F wttr" should give us the full script path on error, but not sure how to get that?!
# Setup error handling
shopt -s extdebug
declare -F wttr

# Enable debugging
# set -x

# Ensure we are always at the root of the repository
cd $(realpath $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../../../)

source .github/workflows/scripts/configure_build_script.sh

GRID=10
HIGH_SPEED=true

## FIXME: The following are wrong:
## - NOZZLE_TO_PROBE_OFFSET (Configuration.h) - NOTE: This also modifies examples, which should NOT happen!
##   - NOTE: This is very tricky to fix and may cause further issues, so we may just leave it as-is for now..

## BEGIN CONFIGURATION.H

# Set minimum extruder temperature when extruding
configValue EXTRUDE_MINTEMP 170 Marlin/Configuration.h

# Set maximum length to extrude within a single extrusion
configValue EXTRUDE_MAXLENGTH 600 Marlin/Configuration.h

# Set default/custom steps per unit, per axis
configValue DEFAULT_AXIS_STEPS_PER_UNIT "{ 80, 80, 400, 93 }" Marlin/Configuration.h

# Set default/custom maximum feedrate (movement speed)
configValue DEFAULT_MAX_FEEDRATE "{ 200, 200, 5, 25}" Marlin/Configuration.h

# Set default/custom maximum acceleration
configValue DEFAULT_MAX_ACCELERATION "{ 1000, 1000, 100, 10000 }" Marlin/Configuration.h

# Set default/custom maximum acceleration while moving/traveling
configValue DEFAULT_TRAVEL_ACCELERATION 500 Marlin/Configuration.h

# Enable S-Curve Acceleration
configEnable S_CURVE_ACCELERATION Marlin/Configuration.h

# Disable Z axis endstop switch support (we use BLTouch/CRTouch instead)
configDisable Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN Marlin/Configuration.h

# Enable Z homing using a probe
configEnable USE_PROBE_FOR_Z_HOMING Marlin/Configuration.h

# Enable BLTouch/CRTouch support
configEnable BLTOUCH Marlin/Configuration.h

# Set default/custom nozzle offsets
configValue NOZZLE_TO_PROBE_OFFSET "{ -45.8, -5.4, 0 }" Marlin/Configuration.h

# Increase the probing margin (for BLTouch/UBL)
configValue PROBING_MARGIN 20 Marlin/Configuration.h

# Increase X/Y axis feed rate (travel speed) when probing (for BLTouch/UBL)
configValue XY_PROBE_FEEDRATE "(133*60)" Marlin/Configuration.h

# Set min/max probe offsets
configValue Z_PROBE_OFFSET_RANGE_MIN -20 Marlin/Configuration.h
configValue Z_PROBE_OFFSET_RANGE_MAX 20 Marlin/Configuration.h

## TODO: This, and probably others, will also need to be separately enabled, right?
# Enable multiple probings (for BLTouch/UBL)
configValue MULTIPLE_PROBING 2 Marlin/Configuration.h

# Enable Z probe testing (for BLTouch/UBL)
configEnable Z_MIN_PROBE_REPEATABILITY_TEST Marlin/Configuration.h

# Require homing after steppers have deactivated/unlocked (and before trying to move)
configEnable NO_MOTION_BEFORE_HOMING Marlin/Configuration.h
configEnable HOME_AFTER_DEACTIVATE Marlin/Configuration.h

# Increase bed size for probing (for BLTouch/UBL)
configValue X_BED_SIZE 235 Marlin/Configuration.h
configValue Y_BED_SIZE 235 Marlin/Configuration.h

# Extend maximum X position for better probe reach (for BLTouch/UBL)
configValue X_MAX_POS "X_BED_SIZE + 15" Marlin/Configuration.h

# Lower maximum Z position for better mechanical gantry calibration
configValue Z_MAX_POS 250 Marlin/Configuration.h

# Enable filament runout sensor
configEnable FILAMENT_RUNOUT_SENSOR Marlin/Configuration.h

# Set the default/custom runout sensor filament distance
configValue FILAMENT_RUNOUT_DISTANCE_MM 0 Marlin/Configuration.h

# Enable Universal Bed Leveling (UBL)
configEnable AUTO_BED_LEVELING_UBL Marlin/Configuration.h

# Enable leveling after completion (for BLTouch/UBL)
## NOTE: Only enable one of these, not both!
configEnable RESTORE_LEVELING_AFTER_G28 Marlin/Configuration.h

## TODO: Reverting back to 10
# Set default fade height, which helps with warped beds and more uniform results (for BLTouch/UBL)
configValue DEFAULT_LEVELING_FADE_HEIGHT "10.0" Marlin/Configuration.h

# Enable leveling debugging
configEnable DEBUG_LEVELING_FEATURE Marlin/Configuration.h

# Set the leveling grid size for the current firmware configuration
configValue GRID_MAX_POINTS_X $GRID Marlin/Configuration.h

# Increase default mesh inset for UBL
configValue MESH_INSET 10 Marlin/Configuration.h

# Disable UBL automatic mesh saving
configDisable UBL_SAVE_ACTIVE_ON_M500 Marlin/Configuration.h

# Enable safe homing on the Z axis
configEnable Z_SAFE_HOMING Marlin/Configuration.h

# Reduce homing feed rate (homing speed)
configValue HOMING_FEEDRATE_MM_M "{ \(20\*60\), \(20\*60\), \(4\*60\) }" Marlin/Configuration.h

# Enable EEPROM feedback
configEnable EEPROM_CHITCHAT Marlin/Configuration.h

# Clear EEPROM on startup after flashing a new firmware
configEnable EEPROM_INIT_NOW Marlin/Configuration.h

# Enable nozzle parking when idle
configEnable NOZZLE_PARK_FEATURE Marlin/Configuration.h

# Increase Z axis while nozzle parking
configValue NOZZLE_PARK_Z_RAISE_MIN 5 Marlin/Configuration.h

# Enable print counting statistics
configEnable PRINTCOUNTER Marlin/Configuration.h

# Enable software PWM fan control
configEnable FAN_SOFT_PWM Marlin/Configuration.h

# Adjust min/max temperatures
configValue HEATER_0_MINTEMP 5 Marlin/Configuration.h
configValue BED_MINTEMP 5 Marlin/Configuration.h
configValue BED_MAXTEMP 120 Marlin/Configuration.h

# Enable thermal protection for a heated chamber (which we don't have, so this is rather meaningless)
configEnable THERMAL_PROTECTION_CHAMBER Marlin/Configuration.h

# Disable endstops interrupt compatibility
configDisable ENDSTOP_INTERRUPTS_FEATURE Marlin/Configuration.h

## TODO: Should we disable this due to potential issues with Junction Deviation still?
# Disable classic jerk
configDisable CLASSIC_JERK Marlin/Configuration.h

# Disable extrapolating beyond the grid
configDisable EXTRAPOLATE_BEYOND_GRID Marlin/Configuration.h

# Enable bed level corner adjustments
configEnable LEVEL_BED_CORNERS Marlin/Configuration.h

# Enable mesh validation support
configEnable G26_MESH_VALIDATION Marlin/Configuration.h
        
# Turn off display after 5 minutes
configValue TOUCH_IDLE_SLEEP 300 Marlin/Configuration.h

## END OF CONFIGURATION.H



## BEGIN CONFIGURATION_ADV.H

# Enable mainboard/controller fan control
configEnable USE_CONTROLLER_FAN Marlin/Configuration_adv.h
configValue CONTROLLER_FAN_PIN FAN2_PIN Marlin/Configuration_adv.h

# Enable automatic fan control for the extruder and parts cooler
configValue E0_AUTO_FAN_PIN FAN1_PIN Marlin/Configuration_adv.h
configValue COOLER_AUTO_FAN_PIN FAN_PIN Marlin/Configuration_adv.h

## TODO: Why would we keep this disabled? It's quicker, what are the drawbacks?
# Disable quick homing
configDisable QUICK_HOME Marlin/Configuration_adv.h

# Disable power loss recovery
configDisable POWER_LOSS_RECOVERY Marlin/Configuration_adv.h

# Lower homing bump
configValue HOMING_BUMP_MM "{ 4, 4, 2 }" Marlin/Configuration_adv.h

# Enable BLTouch High Speed mode (HS) depending on the firmware configuration
if ($HIGH_SPEED); then
  configValue BLTOUCH_HS_MODE true Marlin/Configuration_adv.h
else
  configDisable BLTOUCH_HS_MODE Marlin/Configuration_adv.h
fi

## TODO: This needs testing!
# Disable adaptive step smoothing
configDisable ADAPTIVE_STEP_SMOOTHING Marlin/Configuration_adv.h

# Adjust slowdown divisor when disabling adaptive step smoothing
configValue SLOWDOWN_DIVISOR 8 Marlin/Configuration_adv.h

# Enable DWIN display beep mute option
configEnable SOUND_MENU_ITEM Marlin/Configuration_adv.h

# Enable additional display features (some are useful when used with OctoPrint for example)
configEnable STATUS_MESSAGE_SCROLLING Marlin/Configuration_adv.h
configEnable LCD_SET_PROGRESS_MANUALLY Marlin/Configuration_adv.h

## TODO: Why would BTT have this disabled?
# Disable dynamic memory allocation in SD card menus
configValue SDSORT_DYNAMIC_RAM false Marlin/Configuration_adv.h

# Set default SD card connection type
configValue SDCARD_CONNECTION ONBOARD Marlin/Configuration_adv.h

# Enable UTF filename support
configEnable UTF_FILENAME_SUPPORT Marlin/Configuration_adv.h

# Enable long filename support
configEnable LONG_FILENAME_HOST_SUPPORT Marlin/Configuration_adv.h

# Enable scrolling filenames
configEnable SCROLL_LONG_FILENAMES Marlin/Configuration_adv.h

# Enable automatic reporting of SD card status
configEnable AUTO_REPORT_SD_STATUS Marlin/Configuration_adv.h

# Enable SD card host drive support
configDisable NO_SD_HOST_DRIVE Marlin/Configuration_adv.h
        
# Configure babystepping
configEnable BABYSTEP_WITHOUT_HOMING Marlin/Configuration_adv.h
configEnable BABYSTEP_ALWAYS_AVAILABLE Marlin/Configuration_adv.h
configEnable DOUBLECLICK_FOR_Z_BABYSTEPPING Marlin/Configuration_adv.h
configEnable BABYSTEP_DISPLAY_TOTAL Marlin/Configuration_adv.h

# Enable emergency parser
configEnable EMERGENCY_PARSER Marlin/Configuration_adv.h

# Enable advanced pausing for filament change
configEnable ADVANCED_PAUSE_FEATURE Marlin/Configuration_adv.h

# Configure filament unload length
configValue FILAMENT_CHANGE_UNLOAD_LENGTH 400 Marlin/Configuration_adv.h

# Configure filament fast load length
configValue FILAMENT_CHANGE_FAST_LOAD_LENGTH 350 Marlin/Configuration_adv.h

# Configure filament fast load feed rate (speed)
configValue FILAMENT_CHANGE_FAST_LOAD_FEEDRATE 6 Marlin/Configuration_adv.h

# Enable head parking during pause and filament change
configEnable PARK_HEAD_ON_PAUSE Marlin/Configuration_adv.h

# Run homing before changing filament
configEnable HOME_BEFORE_FILAMENT_CHANGE Marlin/Configuration_adv.h

# Enable display and g-code support for filament loading and unloading
configEnable FILAMENT_LOAD_UNLOAD_GCODES Marlin/Configuration_adv.h

# Configure hybrid threshold (still disabled by default)
configValue Z_HYBRID_THRESHOLD 20 Marlin/Configuration_adv.h

# Configure sensorless homing (still disably by default)
configValue X_STALL_SENSITIVITY 72 Marlin/Configuration_adv.h
configValue Y_STALL_SENSITIVITY 72 Marlin/Configuration_adv.h
configValue Z_STALL_SENSITIVITY 10 Marlin/Configuration_adv.h
configEnable IMPROVE_HOMING_RELIABILITY Marlin/Configuration_adv.h

# Enable additional reporting etc. features
configEnable AUTO_REPORT_POSITION Marlin/Configuration_adv.h
configEnable M114_DETAIL Marlin/Configuration_adv.h
configEnable REPORT_FAN_CHANGE Marlin/Configuration_adv.h
configEnable HOST_PAUSE_M76 Marlin/Configuration_adv.h

# Enable fan control options in LCD (might not work with DWIN?)
configEnable CONTROLLER_FAN_EDITABLE Marlin/Configuration_adv.h

# Enable showing remaining time (this probably only works with LCDs and not with DWIN?)
configEnable SHOW_REMAINING_TIME Marlin/Configuration_adv.h

# Configure the current multiplier when holding/locked
configValue HOLD_MULTIPLIER "0.3" Marlin/Configuration_adv.h

# Configure stepper motor driver currents
configValue Z_CURRENT 1000 Marlin/Configuration_adv.h

# Enable stepper driver debugging
configEnable TMC_DEBUG Marlin/Configuration_adv.h

# Enable meatpack g-code compression
configEnable MEATPACK_ON_SERIAL_PORT_1 Marlin/Configuration_adv.h

# Enable host actions commands
configEnable HOST_ACTION_COMMANDS Marlin/Configuration_adv.h

# Customize host action commands
configEnable HOST_PROMPT_SUPPORT Marlin/Configuration_adv.h

# Enable mechanical gantry calibration
configEnable MECHANICAL_GANTRY_CALIBRATION Marlin/Configuration_adv.h

# Configure additional options for mechanical gantry calibration
configValue GANTRY_CALIBRATION_CURRENT "Z_CURRENT \/ 3" Marlin/Configuration_adv.h
configValue GANTRY_CALIBRATION_EXTRA_HEIGHT 10 Marlin/Configuration_adv.h
configValue GANTRY_CALIBRATION_FEEDRATE 500 Marlin/Configuration_adv.h
configValue GANTRY_CALIBRATION_COMMANDS_POST \"G28\" Marlin/Configuration_adv.h

# Lower the bootscreen timeout
configValue BOOTSCREEN_TIMEOUT 0 Marlin/Configuration_adv.h

# Increase buffers etc.
configEnable ADVANCED_OK Marlin/Configuration_adv.h
configValue BLOCK_BUFFER_SIZE 64 Marlin/Configuration_adv.h
configValue MAX_CMD_SIZE 96 Marlin/Configuration_adv.h
configValue BUFSIZE 32 Marlin/Configuration_adv.h
configValue TX_BUFFER_SIZE 32 Marlin/Configuration_adv.h

# Set temperature watcher intervals
configValue WATCH_TEMP_PERIOD 20 Marlin/Configuration_adv.h
configValue THERMAL_PROTECTION_BED_PERIOD 20 Marlin/Configuration_adv.h
configValue WATCH_BED_TEMP_PERIOD 60 Marlin/Configuration_adv.h

# Turn off display after 30 seconds
configValue LCD_BACKLIGHT_TIMEOUT 30 Marlin/Configuration_adv.h

## END OF CONFIGURATION_ADV.H
