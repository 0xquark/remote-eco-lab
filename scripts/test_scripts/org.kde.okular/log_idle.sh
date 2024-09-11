#! /usr/bin/env bash

startTime=$(date +%s%N)
elapsed=0

syncUp() {
    elapsed=$((elapsed + ($1 * 1000000000)))
    delta=$(echo "scale=10; (($startTime + $elapsed) - $(date +%s%N)) / 1000000000" | bc)
    echo "Sleep" $delta
    sleep $delta
}

# startAction / stopAction functions are used to output the time and action into log.csv file
startAction() {
    echo "iteration $1;$(date -I) $(date +%T);startAction;$2 " >> ~/log_idle.csv
}
stopAction() {
    echo "iteration $1;$(date -I) $(date +%T);stopAction " >> ~/log_idle.csv
}

# Start scripts with everything fresh
# Make sure Okular is not running
killall okular
# Remove previous logs and dot-files
rm -f ~/log_idle.csv
rm -f ~/.config/okularrc
rm -f ~/.config/okularpartrc
rm -f -r ~/.local/share/okular/*

for ((i = 1; i <= 2; i++)); do

    # burn in
    syncUp 60

    # start
    echo "iteration $i;$(date -I) $(date +%T);startTestrun" >> ~/log_idle.csv
    echo "start iteration $i"

    # start pause
    syncUp 5

    # open okular
    echo " open okular "
    startAction "$i" "open okular"
    okular > /dev/null 2>&1 & # open okular
    syncUp 2
    stopAction "$i"

    # leave open for time (in seconds)
    # for SUS minus start pause minus wrap-up
    syncUp 211

    # wrap-up
    # quit okular
    echo " quit okular "
    startAction "$i" "quit okular"
    xdotool key Ctrl+q
    syncUp 2
    stopAction "$i"

    # stop iteration
    echo " stop iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_idle.csv

    syncUp 1

    # Remove logs
    rm ~/.config/okularrc
    rm ~/.config/okularpartrc
    rm -r ~/.local/share/okular/*

    # cool down
    syncUp 30

    clear

done
