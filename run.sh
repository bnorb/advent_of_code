#!/usr/bin/env bash

FIRST_YEAR=2015
CURRENT_YEAR=$(date +%Y)
CUTOFF_YEAR="2025" # from this year, there are only 12 days of puzzles instead of 25
YEAR="$CURRENT_YEAR"
DAY=$(date +%-d)
PART=1
SCRIPT_DIR=$(dirname "$(realpath $0)")
LOG_OUTPUT="/dev/null"

function help() {
  errorMessage=$1
  exitCode=${2:-1}

  if [ -n "$errorMessage" ]; then
    echo -ne "ERROR: $errorMessage\n\n"
  fi

  cat << EOF
Usage: run.sh [OPTIONS]

OPTIONS:
  -y, --year number|all       Year to run ($FIRST_YEAR-$CURRENT_YEAR), or 'all' to run every year (default: current year)
  -d, --day number|all        Day to run (1-25), or 'all' to run every day (default: current day of the month)
  -p, --part 1|2|all          Part to run (1-2) or 'all' to run both parts (default: 1)
  -v, --verbose               Show more logs
  -h, --help                  Show this help
EOF

  exit $exitCode
}

function error() {
  message=$1

  echo $message

  exit 1
}

function validateYear() {
  [[ "$YEAR" == "all" ]] && return

  re='^[0-9]{4}$'  
  [[ "$YEAR" =~ $re ]] && [ "$YEAR" -ge "$FIRST_YEAR" ] && [ "$YEAR" -le "$CURRENT_YEAR" ] && return
  
  help "Year must be a number between $FIRST_YEAR-$CURRENT_YEAR or 'all'. Got: '$YEAR'"
}

function validateDay() {
  [[ "$DAY" == "all" ]] && return

  re='^[0-9]{1,2}$'  
  [[ "$DAY" =~ $re ]] && [ "$DAY" -ge "1" ] && [ "$DAY" -le "25" ] && return

  help "Day must be a number between 1-25 or 'all'. Got: '$DAY'"
}

function validatePart() {
  [[ "$PART" == "all" ]] && return

  re='^[12]$'  
  [[ "$PART" =~ $re ]] && return

  help "Part must be a number between 1-2 or 'all'. Got: '$PART'"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--year)
      YEAR="$2"
      validateYear
      shift;shift
      ;;
    -d|--day)
      DAY="$2"
      validateDay
      shift;shift
      ;;
    -p|--part)
      PART="$2"
      validatePart
      shift;shift
      ;;
    -v|--verbose)
      LOG_OUTPUT="/dev/stdout"
      shift
      ;;
    -h|--help)
      help "" 0
      ;;
    *)
      help "Unknown argument $1"
      ;;
  esac
done

[ -f "./.env" ] && source ./.env

function getInput() {
  year=$1
  day=$2

  command -v wget > /dev/null || error "Need wget to download input"

  [ -n "$AOC_SESSION" ] || error "Need AOC_SESSION set up in .env file to download input"

  wget --quiet --header="Cookie: session=$AOC_SESSION" -O "./input/day$day.txt" "https://adventofcode.com/$year/day/$day/input"
}

function runDay() {
  year=$1
  day=$2
  lastDay=$3

  [ "$day" -gt "$lastDay" ] && error "Trying to run day $day, but last day is $lastDay"

  [ -f "./input/day$day.txt" ] || getInput $year $day

  [[ $PART == "all" ]] || [ "$PART" -eq "1" ] && ./run.sh $day 1
  [[ $PART == "all" ]] || [ "$PART" -eq "2" ] && [ "$day" -lt "$lastDay" ] && ./run.sh $day 2
}

function runYear() {
  year=$1

  pushd "$SCRIPT_DIR/$year" > $LOG_OUTPUT

  [ ! -f "./run.sh" ] && echo "Not solved yet" && return
  [ -f "./build.sh" ] && ./build.sh > $LOG_OUTPUT

  lastDay=25
  [ "$year" -ge "$CUTOFF_YEAR" ] && lastDay=12

  if [[ $DAY == "all" ]]; then
    for day in $(seq 1 $lastDay); do
      echo "Day $day:"
      runDay $year $day $lastDay
      echo ""
    done
  else
    runDay $year $DAY $lastDay
  fi

  popd > $LOG_OUTPUT
}

if [[ $YEAR == "all" ]]; then
  for year in $(seq $FIRST_YEAR $CURRENT_YEAR); do
    cat << EOF
#############
# Year $year #
#############
EOF
    runYear $year
    echo ""
  done
else
  runYear $YEAR
fi
