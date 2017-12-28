
#include <stdio.h>

#include "gpio/gpio.h"

int main()
{
    if(!gpio_init())
    {
        printf("Failed!\n");
        return -1;
    }

    gpio_set_input_pull_up(24);
    if(gpio_read(24))
    {
        printf("UP OK\n");
    }
    else
    {
        printf("UP FAILED\n");
    }

    gpio_set_input_pull_down(24);
    if(gpio_read(24))
    {
        printf("DOWN FAILED\n");
    }
    else
    {
        printf("DOWN OK\n");
    }

    gpio_set_output(24, true);
    if(gpio_read(24))
    {
        printf("OUT HIGH OK\n");
    }
    else
    {
        printf("OUT HIGH FAILED\n");
    }

    gpio_write(24, false);
    if(gpio_read(24))
    {
        printf("OUT LOW FAILED\n");
    }
    else
    {
        printf("OUT LOW OK\n");
    }

    gpio_write(24, true);
    if(gpio_read(24))
    {
        printf("OUT HIGH 2 OK\n");
    }
    else
    {
        printf("OUT HIGH 2 FAILED\n");
    }

    printf("Ok.\n");
    return 0;
}
