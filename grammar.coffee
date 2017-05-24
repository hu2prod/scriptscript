require 'fy'
{Gram} = require 'gram'
module = @

# ###################################################################################################
#    specific
# ###################################################################################################
# API should be async by default in case we make some optimizations in future

g = new Gram
q = (a, b)->g.rule a,b

# ###################################################################################################
#    1-position tokens/const
# ###################################################################################################
base_priority = -9000
q('lvalue', '#identifier')                              .mx("priority=#{base_priority} tail_space=$1.tail_space ult=value ti=id")
q('rvalue', '#lvalue')                                  .mx("priority=#{base_priority} tail_space=$1.tail_space ult=deep  ti=pass")

q('num_const', '#decimal_literal')                      .mx("ult=value ti=const type=int")
q('num_const', '#octal_literal')                        .mx("ult=value ti=const type=int")
q('num_const', '#hexadecimal_literal')                  .mx("ult=value ti=const type=int")
q('num_const', '#binary_literal')                       .mx("ult=value ti=const type=int")
q('num_const', '#float_literal')                        .mx("ult=value ti=const type=float")
q('const', '#num_const')                                .mx("ult=deep ti=pass")
q('str_const', '#string_literal_singleq')               .mx("ult=value ti=const type=string")
q('str_const', '#block_string_literal_singleq')         .mx("ult=value ti=const type=string")
q('str_const', '#string_non_interpolated_literal')      .mx("ult=value ti=const type=string")
q('const', '#str_const')                                .mx("ult=deep  ti=pass")
q('rvalue','#const')                                    .mx("priority=#{base_priority} ult=deep  ti=pass")
q('lvalue','@')                                         .mx("priority=#{base_priority} ult=value ti=this block_assign=1")
q('lvalue','@ #identifier')                             .mx("priority=#{base_priority} ult=value")

q('rvalue', '#string_interpolated_start_single_literal #rvalue #string_interpolated_end_single_literal').mx("ult=string_interpolated")

# ###################################################################################################
#    operators define
# ###################################################################################################
q('pre_op',  '!')                                       .mx('priority=1')
q('pre_op',  'not')                                     .mx('priority=1')
q('pre_op',  '~')                                       .mx('priority=1')
q('pre_op',  '-')                                       .mx('priority=1')                             .strict('!$1.tail_space')
q('pre_op',  '+')                                       .mx('priority=1')                             .strict('!$1.tail_space')
q('pre_op',  'typeof')                                  .mx('priority=1')

q('pre_op',  'void')                                    .mx('priority=15')
q('pre_op',  'new')                                     .mx('priority=15')
q('pre_op',  'delete')                                  .mx('priority=15')
# ++ -- pre_op is banned.

q('post_op', '++')                                      .mx('priority=1')
q('post_op', '--')                                      .mx('priority=1')
q('post_op', '[QUESTION]')                              .mx('priority=1')

# https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Operators/Operator_Precedence
# TODO all ops
pipe_priority = 100

q('bin_op',  '//|%%')                                   .mx('priority=4  right_assoc=1')
q('bin_op',  '**')                                      .mx('priority=4  left_assoc=1') # because JS
q('bin_op',  '*|/|%')                                   .mx('priority=5  right_assoc=1')
q('bin_op',  '+|-')                                     .mx('priority=6  right_assoc=1')
q('bin_op',  '<<|>>|>>>')                               .mx('priority=7  right_assoc=1')
q('bin_op',  'instanceof')                              .mx('priority=8  right_assoc=1')
q('bin_op',  '<|<=|>|>=')                               .mx('priority=9')                 # NOTE NOT associative, because chained comparison
q('bin_op',  '!=|==')                                   .mx('priority=9  right_assoc=1') # NOTE == <= has same priority
# WARNING a == b < c is bad style. So all fuckups are yours

q('bin_op',  '&&|and|or|[PIPE][PIPE]')                  .mx('priority=10 right_assoc=1')

q('assign_bin_op',  '=|+=|-=|*=|/=|%=|<<=|>>=|>>>=|**=|//=|%%=|[QUESTION]=').mx('priority=3')


# ###################################################################################################
#    operators constructions
# ###################################################################################################
# PIPE special
q('bin_op',  '#multipipe')                              .mx("priority=#{pipe_priority} right_assoc=1") # возможно стоит это сделать отдельной конструкцией языка дабы проверять всё более тсчательно
q('multipipe',  '[PIPE] #multipipe?')
# NOTE need ~same rule for lvalue ???
q('rvalue',  '( #rvalue )')                             .mx("priority=#{base_priority} ult=deep ti=bracket")

q('rvalue',  '#rvalue #bin_op #rvalue')                 .mx('priority=#bin_op.priority ult=bin_op ti=bin_op')   .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority<#bin_op.priority')
q('rvalue',  '#rvalue #bin_op #rvalue')                 .mx('priority=#bin_op.priority ult=bin_op ti=bin_op')   .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority=#bin_op.priority #bin_op.left_assoc')
q('rvalue',  '#rvalue #bin_op #rvalue')                 .mx('priority=#bin_op.priority ult=bin_op ti=bin_op')   .strict('#rvalue[1].priority=#bin_op.priority #rvalue[2].priority<#bin_op.priority #bin_op.right_assoc')
# indent set
q('rvalue',  '#rvalue #bin_op #indent #rvalue #dedent') .mx('priority=#bin_op.priority ti=bin_op')              .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority<#bin_op.priority')
q('rvalue',  '#rvalue #bin_op #indent #rvalue #dedent') .mx('priority=#bin_op.priority ti=bin_op')              .strict('#rvalue[1].priority<#bin_op.priority #rvalue[2].priority=#bin_op.priority #bin_op.left_assoc')
q('rvalue',  '#rvalue #bin_op #indent #rvalue #dedent') .mx('priority=#bin_op.priority ti=bin_op')              .strict('#rvalue[1].priority=#bin_op.priority #rvalue[2].priority<#bin_op.priority #bin_op.right_assoc')
# indent+pipe
q('pre_pipe_rvalue',  '#multipipe #rvalue')                                                           #.strict("#rvalue.priority<#{pipe_priority}")
q('pre_pipe_rvalue',  '#pre_pipe_rvalue #eol #multipipe #rvalue')                                     #.strict("#rvalue.priority<#{pipe_priority}")
q('rvalue',  '#rvalue #multipipe #indent #pre_pipe_rvalue #dedent').mx("priority=#{pipe_priority}")   .strict("#rvalue[1].priority<=#{pipe_priority}")
# assign
q('rvalue',  '#lvalue #assign_bin_op #rvalue')          .mx('priority=#assign_bin_op.priority ult=bin_op ti=assign_bin_op').strict('#lvalue.priority<#assign_bin_op.priority #rvalue.priority<=#assign_bin_op.priority !#lvalue.block_assign')


q('rvalue',  '#pre_op #rvalue')                         .mx('priority=#pre_op.priority ult=pre_op ti=pre_op').strict('#rvalue[1].priority<=#pre_op.priority')
q('rvalue',  '#rvalue #post_op')                        .mx('priority=#post_op.priority ult=post_op') .strict('#rvalue[1].priority<#post_op.priority !#rvalue.tail_space') # a++ ++ is not allowed
# ###################################################################################################
#    ternary
# ###################################################################################################
q('rvalue',  '#rvalue [QUESTION] #rvalue : #rvalue')    .mx("priority=#{base_priority} ult=deep delimiter='[SPACE]' ti=ternary")
# ###################################################################################################
#    array
# ###################################################################################################
q('comma_rvalue',  '#rvalue')                           .mx("ult=deep")
# q('comma_rvalue',  '#eol #comma_rvalue')                .mx("ult=deep") # NOTE eol in back will not work. Gram bug
q('comma_rvalue',  '#comma_rvalue , #rvalue')           .mx("ult=deep")
q('comma_rvalue',  '#comma_rvalue #eol #rvalue')        .mx("ult=deep delimiter=,")
q('comma_rvalue',  '#comma_rvalue #eol? , #eol? #rvalue').mx("ult=deep")
q('array',  '[ #eol? ]')                                .mx("priority=#{base_priority} ult=deep")
q('array',  '[ #eol? #comma_rvalue #eol? ]')            .mx("priority=#{base_priority} ult=deep")
q('array',  '[ #indent #comma_rvalue? #dedent ]')       .mx("priority=#{base_priority} ult=deep")
q('rvalue',  '#array')                                  .mx("priority=#{base_priority} ult=deep ti=array")
# NOTE lvalue array come later

# ###################################################################################################
#    hash
# ###################################################################################################
# hash with brackets
q('pair',  '#identifier : #rvalue')                     .mx("ult=hash_pair_simple")
q('pair',  '#const : #rvalue')                          .mx("ult=deep")
q('pair',  '( #rvalue ) : #rvalue')                     .mx("ult=hash_pair_eval")
q('pair',  '#identifier')                               .mx("ult=hash_pair_auto auto=1")
q('pair_comma_rvalue',  '#pair')                        .mx("ult=deep")
q('pair_comma_rvalue',  '#pair_comma_rvalue #eol #pair').mx("ult=deep delimiter=,")
q('pair_comma_rvalue',  '#pair_comma_rvalue #eol? , #eol? #pair').mx("ult=deep")
q('hash',  '{ #eol? }')                                 .mx("priority=#{base_priority} ult=deep")
q('hash',  '{ #eol? #pair_comma_rvalue #eol? }')        .mx("priority=#{base_priority} ult=deep")
q('hash',  '{ #indent #pair_comma_rvalue? #dedent }')   .mx("priority=#{base_priority} ult=deep")
q('rvalue',  '#hash')                                   .mx("ult=deep ti=hash")


q('BL_pair_comma_rvalue',  '#pair')                        .mx("ult=deep")                           .strict("!#pair.auto")
q('BL_pair_comma_rvalue',  '#eol #pair')                   .mx("ult=deep")                           .strict("!#pair.auto")
q('BL_pair_comma_rvalue',  '#BL_pair_comma_rvalue , #pair').mx("ult=deep")                           .strict("!#pair.auto")

q('bracket_less_hash',  '#BL_pair_comma_rvalue')                 .mx("priority=#{base_priority} ult=deep")
q('bracket_less_hash',  '#indent #BL_pair_comma_rvalue #dedent') .mx("priority=#{base_priority} ult=deep")
q('rvalue',  '#bracket_less_hash')                      .mx("ult=hash_wrap")
# LATER bracket-less hash
# fuckup sample
# a a:b,c:d
#   a({a:b,c:d})
#   a({a:b},{c:d})

# ###################################################################################################
#    access
# ###################################################################################################
# [] access
q('lvalue', '#lvalue [ #rvalue ]')                      .mx("priority=#{base_priority} ult=array_access ti=access_stub")
# . access
q('lvalue', '#lvalue . #identifier')                    .mx("priority=#{base_priority} ult=field_access ti=access_stub")

# opencl-like access
# proper
q('lvalue', '#lvalue . #decimal_literal')               .mx("priority=#{base_priority} ult=opencl_access ti=access_stub")
q('lvalue', '#lvalue . #octal_literal')                 .mx("priority=#{base_priority} ult=opencl_access ti=access_stub")
# hack for a.0123 float_enabled
# q('lvalue', '#lvalue #float_literal')                   .mx("priority=#{base_priority}")      .strict('#lvalue.tail_space=0 #float_literal[0:0]="."')
# ###################################################################################################
#    function call
# ###################################################################################################
q('rvalue', '#lvalue ( #comma_rvalue? #eol? )')         .mx("priority=#{base_priority}")
# ###################################################################################################
#    function decl
# ###################################################################################################
q('rvalue', '-> #function_body?')                       .mx("priority=#{base_priority} ult=func_decl ti=func_stub")
q('rvalue', '=> #function_body?')                       .mx("priority=#{base_priority} ult=func_decl ti=func_stub")
q('rvalue', '( #arg_list? ) -> #function_body?')        .mx("priority=#{base_priority} ult=func_decl ti=func_stub")
q('rvalue', '( #arg_list? ) => #function_body?')        .mx("priority=#{base_priority} ult=func_decl ti=func_stub")
q('rvalue', '( #arg_list? ) : #type -> #function_body?').mx("priority=#{base_priority} ult=func_decl ti=func_stub")
q('rvalue', '( #arg_list? ) : #type => #function_body?').mx("priority=#{base_priority} ult=func_decl ti=func_stub")

q('arg_list', '#arg')                                   .mx("priority=#{base_priority}")
q('arg_list', '#arg_list , #arg')                       .mx("priority=#{base_priority}")

q('arg', '#identifier')                                 .mx("priority=#{base_priority}")
q('arg', '#identifier : #type')                         .mx("priority=#{base_priority}")
q('arg', '#identifier = #rvalue')                       .mx("priority=#{base_priority}")


q('type', '#identifier')                                .mx("priority=#{base_priority}")
# LATER array<T> support

q('function_body', '#stmt')                             .mx("priority=#{base_priority} ult=func_decl_return ti=pass")
q('function_body', '#block')                            .mx("priority=#{base_priority} ult=deep ti=pass")
# ###################################################################################################
#    block
# ###################################################################################################

q('block', '#indent #stmt_plus #dedent')                .mx("priority=#{base_priority} ult=block ti=block")
q('stmt_plus', '#stmt')                                 .mx("priority=#{base_priority} ult=deep ti=pass")
q('stmt_plus', '#stmt_plus #eol #stmt')                 .mx("priority=#{base_priority} ult=deep ti=stmt_plus_last eol_pass=1")

# ###################################################################################################
#    macro-block
# ###################################################################################################
q('rvalue', '#identifier #rvalue? #block')              .mx("priority=#{base_priority} ult=macro_block ti=macro_stub")


# ###################################################################################################

q('stmt',  '#rvalue')                                   .mx("ult=deep ti=pass")
q('stmt',  '#stmt #comment')                            .mx("ult=deep ti=pass")
q('stmt',  '#comment')                                  .mx("ult=deep ti=skip")

q('stmt',  '__test_untranslated')                       .mx("ti=skip")                       # FOR test purposes only

show_diff = (a,b)->
  ### !pragma coverage-skip-block ###
  if a.rule != b.rule
    perr "RULE mismatch"
    perr "a="
    perr a.rule
    perr "b="
    perr b.rule
    return
  if a.value != b.value
    perr "a=#{a.value}"
    perr "b=#{b.value}"
    return
  if a.mx_hash.hash_key != b.mx_hash.hash_key
    perr "a.hash_key = #{a.mx_hash.hash_key}"
    perr "b.hash_key = #{b.mx_hash.hash_key}"
    return
  js_a = JSON.stringify a.mx_hash
  js_b = JSON.stringify b.mx_hash
  if js_a != js_b
    perr "a.mx_hash = #{js_a}"
    perr "b.mx_hash = #{js_b}"
    return
  if a.value_array.length != b.value_array.length
    perr "list length mismatch #{a.value_array.length} != #{b.value_array.length}"
    perr "a=#{a.value_array.map((t)->t.value).join ','}"
    perr "b=#{b.value_array.map((t)->t.value).join ','}"
    return
  for i in [0 ... a.value_array.length]
    show_diff a.value_array[i], b.value_array[i]
  return

g.fix_overlapping_token = true
@_parse = (str, opt={})->
  g.mode_full = opt.mode_full || false
  res = g.parse_text_list str,
    expected_token : 'stmt_plus'
  if res.length == 0
    throw new Error "Parsing error. No proper combination found"
  if res.length != 1
    [a,b] = res
    show_diff a,b
    ### !pragma coverage-skip-block ###
    throw new Error "Parsing error. More than one proper combination found #{res.length}"
  res

@parse = (str, opt, on_end)->
  try
    res = module._parse str, opt
  catch e
    return on_end e
  on_end null, res
