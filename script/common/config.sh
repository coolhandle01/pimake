#!/bin/bash

function sed_escape() {
  sed -e 's/[]\/$*.^[]/\\&/g'
}

# path, key -> value
function cfg_read() {
  test -f "$1" && grep "^$(echo "$2" | sed_escape)=" "$1" | sed "s/^$(echo "$2" | sed_escape)=//" | tail -1
}

# path, key, value ->
function cfg_write() { 
  cfg_delete "$1" "$2"
  echo "$2=$3" >> "$1"
}

# path, key ->
function cfg_delete() {
  test -f "$1" && sed -i "/^$(echo $2 | sed_escape).*$/d" "$1"
}

# path, key -> 
function cfg_haskey() {
  test -f "$1" && grep "^$(echo "$2" | sed_escape)=" "$1" > /dev/null
}
