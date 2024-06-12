#!/usr/bin/env bash

startTime=$(date +%s%N)

elapsed=0

syncUp() {
    elapsed=$((elapsed + ($1 * 1000000000)))
    delta=$(echo "scale=10; (($startTime + $elapsed) - $(date +%s%N)) / 1000000000" | bc)
    echo "Sleep" $delta
    sleep $delta
}

timestamp() {
    echo "iteration $1;$(date -I) $(date +%T);$2 " >> ~/log_baseline.csv
}

for ((i = 1 ; i <= 2; i++)); do

    # burn in
    syncUp 2 #60

    # start
    timestamp "$i" "startTestrun"
    echo "start iteration $i"

    # leave running for time (in seconds)
    # for SUS
    syncUp 6

    echo " stop  iteration "
    timestamp "$i" "stopTestrun"

    # cool down
    syncUp 1

done
