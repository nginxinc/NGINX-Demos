### Load generating Raspberry Pi frontend

NGINX is not responsible for any fried Raspberries or any other damage to people or equiment as result of using of this code.
You are doing this on your own risk.

You will need a Raspberry Pi, a photo resistor, capacitor and a rotary encoder.

Pi GPIO is digital and we need to read analog data. For that reason we added a capacitor to the resistor
and we are measuring number of cycles before the input switches from 0 to 1. This is quite unprecise.
In order to make it more precise you can measure light intensity many times a second and average the data.

Turn the knob to change the frequency of updates.

The code will create a CoAP message and will send it to the server. Output is suppressed if frequency is more than 10Hz.
