#!/usr/bin/env iced
### !pragma coverage-skip-block ###
require 'fy'
{yellow, green, cyan, magenta} = require "colors"
{tokenize, _tokenize} = require './tokenizer'
{parse   , _parse   } = require './grammar'
{type_inference, _type_inference} = require './type_inference'
{translate, _translate} = require './translator'

argv = require('minimist')(process.argv.slice(2))
input = argv._[0]?.toString().trim()
if !input
  console.error """
    -i     print input
    -t     print tokens
    -a     print ast
    --perf launch test specified times and hang
    
    Usage:    iced run.coffee input [-ita]
       or        ./run.coffee input [-ita]
    """
  process.exit 1

# some escape remove
input = input.replace /\\n/g, "\n"

perform_test = (on_end=->)->
  ### !pragma coverage-skip-block ###
  if argv.i
    p magenta "Input:", cyan.bold input
  await tokenize input, {}, defer err, tok_res
  ### !pragma coverage-skip-block ###
  throw err if err
  if argv.t
    p "Token list:"
    pp tok_res
  await parse     tok_res, {}, defer err, ast
  throw err if err
  ### !pragma coverage-skip-block ###
  await type_inference ast[0],  {}, defer err, res
  throw err if err
  ### !pragma coverage-skip-block ###

  if argv.a
    p yellow.bold "AST[0]:"
    p ast[0]
    p yellow.bold "AST[0].value_array[0]:"
    p ast[0].value_array[0]

  await translate ast[0],  {}, defer err, res
  ### !pragma coverage-skip-block ###
  throw err if err
  p yellow "Output:", green.bold res
  on_end()

perform_test_sync = ()->
  ### !pragma coverage-skip-block ###
  if argv.i
    p magenta "Input:", cyan.bold input
  tok_res = _tokenize input, {}
  if argv.t
    p "Token list:"
    pp tok_res
  ast = _parse     tok_res, {}
  res = _type_inference ast[0],  {}
  if argv.a
    p yellow.bold "AST[0]:"
    p ast[0]
    p yellow.bold "AST[0].value_array[0]:"
    p ast[0].value_array[0]

  res = _translate ast[0],  {}
  p yellow "Output:", green.bold res

if argv.perf
  global.perf_counter = 0
  for i in [0 ... argv.perf]
    perform_test_sync()
  console.log "global.perf_counter=#{global.perf_counter}"
  setTimeout (()->), 1e10
else
  perform_test() # async call is not necessary