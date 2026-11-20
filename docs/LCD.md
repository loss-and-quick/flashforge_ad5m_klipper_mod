# LCD Display & Touchscreen

The FlashForge Adventurer 5M (AD5M / AD5M Pro) features a 4.3" color touchscreen mounted on the front panel.

## Display Hardware

- **Panel Type**: 4.3" TFT LCD, 800 × 480 resolution, 60 Hz refresh rate.
- **Interface**: Single-link LVDS (VESA-24 pixel format, 24-bit RGB).
- **Physical Pins**: Connected to Port D (`PD0` through `PD9`) via the Allwinner T113 combo D-PHY operating in LVDS mode.
- **Kernel Driver**: Mainline Linux `sun4i-drm` display engine 2 (DE2) driver with `panel-simple`.

## Touchscreen Hardware

- **Type**: 4-wire resistive touch panel.
- **Controller**: Integrated Allwinner Resistive Touch Panel (RTP) controller located at `0x02009c00` (`allwinner,sun8i-ts`).
- **Kernel Driver**: Mainline `sun4i-ts` input driver with reset and bus clock support.
- **Note on Stock Firmware**: The stock vendor device tree contained a dormant Goodix I2C touch node (`gt911`), but physical hardware verification on live units confirmed the actual panel is connected to the built-in resistive RTP interface.
- **Calibration Matrix**: Pre-calibrated in `/etc/pointercal`:
  ```
  15066 -97 -4089040 -221 -11814 40462876 65536 800 480
  ```

## Backlight Control

The LCD backlight is driven by Allwinner PWM channel 7 on pin `PD22`.

### From Klipper Macros
- `LCD_ON` — Turn on backlight (default 50%).
- `LCD_ON VALUE=80` — Set brightness to 80% (range: 1–100).
- `LCD_OFF` — Turn off backlight.

### From Command Line
The brightness can also be controlled directly from the shell:
```bash
backlight 100   # Maximum brightness
backlight 50    # 50% brightness
backlight 0     # Screen off
```
Or directly via sysfs:
```bash
echo 50 > /sys/class/backlight/backlight/brightness
```
