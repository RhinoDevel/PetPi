# RhinoDevel, Marcel Timm, 2017.09.07

import RPi.GPIO as GPIO
import time

pin_mode = GPIO.BCM # GPIO.BOARD
pin_0 = 4 # BCM

def setup_pins():
    GPIO.setup(pin_0, GPIO.OUT)

def setup():
    GPIO.setwarnings(False)
    GPIO.setmode(pin_mode)
    setup_pins()

def set_output(pin_nr, val):
    print('Setting pin '+str(pin_nr)+' to '+str(val)+'..')
    GPIO.output(pin_nr, val)

def main():
    b = 137
    val = GPIO.LOW

    setup()

    print('Initialising..')
    set_output(pin_0, GPIO.LOW)
    time.sleep(2.5) # MAGIC

    print('Transfering..')

    for i in range(0,8):
        if (b>>i)&1 == 1:
            val = GPIO.HIGH
        else:
            val = GPIO.LOW
        set_output(pin_0, val)
        time.sleep(1)

    raw_input('Press ENTER to exit.')

    print('Cleaning up..')
    GPIO.cleanup()

    print('Done.')

main()
