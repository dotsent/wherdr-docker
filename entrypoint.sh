#!/bin/sh
set -eu

install -d -m 0700 "$XDG_RUNTIME_DIR"
hc server start
exec node .output/server/index.mjs
