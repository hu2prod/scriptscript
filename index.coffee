require 'fy'

{tokenize} = require './tokenizer'
{parse} = require './grammar'
@tokenize = tokenize
@parse = parse
@go = (str, opt, on_end)->
  await tokenize str,     opt, defer err, tok_res; return on_end err if err
  await parse    tok_res, opt, defer err, res; return on_end err if err
  
  on_end null, res
