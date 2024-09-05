#! /usr/bin/env bash

startTime=$(date +%s%N)
elapsed=0

# syncUp function is used to get accurate time to be elapsed
syncUp() {
    elapsed=$((elapsed + ($1 * 1000000000)))
    delta=$(echo "scale=10; (($startTime + $elapsed) - $(date +%s%N)) / 1000000000" | bc)
    echo "Sleep" $delta
    sleep $delta
}

# startAction / stopAction functions not needed

for ((i = 1; i <= 5; i++)); do

    # burn in
    syncUp 10 #60

    # start
    echo "iteration $i;$(date -I) $(date +%T);startTestrun" >> ~/log_baseline.csv
    echo "start iteration $i"

    # leave running for time (in seconds)
    # for SUS
    syncUp 210

    # stop iteration
    echo " stop iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_baseline.csv

    # cool down
    syncUp 10

done
