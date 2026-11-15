#!/bin/sh
printf '\033c\033]0;%s\a' DopamineBouce
base_path="$(dirname "$(realpath "$0")")"
"$base_path/DopamineBouce.x86_64" "$@"
