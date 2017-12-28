
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

    //gpio_set_output

    printf("Ok.\n");
    return 0;
}
