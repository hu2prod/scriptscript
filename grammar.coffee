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
q('rvalue', '#lvalue')                  .mx("priority=#{base_priority}")

q('const', '#decimal_literal')
q('const', '#octal_literal')
q('const', '#hexadecimal_literal')
q('const', '#binary_literal')
q('rvalue','#const')                    .mx("priority=#{base_priority}")

q('pre_op',  '-').mx('priority=1')
q('pre_op',  '+').mx('priority=1')

# TODO all ops
q('bin_op',  '*|/|%')       .mx('priority=5 right_assoc=1')
q('bin_op',  '+|-')         .mx('priority=6 right_assoc=1')

# NOTE need ~same rule for lvalue
q('rvalue',  '( #rvalue )')             .mx("priority=#{base_priority}")

q('rvalue',  '#rvalue #bin_op #rvalue')       .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority<#bin_op.priority')
q('rvalue',  '#rvalue #bin_op #rvalue')       .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority=#bin_op.priority #bin_op.left_assoc')
q('rvalue',  '#rvalue #bin_op #rvalue')       .mx('priority=#bin_op.priority')       .strict('#rvalue[1].priority=#bin_op.priority #rvalue[2].priority<#bin_op.priority #bin_op.right_assoc')
q('rvalue',  '#pre_op #rvalue')               .mx('priority=#pre_op.priority')       .strict('#rvalue[1].priority<=#pre_op.priority')

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
