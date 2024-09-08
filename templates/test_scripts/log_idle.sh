#! /usr/bin/env bash

# SEE HERE FOR AN EXAMPLE SCRIPT: https://invent.kde.org/teams/eco/remote-eco-lab/-/blob/master/scripts/test_scripts/org.kde.okular/log_idle.sh

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
# Make sure software is not running
## CHANGE <SOFTWARE> TO THE NAME OF THE SOFTWARE BEING TESTED
killall <SOFTWARE>
# Remove previous logs and dot-files
rm -f ~/log_sus.csv
rm -f ~/.config/<SOFTWARE>
rm -f -r ~/.local/share/<SOFTWARE>/*

for ((i = 1; i <= 30; i++)); do

    # burn in
    syncUp 60

    # start
    echo "iteration $i;$(date -I) $(date +%T);startTestrun" >> ~/log_idle.csv
    echo "start iteration $i"

    # start pause
    syncUp 5

    # Open SOFTWARE, discard STDERR and STDOUT to /dev/null
    echo " Open <SOFTWARE> "
    startAction "$i" "Open <SOFTWARE>"
    <SOFTWARE> > /dev/null 2>&1 &
    syncUp 2
    stopAction "$i"

    # Change <000> to the length of the SUS.
    # Leave SOFTWARE open for time (in seconds) for
    # SUS minus start pause minus wrap-up.
    syncUp <000>

   # quit SOFTWARE
    echo " Quit <SOFTWARE> "
    startAction "$i" "Quit <SOFTWARE>"
    xdotool key Ctrl+q
    syncUp 2
    stopAction "$i"

    # stop iteration
    echo " stop iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_idle.csv

    syncUp 1

    # remove logs
    rm -f ~/.config/<SOFTWARE>
    rm -f -r ~/.local/share/<SOFTWARE>/*

    # cool down
    syncUp 30

    clear

done
