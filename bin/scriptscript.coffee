#!/usr/bin/env iced
# NO TESTS FOR NOW
# tests will be added later
### !pragma coverage-skip-block ###
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
      s10t -c input.ss -o output.js
      s10t -c input.ss                # print result to stdout
  """
  process.exit 1

me = require ".."
await me.go input, {}, defer err, res
### !pragma coverage-skip-block ###
throw err if err

if argv.o
  try
    fs.writeFileSync argv.o, res, "utf8"
  catch err
    perr err.message
    process.exit 1
else
  p "output:", res
