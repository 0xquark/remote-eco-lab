#! /usr/bin/env bash

# SEE HERE FOR AN EXAMPLE SCRIPT: https://invent.kde.org/teams/eco/remote-eco-lab/-/blob/master/scripts/test_scripts/org.kde.okular/log_baseline.sh

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

for ((i = 1; i <= 30; i++)); do

    # burn in
    syncUp 60

    # start
    echo "iteration $i;$(date -I) $(date +%T);startTestrun" >> ~/log_baseline.csv
    echo "start iteration $i"

    # Change <000> to the length of the SUS.
    syncUp <000>

    # stop iteration
    echo " stop iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_baseline.csv

    # cool down
    syncUp 30

done
