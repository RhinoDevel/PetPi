# RhinoDevel, Marcel Timm, 2017.09.07

# - This is written in Python 2.7.

# Tested with:
#
# - Commodore/CBM 3001 Series Computer 3032, PET 2001-32N C with Basic 1.0 / ROM v2

# - PET's user port pins interpreted as outputs have LOW level, if PET is powered off.
# - They are "set" to HIGH level (interpreted as outputs) during PET booting up.
# - Initially, the I/O user port pins 0-7 are configured as inputs: PEEK(59459) => 0
# - Such a pin can be configured as output via poking to 59459. E.g. for pin 1: POKE 59459,(PEEK(59459) OR 2) => LOW level (should initially be low..).
# - Output level can be set by poking to 59471. E.g. for pin 1: POKE 59471,(PEEK(59471) OR 2) => HIGH level.

import RPi.GPIO as GPIO
import time

pin_mode = GPIO.BCM # GPIO.BOARD
pin_0_data_to_pet = 4 # BCM
pin_1_read_ack_from_pet = 17 # BCM
pin_2_wrt_rdy_to_pet = 27 # BCM

pet_max_rise_seconds = 2.0*1e-6
pet_max_fall_seconds = 50.0*1e-9

def setup_pins():
    GPIO.setup(pin_0_data_to_pet, GPIO.OUT, initial=GPIO.LOW) # DATA to PET (init. val. shouldn't matter).
    GPIO.setup(pin_1_read_ack_from_pet, GPIO.IN, pull_up_down=GPIO.PUD_DOWN) # READ ACK from PET.
    GPIO.setup(pin_2_wrt_rdy_to_pet, GPIO.OUT, initial=GPIO.HIGH) # WRITE READY to PET.

    print('Pin 0 / ' + str(pin_0_data_to_pet) + ' (DATA to PET): ' + str(GPIO.gpio_function(pin_0_data_to_pet)))
    print('Pin 1 / ' + str(pin_1_read_ack_from_pet) + ' (READ ACK from PET): ' + str(GPIO.gpio_function(pin_1_read_ack_from_pet)))
    print('Pin 2 / ' + str(pin_2_wrt_rdy_to_pet) + ' (WRITE READY to PET): ' + str(GPIO.gpio_function(pin_2_wrt_rdy_to_pet)))

def setup():
    #GPIO.setwarnings(False)
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

def send_bit(b):
    expected_read_ack = get_input(pin_2_wrt_rdy_to_pet)
    wrt_rdy = not expected_read_ack # Just toggles.
    pet_max_seconds = pet_max_rise_seconds if expected_read_ack is GPIO.HIGH else pet_max_fall_seconds
    val = GPIO.LOW

    # Should be an assert (debugging):
    #
    if b not in (0, 1):
        cleanup()
        raise Exception('send_bit : Error: Invalid value given!')

    if b == 1:
        val = GPIO.HIGH

    set_output(pin_0_data_to_pet, val) # DATA to PET.
    set_output(pin_2_wrt_rdy_to_pet, wrt_rdy) # WRITE READY to PET.

    # TODO: Find a way to increase time precision to also increase speed:
    #
    while get_input(pin_1_read_ack_from_pet) is not expected_read_ack:
        stop_time = time.time()+pet_max_seconds        
        while time.time()<stop_time:
            pass
        

def send_byte(b):
    i = 0

    # Should be an assert (debugging):
    #
    if get_input(pin_1_read_ack_from_pet) is not GPIO.LOW:
        cleanup()
        raise Exception('send_byte : Error: READ ACK input must be set to low!')

    # Should be an assert (debugging):
    #
    if get_input(pin_2_wrt_rdy_to_pet) is not GPIO.HIGH:
        cleanup()
        raise Exception('send_byte : Error: WRITE READY output must be set to high!')

    for i in range(0,8):
        send_bit(b>>i&1)

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

    if get_input(pin_1_read_ack_from_pet) is not GPIO.HIGH:
        print('Input must be set to HIGH. Exiting..')
        cleanup()
        return

    # This should be OK, because PET's max. falling time is below 50ns:
    #
    print('Waiting for start signal..')
    if GPIO.wait_for_edge(
            pin_1_read_ack_from_pet,
            GPIO.FALLING,
            timeout=60000) is None:
        cleanup()
	print('Start signal timeout happened.')
        return

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

    t0 = time.time()

    print('Sending payload ('+str(payload_len)+' bytes)..')
    for i in range(payload_len):
        send_byte(payload[i])
    print('Transfer done.')

    t_end = time.time()-t0

    print('Elapsed seconds for payload transfer: '+str(t_end))
    print('Bytes per second for payload transfer: '+str((2+2+payload_len)/t_end))

    cleanup()

    print('Done.')

def main():
    try:
        main_nocatch()
    except KeyboardInterrupt:
        print('Keyboard interrupt detected.')
        cleanup()

main()

# Output test stuff:
#
#print('Key for setup..')
#raw_input()
#setup()
#
#print('Key for setting write ready to LOW..')
#raw_input()
#set_output(pin_2_wrt_rdy_to_pet, GPIO.LOW)
#
#print('Key for setting data to HIGH..')
#raw_input()
#set_output(pin_0_data_to_pet, GPIO.HIGH)
#
#print('Key for cleanup and exit..')
#raw_input()
#cleanup()
