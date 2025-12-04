#!/usr/bin/env bash

DAY=$1
PART=$2

[ ! -f "./src/days/day$DAY.js" ] && echo "Not solved yet" && exit 1

bun run ./src/main.ts $DAY $PART
