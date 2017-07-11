#!/usr/bin/env iced
### !pragma coverage-skip-block ###

require "fy"
fs = require 'fs'
ss = require ".."
a = require('minimist') process.argv.slice(2), 
  boolean: ['s', 'p', 'c', 'd']
  string: ['o', 'i']
  # -e can be boolean or string
  alias: 
    's': "stdin"
    'p': "print"
    'c': "compile"
    'o': "output"
    'i': "input" 
    'e': "exec"
    'd': "debug"

if a.d
  pp a

##################################### REPL ####################################

if !a.s and !a.p and !a.c and !a.o and !a.i and !a.e and !a._.length
  geval = eval
  (require "repl").start eval: (input, skip1, skip2, cb)->
    if input.startsWith ":c "
      await ss.go input[3...], {}, defer err, res
      ### !pragma coverage-skip-block ###
      return cb err, res
    debug = input.startsWith ":d "
    input = input[3...] if debug
    await ss.go input, {}, defer ss_err, res
    ### !pragma coverage-skip-block ###
    if ss_err
      perr if a.d or debug then ss_err.stack else ss_err.message
      cb()
    else
      try
        ret = geval res
        cb null, ret
      catch eval_err
        perr if a.d or debug then eval_err.stack else eval_err.message
        cb()
    return

################################### compiler ##################################

compile = (file, cb)->
  await fs.readFile file, "utf8", defer err, contents
  ### !pragma coverage-skip-block ###
  if err
    perr file + ": " + if a.d then err.stack else err.message
    return cb(err, null)
  await ss.go contents, {}, defer err, res
  ### !pragma coverage-skip-block ###
  if err
    perr file + ": " + if a.d then err.stack else err.message
  cb(err, res)

# a._ contents are treated as filenames to compile
if a._.length
  if a.o and a.c
    await (require "child_process").exec "mkdir -p #{a.o}", defer err, stdout, stderr
    ### !pragma coverage-skip-block ###
    throw err if err
  ### !pragma coverage-skip-block ###
  for file in a._
    await compile file, defer err, res
    ### !pragma coverage-skip-block ###
    throw err if err
    if a.c
      await fs.writeFile "#{a.o or '.'}/#{file.replace /\.\w+$/, '.js'}", res, "utf8"
      ### !pragma coverage-skip-block ###
      if err
        perr file + ": " + if a.d then err.stack else err.message
        continue
    ### !pragma coverage-skip-block ###
    if a.p
      p res
    if a.e and typeof a.e == "boolean" or !a.s and !a.p and !a.c and !a.o and !a.i
      try
        eval res
      catch err
        perr file + ": " + if a.d then err.stack else err.message
### !pragma coverage-skip-block ###
#################################### stdin ####################################

read_stdin = (cb)->
  input = ""
  process.stdin.setEncoding 'utf8'
  process.stdin.on 'readable', ()->
    chunk = process.stdin.read();
    input += chunk if chunk
  process.stdin.on 'end', ()->
    cb null, input

if a.s
  await read_stdin defer err, input
  ### !pragma coverage-skip-block ###
  await ss.go input, {}, defer err, res
  ### !pragma coverage-skip-block ###
  throw err if err
  if a.e
    eval res
  if a.p or !a.e
    p res
### !pragma coverage-skip-block ###

################################## CLI input ##################################

if a.i
  await ss.go a.i, {}, defer err, res
  ### !pragma coverage-skip-block ###
  throw err if err
  if a.e
    eval res
  if a.p or !a.e
    process.stdout.write res
### !pragma coverage-skip-block ###
##################################### exec ####################################

if a.e and typeof a.e != "boolean"
  await ss.go a.e, {}, defer err, res
  ### !pragma coverage-skip-block ###
  throw err if err
  eval res
