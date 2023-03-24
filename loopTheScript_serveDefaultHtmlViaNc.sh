#!/bin/sh

## Customizeable defaults
delay=60

## Dependant variables
# Subordinate script, that manages netcat, pv (slow data streaming), and the HTTP-response headers
secondaryScript="./serveDefaultHtmlViaNc.sh"

# create a self-looping worker
while /bin/true ; do
    timeout "$delay" bash "$secondaryScript" "8080" "$((delay - 2))"
done &
