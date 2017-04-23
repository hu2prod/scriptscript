require 'fy'
{Token_parser, Tokenizer} = require 'gram'
module = @

# ###################################################################################################
#    specific
# ###################################################################################################
# API should be async by default in case we make some optimizations in future

tokenizer = new Tokenizer
tokenizer.parser_list.push (new Token_parser 'bracket', /^[\[\]\(\)\{\}]/)

tokenizer.parser_list.push (new Token_parser 'decimal_literal', /^(0|[1-9][0-9]*)/)
tokenizer.parser_list.push (new Token_parser 'octal_literal', /^0o?[0-7]+/i)
tokenizer.parser_list.push (new Token_parser 'hexadecimal_literal', /^0x[0-9a-f]+/i)
tokenizer.parser_list.push (new Token_parser 'binary_literal', /^0b[01]+/i)
tokenizer.parser_list.push (new Token_parser 'unary_operator', /// ^ (
  (--?|\+\+?)|
  [~!]|
  not|
  typeof|
  new|
  delete
)  ///)
tokenizer.parser_list.push (new Token_parser 'binary_operator', /// ^ (
  \.\.\.?|
  \??(::|\.)|
  (\*\*?|//?|%%?|<<|>>>?|&&?|\|\|?|\^\^?|[-+?]|and|or|xor)=?|
  instanceof|in|of|isnt|is|
  [<>!=]=|<|>
) ///)
tokenizer.parser_list.push (new Token_parser 'identifier', /^[_\$a-z][_\$a-z0-9]*/i)

@_tokenize = (str, opt)->
  tokenizer.go str

@tokenize = (str, opt, on_end)->
  try
    res = module._tokenize str, opt
  catch e
    return on_end e
  on_end null, res