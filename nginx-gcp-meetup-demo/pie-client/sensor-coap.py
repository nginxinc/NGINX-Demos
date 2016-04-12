#!/usr/bin/env python
import RPi.GPIO as GPIO
import socket, sys, time
from coapthon import defines
from coapthon.serializer import Serializer
from coapthon.messages.message import Message

GPIO.setmode(GPIO.BOARD)

COUNTER = 0

PIN_ROT_DT = 40
PIN_ROT_CLK = 36
PIN_LIGHT_SENSOR = 12

SEND_DELAY = 0.5
SEND_MULTIPLIER = 1.25

COAP_OP = "PUT"
#COAP_HOST = "udp.nginxlab.net"
COAP_HOST = "104.197.244.155" # GCP Kubernetes
#COAP_HOST = "52.8.148.80"
COAP_PORT = 5683
#COAP_PORT = 8560
COAP_PATH = "/lights"

GPIO.setup(PIN_ROT_CLK, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(PIN_ROT_DT, GPIO.IN, pull_up_down=GPIO.PUD_UP)

sock = socket.socket(socket.AF_INET, # Internet
             socket.SOCK_DGRAM) # UDP

def coap_encode(payload):
    message = Message()
    message.type = defines.Types['CON']
    message.token = 4321
    message.mid = 2
    message.options = None
    message.payload = str(payload)
    serializer = Serializer()
    messagestring = serializer.serialize(message)
    return messagestring

def analog_read(pin):
    global client
    global COAP_PATH
    global SEND_DELAY
    global COUNTER
    reading = 0
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.LOW)
    time.sleep(SEND_DELAY)
    GPIO.setup(pin, GPIO.IN)
    while (GPIO.input(pin) == 0):
            reading += 1
    sock.sendto(coap_encode(reading), (COAP_HOST, COAP_PORT))
    COUNTER += 1
    if SEND_DELAY > 0.1:
        print "Sent reading ", reading
    return reading

def clk(channel):
    global SEND_DELAY
    if GPIO.input(PIN_ROT_CLK) == 0:
        if GPIO.input(PIN_ROT_DT) == 1:
            SEND_DELAY = SEND_DELAY * SEND_MULTIPLIER
        else:
            SEND_DELAY = SEND_DELAY / SEND_MULTIPLIER
    if SEND_DELAY < 1:
        chatterfrequency = int(1/SEND_DELAY)
    else:
        chatterfrequency = 1/SEND_DELAY
    print "Sending data ", chatterfrequency, " times a second, total sent: ", COUNTER

GPIO.add_event_detect(PIN_ROT_CLK, GPIO.FALLING, callback=clk, bouncetime=50)

try:
	while 1:
		reading = analog_read(PIN_LIGHT_SENSOR)

except KeyboardInterrupt:
    GPIO.cleanup()

finally:
    GPIO.cleanup()
