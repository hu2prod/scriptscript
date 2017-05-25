#!/usr/bin/env iced
### !pragma coverage-skip-block ###
## TODO add shebang & make executable  +
## TODO figure out better name & place & API for such script
require 'fy'
{yellow, green, cyan, magenta} = require "colors"
{tokenize} = require './tokenizer'
{parse   } = require './grammar'
{type_inference} = require './type_inference'
{translate} = require './translator'

argv = require('minimist')(process.argv.slice(2))
input = argv._[0].trim()
if !input
  console.error """
    -i    print input
    -t    print tokens
    -a    print ast
    
    Usage:    iced run.coffee input [-ita]
       or        ./run.coffee input [-ita]
    """
  process.exit 1

# some escape remove
input = input.replace /\\n/g, "\n"

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