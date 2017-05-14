require 'fy'
require 'fy/codegen'
{
  Translator
  un_op_translator_holder
  un_op_translator_framework
  bin_op_translator_holder
  bin_op_translator_framework
} = require 'gram'
module = @

# ###################################################################################################
trans = new Translator
trans.trans_skip =
  indent : true
  dedent : true
  eol    : true

# trans.trans_value = {}
trans.trans_token =
  comment : (v)-> "//" + v.substr 1
deep = (ctx, node)->
  list = []
  # if node.mx_hash.deep?
  #   node.mx_hash.deep = '0' if node.mx_hash.deep == false # special case for deep=0
  #   value_array = (node.value_array[pos] for pos in node.mx_hash.deep.split ',')
  # else
  #   value_array = node.value_array
  
  
  value_array = node.value_array
  for v,k in value_array
    if trans.trans_skip[v.mx_hash.hash_key]?
      # LATER
      # if node.mx_hash.eol_pass and v.mx_hash.hash_key == 'eol'
        # list.push "\n"
    else if fn = trans.trans_token[v.mx_hash.hash_key]
      list.push fn v.value
    # else if trans.trans_value[v.mx_hash.hash_key]?
      # list.push v.value
    else if /^proxy_/.test v.mx_hash.hash_key
      list.push v.value
    else
      list.push ctx.translate v
  if delimiter = node.mx_hash.delimiter
    delimiter = ' ' if delimiter == "'[SPACE]'"
    list = [ list.join(delimiter) ]
  list

trans.translator_hash['value']  = translate:(ctx, node)->node.value
trans.translator_hash['deep']   = translate:(ctx, node)->
  list = deep ctx, node
  list.join('')
# ###################################################################################################
#    bin_op
# ###################################################################################################
holder = new bin_op_translator_holder
for v in bin_op_list = "+ - * /".split ' '
  holder.op_list[v]  = new bin_op_translator_framework "($1$op$2)"
  v = v+"="
  holder.op_list[v]  = new bin_op_translator_framework "($1$op$2)"

for v in bin_op_list = "=".split ' '
  holder.op_list[v]  = new bin_op_translator_framework "($1$op$2)"

trans.translator_hash['bin_op'] = holder
# ###################################################################################################
#    pre_op
# ###################################################################################################
holder = new un_op_translator_holder
holder.mode_pre()
for v in un_op_list = "~ + - !".split ' '
  holder.op_list[v]  = new un_op_translator_framework "$op$1"

holder.op_list["not"]  = new un_op_translator_framework "!$1"
holder.op_list["void"] = new un_op_translator_framework "null"

for v in un_op_list = "typeof new delete".split ' '
  holder.op_list[v]  = new un_op_translator_framework "($op $1)"
trans.translator_hash['pre_op'] = holder

# ###################################################################################################
#    post_op
# ###################################################################################################
holder = new un_op_translator_holder
holder.mode_post()
for v in un_op_list = ["++", '--']
  holder.op_list[v]  = new un_op_translator_framework "($1$op)"
trans.translator_hash['post_op'] = holder
# ###################################################################################################
#    hash
# ###################################################################################################
trans.translator_hash["hash_pair_simple"] = translate:(ctx,node)->
  [_key,skip,_value] = node.value_array
  value = ctx.translate _value
  "#{_key.value}:#{value}"
trans.translator_hash["hash_pair_auto"] = translate:(ctx,node)->
  [_value] = node.value_array
  "#{_value.value}:#{_value.value}"
trans.translator_hash['hash_wrap']   = translate:(ctx, node)->
  list = deep ctx, node
  "{"+list.join('')+"}"
# ###################################################################################################
#    func_decl
# ###################################################################################################
trans.translator_hash["func_decl_return"] = translate:(ctx,node)->
  str = ctx.translate node.value_array[0]
  "return(#{str})"
trans.translator_hash["func_decl"] = translate:(ctx,node)->
  arg_list = []
  if node.value_array[0].value == '(' and node.value_array[2].value == ')'
    arg_list_node = node.value_array[1]
    for arg in arg_list_node.value_array
      continue if arg.value_array[0].value == ","
      default_value_node = null
      if arg.value_array.length == 1
        name_node = arg.value_array[0]
      else if arg.value_array.length == 3
        if arg.value_array[1].value == "="
          name_node         = arg.value_array[0]
          default_value_node= arg.value_array[2]
        else if arg.value_array[1].value == ":"
          ### !pragma coverage-skip-block ###
          throw new Error "types are unsupported arg syntax yet"
        else
          ### !pragma coverage-skip-block ###
          throw new Error "unsupported arg syntax"
      else
        ### !pragma coverage-skip-block ###
        throw new Error "unsupported arg syntax"
      
      default_value = null
      if default_value_node
        default_value = ctx.translate default_value_node
      arg_list.push {
        name : name_node.value
        type : null
        default_value
      }
  
  body_node = node.value_array.last()
  body_node = null if body_node.value in ["->", "=>"] # no body
  
  
  arg_str_list = []
  default_arg_str_list = []
  for arg in arg_list
    arg_str_list.push arg.name
    if arg.default_value
      default_arg_str_list.push """
        #{arg.name}=#{arg.name}==null?(#{arg.default_value}):#{arg.name};
      """
  
  body = ""
  body = ctx.translate body_node if body_node
  
  body = """
  {
    #{join_list default_arg_str_list, '  '}
    #{body}
  }
  """
  body = body.replace /^{\s+/, '{\n  '
  body = body.replace /\s+}$/, '\n}'
  body = "{}" if /^\{\s+\}$/.test body
  
  "(function(#{arg_str_list.join ', '})#{body})"
# ###################################################################################################

@_translate = (ast, opt={})->
  trans.go ast

@translate = (ast, opt, on_end)->
  try
    res = module._translate ast, opt
  catch e
    return on_end e
  on_end null, res
