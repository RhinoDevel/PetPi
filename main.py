# RhinoDevel, Marcel Timm, 2017.09.07

# - This is written in Python 2.7.

# Tested with:
#
# - Commodore/CBM 3001 Series Computer 3032, PET 2001-32N C with Basic 1.0 / ROM v2

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
pin_2 = 27 # BCM

wrt_rdy = GPIO.LOW # Also used as initial value [see setup_pins()].

#edge_wait_seconds = 0.001 # Use slightly higher delay on PET.

def setup_pins():
    GPIO.setup(
        pin_0, GPIO.OUT, initial=GPIO.LOW) # DATA to PET (init. val. shouldn't matter).
    GPIO.setup(pin_1, GPIO.IN, pull_up_down=GPIO.PUD_UP) # READ ACK from PET.
    GPIO.setup(pin_2, GPIO.OUT, initial=wrt_rdy) # WRITE READY to PET.

def setup():
    GPIO.setwarnings(False)
    GPIO.setmode(pin_mode)
    setup_pins()

def set_output(pin_nr, val):
    #print('set_output : '+'Setting pin '+str(pin_nr)+' to '+str(val)+'..')
    GPIO.output(pin_nr, val)

def get_input(pin_nr):
    val = GPIO.input(pin_nr)
    #print('get_input : '+'Input at pin '+str(pin_nr)+' is '+str(val)+'.')
    return val

def cleanup():
    print('Cleaning up..')
    GPIO.cleanup()

def send_byte(b):
    global wrt_rdy

    i = 0
    val = GPIO.LOW
    next_edge = GPIO.RISING
    next_wrt_rdy = GPIO.HIGH # wrt_rdy must always be low, here!

    # Should be an assert (debugging):
    #
    if get_input(pin_1) is GPIO.HIGH:
        cleanup()
        raise Exception('send_byte : Error: Input pin must be set to low!')

    # Should be an assert (debugging):
    #
    if wrt_rdy is GPIO.HIGH:
        cleanup()
        raise Exception('send_byte : Error: WRITE READY state must be set to low!')

    for i in range(0,8):
        if (b>>i)&1 == 1:
            val = GPIO.HIGH
        else:
            val = GPIO.LOW
        set_output(pin_0, val) # DATA to PET.

        set_output(pin_2, next_wrt_rdy) # WRITE READY to PET.

        #time.sleep(edge_wait_seconds) # To avoid detecting false edge.

        GPIO.wait_for_edge(pin_1, next_edge) # Waiting for READ ACK from PET.
        if next_edge is GPIO.FALLING:
           next_edge = GPIO.RISING
        else:
           next_edge = GPIO.FALLING

        wrt_rdy, next_wrt_rdy = next_wrt_rdy, wrt_rdy # Swap

def main_nocatch():
    i = -1

    #start_addr = 826 # ROM v2 and v3 tape #2 buffer.
    #payload = [
    #        169, # Immediate LDA.
    #        83, # Heart symbol (yes, it is romantic).
    #        141, # Absolute STA.
    #        0, # Lower byte of 32768 (0x8000 - video RAM start).
    #        128, # Higher byte of 32768.
    #        96 # RTS.
    #    ]
    #
    file_path = raw_input('Please enter PRG file path: ')
    print('"'+file_path+'"')
    payload = list(open(file_path, 'rb').read())
    for i in range(len(payload)):
        payload[i] = ord(payload[i])
    start_addr = payload[0]+256*payload[1]
    del payload[0]
    del payload[0]

    payload_len = len(payload)
    b = -1
    l = -1
    h = -1
    t0 = None
    t_end = None

    setup()

    if get_input(pin_1) is not GPIO.HIGH:
        print('Error: Input must be set to HIGH! Exiting..')
        cleanup()
        return

    print('Waiting for start signal..')
    GPIO.wait_for_edge(pin_1, GPIO.FALLING)

    t0 = time.time()

    print('Starting transfer of 2+2+'+str(payload_len)+' bytes..')
    h = start_addr//256 # ("Python-style") integer division.
    l = start_addr-256*h
    print('Sending start address low byte: '+str(l)+'..')
    send_byte(l)
    print('Sending start address high byte: '+str(h)+'..')
    send_byte(h)
    h = payload_len//256
    l = payload_len-256*h
    print('Sending payload length low byte: '+str(l)+'..')    
    send_byte(l)
    print('Sending payload length high byte: '+str(h)+'..')    
    send_byte(h)
    for i in range(len(payload)):
        print('Sending payload byte at index '+str(i)+' of '+str(len(payload))+': '+str(payload[i])+'..')
        send_byte(payload[i])
    print('Transfer done.')

    t_end = time.time()-t0

    print('Elapsed seconds: '+str(t_end))
    print('Bytes per second: '+str((2+2+payload_len)/t_end))

    cleanup()

    print('Done.')

def main():
    try:
        main_nocatch()
    except KeyboardInterrupt:
        print('Keyboard interrupt detected.')
        cleanup()

main()
