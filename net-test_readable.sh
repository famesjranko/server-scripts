## network speed test script
## requires speedtest-cli
## pipe output to log (net-speed_readable.log) for use with avg-speeds.sh

#!/bin/bash

OUTPUT=$(speedtest)

PING=$(echo "$OUTPUT" | grep Latency:)
DOWN=$(echo "$OUTPUT" | grep Download: | cut -c 2-)
UP=$(echo "$OUTPUT" | grep Upload: | cut -c 2-)
PACKET_LOSS=$(echo "$OUTPUT" | grep "Packet Loss:" | cut -c 1-)

echo "$(date):"
echo -e ' \t ' $PING
echo -e ' \t ' $DOWN
echo -e ' \t ' $UP
echo -e ' \t ' $PACKET_LOSS
