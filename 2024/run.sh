#!/usr/bin/env bash

DAY=$1
PART=$2

[ ! -f "./zig-out/bin/day$DAY" ] && echo "Not solved yet" && exit 1

./zig-out/bin/day$DAY $PART
