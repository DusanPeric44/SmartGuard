#include "FlashManager.h"

namespace
{
  enum class FlashMode
  {
    Off,
    On,
    Blink
  };

  FlashMode mode = FlashMode::Off;
  uint32_t intervalMs = 1000;
  uint32_t lastToggleMs = 0;
  bool isOn = false;

  void writeState(bool on)
  {
    digitalWrite(SMARTGUARD_FLASH_PIN, on ? HIGH : LOW);
    isOn = on;
  }
}

void setupFlashManager()
{
  pinMode(SMARTGUARD_FLASH_PIN, OUTPUT);
  writeState(false);
  mode = FlashMode::Off;
}

void flashBlink(uint32_t interval)
{
  intervalMs = interval == 0 ? 1000 : interval;
  lastToggleMs = millis();
  mode = FlashMode::Blink;
  writeState(false);
}

void flashOn()
{
  mode = FlashMode::On;
  writeState(true);
}

void flashOff()
{
  mode = FlashMode::Off;
  writeState(false);
}

void flashUpdate()
{
  if (mode != FlashMode::Blink)
  {
    return;
  }

  const uint32_t now = millis();
  if (now - lastToggleMs >= intervalMs)
  {
    lastToggleMs = now;
    writeState(!isOn);
  }
}
