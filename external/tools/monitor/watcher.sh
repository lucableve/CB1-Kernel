#!/bin/bash
#echo $$ > watcher.pid

if [ "$1" == "--flush" ]; then
  # Remove the ./data folder if the --flush option is present
  rm -rf ./data
fi

mkdir -p ./data

# Function to get the current date and time in the format "day/month/year hour:minutes:seconds"
get_current_datetime() {
  TZ="Europe/Rome" date "+%d/%m/%Y %H:%M:%S"
}

# Function to print the ghostInputs table
data_table() {
  local file_path=$1

  echo "+---------------------+--------+-------+-------+------+-------+"
  echo "|        DATA         |   RT   | TC Z1 | TC Z2 | TC X | TC Y  |"
  echo "+---------------------+--------+-------+-------+------+-------+"

  while read -r line; do
    data=$(echo "$line" | grep -oP '\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}')
    rt=$(echo "$line" | grep -oP 'RT: \(\s*\K\d+(?=\s*\))')
    tc_z1=$(echo "$line" | grep -oP 'TC Z1: \(\s*\K\d+(?=\s*\))')
    tc_z2=$(echo "$line" | grep -oP 'TC Z2: \(\s*\K\d+(?=\s*\))')
    tc_x=$(echo "$line" | grep -oP 'TC X: \(\s*\K\d+(?=\s*\))')
    tc_y=$(echo "$line" | grep -oP 'TC Y: \(\s*\K\d+(?=\s*\))')

    printf "| %-19s | %-6s | %-5s | %-5s | %-4s | %-5s |\n" \
      "$data" "$rt" "$tc_z1" "$tc_z2" "$tc_x" "$tc_y"
  done < "$file_path"

  echo "+---------------------+--------+-------+-------+------+-------+"
}

startup_datetime=$(get_current_datetime)  # Get the startup date and time
startup_time_seconds=$(date -d "$startup_datetime" +"%s")  # Initialize startup time

cleanup() {
  # Clean up temporary resources here, for example, delete the data.debug file
  rm -f ./data/data.debug
}

# Handle script exit
trap cleanup EXIT

# Start monitoring
#stdbuf -oL dmesg -w | grep -A 8 "tsc2007" | grep "RT:" | stdbuf -oL awk -F"[()]" '{print $2; fflush();}' > "data.debug" &
stdbuf -oL dmesg -w | grep -o '\[DEBUG TSC\] TOUCH[^\n]*' > "./data/data.debug" &

# Store the process ID
pid=$!

# Function to print a row of the table
print_row_counters() {
  printf "| %-36s | %-23s | %-23s |\n" "$1" "$2"  "$3"
}

# Function to print a row of the table
print_row_global() {
  printf "| %-110s |\n" "Total Reads: $1"
}

counter=0
events=0
acceptedTrigger=0
ghostInputs=0

# Initialize elapsed time only in the first cycle
while true; do
  lastTouchTrigger=99999999999
  lastTouchLine=""

  while read -r line; do

    rt=$(echo "$line" | grep -oP 'RT: \(\K\d+(?=\))')

    if [[ $line =~ "TOUCH TRIGGERED" ]]; then
              events=$((events + 1))
              counter=$((counter + 1))
              lastTouchTrigger="$rt"
              lastTouchLine="$line"
              echo "$(TZ='Europe/Rome' date '+%d/%m/%Y %H:%M:%S') | $lastTouchLine" >> ./data/acceptedTrigger.debug
    fi

  done < "./data/data.debug"

  # Get the date and time of the last update
  update_datetime=$(get_current_datetime)

  clear
  # Print the startup date and time
  echo "Startup datetime: $startup_datetime"
  # Print the date and time of the last update
  echo "Last update datetime: $update_datetime"

  if [ -s ./data/acceptedTrigger.debug ]; then
    # The condition is true, you can perform desired actions
    echo "+-------------------------------------------------------------+"
    echo "|                     TRIGGER DATA                    |"
    data_table ./data/acceptedTrigger.debug
  else
    # The condition is false, you can perform desired actions
    echo "NO TRIGGER INPUT"
  fi
   printf "\n"

  > ./data/data.debug
  sleep 1
done
