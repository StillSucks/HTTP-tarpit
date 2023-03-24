#!/bin/sh
#
# usage: $0 [port]
#    port (optional): registered localhost port for serving content
#

# default values
outputFile="./default.html"
port="8080"

# ports below 1024 require elevated privileges
[ "$#" -gt 0 ] && [ "$1" -gt 1023 ] && port="$1"

contentLength=$(du -b "$outputFile" | cut -f1)
timestamp=$(date +'%a, %d %b %Y %H:%M:%S GMT')

# pipe mock-up nginx headers and actual file into nc
(
echo "HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: $timestamp
Content-Type: text/html; charset=UTF-8
Content-Length: $contentLength
Connection: keep-alive
"

cat "$outputFile"
) | nc -l localhost "$port"
