#!/bin/sh
#
# This script starts an independant background process for each $usedPorts.
# These initiate the secondary script (containing the port reservation via netcat/nc).
#     The secondary script slowly streams content into nc according to the $((delay - 2)) duration.
# If a client is connecting to the reverse proxy, the proxy tries to foreward data from a local upstream sources.
#     If no request has been forewarded, the timeout quits the process and the while-loop initializes a new instance.
#     As the clients continually receive data, usual (connection-)timeouts are not hit.
#     Currently, the data is buffered by the reverse-proxy and split into its defined data sizes.
# Clients usually connect within X seconds after the timeout cycle of a choosen worker.
#     Therefore they experience an actual delay of (($delay - X)) seconds [maximum: ((delay -2))].
#
# Complication (the last part I'm not sure about):
# The higher the $delay, the more ports ($usedPorts) you might need.
#     If there are (at any time) more active connection than #usedPorts, the reverse-proxy will respond with an internal error (502).
# The more ports you use, the higher the probability that the actual waiting time will be lower than ((delay - 2)).
#     If a single worker handles all request, any request will likely hit the first few seconds of this worker (spamming behavior).
#     If a request is assigned (via random/alternation/..) to a worker, this worker might have been waiting longer than in the previous example.

## Customizeable defaults
delay=60
# The variable $usedPorts may be overwritten by the contents of $nginxFile
usedPorts="8080 8081 8082"
nginxFile="./exemplary_nginx-defaultsite"
# nginxFile="/etc/nginx/sites-enabled/default"
# These HTTP client-headers are uninteresting and should not be included in basic output
uselessHttpRequestHeaders="Connection|Accept|Accept-Language|Accept-Encoding|Upgrade-Insecure-Requests|Sec-Fetch-Dest|Sec-Fetch-Mode|Sec-Fetch-Site|If-Modified-Since|If-None-Match"

## Dependant variables
# Subordinate script, that manages netcat, pv (slow data streaming), and the HTTP-response headers
secondaryScript="./serveDefaultHtmlViaNc.sh"

# Nginx / Reverse-Proxy dependant variable
# If nginx config file exists/is readable:
#    first grep:  parse the whole 'upstream *name* {*list-of-servers*}' block
#    second grep: parse the port numbers (individual lines)
[ -r "$nginxFile" ] && \
    usedPorts=$(grep -Po -z "upstream [\w\s\-]+\{[^\}]*\}" "$nginxFile" \
        | grep -Po -a "(?<=server localhost:)\d+" \
        | tr '\n' ' ')


# create a self-looping worker for each port
for port in $usedPorts ; do
    while /bin/true ; do
        timeout "$delay" bash "$secondaryScript" "$port" "$((delay - 2))" \
            | grep -Ev "($uselessHttpRequestHeaders): "
    done &

    # create an offset to prohibit simultaneous timeouts
    sleep 1
done

# Overwrite the 'exit code' of this script (Neccessary as for systemd)
#    'while' has no exit code and the last statement (string comparisson) will always be false
true
