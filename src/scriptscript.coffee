#!/usr/bin/env iced

# TODO
# no args - REPL
# no options - exec
# -c - compile      +
# -o - output dir
# -O - output file  +
# -p - stdout
# -s - stdin
# -e - exec

require "fy"
fs = require 'fs'
argv = require('minimist')(process.argv.slice(2))

if argv.c
  try
    input = fs.readFileSync argv.c, "utf8"
  catch err
    perr err.message
    process.exit 1
else
  perr """
    For now, -c option is required.
    Usage:
      s10t -c input.ss -O output.js
      s10t -c input.ss                # print result to stdout
  """
  process.exit 1

me = require ".."
await me.go input, {}, defer err, res
throw err if err

if argv.O
  try
    fs.writeFileSync argv.O, res, "utf8"
  catch err
    perr err.message
    process.exit 1
else
  process.stdout.write res
