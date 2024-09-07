#! /usr/bin/env bash

## This script adds custom shortcuts. Change
## the default shortcuts locally and push in
## your MR (together with the usage scenario
## script).

## SEE: https://invent.kde.org/teams/eco/remote-eco-lab/-/blob/master/scripts/test_scripts/org.kde.okular/configuration.sh
## AND: https://invent.kde.org/teams/eco/remote-eco-lab/-/blob/master/scripts/test_scripts/org.kde.okular/part.rc

## Import custom shortcuts
echo "Importing custom shortcuts"
sleep 1
## Remove previous configuration file:
## change path to remove any previous shortcuts.
rm ~/.local/share/kxmlgui5/<PATH/TO/FILENAME>
sleep 1
## Change filename and path to import your shortcuts
cp <FILENAME> ~/.local/share/kxmlgui5/<PATH/TO/FILE>
sleep 1
echo "Finished importing shortcuts"
