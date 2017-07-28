#!/usr/bin/env iced
### !pragma coverage-skip-block ###

require "fy"
fs = require 'fs'
ss = require ".."
{red} = require "colors"
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

geval = eval    # this magic prevents exposing local scope

#################################### utils ####################################

print_error = (err, debug, prefix="") ->
  perr red.bold(prefix +
    if debug
    then err.stack
    else err.stack.split('\n')[...2].join('\n') + "\n    <You can see full stack trace in debug mode (-d option or :d in the REPL)>"
  )

try_eval = (err, res)->
  if err
    print_error err, a.d
    return
  if a.e
    try
      geval res
    catch eval_err
      print_error eval_err, a.d
  if a.p or !a.e
    puts res

##################################### REPL ####################################

if !a.s and !a.p and !a.c and !a.o and !a.i and !a.e and !a._.length
  (require "repl").start eval: (input, skip1, skip2, cb)->
    if input.startsWith ":c "
      await ss.go input[3...], {}, defer err, res
      ### !pragma coverage-skip-block ###
      if err
        print_error err, a.d
        cb()
      else
        cb null, res
      return
    debug = input.startsWith ":d "
    input = input[3...] if debug
    await ss.go input, {}, defer ss_err, res
    ### !pragma coverage-skip-block ###
    if ss_err
      print_error ss_err, a.d or debug
      cb()
    else
      try
        ret = geval res
        cb null, ret
      catch eval_err
        print_error eval_err, a.d or debug
        cb()
    return

################################### compiler ##################################

compile = (file, cb)->
  await fs.readFile file, "utf8", defer err, contents
  ### !pragma coverage-skip-block ###
  if err
    print_error err, a.d, file + ": "
    return cb(err, null)
  await ss.go contents, {}, defer err, res
  ### !pragma coverage-skip-block ###
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
    if err
      print_error err, a.d, file + ": "
      continue
    if a.c
      await fs.writeFile "#{a.o or '.'}/#{file.replace /\.\w+$/, '.js'}", res, "utf8"
      ### !pragma coverage-skip-block ###
      if err
        print_error err, a.d, file + ": "
        continue
    ### !pragma coverage-skip-block ###
    if a.p
      puts res
    if a.e and typeof a.e == "boolean" or !a.s and !a.p and !a.c and !a.o and !a.i
      try
        geval res
      catch err
        print_error err, a.d, file + ": "
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
  try_eval err, res
### !pragma coverage-skip-block ###

################################ Other options ################################

if a.i
  await ss.go a.i, {}, defer err, res
  ### !pragma coverage-skip-block ###
  try_eval err, res
### !pragma coverage-skip-block ###

if a.e and typeof a.e != "boolean"
  await ss.go a.e, {}, defer err, res
  ### !pragma coverage-skip-block ###
  try_eval err, res
