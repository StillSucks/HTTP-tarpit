#!/bin/sh
#
# usage: $0 [port] [duration]
#    port (optional): registered localhost port for serving content
#    duration (optional, requires port): time which the content should be streched across
#

# default values
outputHeading="./HttpOutput/_heading.html"
outputContent="./HttpOutput/content.html"
outputClosure="./HttpOutput/_closure.html"
port="8080"
# outputDuration="50"
bytesPerSecond="220"

# ports below 1024 require elevated privileges
[ "$#" -gt 0 ] && [ "$1" -gt 1023 ] && port="$1"
[ "$#" -gt 1 ] && [ "$2" -gt 1 ] && outputDuration="$2"

[ -r "$outputHeading" ] && [ -r "$outputContent" ] && [ -r "$outputClosure" ] || exit 1
contentLength=$(du -cb "$outputHeading" "$outputContent" "$outputClosure" | grep -i "total" | cut -f1)

timestamp=$(date +'%a, %d %b %Y %H:%M:%S GMT')
# if outputDuration is not empty, override bytesPerSecond
[ -n "$outputDuration" ] && bytesPerSecond=$(echo "$contentLength / $outputDuration" | bc)

# pipe mock-up nginx headers and actual files into nc
(
echo "HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: $timestamp
Content-Type: text/html; charset=UTF-8
Content-Length: $contentLength
Connection: keep-alive
"

pv -q -L "$bytesPerSecond" "$outputHeading" "$outputContent" "$outputClosure"
) | nc -l localhost "$port"
