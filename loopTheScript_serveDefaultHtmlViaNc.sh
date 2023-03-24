#!/bin/sh

## Customizeable defaults
delay=60
# The variable $usedPorts may be overwritten by the contents of $nginxFile
usedPorts="8080 8081 8082"
nginxFile="./nginx-defaultsite"
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
