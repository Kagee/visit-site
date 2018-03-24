#! /bin/bash
# dump-init?

# Consider replaceing with child_process-examples.js

echo "Let us visit $1"
MINUTE="$(date +'%Y-%m-%d-%H-%M')"
STORAGE="$PWD/data/$1/$MINUTE"
mkdir -p "$STORAGE"
echo "Data vill be saved in $STORAGE"

#trap 'kill -TERM $PID; wait $PID' TERM INT

# Perhaps run tcpdump as normal user? https://askubuntu.com/a/632189
#tcpdump -i docker0 tcp port 80 -w test.pcap &
#PID_TCPDUMP=$!


# SSLKEYLOGFILE="$STORAGE/mitmdump.sslkeylogfile.txt" \
#    mitmdump --conf ~/bin/options.yaml \
#    --save-stream-file "$STORAGE/mitmdump.flows" &
#PID_MITMDUMP=$!
PID="$PID_TCPDUMP $PID_MITMDUMP"

#wait $PID

find "$STORAGE" -type d -exec chmod 777 {} \;
find "$STORAGE" -type f -exec chmod 666 {} \;
