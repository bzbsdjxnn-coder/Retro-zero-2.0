#!/usr/bin/env python3
import RPi.GPIO as GPIO
import os
import time

BUTTON = 3  # GPIO3

GPIO.setmode(GPIO.BCM)
GPIO.setup(BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)

try:
    while True:
        if GPIO.input(BUTTON) == 0:
            time.sleep(0.5)
            if GPIO.input(BUTTON) == 0:
                os.system("shutdown -h now")
        time.sleep(0.1)
except KeyboardInterrupt:
    GPIO.cleanup()
