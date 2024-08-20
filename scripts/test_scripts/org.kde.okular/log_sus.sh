#!/usr/bin/env bash

######################################
# THESE NEED TO BE DEFINED IN OKULAR #
######################################
# Rotate Left: Ctrl+l
# Rotate Right: Ctrl+r
# Invert color: Ctrl+i
# Fit to width: Ctrl+Shift+w

# Make sure language is set to en_us
setxkbmap us

# syncUp unction to synchronize code execution with real-world time:
# It executes sleep command with about 0.99% accuracy.
# It calculates the elapsed time by adding the argument ($1) multiplied by 1 billion (1000000000) to the elapsed variable.
# It calculates the delta (difference) between the start time ($startTime) plus the elapsed time and the current time in nanoseconds ($(date +%s%N)).
# It uses the bc command in a pipeline to perform floating-point arithmetic to divide the delta by 1 billion and store the result in the delta variable.
# Then it sleeps for this delta variable.
startTime=$(date +%s%N)
elapsed=0
syncUp() {
    elapsed=$((elapsed + ($1 * 1000000000)))
    delta=$(echo "scale=10; (($startTime + $elapsed) - $(date +%s%N)) / 1000000000" | bc)
    echo "Sleep" $delta
    sleep $delta
}

# Log file names start with today's date, so new log file name is given if running past midnight.
# Timestamp function is used to output the time and action into log.csv file.
timestamp() {
    echo "$(date -I) $(date +%T);;$2;iteration $1" >> ~/$(date -d "today" +"%Y%m%d")_log_sus_okular.csv
}

# Log the system info at the time of testing
okular -v > ~/$(date -d "today" +"%Y%m%d")\_system-info.txt
inxi -F >> ~/$(date -d "today" +"%Y%m%d")\_system-info.txt

# Start scripts with everything fresh
# Make sure Okular is not running
killall okular
# Remove previous logs and dot-files
rm -f ~/$(date -d "today" +"%Y%m%d")_log_sus_okular.csv
rm -f ~/.config/okularrc
rm -f ~/.config/okularpartrc
rm -f -r ~/.local/share/okular/*
rm -f -r ~/20yearsofKDE.pdf

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
for ((i = 1 ; i <= 2 ; i++)); do

    # Copy PDF to home directory
    # so PDF is identical every time
    cp ~/Documents/okular/20yearsofKDE.pdf ~/20yearsofKDE.pdf

    # Burn in time
    syncUp 5

    # Start iteration
    echo "$(date -I) $(date +%T);startTestrun;;iteration $i" >> ~/$(date -d "today" +"%Y%m%d")_log_sus_okular.csv
    echo "start iteration $i"

    syncUp 1

    # Open okular, discard STDERR and STDOUT to /dev/null
    echo " Open PDF document 20yearsofKDE.pdf "
    timestamp "$i" "Open PDF document 20yearsofKDE.pdf"
    okular ~/20yearsofKDE.pdf > /dev/null 2>&1 &
    syncUp 1
    # Fit to width
    echo " Fit to width "
    timestamp "$i" "Fit to width"
    xdotool key Ctrl+Shift+w
    syncUp 2

    # Enter page number 38 and jump there
    echo " Open 'Go to' dialogue, type 38 + Return "
    timestamp "$i" "Open 'Go to' dialogue, type 38 + Return"
    xdotool key Ctrl+g
    syncUp 1
    xdotool type --delay 400 "38"
    syncUp 1
    xdotool key Return
    syncUp 1

    # Mark text and insert comment
    echo " Toggle annotation panel "
    timestamp "$i" "Toggle annotation panel"
    # Toggle annotations panel
    xdotool key F6
    syncUp 2
    # Move mouse to center of Okular window
    xdotool mousemove --window "okular" --polar 0 0
    syncUp 2
    # Select highlighter tool
    echo " Toggle highlighter tool, select text to highlight "
    timestamp "$i" "Toggle highlighter tool, select text to highlight"
    xdotool key Alt+1
    # Hold mouse button down, move directly downwards (180) for 75 pixels, unclick
    xdotool mousedown 1 mousemove --polar 180 75 click 1
    syncUp 2
    # Move mouse directly downwards from middle point of
    # window (180) over highlighted text, double click to add note
    echo " Write annotation "
    timestamp "$i" "Write annotation"
    xdotool mousemove --polar 180 25 click --repeat 2 1 type --delay 200 'Very interesting text! I should read more about this topic.'
    syncUp 8
    # return to browsing mode
    echo " Toggle highlighter tool again to return to browsing mode "
    timestamp "$i" "Toggle highlighter tool again to return to browsing mode"
    xdotool key Alt+1
    syncUp 2

    # Start presentation mode and move up and down pages
    echo " Start presentation mode "
    timestamp "$i" "Start presentation mode"
    # Toggle presentation
    xdotool key Ctrl+Shift+p
    syncUp 1
    # Close default popup window
    xdotool key Return
    syncUp 1
    # Move around the pages
    echo " Move down 5 pages "
    timestamp "$i" "Move down 5 pages"
    xdotool key Down
    syncUp 2
    xdotool key Down
    syncUp 2
    xdotool key Down
    syncUp 2
    xdotool key Down
    syncUp 2
    xdotool key Down
    syncUp 1
    echo " Move up 5 pages "
    timestamp "$i" "Move up 5 pages"
    xdotool key Up
    syncUp 2
    xdotool key Up
    syncUp 2
    xdotool key Up
    syncUp 2
    xdotool key Up
    syncUp 2
    xdotool key Up
    syncUp 1
    # Exit
    echo " Exit presentation mode "
    timestamp "$i" "Exit presentation mode"
    xdotool key Escape
    syncUp 1
    # Move mouse to center of Okular window, click mouse to exit text box
    xdotool mousemove --window "okular" --polar 0 0 click 1
    syncUp 3

    # Rotate page right
    echo " Rotate page right twice "
    timestamp "$i" "Rotate page right twice"
    xdotool key Ctrl+r
    syncUp 6
    xdotool key Ctrl+r
    syncUp 6
    # Rotate page left
    echo " Rotate page left twice "
    timestamp "$i" "Rotate page left twice"
    xdotool key Ctrl+l
    syncUp 6
    xdotool key Ctrl+l
    syncUp 6

    # Move around the pages
    echo " Move forward 5 pages "
    timestamp "$i" "Move forward 5 pages"
    xdotool key Right
    syncUp 2
    xdotool key Right
    syncUp 2
    xdotool key Right
    syncUp 2
    xdotool key Right
    syncUp 2
    xdotool key Right
    syncUp 2
    echo " Move backward 5 pages "
    timestamp "$i" "Move backward 5 pages"
    xdotool key Left
    syncUp 2
    xdotool key Left
    syncUp 2
    xdotool key Left
    syncUp 2
    xdotool key Left
    syncUp 2
    xdotool key Left
    syncUp 3

    # Zoom out
    echo " Zoom to 100% "
    timestamp "$i" "Zoom to 100%"
    xdotool key Ctrl+0
    syncUp 3
    echo " Zoom to 400% "
    timestamp "$i" "Zoom to 400%"
    # Zoom in
    xdotool key Ctrl+plus
    syncUp 1
    xdotool key Ctrl+plus
    syncUp 1
    xdotool key Ctrl+plus
    syncUp 1
    xdotool key Ctrl+plus
    syncUp 1
    xdotool key Ctrl+plus
    syncUp 1
    # Fit to width
    echo " Fit to width "
    timestamp "$i" "Fit to width"
    xdotool key Ctrl+Shift+w
    syncUp 1

    # Invert colors
    echo " Invert colors "
    timestamp "$i" "Invert colors"
    # Invert colors
    xdotool key Ctrl+i
    syncUp 5

# START PARTIAL REPEAT
# Note: now goes to page number 42, writes slightly different annotation

    # Enter page number 42 and jump there
    echo " Open 'Go to' dialogue, type 42 + Return "
    timestamp "$i" "Open 'Go to' dialogue, type 42 + Return"
    xdotool key Ctrl+g
    syncUp 1
    xdotool type --delay 400 "42"
    syncUp 1
    xdotool key Return
    syncUp 2

    # Mark text and insert comment
    echo " Toggle annotation panel "
    timestamp "$i" "Toggle annotation panel"
    # Toggle annotations panel
    xdotool key F6
    syncUp 2
    # Move mouse to center of Okular window
    xdotool mousemove --window "okular" --polar 0 0
    syncUp 2
    # Select highlighter tool
    echo " Toggle highlighter tool, select text to highlight "
    timestamp "$i" "Toggle highlighter tool, select text to highlight"
    xdotool key Alt+1
    # Hold mouse button down, move directly downwards (180) for 75 pixels, unclick
    xdotool mousedown 1 mousemove --polar 180 75 click 1
    syncUp 2
    # Move mouse directly downwards from middle point of
    # window (180) over highlighted text, double click to add note
    echo " Write annotation "
    timestamp "$i" "Write annotation"
    xdotool mousemove --polar 180 25 click --repeat 2 1 type --delay 200 'Again this is very interesting, should read more.'
    syncUp 8
    # return to browsing mode
    echo " Toggle highlighter tool again to return to browsing mode "
    timestamp "$i" "Toggle highlighter tool again to return to browsing mode"
    xdotool key Alt+1
    syncUp 1

    # Start presentation mode and move up and down pages
    echo " Start presentation mode "
    timestamp "$i" "Start presentation mode"
    # Toggle presentation
    xdotool key Ctrl+Shift+p
    syncUp 2
    # Close default popup window
    xdotool key Return
    syncUp 19
    # Exit presentation
    echo " Exit presentation mode "
    timestamp "$i" "Exit presentation mode"
    xdotool key Escape
    syncUp 1
    # Move mouse to center of Okular window, click mouse to exit text box
    xdotool mousemove --window "okular" --polar 0 0 click 1
    syncUp 1

    # Rotate page right
    echo " Rotate page right twice "
    timestamp "$i" "Rotate page right twice"
    xdotool key Ctrl+r
    syncUp 6
    xdotool key Ctrl+r
    syncUp 6
    # Rotate page left
    echo " Rotate page left twice "
    timestamp "$i" "Rotate page left twice"
    xdotool key Ctrl+l
    syncUp 6
    xdotool key Ctrl+l
    syncUp 7

    # Move around the pages
    echo " Move forward 5 pages "
    timestamp "$i" "Move forward 5 pages"
    xdotool key Right
    syncUp 2
    xdotool key Right
    syncUp 2
    xdotool key Right
    syncUp 2
    xdotool key Right
    syncUp 2
    xdotool key Right
    syncUp 2
    echo " Move backward 5 pages "
    timestamp "$i" "Move backward 5 pages"
    xdotool key Left
    syncUp 2
    xdotool key Left
    syncUp 2
    xdotool key Left
    syncUp 2
    xdotool key Left
    syncUp 2
    xdotool key Left
    syncUp 2

    # Zoom out
    echo " Zoom to 100% "
    timestamp "$i" "Zoom to 100%"
    xdotool key Ctrl+0
    syncUp 3
    echo " Zoom to 400% "
    timestamp "$i" "Zoom to 400%"
    # Zoom in
    xdotool key Ctrl+plus
    syncUp 1
    xdotool key Ctrl+plus
    syncUp 1
    xdotool key Ctrl+plus
    syncUp 1
    xdotool key Ctrl+plus
    syncUp 1
    xdotool key Ctrl+plus
    syncUp 2
    # Fit to width
    echo " Fit to width "
    timestamp "$i" "Fit to width"
    xdotool key Ctrl+Shift+w
    syncUp 1

    # Invert colors back
    echo " Invert colors back "
    timestamp "$i" "Invert colors back"
    xdotool key Ctrl+i
    syncUp 5

# REPEAT OVER

    ## wrap-up
    # save
    echo " Save PDF "
    timestamp "$i" "Save PDF"
    xdotool key Ctrl+s
    syncUp 1
    # quit okular
    echo " Quit Okular "
    timestamp "$i" "Quit Okular"
    xdotool key Ctrl+q
    syncUp 1

    # end iteration
    echo " end iteration "
    echo "$(date -I) $(date +%T);stopTestrun;;iteration $i" >> ~/$(date -d "today" +"%Y%m%d")_log_sus_okular.csv
    syncUp 1

    ## clean up
    # remove logs
    rm ~/.config/okularrc
    rm ~/.config/okularpartrc
    rm -r ~/.local/share/okular/*
    # delete annotated PDF
    rm ~/20yearsofKDE.pdf

    clear

done
