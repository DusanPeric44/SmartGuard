#ifndef FLASH_MANAGER_H
#define FLASH_MANAGER_H

#include <Arduino.h>

#ifndef SMARTGUARD_FLASH_PIN
#define SMARTGUARD_FLASH_PIN 4
#endif

void setupFlashManager();
void flashBlink(uint32_t intervalMs);
void flashOn();
void flashOff();
void flashUpdate();

#endif

