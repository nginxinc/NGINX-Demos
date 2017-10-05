MQTT Mote Type for Contiki OS
=============================

This is a simple implementation of a MQTT client for use with the Contiki OS Cooja simulator.

http://www.contiki-os.org/

The code itself is a combination of two separate Contiki examples - combined, modified and sanitized enough to fit on a Z1 Mote Type. It is designed so that it can run entirely within the Cooja simulator, and has not been tested on real hardware.

1. https://github.com/contiki-os/contiki/tree/master/examples/ipv6/sky-websense
2. https://github.com/contiki-os/contiki/tree/master/examples/nrf52dk/mqtt-demo

By default the MQTT client will attempt to reach the MQTT broker on the Tunslip IPv6 address (aaaa::1). Modify this in `project-conf.h`

See the MQTT Mote in action at https://youtu.be/lUoQgx_eZWo
