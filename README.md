# PetPi
Raspberry Pi and Commodore PET / CBM communication via GPIO and user port.

Current transfer speed (using ASM receiver on PET): Almost 60 bytes per second (limited by Linux!).

Working features (>v1.1.3):

- Transfer files (e.g. ASM applications) from Pi to PET's non-BASIC memory (e.g. to tape buffers) by using BASIC receiver application (see main.bas file).

- Transfer BASIC PRG files from Pi to PET's BASIC memory by using C or Python sender and ASM receiver application (see main.asm file).

- Autostart retrieved PRG files on PET.

How to:

![Photo of PetPi custom connection between Pi and PET](https://raw.githubusercontent.com/RhinoDevel/PetPi/master/howto.jpg)

- Use (e.g.) CBM prg Studio to create PRG files from BASIC (main.bas) and ASM (main.asm) receiver applications.

- Details about the custom cable to be build (very simple: currently four wires, four resistors and one transistor, only) will follow soon!

- Use C sender application on Pi (see main.c file, etc. - use Makefile to build).

- As an alternative to C use Python sender application on Pi (see main.py file).

- Details about the process will also follow soon!

Features to be implemented:

- Sending data (PRGs) from PET to Pi.

- (Automatically) relocate ASM receiver application in PET memory "out of the way" to be able to store more than BASIC applications in memory during retrieval from Pi.

- ...
