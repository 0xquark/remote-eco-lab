#! /usr/bin/env bash

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

for ((i = 0; i < 30; i++)); do

    # burn in
    syncUp 60

    # start
    echo "iteration $i;$(date -I) $(date +%T);startTestRun" >> ~/log_baseline.csv
    echo "start iteration $i"

    # leave running for time (in seconds)
    # for SUS
    syncUp 210

    echo " stop  iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_baseline.csv

    # cool down
    syncUp 60

done
