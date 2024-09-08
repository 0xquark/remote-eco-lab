#! /usr/bin/env bash

## This script adds the option to add user
## configurations such as shortcuts which might
## be used to make the automation process easier.
## Make the changes locally and push in the reqd.
## configuration file with your MR (together with
## the usage scenario scripts).

## EXAMPLE: The following is used to load custom shortcuts to okular
## SEE: https://invent.kde.org/teams/eco/remote-eco-lab/-/blob/master/scripts/test_scripts/org.kde.okular/configuration.sh
## AND: https://invent.kde.org/teams/eco/remote-eco-lab/-/blob/master/scripts/test_scripts/org.kde.okular/part.rc

## Import user configurations
echo "Importing user configurations"
sleep 1

## Remove previous configuration file(if any present) from KEcoLab:
## HINT: These maybe present in `~/.local/share` or '~/.config/'
rm <PATH/TO/CONFIGURATION-FILE>
sleep 1

## Copy the configuration files to the reqd. location.
## You may be reqd. to create a folder for this.
[mkdir <PATH/TO/CONFIGURATION-FOLDER]
cp <FILENAME> <PATH/TO/CONFIGURATION-FILE>
sleep 1

echo "Finished importing user configurations"
