
#include <stdio.h>

#include "gpio/gpio.h"

int main()
{
    if(!gpio_init())
    {
        printf("Failed!\n");
        return -1;
    }

    gpio_set_output(4, false);

    while(true)
    {
        gpio_write(4, !gpio_read(4));
        sleep(1);
    }
    printf("Ok.\n");
    return 0;
}
