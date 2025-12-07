#!/usr/bin/env bash

FIRST_YEAR=2015
CURRENT_YEAR=$(date +%Y)
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

function runDay() {
  year=$1
  day=$2

  [[ $PART == "all" ]] || [ "$PART" -eq "1" ] && ./run.sh $day 1
  [[ $PART == "all" ]] || [ "$PART" -eq "2" ] && [ "$day" -lt "25" ] && ./run.sh $day 2
}

function runYear() {
  year=$1

  pushd "$SCRIPT_DIR/$year" > $LOG_OUTPUT

  [ ! -f "./run.sh" ] && echo "Not solved yet" && return
  [ -f "./build.sh" ] && ./build.sh > $LOG_OUTPUT

  if [[ $DAY == "all" ]]; then
    lastDay=25
    [ "$year" -ge "2025" ] && lastDay=12
    
    for day in $(seq 1 $lastDay); do
      echo "Day $day:"
      runDay $year $day
      echo ""
    done
  else
    runDay $year $DAY
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
