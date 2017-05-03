require 'fy'
{Token_parser, Tokenizer, Node} = require 'gram'
module = @

# ###################################################################################################
#    specific
# ###################################################################################################
# API should be async by default in case we make some optimizations in future

last_space = 0
tokenizer = new Tokenizer
tokenizer.parser_list.push (new Token_parser 'Xdent', /^\n/, (_this, ret_value, q)->
  _this.text = _this.text.substr 1 # \n
  tail_space_len = /^[ \t]*/.exec(_this.text)[0].length
  _this.text = _this.text.substr tail_space_len
  if tail_space_len != last_space
    while last_space < tail_space_len
      node = new Node
      node.mx_hash.hash_key = 'indent'
      ret_value.push [node]
      last_space += 2
    
    while last_space > tail_space_len
      indent_change_present = true
      node = new Node
      node.mx_hash.hash_key = 'dedent'
      ret_value.push [node]
      last_space -= 2
  else
    return if _this.ret_access.last()?[0].mx_hash.hash_key == 'eol' # do not duplicate
    node = new Node
    node.mx_hash.hash_key = 'eol'
    ret_value.push [node]
    
  last_space = tail_space_len
)

tokenizer.parser_list.push (new Token_parser 'bracket', /^[\[\]\(\)\{\}]/)
tokenizer.parser_list.push (new Token_parser 'decimal_literal', /^(0|[1-9][0-9]*)/)
tokenizer.parser_list.push (new Token_parser 'octal_literal', /^0o?[0-7]+/i)
tokenizer.parser_list.push (new Token_parser 'hexadecimal_literal', /^0x[0-9a-f]+/i)
tokenizer.parser_list.push (new Token_parser 'binary_literal', /^0b[01]+/i)
# .123 syntax must be enabled by option
# tokenizer.parser_list.push (new Token_parser 'float_literal', ///
#   ^ (?:
#       (?:
#         \d+\.\d* |
#         \.\d+
#       )  (?:e[+-]?\d+)? |
#       \d+(?:e[+-]?\d+)
#     )
#   ///i)
tokenizer.parser_list.push (new Token_parser 'float_literal', ///
  ^ (?:
      (?:
        \d+\.\d*
      )  (?:e[+-]?\d+)? |
      \d+(?:e[+-]?\d+)
    )
  ///i)
tokenizer.parser_list.push (new Token_parser 'this', /^@/)
tokenizer.parser_list.push (new Token_parser 'comma', /^,/)
tokenizer.parser_list.push (new Token_parser 'pair_separator', /^:/)
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
  [<>!=]=|<|>|
  =
) ///)
tokenizer.parser_list.push (new Token_parser 'identifier', /^[_\$a-z][_\$a-z0-9]*/i)
tokenizer.parser_list.push (new Token_parser 'arrow_function', /^[-=]>/)
# Version from the CoffeeScript source code: /^###([^#][\s\S]*?)(?:###[^\n\S]*|###$)|^(?:\s*#(?!##[^#]).*)+/
tokenizer.parser_list.push (new Token_parser 'comment', /^(###[^#][^]*###|#.*\n)/)

@_tokenize = (str, opt)->
  # reset
  last_space = 0
  
  # TODO later better replace policy/heur
  str = str.replace /\t/, '  '
  str += "\n" # dedent fix
  res = tokenizer.go str
  while res.length && res.last()[0].mx_hash.hash_key == 'eol'
    res.pop()
  res

@tokenize = (str, opt, on_end)->
  try
    res = module._tokenize str, opt
  catch e
    return on_end e
  on_end null, res