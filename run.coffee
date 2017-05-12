#!/usr/bin/env iced
## TODO add shebang & make executable  +
## TODO figure out better name & place & API for such script
## TODO use minimist / optimist

if !process.argv[2]?
  console.error (
    """Usage:    iced run.coffee input [-v|--vv]
       or        ./run.coffee input [-v|--vv]
    """)
  process.exit 1

require 'fy'
{yellow, green, cyan, magenta} = require "colors"

switch process.argv[3]
  when undefined
    # not verbose
    await (require ".").go process.argv[2], {}, defer err, res
    throw err if err
    p res
  
  when "-v"
    p magenta "Input:", cyan process.argv[2]
    await (require ".").go process.argv[2], {}, defer err, res
    throw err if err
    p yellow "Output:", green res
  
  when "--vv"
    p magenta "Input:", cyan.bold process.argv[2]
    {tokenize} = require './tokenizer'
    {parse   } = require './grammar'
    {translate} = require './translator'
    await tokenize  process.argv[2], {}, defer err, tok_res
    throw err if err
    p "Token list:"
    pp tok_res
    debugger
    await parse     tok_res, {}, defer err, ast
    throw err if err
    p yellow.bold "AST[0]:"
    p ast[0]
    p yellow.bold "AST[0].value_array[0]:"
    p ast[0].value_array[0]
    await translate ast[0],  {}, defer err, res
    throw err if err
    p yellow "Output:", green.bold res
  
  else
    perr (
      """Unsupported option: #{process.argv[3]}
         Supported options are: -v, --vv (or you can omit an option).
      """)
    process.exit 1
