# Things To Do

Prioritized tasks related to this project/repository, and to the very specific custom builds/hardware.

See [here](https://code.visualstudio.com/blogs/2020/05/06/github-issues-integration) and [here](https://code.visualstudio.com/docs/editor/github) for the documentation on VSCode's GitHub integration.

## Critical

- [ ] Try disabling `SDCARD_CONNECTION`, since this should cause the board itself to figure out the correct SD card connection

- [ ] Try lowering `ENCODER_PULSES_PER_STEP` from `4` to `3` or `2`, as the stock Creality DWIN display's rotary encoder seems to not register when changing direction and a single step is produced, requiring an additional step to register (must be a bug, but not sure where/why or if it's actually a hardware fault or not)

- [ ] Try enabling `ADAPTIVE_STEP_SMOOTHING` to see if it works fine with it enabled (most BTT boards recommend or require it to be disabled)

- [ ] Try enabling `ENDSTOP_INTERRUPTS_FEATURE` to see if it works fine with it enabled (most BTT boards recommend or require it to be disabled)

- [ ] Try enabling `SPEAKER` with the BTT display, as it should then be able to display tones at different frequencies etc.

- [ ] Switch our software to use baud rate of 115200 again, as the higher baud rate is unnecessary (I feel like?)

- [ ] Update Cura to match our new/default speeds, acceleration etc.

- [ ] Calibrate flowrate (may need other calibrations first!)

- [ ] Recalibrate linear advance and configure in firmware (likely needs other calibrations first!)
      -> We currently use a K value of 0.15

- [ ] Install filament sensor and adjust firmware values for the sensor/filament length

- [ ] Recalibrate retraction and enable/configure firmware retraction (remember to enable in Cura also)

- [ ] Probing position is never at the cented of the bed, X seems okay but Y is way too far in the positive numbers

- [ ] Implement an easy way to run these builds locally in Docker (I guess with `act` we could still do that, but it's still a bit buggy)

- [ ] Implement BTT TFT display support (with dual mode?), possibly also enabling `BTT_TFT35_SPI_V1_0`? (see [here](https://github.com/bigtreetech/BIGTREETECH-TouchScreenFirmware), [here](https://github.com/bigtreetech/BTT-E3-RRF/issues/3) and most importantly [here](https://www.reddit.com/r/BIGTREETECH/comments/t2mvyw/skr_mini_e3_v2_marlin_settings_with_btt_tft35/))
  - [ ] Enable and configure `CUSTOM_MENU_MAIN`, `CUSTOM_MENU_CONFIG`, `CUSTOM_USER_BUTTONS` with the BTT display

## High

- [ ] Research/implement MPC builds (Didstopia/Marlin#4)

- [ ] Research/implement `DIRECT_STEPPING`

## Medium

- [ ] Try a different language, especially with the BTT TFT (eg. `LCD_LANGUAGE` set to `fi` instead of `en`)

## Low

- [ ] Test `TEMP_STAT_LEDS` with a Neopixel RGB LED strip to change colors based on the current temperatures

- [ ] Implement PSU control support

- [ ] Implement Neopixel RGB LED support with `NEOPIXEL_LED` (WARNING: See the notes about mosfets and power handling first!)

- [ ] Implement [automatic patch file generation](https://stackoverflow.com/questions/9980186/how-to-create-a-patch-for-a-whole-directory-to-update-it) for the entire repository (Didstopia/Marlin#3)

- [ ] Test various "easter eggs" like games in the firmware (with the BTT display running in LCD mode)

- [ ] Try enabling `POWER_MONITOR_CURRENT` and `POWER_MONITOR_VOLTAGE` (`#error "POWER_MONITOR_CURRENT requires a valid POWER_MONITOR_CURRENT_PIN."`)
