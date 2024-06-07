#!/usr/bin/env bash

startTime=$(date +%s%N)
elapsed=0

# syncUp function is used to get accurate time to be elapsed
syncUp() {
    elapsed=$((elapsed + ($1 * 1000000000)))
    delta=$(echo "scale=10; (($startTime + $elapsed) - $(date +%s%N)) / 1000000000" | bc)
    echo "Sleep" $delta
    sleep $delta
}

# timestamp function is used to output the time and action into log.csv file.
timestamp() {
    echo "iteration $1;$(date -I) $(date +%T);startAction;$2 " >> ~/log_sus.csv

}

# Loop running for 30 times
# start loop
for ((i = 1 ; i <= 2 ; i++)); do

    # burn in
    syncUp 10 #60

    # start
    echo "iteration $i;$(date -I) $(date +%T);startTestrun" >> ~/log_sus.csv
    echo "start iteration $i"

    # start pause
    syncUp 5

    # open writer
    flatpak run org.libreoffice.LibreOffice --writer 2>&1 &
    syncUp 20

    # Close the tip of the day dialog
    xdotool key Return
    syncUp 2

    echo "iteration $i;$(date -I) $(date +%T);stopAction" >> ~/log_sus.csv
    echo " type lorem ipsum "
    # Type lorem ipsum
    timestamp "$i" "type lorem ipsum"
    xdotool type "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna"
    xdotool key Return
    syncUp 5
    xdotool type "aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata"
    xdotool key Return
    syncUp 5
    xdotool type "sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor"
    xdotool key Return
    syncUp 5
    xdotool type "invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet"
    xdotool key Return
    syncUp 5
    xdotool type "clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet"
    syncUp 10

    echo "iteration $i;$(date -I) $(date +%T);stopAction" >> ~/log_sus.csv
    echo " find lorem and move between searches"
    timestamp "$i" "find lorem"
    # find lorem
    xdotool key Ctrl+f
    syncUp 3
    xdotool type "lorem"
    syncUp 2

    echo "iteration $i;$(date -I) $(date +%T);stopAction" >> ~/log_sus.csv
    timestamp "$i" "move between searches 6 times "
    # next
    xdotool key F3
    syncUp 1
    # next
    xdotool key F3
    syncUp 1
    # next
    xdotool key F3
    syncUp 1
    # next
    xdotool key F3
    syncUp 5

    # prev
    xdotool key Shift+F3
    syncUp 1
    # prev
    xdotool key Shift+F3
    syncUp 1

    echo "iteration $i;$(date -I) $(date +%T);stopAction" >> ~/log_sus.csv
    timestamp "$i" "close find bar"
    # close find bar
    xdotool key Escape

    echo "iteration $i;$(date -I) $(date +%T);stopAction" >> ~/log_sus.csv
    echo " open and close Styles"
    # Enter full screen mode
    timestamp "$i" "open Styles"
    xdotool key F11
    syncUp 5
    echo "iteration $i;$(date -I) $(date +%T);stopAction" >> ~/log_sus.csv
    # Exit Full screen mode
    timestamp "$i" "close Styles"
    xdotool key F11
    syncUp 5

    echo "iteration $i;$(date -I) $(date +%T);stopAction" >> ~/log_sus.csv
    echo " save file "
    timestamp "$i" "save file"
    xdotool key Ctrl+s
    syncUp 2
    xdotool type "writerExampleDocument.odt"
    syncUp 2
    xdotool key Return
    syncUp 5

    # wrap-up
    # quit writer
    xdotool key Ctrl+q
    syncUp 5

    # stop iteration
    echo "iteration $i;$(date -I) $(date +%T);stopAction" >> ~/log_sus.csv
    echo " stop  iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_sus.csv
    syncUp 1

    # remove file
    find ~/ -name writerExampleDocument.odt -delete

    # Remove user directory
    rm -rf ~/.var/app/org.libreoffice.LibreOffice/

done

clear


#end loop
#end script
