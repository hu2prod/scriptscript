require 'fy'
{
  Translator
  un_op_translator_holder
  un_op_translator_framework
} = require 'gram'
module = @

# ###################################################################################################
trans = new Translator
trans.trans_skip = {}
trans.trans_value = {}
deep = (ctx, node)->
  list = []
  # if node.mx_hash.deep?
  #   node.mx_hash.deep = '0' if node.mx_hash.deep == false # special case for deep=0
  #   value_array = (node.value_array[pos] for pos in node.mx_hash.deep.split ',')
  # else
  #   value_array = node.value_array
  
  value_array = node.value_array
  for v,k in value_array
    # if trans.trans_skip[v.mx_hash.hash_key]?
    #   list.push "" # nothing
    # if trans.trans_value[v.mx_hash.hash_key]?
    #   list.push v.value
    # else if /^proxy_/.test v.mx_hash.hash_key
    if /^proxy_/.test v.mx_hash.hash_key
      list.push v.value
    else
      list.push ctx.translate v
  # if delimiter = node.mx_hash.delimiter
    # list = [ list.join(delimiter) ]
  list

trans.translator_hash['value']  = translate:(ctx, node)->node.value
trans.translator_hash['deep']   = translate:(ctx, node)->
  list = deep ctx, node
  list.join('')

holder = new un_op_translator_holder
holder.mode_pre()
for v in un_op_list = "~ + - !".split ' '
  holder.op_list[v]  = new un_op_translator_framework "$op$1"

holder.op_list["not"]  = new un_op_translator_framework "!$1"

for v in un_op_list = "typeof".split ' '
  holder.op_list[v]  = new un_op_translator_framework "($op $1)"
trans.translator_hash['pre_op'] = holder

@_translate = (ast, opt={})->
  trans.go ast

@translate = (ast, opt, on_end)->
  try
    res = module._translate ast, opt
  catch e
    return on_end e
  on_end null, res
