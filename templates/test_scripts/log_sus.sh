#!/usr/bin/env bash

# SEE HERE FOR AN EXAMPLE SCRIPT: https://invent.kde.org/teams/eco/remote-eco-lab/-/blob/master/scripts/test_scripts/org.kde.okular/log_sus.sh

# Make sure language is set to en_us
setxkbmap us

# import custom keyboard shortcuts
./configuration.sh

# Log file names start with today's date, so new log file name is given if running past midnight.

# syncUp unction to synchronize code execution with real-world time:
# It executes sleep command with about 0.99% accuracy.
# It calculates the elapsed time by adding the argument ($1) multiplied by 1 billion (1000000000) to the elapsed variable.
# It calculates the delta (difference) between the start time ($startTime) plus the elapsed time and the current time in nanoseconds ($(date +%s%N)).
# It uses the bc command in a pipeline to perform floating-point arithmetic to divide the delta by 1 billion and store the result in the delta variable.
# Then it sleeps for this delta variable.
startTime=$(date +%s%N)
elapsed=0

# syncUp function is used to get accurate time to be elapsed
syncUp() {
    elapsed=$((elapsed + ($1 * 1000000000)))
    delta=$(echo "scale=10; (($startTime + $elapsed) - $(date +%s%N)) / 1000000000" | bc)
    echo "Sleep" $delta
    sleep $delta
}

# startAction / stopAction functions are used to output the time and action into log.csv file
startAction() {
    echo "iteration $1;$(date -I) $(date +%T);startAction;$2 " >> ~/log_sus.csv
}
stopAction() {
    echo "iteration $1;$(date -I) $(date +%T);stopAction " >> ~/log_sus.csv
}

# Log the system info at the time of testing
## CHANGE <SOFTWARE> TO THE NAME OF THE SOFTWARE BEING TESTED
<SOFTWARE> -v > ~/$(date -d "today" +"%Y%m%d")\_system-info.txt
inxi -F >> ~/$(date -d "today" +"%Y%m%d")\_system-info.txt

# Start scripts with everything fresh
# Make sure software is not running
## CHANGE <SOFTWARE> TO THE NAME OF THE SOFTWARE BEING TESTED
killall <SOFTWARE>
# Remove previous logs and dot-files
rm -f ~/log_sus.csv
rm -f ~/.config/<SOFTWARE>
rm -f -r ~/.local/share/<SOFTWARE>/*

## If you need to download any files to be used in the scripts,
## you can avoid downloading it with every run here.
# Define <FILE> used for the script exists
FILE=~/Documents/<SOFTWARE>/<TESTFILE>
# check if the file exists
if test -f "$FILE"; then
    echo "$FILE exists"
# if it does not exist, download it
else
    wget <LINK -P ~/Documents/<SOFTWARE>/
fi

# Loop running for 30 times
# Start loop
for ((i = 1 ; i <= 30; i++)); do

    # If changes are made during the script, copy <TESTFILE>
    # to home directory so file is identical every time,
    cp ~/Documents/<SOFTWARE>/<TESTFILE> ~/Documents/<TESTFILE>

    # Burn in time
    syncUp 60

    # Start iteration
    echo "iteration $i;$(date -I) $(date +%T);startTestrun" >> ~/log_sus.csv
    echo "start iteration $i"

    # start pause
    syncUp 5

    # Open SOFTWARE, discard STDERR and STDOUT to /dev/null
    echo " Open <SOFTWARE> "
    startAction "$i" "Open <SOFTWARE>"
    <SOFTWARE> > /dev/null 2>&1 &
    syncUp 2
    stopAction "$i"

    # <ACTION>
    echo " <ACTION> "
    startAction "$i" "<ACTION>"
    <ACTION>
    stopAction "$i"

    # quit SOFTWARE
    echo " Quit <SOFTWARE> "
    startAction "$i" "Quit <SOFTWARE>"
    xdotool key Ctrl+q
    syncUp 2
    stopAction "$i"

    # stop iteration
    echo " stop iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_sus.csv

    syncUp 1

    ## clean up
    # remove logs
    rm -f ~/.config/<SOFTWARE>
    rm -f -r ~/.local/share/<SOFTWARE>/*
    # delete <TESTFILE>
    rm ~/Documents/<TESTFILE>

    # cool down
    syncUp 30

    clear

done

## rm configuration scripts and keyboard shortcuts at end of script

rm /tmp/configuration.sh
rm /tmp/part.rc
