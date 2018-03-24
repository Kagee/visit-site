#! /bin/bash
# dump-init?

# Consider replaceing with child_process-examples.js

if [[ "x" != "x$1" ]]; then
exit
fi

echo "Let us visit $1"
MINUTE="$(date +'%Y-%m-%d-%H-%M')"
STORAGE="$PWD/data/$1/$MINUTE"
mkdir -p "$STORAGE"
echo "Data vill be saved in $STORAGE"

trap 'kill -TERM $PID; wait $PID' TERM INT

# Perhaps run tcpdump as normal user? https://askubuntu.com/a/632189
tcpdump -i eth0 -w $STORAGE/tcpdump.pcap &
PID_TCPDUMP=$!


SSLKEYLOGFILE="$STORAGE/mitmdump.sslkeylogfile.txt" \
    mitmdump --conf ~/bin/options.yaml \
    --save-stream-file "$STORAGE/mitmdump.flows" &
PID_MITMDUMP=$!

PID="$PID_TCPDUMP $PID_MITMDUMP"

sleep 2

ENTRYPOINT [ "google-chrome-stable" ]
CMD [ "--headless", "--disable-gpu", "--remote-debugging-address=0.0.0.0", "--remote-debugging-port=9222" ]

wget --no-check-certificate -e use_proxy=yes -e http_proxy=127.0.0.1:8080 -e https_proxy=127.0.0.1:8080 http://$1
wget --no-check-certificate -e use_proxy=yes -e http_proxy=127.0.0.1:8080 -e https_proxy=127.0.0.1:8080 http://www.$1
wget --no-check-certificate -e use_proxy=yes -e http_proxy=127.0.0.1:8080 -e https_proxy=127.0.0.1:8080 https://$1
wget --no-check-certificate -e use_proxy=yes -e http_proxy=127.0.0.1:8080 -e https_proxy=127.0.0.1:8080 https://www.$1

sleep 5

kill $PID_TCPDUMP
kill $PID_MITMDUMP

wait $PID

#find "$STORAGE" -type d -exec chmod 777 {} \;
#find "$STORAGE" -type f -exec chmod 666 {} \;
chown -R 1000:1000 "$STORAGE"
