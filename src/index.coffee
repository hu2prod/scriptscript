require 'fy'

global.stdout = puts

{@tokenize} = require './tokenizer'
{@parse   } = require './grammar'
{@type_inference} = require './type_inference'
{@translate} = require './translator'

@go = (str, opt, on_end)=>
  await @tokenize        str,     opt, defer err, tok_res; return on_end err if err
  await @parse           tok_res, opt, defer err, ast;     return on_end err if err
  await @type_inference  ast[0],  opt, defer err, res;     return on_end err if err # Рано
  await @translate       ast[0],  opt, defer err, res;     return on_end err if err
  
  on_end null, res
