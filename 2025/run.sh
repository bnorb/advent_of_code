#!/usr/bin/env bash

DAY=$1
PART=$2

[ ! -f "./src/day$DAY/solution.ts" ] && echo "Not solved yet" && exit 1

bun run ./src/main.ts $DAY $PART
