#!/bin/bash

if [ "$1" == "--flush" ]; then
  # Remove the ./data folder if the --flush option is present
  rm -rf ./data
fi

clear & dmesg -w | grep 'TOUCH TRIGG'

