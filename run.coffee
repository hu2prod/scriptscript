# # TODO figure out better name & place & API for such script
# # TODO add shebang & make executable
require 'fy'
if !process.argv[2]?
  perr "Usage: iced run.coffee [input]"
  process.exit 1
## -v 0
# me = require "."
# await me.go process.argv[2], {}, defer err, res
# throw err if err
# p res

## -v 2
p "Input:", process.argv[2] # just to make sure that we are given the right string
{tokenize} = require './tokenizer'
{parse   } = require './grammar'
{translate} = require './translator'
await tokenize  process.argv[2], {}, defer err, tok_res
throw err if err
p "Token list:"
pp tok_res
await parse     tok_res, {}, defer err, ast
throw err if err
p "AST:"
p ast
await translate ast[0],  {}, defer err, res
throw err if err
p "Output: ", res

