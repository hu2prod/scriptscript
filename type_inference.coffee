require 'fy'
require 'fy/codegen'
{
  Translator
} = require 'gram'

trans = new Translator
trans.key = 'ti'
trans.translator_hash['pass'] = translate:(ctx, node)->
  child = node.value_array[0]
  ctx.translate child
  if child.mx_hash.type
    node.mx_hash.type = child.mx_hash.type
  
  return

trans.translator_hash['const'] = translate:(ctx, node)->
  if !node.mx_hash.type
    ### !pragma coverage-skip-block ###
    throw new Error "You forgot specify type at ti=const"
  return

type_table = {}
def = (op,at,bt,ret)->
  key = "#{op},#{at},#{bt}"
  type_table[key] = ret
  return

for op in "+ - * //".split /\s+/
  def op, "int", "int", "int"

trans.translator_hash['bin_op'] = translate:(ctx, node)->
  rvalue_list = []
  bin_op_list = []
  for v in node.value_array
    rvalue_list.push v if v.mx_hash.hash_key == 'rvalue'
    bin_op_list.push v if v.mx_hash.hash_key == 'bin_op'
  
  bin_op_node = bin_op_list[0]
  op = bin_op_node.value
  
  for v in rvalue_list
    ctx.translate v
  
  # cases
  # no type detected - can build system that limits a, b and result
  # 1 type detected  - can build system that limits second and result
  # 2 type detected  - can validate and send result
  
  [a,b] = rvalue_list
  if !a.mx_hash.type? and !b.mx_hash.type?
    # case 1
    # not implemented
    return
  else if a.mx_hash.type? and b.mx_hash.type?
    # case 3
    at = a.mx_hash.type
    bt = b.mx_hash.type
    key = "#{op},#{at},#{bt}"
    if !ret = type_table[key]
      throw new Error "can't find op=#{op} a=#{at} b=#{bt}"
    node.mx_hash.type = ret
  else
    # case 2
    # not implemented
    return
  
  return


@_type_inference = (ast, opt={})->
  # phase 1 deep
  # found atoms of known types
  # found bigger atoms that can be constructed for lower ones with 1 pass
  trans.go ast
  
  return

@type_inference = (ast, opt, on_end)->
  try
    res = module._type_inference ast, opt
  catch e
    return on_end e
  on_end null, res
