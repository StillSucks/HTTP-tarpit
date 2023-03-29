#!/bin/sh
#
# usage: $0 [port] [duration]
#    port (optional): registered localhost port for serving content
#    duration (optional, requires port): time which the content should be streched across
#

# constants
timestamp=$(date +'%a, %d %b %Y %H:%M:%S GMT')
bytesPerSecondMIN="200"
outputHeading="./HttpOutput/_heading.html"
outputContent="./HttpOutput/content.html"
outputClosure="./HttpOutput/_closure.html"

# default values
bytesPerSecond="$((bytesPerSecondMIN * 11/10))"
port="8080"

# ports below 1024 require elevated privileges
[ "$#" -gt 0 ] && [ "$1" -gt 1023 ] && port="$1"
[ "$#" -gt 1 ] && [ "$2" -gt 1 ] && outputDuration="$2"

[ -r "$outputHeading" ] && [ -r "$outputContent" ] && [ -r "$outputClosure" ] || exit 1
contentLength=$(du -cb "$outputHeading" "$outputContent" "$outputClosure" | grep -i "total" | cut -f1)

printContent_NTimes=1
# if outputDuration is set, check if content needs to be repeated and adapt bytesPerSecond
if [ -n "$outputDuration" ] ; then
  contentFileLength=$(du -b "$outputContent" | cut -f1)
  while [ "$((contentLength / outputDuration))" -lt "$bytesPerSecondMIN" ] ; do
    contentLength=$((contentLength + contentFileLength))
    printContent_NTimes=$((printContent_NTimes + 1))
  done
  # '1+' prohibits the default downwards-rounding
  bytesPerSecond=$((1 + (contentLength / outputDuration)))
fi

# pipe mock-up nginx headers and actual files into nc
(
echo "HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: $timestamp
Content-Type: text/html; charset=UTF-8
Content-Length: $contentLength
Connection: keep-alive
"
pv -q -L "$bytesPerSecond" "$outputHeading"
for ((i=0 ; i < $printContent_NTimes ; ++i)) ; do
  pv -q -L "$bytesPerSecond" "$outputContent"
done
pv -q -L "$bytesPerSecond" "$outputClosure"
) | nc -l localhost "$port"
