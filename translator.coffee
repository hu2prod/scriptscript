require 'fy'
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
    if trans.trans_skip[v.mx_hash.hash_key]?
      # LATER
      # if node.mx_hash.eol_pass and v.mx_hash.hash_key == 'eol'
        # list.push "\n"
    # if trans.trans_value[v.mx_hash.hash_key]?
    #   list.push v.value
    else if /^proxy_/.test v.mx_hash.hash_key
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
# ###################################################################################################

@_translate = (ast, opt={})->
  trans.go ast

@translate = (ast, opt, on_end)->
  try
    res = module._translate ast, opt
  catch e
    return on_end e
  on_end null, res
