#!/usr/bin/env bash

DAY=$1
PART=$2

[ ! -f "./days/day$DAY/part$PART.ts" ] && echo "Not solved yet" && exit 1

bun run ./days/day$DAY/part$PART.ts
