# RhinoDevel, Marcel Timm, 2017.09.07

# Tested with:
#
# - Commodore/CBM 3001 Series Computer 3032, PET 2001-32N C with Basic 2.0

# - PET's user port pins interpreted as outputs have LOW level, if PET is powered off.
# - They are "set" to HIGH level (interpreted as outputs) during PET booting up. 
# - Initially, the I/O user port pins 0-7 are configured as inputs: PEEK(59459) => 0
# - Such a pin can be configured as output via poking to 59459. E.g. for pin 1: POKE 59459,(PEEK(59459) OR 2) => LOW level (maybe not always!).
# - Output level can be set by poking to 59471. E.g. for pin 1: POKE 59471,(PEEK(59471) OR 2) => HIGH level.

import RPi.GPIO as GPIO
import time

pin_mode = GPIO.BCM # GPIO.BOARD
pin_0 = 4 # BCM
pin_1 = 17 # BCM

def setup_pins():
    GPIO.setup(pin_0, GPIO.OUT)
    GPIO.setup(pin_1, GPIO.IN, pull_up_down=GPIO.PUD_UP)

def setup():
    GPIO.setwarnings(False)
    GPIO.setmode(pin_mode)
    setup_pins()

def set_output(pin_nr, val):
    print('Setting pin '+str(pin_nr)+' to '+str(val)+'..')
    GPIO.output(pin_nr, val)

def get_input(pin_nr):
    val = GPIO.input(pin_nr)
    print('Input at pin '+str(pin_nr)+' is '+str(val)+'.')
    return val

def main():
    b = int(raw_input('Enter byte: '))
    val = GPIO.LOW

    setup()
        
    get_input(pin_1)

    for i in range(0,8):
        GPIO.wait_for_edge(pin_1, GPIO.BOTH)
        if (b>>i)&1 == 1:
            val = GPIO.HIGH
        else:
            val = GPIO.LOW
        set_output(pin_0, val)
        time.sleep(0.2)

    time.sleep(2)

    print('Cleaning up..')
    GPIO.cleanup()

    print('Done.')

main()
