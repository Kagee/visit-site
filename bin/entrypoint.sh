#!/usr/bin/dumb-init /bin/sh /bin/bash

if [[ "x" == "x$1" ]]; then
    echo "Must supply either filename or domain as argument" 1>&2;
    exit 1;
fi

function visit {
echo "Let us visit $1"
MINUTE="$(date +'%Y-%m-%d-%H-%M')"
STORAGE="$PWD/data/$1/$MINUTE"
mkdir -p "$STORAGE"
echo "Data vill be saved in $STORAGE"

trap 'kill -TERM $PID; wait $PID' TERM INT

# Perhaps run tcpdump as normal user? https://askubuntu.com/a/632189
# No, let's not
# Drop ARP? Drop MDNS? 
tcpdump -i eth0 -w $STORAGE/tcpdump.pcap &
PID_TCPDUMP=$!


SSLKEYLOGFILE="$STORAGE/mitmdump.sslkeylogfile.txt" \
    mitmdump --conf ~/bin/options.yaml \
    --save-stream-file "$STORAGE/mitmdump.flows" &
PID_MITMDUMP=$!

PID="$PID_TCPDUMP $PID_MITMDUMP"

sleep 2

wget --no-check-certificate -e use_proxy=yes -e http_proxy=127.0.0.1:8080 -e https_proxy=127.0.0.1:8080 http://$1
wget --no-check-certificate -e use_proxy=yes -e http_proxy=127.0.0.1:8080 -e https_proxy=127.0.0.1:8080 http://www.$1
wget --no-check-certificate -e use_proxy=yes -e http_proxy=127.0.0.1:8080 -e https_proxy=127.0.0.1:8080 https://$1
wget --no-check-certificate -e use_proxy=yes -e http_proxy=127.0.0.1:8080 -e https_proxy=127.0.0.1:8080 https://www.$1

sleep 5

kill $PID_TCPDUMP
kill $PID_MITMDUMP

wait $PID
}

if [[ -f "$1" ]]; then
    cat "$1" | while read DOMAIN; do
        visit "$DOMAIN";
    done
else
    visit "$1"
fi

chown -R 1000:1000 "$STORAGE"
