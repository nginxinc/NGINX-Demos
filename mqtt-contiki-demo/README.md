MQTT Mote Type for Contiki OS
=============================

This is a simple implementation of a MQTT client for use with the Contiki OS Cooja simulator.

http://www.contiki-os.org/

The code itself is a combination of two separate Contiki examples - combined, modified and sanitized enough to fit on a Z1 Mote Type. It is designed so that it can run entirely within the Cooja simulator, and has not been tested on real hardware.

1. https://github.com/contiki-os/contiki/tree/master/examples/ipv6/sky-websense
2. https://github.com/contiki-os/contiki/tree/master/examples/nrf52dk/mqtt-demo

By default the MQTT client will attempt to reach the MQTT broker on the Tunslip IPv6 address (aaaa::1). Modify this in `project-conf.h`

See the MQTT Mote in action at https://youtu.be/lUoQgx_eZWo

MQTT client behaviours
----------------------
### Publish
Publishes internal sensor data to the MQTT topic `sensor/data`. Client ID is **sensor**_N_ where _N_ is obtained from the last segment of its IPv6 address.

Message data is in JSON format, consisting of a counter, uptime, and fictitious temperature and light values.
`{"sensor6":{"Sequence":1,"Clock":39,"Temp":22,"Light":282}}`

### Subscribe
Subscribes to topic `sensor/command`. Message value of `1` illuminates the red LED, message value of `0` extinguishes the red LED.
