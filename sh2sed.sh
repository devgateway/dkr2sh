#!/bin/sh
# escape shell script for use as sed string
unexpand -t 2 --first-only $1 | sed -n 's/[\&/]/\\&/g; s/\t/\\t/g; 1h; 1!H; $ {g; s/\n/\\n/g; p}'
