require 'fy'
{Gram} = require 'gram'
module = @

# ###################################################################################################
#    specific
# ###################################################################################################
# API should be async by default in case we make some optimizations in future

g = new Gram
q = (a, b)->g.rule a,b
base_priority = -9000
q('lvalue', '#identifier')
q('rvalue', '#lvalue')                                  .mx("priority=#{base_priority}")

q('const', '#decimal_literal')
q('const', '#octal_literal')
q('const', '#hexadecimal_literal')
q('const', '#binary_literal')
q('rvalue','#const')                                    .mx("priority=#{base_priority}")

q('pre_op',  '!')                                       .mx('priority=1')
q('pre_op',  'not')                                     .mx('priority=1')
q('pre_op',  '~')                                       .mx('priority=1')
q('pre_op',  '-')                                       .mx('priority=1')
q('pre_op',  '+')                                       .mx('priority=1')
q('pre_op',  'typeof')                                  .mx('priority=1')
q('pre_op',  'void')                                    .mx('priority=1')
# ++ -- pre_op is banned.

q('post_op', '++').mx('priority=1')
q('post_op', '--').mx('priority=1')

# https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Operators/Operator_Precedence
# TODO all ops
pipe_priority = 100

q('bin_op',  '**')                                      .mx('priority=4  left_assoc=1')
q('bin_op',  '*|/|%')                                   .mx('priority=5  right_assoc=1')
q('bin_op',  '+|-')                                     .mx('priority=6  right_assoc=1')
q('bin_op',  '<<|>>|>>>')                               .mx('priority=7  right_assoc=1')
q('bin_op',  'instanceof')                              .mx('priority=8  right_assoc=1')
q('bin_op',  '<|<=|>|>=|!=|==')                         .mx('priority=9  right_assoc=1') # NOTE == <= has same priority
q('bin_op',  '&&|and|or|[PIPE][PIPE]')                  .mx('priority=10 right_assoc=1')


q('bin_op',  '#multipipe')                              .mx("priority=#{pipe_priority} right_assoc=1") # возможно стоит это сделать отдельной конструкцией языка дабы проверять всё более тсчательно
q('multipipe',  '[PIPE] #multipipe?')

# NOTE need ~same rule for lvalue
q('rvalue',  '( #rvalue )')                             .mx("priority=#{base_priority}")

q('rvalue',  '#rvalue #bin_op #rvalue')                 .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority<#bin_op.priority')
q('rvalue',  '#rvalue #bin_op #rvalue')                 .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority=#bin_op.priority #bin_op.left_assoc')
q('rvalue',  '#rvalue #bin_op #rvalue')                 .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority=#bin_op.priority #rvalue[2].priority<#bin_op.priority #bin_op.right_assoc')
# indent set
q('rvalue',  '#rvalue #bin_op #indent #rvalue #dedent') .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority<#bin_op.priority')
q('rvalue',  '#rvalue #bin_op #indent #rvalue #dedent') .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority=#bin_op.priority #bin_op.left_assoc')
q('rvalue',  '#rvalue #bin_op #indent #rvalue #dedent') .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority=#bin_op.priority #rvalue[2].priority<#bin_op.priority #bin_op.right_assoc')
# indent+pipe
q('pre_pipe_rvalue',  '#multipipe #rvalue')                                                    #.strict("#rvalue.priority<#{pipe_priority}")
q('pre_pipe_rvalue',  '#pre_pipe_rvalue #eol #multipipe #rvalue')                              #.strict("#rvalue.priority<#{pipe_priority}")
q('rvalue',  '#rvalue #multipipe #indent #pre_pipe_rvalue #dedent').mx("priority=#{pipe_priority}").strict("#rvalue[1].priority<=#{pipe_priority}")


q('rvalue',  '#pre_op #rvalue')                         .mx('priority=#pre_op.priority')       .strict('#rvalue[1].priority<=#pre_op.priority')
q('rvalue',  '#rvalue #post_op')                        .mx('priority=#post_op.priority')      .strict('#rvalue[1].priority<#post_op.priority') # a++ ++ is not allowed
# array
q('comma_rvalue',  '#rvalue')
q('comma_rvalue',  '#eol #comma_rvalue')
q('comma_rvalue',  '#comma_rvalue , #rvalue')
q('array',  '[ #comma_rvalue? #eol? ]')                 .mx("priority=#{base_priority}")
q('array',  '[ #indent #comma_rvalue? #dedent ]')       .mx("priority=#{base_priority}")
q('rvalue',  '#array')
# NOTE lvalue array come later

q('stmt',  '#rvalue')

@_parse = (str, opt)->
  debugger
  res = g.parse_text_list str,
    expected_token : 'stmt'
  if res.length == 0
    throw new Error "Parsing error. No proper combination found"
  res

@parse = (str, opt, on_end)->
  try
    res = module._parse str, opt
  catch e
    return on_end e
  on_end null, res
