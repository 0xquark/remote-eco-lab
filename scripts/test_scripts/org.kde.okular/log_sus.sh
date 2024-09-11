#!/usr/bin/env bash

# Make sure language is set to en_us
setxkbmap us

######################################
# THESE NEED TO BE DEFINED IN OKULAR #
######################################
# Rotate Left: Ctrl+l
# Rotate Right: Ctrl+r
# Invert color: Ctrl+i
# Fit to width: Ctrl+Shift+w

# import keyboard shortcuts
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
okular -v > ~/$(date -d "today" +"%Y%m%d")\_system-info.txt
inxi -F >> ~/$(date -d "today" +"%Y%m%d")\_system-info.txt

# Start scripts with everything fresh
# Make sure Okular is not running
killall okular
# Remove previous logs and dot-files
rm -f ~/log_sus.csv
rm -f ~/.config/okularrc
rm -f ~/.config/okularpartrc
rm -f -r ~/.local/share/okular/*
rm -f ~/Documents/20yearsofKDE.pdf

# Define PDF used for the script exists
FILE=~/Documents/okular/20yearsofKDE.pdf
# check if the file exists
if test -f "$FILE"; then
    echo "$FILE exists"
# if it does not exist, download it
else
    wget https://20years.kde.org/book/20yearsofKDE.pdf -P ~/Documents/okular/
fi

# Loop running for 30 times
# Start loop
for ((i = 1 ; i <= 2; i++)); do

    # Copy PDF to home directory
    # so PDF is identical every time
    cp ~/Documents/okular/20yearsofKDE.pdf ~/Documents/20yearsofKDE.pdf

    # Burn in time
    syncUp 60

    # Start iteration
    echo "iteration $i;$(date -I) $(date +%T);startTestrun" >> ~/log_sus.csv
    echo "start iteration $i"

    # start pause
    syncUp 5

    # Open okular, discard STDERR and STDOUT to /dev/null
    echo " Open Okular "
    startAction "$i" "Open Okular"
    okular > /dev/null 2>&1 &
    syncUp 2
    stopAction "$i"

    # open PDF document
    echo " open PDF document "
    startAction "$i" "open PDF document"
    xdotool key Ctrl+o
    syncUp 1
    xdotool type --delay 100 "20yearsofKDE.pdf"
    syncUp 1
    xdotool key Return
    syncUp 1
    stopAction "$i"

    # Fit to width
    echo " Fit to width "
    startAction "$i" "Fit to width"
    xdotool key Ctrl+Shift+w
    syncUp 2
    stopAction "$i"

    # Enter page number 38 and jump there
    echo " Open Go to dialogue and type 38 "
    startAction "$i" "Open Go to dialogue and type 38"
    xdotool key Ctrl+g
    syncUp 1
    xdotool type --delay 400 "38"
    syncUp 1
    xdotool key Return
    syncUp 1
    stopAction "$i"

    # Mark text and insert comment
    echo " Toggle annotation panel "
    startAction "$i" "Toggle annotation panel"
    # Toggle annotations panel
    xdotool key F6
    syncUp 2
    # Move mouse to center of Okular window
    xdotool mousemove --window "okular" --polar 0 0
    syncUp 2
    stopAction "$i"

    # Select highlighter tool
    echo " Toggle highlighter tool and select text to highlight "
    startAction "$i" "Toggle highlighter tool and select text to highlight"
    xdotool key Alt+1
    # Hold mouse button down, move directly downwards (180) for 75 pixels, unclick
    xdotool mousedown 1 mousemove --polar 180 75 click 1
    syncUp 2
    stopAction "$i"

    # Move mouse directly downwards from middle point of
    # window (180) over highlighted text, double click to add note
    echo " Write annotation "
    startAction "$i" "Write annotation"
    xdotool mousemove --polar 180 25 click --repeat 2 1 type --delay 200 'Very interesting text! I should read more about this topic.'
    syncUp 8
    stopAction "$i"

    # return to browsing mode
    echo " Toggle highlighter tool again to return to browsing mode "
    startAction "$i" "Toggle highlighter tool again to return to browsing mode"
    xdotool key Alt+1
    syncUp 2
    stopAction "$i"

    # Start presentation mode and move up and down pages
    echo " Start presentation mode "
    startAction "$i" "Start presentation mode"
    # Toggle presentation
    xdotool key Ctrl+Shift+p
    syncUp 1
    # Close default popup window
    xdotool key Return
    syncUp 1
    stopAction "$i"

    # Move around the pages
    echo " Move down five pages "
    startAction "$i" "Move down a page 1"
    xdotool key Down
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move down a page 2"
    xdotool key Down
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move down a page 3"
    xdotool key Down
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move down a page 4"
    xdotool key Down
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move down a page 5"
    xdotool key Down
    syncUp 2
    stopAction "$i"

    echo " Move up five pages "
    startAction "$i" "Move up a page 1"
    xdotool key Up
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move up a page 2"
    xdotool key Up
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move up a page 3"
    xdotool key Up
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move up a page 4"
    xdotool key Up
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move up a page 5"
    xdotool key Up
    syncUp 2
    stopAction "$i"

    # Exit
    echo " Exit presentation mode "
    startAction "$i" "Exit presentation mode"
    xdotool key Escape
    syncUp 1
    stopAction "$i"

    # Move mouse to center of Okular window, click mouse to exit text box
    echo " Move mouse to center of window "
    startAction "$i" "Move mouse to center of window"
    xdotool mousemove --window "okular" --polar 0 0 click 1
    syncUp 3
    stopAction "$i"

    # Rotate page right twice
    echo " Rotate page right twice "
    startAction "$i" "Rotate page 1"
    xdotool key Ctrl+r
    syncUp 2
    stopAction "$i"
    syncUp 4
    startAction "$i" "Rotate page 2"
    xdotool key Ctrl+r
    syncUp 2
    stopAction "$i"
    syncUp 4

    # Rotate page left twice
    echo " Rotate page left twice "
    startAction "$i" "Rotate page left 1"
    xdotool key Ctrl+l
    syncUp 2
    stopAction "$i"
    syncUp 4
    echo " Rotate page left 2 "
    startAction "$i" "Rotate page left 2"
    xdotool key Ctrl+l
    syncUp 2
    stopAction "$i"
    syncUp 4

    # Move around the pages
    echo " Move forward five pages "
    startAction "$i" "Move forward a page 1"
    xdotool key Right
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move forward a page 2"
    xdotool key Right
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move forward a page 3"
    xdotool key Right
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move forward a page 4"
    xdotool key Right
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move forward a page 5"
    xdotool key Right
    syncUp 2
    stopAction "$i"

    echo " Move backward five pages "
    startAction "$i" "Move backward a page 1"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move backward a page 2"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move backward a page 3"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move backward a page 4"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move backward a page 5"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    syncUp 1

    # Zoom out
    echo " Zoom to 100 percent "
    startAction "$i" "Zoom to 100 percent"
    xdotool key Ctrl+0
    syncUp 3
    stopAction "$i"

    echo " Zoom to 400 percent "
    # Zoom in
    startAction "$i" "Zoom in to 400 percent 1"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    startAction "$i" "Zoom in to 400 percent 2"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    startAction "$i" "Zoom in to 400 percent 3"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    startAction "$i" "Zoom in to 400 percent 4"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    startAction "$i" "Zoom in to 400 percent 5"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"

    # Fit to width
    echo " Fit to width "
    startAction "$i" "Fit to width"
    xdotool key Ctrl+Shift+w
    syncUp 1
    stopAction "$i"

    # Invert colors
    echo " Invert colors "
    startAction "$i" "Invert colors"
    # Invert colors
    xdotool key Ctrl+i
    syncUp 2
    stopAction "$i"
    syncUp 3

# START PARTIAL REPEAT
# Note: now goes to page number 42, writes slightly different annotation

    # Enter page number 42 and jump there
    echo " Open Go to dialogue and type 42 "
    startAction "$i" "Open Go to dialogue and type 42"
    xdotool key Ctrl+g
    syncUp 1
    xdotool type --delay 400 "42"
    syncUp 1
    xdotool key Return
    syncUp 2
    stopAction "$i"

    # Mark text and insert comment
    echo " Toggle annotation panel "
    startAction "$i" "Toggle annotation panel"
    # Toggle annotations panel
    xdotool key F6
    syncUp 2
    # Move mouse to center of Okular window
    xdotool mousemove --window "okular" --polar 0 0
    syncUp 2
    stopAction "$i"

    # Select highlighter tool
    echo " Toggle highlighter tool and select text to highlight "
    startAction "$i" "Toggle highlighter tool and select text to highlight"
    xdotool key Alt+1
    xdotool mousedown 1 mousemove --polar 180 75 click 1
    syncUp 2
    stopAction "$i"

    # Move mouse directly downwards from middle point of
    # window (180) over highlighted text, double click to add note
    echo " Write annotation "
    startAction "$i" "Write annotation"
    xdotool mousemove --polar 180 25 click --repeat 2 1 type --delay 200 'Again this is very interesting, should read more.'
    syncUp 8
    stopAction "$i"

    # return to browsing mode
    echo " Toggle highlighter tool again to return to browsing mode "
    startAction "$i" "Toggle highlighter tool again to return to browsing mode"
    xdotool key Alt+1
    syncUp 1
    stopAction "$i"

    # Start presentation mode and move up and down pages
    echo " Start presentation mode "
    startAction "$i" "Start presentation mode"
    # Toggle presentation
    xdotool key Ctrl+Shift+p
    syncUp 2
    # Close default popup window
    xdotool key Return
    syncUp 19
    stopAction "$i"

    # Exit presentation
    echo " Exit presentation mode "
    startAction "$i" "Exit presentation mode"
    xdotool key Escape
    syncUp 1
    # Move mouse to center of Okular window, click mouse to exit text box
    xdotool mousemove --window "okular" --polar 0 0 click 1
    syncUp 1
    stopAction "$i"

    # Rotate page right twice
    echo " Rotate page right twice "
    startAction "$i" "Rotate page right 1"
    xdotool key Ctrl+r
    syncUp 2
    stopAction "$i"
    syncUp 4
    startAction "$i" "Rotate page right 2"
    xdotool key Ctrl+r
    syncUp 2
    stopAction "$i"
    syncUp 4

    # Rotate page left twice
    echo " Rotate page left twice "
    startAction "$i" "Rotate page left 1"
    xdotool key Ctrl+l
    syncUp 2
    stopAction "$i"
    syncUp 4
    echo " Rotate page left 2 "
    startAction "$i" "Rotate page left 2"
    xdotool key Ctrl+l
    syncUp 2
    stopAction "$i"
    syncUp 4

    # Move around the pages
    echo " Move forward five pages "
    startAction "$i" "Move forward a page 1"
    xdotool key Right
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move forward a page 2"
    xdotool key Right
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move forward a page 3"
    xdotool key Right
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move forward a page 4"
    xdotool key Right
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move forward a page 5"
    xdotool key Right
    syncUp 2
    stopAction "$i"

    echo " Move backward five pages "
    startAction "$i" "Move backward a page 1"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move backward a page 2"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move backward a page 3"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move backward a page 4"
    xdotool key Left
    syncUp 2
    stopAction "$i"
    startAction "$i" "Move backward a page 5"
    xdotool key Left
    syncUp 2
    stopAction "$i"

    # Zoom out
    echo " Zoom to 100 percent "
    startAction "$i" "Zoom to 100 percent"
    xdotool key Ctrl+0
    syncUp 3
    stopAction "$i"

    echo " Zoom to 400 percent "
    # Zoom in
    startAction "$i" "Zoom in to 400 percent 1"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    startAction "$i" "Zoom in to 400 percent 2"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    startAction "$i" "Zoom in to 400 percent 3"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    startAction "$i" "Zoom in to 400 percent 4"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    startAction "$i" "Zoom in to 400 percent 5"
    xdotool key Ctrl+plus
    syncUp 1
    stopAction "$i"
    syncUp 1

    # Fit to width
    echo " Fit to width "
    startAction "$i" "Fit to width"
    xdotool key Ctrl+Shift+w
    syncUp 1
    stopAction "$i"

    # Invert colors back
    echo " Invert colors back "
    startAction "$i" "Invert colors back"
    xdotool key Ctrl+i
    syncUp 2
    stopAction "$i"
    syncUp 2

# REPEAT OVER

    ## wrap-up
    # save
    echo " Save PDF "
    startAction "$i" "Save PDF"
    xdotool key Ctrl+s
    syncUp 1
    stopAction "$i"

    # quit okular
    echo " Quit Okular "
    startAction "$i" "Quit Okular"
    xdotool key Ctrl+q
    syncUp 2
    stopAction "$i"

    # stop iteration
    echo " stop iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_sus.csv

    syncUp 1

    ## clean up
    # remove logs
    rm ~/.config/okularrc
    rm ~/.config/okularpartrc
    rm -r ~/.local/share/okular/*
    # delete annotated PDF
    rm ~/Documents/20yearsofKDE.pdf

    # cool down
    syncUp 30

    clear

done

## rm configuration scripts and keyboard shortcuts

rm /tmp/configuration.sh
rm /tmp/part.rc
