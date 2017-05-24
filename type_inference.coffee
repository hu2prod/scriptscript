require 'fy'
require 'fy/codegen'
{
  Translator
} = require 'gram'
module = @

assert_pass_down = (ast, type, diagnostics)->
  if ast.mx_hash.type?
    if ast.mx_hash.type != type
      throw new Error "assert pass up failed node='#{ast.value}'['#{ast.mx_hash.type}'] should be type '#{type}'; extra=#{diagnostics}"
  else
    ast.mx_hash.type = type
  # if rvalue
  # if lvalue
  # TODO
  return

assert_pass_down_eq = (ast1, ast2, diagnostics)->
  if ast1.mx_hash.type? and ast2.mx_hash.type?
    if ast1.mx_hash.type != ast2.mx_hash.type
      throw new Error "assert pass up eq failed node1='#{ast1.value}'[#{ast1.mx_hash.type}] != node2='#{ast2.value}'[#{ast2.mx_hash.type}]; extra=#{diagnostics}"
  else if !ast1.mx_hash.type? and !ast2.mx_hash.type?
    # nothing
    return
  else if !ast1.mx_hash.type?
    assert_pass_down ast1, ast2.mx_hash.type, "#{diagnostics} ast1 down"
  else #!ast2.mx_hash.type?
    assert_pass_down ast2, ast1.mx_hash.type, "#{diagnostics} ast2 down"
    
  return
assert_pass_down_eq_list = (ast_list, diagnostics)->
  type = undefined
  for v in ast_list
    break if type = v.mx_hash.type
  return if !type?
  for v, idx in ast_list
    assert_pass_down v, type, "#{diagnostics} pos #{idx}"
  
  return
# ###################################################################################################

trans = new Translator
trans.key = 'ti'
trans.translator_hash['pass'] = translate:(ctx, node)->
  child = node.value_array[0]
  ctx.translate child
  if child.mx_hash.type
    node.mx_hash.type = child.mx_hash.type

trans.translator_hash['bracket'] = translate:(ctx, node)->
  child = node.value_array[1]
  ctx.translate child
  if child.mx_hash.type
    node.mx_hash.type = child.mx_hash.type
  
  return
trans.translator_hash['id'] = translate:(ctx, node)->
  if node.value in ['true', 'false'] # .toLowerCase() ??
    node.mx_hash.type = 'bool'
  # not implemented
  return

trans.translator_hash['const'] = translate:(ctx, node)->
  if !node.mx_hash.type
    ### !pragma coverage-skip-block ###
    throw new Error "You forgot specify type at ti=const"
  return
# ###################################################################################################
#    bin_op
# ###################################################################################################
bin_op_type_table = {}
def_bin = (op,at,bt,ret)->
  key = "#{op},#{at},#{bt}"
  bin_op_type_table[key] = ret
  return

for op in "+ - * // % << >> >>>".split /\s+/
  def_bin op, "int", "int", "int"

for op in "and or".split /\s+/
  def_bin op, "bool", "bool", "bool"
for op in "and or".split /\s+/
  def_bin op, "int", "int", "int"
for type in "int float".split /\s+/
  for op in "== != < <= > >=".split /\s+/
    def_bin op, type,type, "bool"

for type in "string".split /\s+/ # NOTE any equal type !!!
  for op in "== !=".split /\s+/
    def_bin op, type,type, "bool"

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
  # LATER result defined + some args
  
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
    if !ret = bin_op_type_table[key]
      throw new Error "can't find bin_op=#{op} a=#{at} b=#{bt} node=#{node.value}"
    node.mx_hash.type = ret
  else
    # case 2
    # not implemented
    return
  
  return
# ###################################################################################################
#    assign_bin_op
# ###################################################################################################
trans.translator_hash['assign_bin_op'] = translate:(ctx, node)->
  rvalue_list = []
  bin_op_list = []
  for v in node.value_array
    rvalue_list.push v if v.mx_hash.hash_key in ['lvalue', 'rvalue']
    bin_op_list.push v if v.mx_hash.hash_key == 'assign_bin_op'
  
  bin_op_node = bin_op_list[0]
  op = bin_op_node.value.replace '=', ''
  
  for v in rvalue_list
    ctx.translate v
  
  # cases
  # no type detected - can build system that limits a, b and result
  # 1 type detected  - can build system that limits second and result
  # 2 type detected  - can validate and send result
  # LATER result defined + some args
  
  [a,b] = rvalue_list
  if !a.mx_hash.type? and !b.mx_hash.type?
    # case 1
    # not implemented
    return
  else if a.mx_hash.type? and b.mx_hash.type?
    # case 3
    if op == ''
      assert_pass_down_eq a, b, "assign_bin_op"
    else
      at = a.mx_hash.type
      bt = b.mx_hash.type
      key = "#{op},#{at},#{bt}"
      if !ret = bin_op_type_table[key]
        throw new Error "can't find assign_bin_op=#{op} a=#{at} b=#{bt} node=#{node.value}"
      if ret != at
        throw new Error "assign_bin_op conflict '#{ret}' != '#{at}'"
      node.mx_hash.type = ret
  else
    if b.mx_hash.type?
      assert_pass_down a, b.mx_hash.type, 'assign_bin_op'
      node.mx_hash.type = b.mx_hash.type
    # case 2
    # not implemented
    return
  
  return

# ###################################################################################################
#    pre_op
# ###################################################################################################
pre_op_type_table = {}
def_pre = (op,at,ret)->
  key = "#{op},#{at}"
  pre_op_type_table[key] = ret
  return

def_pre "-", "int",    "int"
def_pre "~", "int",    "int"
def_pre "+", "string", "float"
def_pre "!",   "bool", "bool"
def_pre "not", "bool", "bool"


trans.translator_hash['pre_op'] = translate:(ctx, node)->
  rvalue_list = []
  pre_op_list = []
  for v in node.value_array
    rvalue_list.push v if v.mx_hash.hash_key == 'rvalue'
    pre_op_list.push v if v.mx_hash.hash_key == 'pre_op'
  
  pre_op_node = pre_op_list[0]
  op = pre_op_node.value
  
  for v in rvalue_list
    ctx.translate v
  
  # cases
  # no type detected - can build system that limits a, b and result
  # 1 type detected  - can validate and send result
  
  [a] = rvalue_list
  if !a.mx_hash.type?
    # case 1
    # not implemented
    return
  else
    # case 2
    at = a.mx_hash.type
    key = "#{op},#{at}"
    if !ret = pre_op_type_table[key]
      throw new Error "can't find pre_op=#{op} a=#{at} node=#{node.value}"
    node.mx_hash.type = ret
  
  return

# LATER
# # ###################################################################################################
# #    post_op
# # ###################################################################################################
# post_op_type_table = {}
# def_post = (op,at,ret)->
#   key = "#{op},#{at}"
#   post_op_type_table[key] = ret
#   return
# 
# def_post "++", "int",  "int"
# def_post "--", "int",  "int"
# 
# 
# trans.translator_hash['post_op'] = translate:(ctx, node)->
#   rvalue_list = []
#   post_op_list = []
#   for v in node.value_array
#     rvalue_list.push v if v.mx_hash.hash_key == 'rvalue'
#     post_op_list.push v if v.mx_hash.hash_key == 'post_op'
#   
#   post_op_node = post_op_list[0]
#   op = post_op_node.value
#   
#   for v in rvalue_list
#     ctx.translate v
#   
#   # cases
#   # no type detected - can build system that limits a, b and result
#   # 1 type detected  - can validate and send result
#   
#   [a] = rvalue_list
#   if !a.mx_hash.type?
#     # case 1
#     # not implemented
#     return
#   else
#     # case 2
#     at = a.mx_hash.type
#     key = "#{op},#{at}"
#     if !ret = post_op_type_table[key]
#       throw new Error "can't find post_op=#{op} a=#{at} node=#{node.value}"
#     node.mx_hash.type = ret
#   
#   return
# # ###################################################################################################
trans.translator_hash["ternary"] = translate:(ctx, node)->
  [cond, _s1, vtrue, _s2, vfalse] = node.value_array
  ctx.translate cond
  assert_pass_down cond, 'bool', 'ternary'
  
  ctx.translate vtrue
  ctx.translate vfalse
  assert_pass_down_eq vtrue, vfalse
  
  node.mx_hash.type = vtrue.mx_hash.type if vtrue.mx_hash.type?
  return
# ###################################################################################################
trans.translator_hash["array"] = translate:(ctx, node)->
  element_list = []
  walk = (node)->
    for sn in node.value_array
      if sn.mx_hash.hash_key == 'rvalue'
        element_list.push sn
      else
        walk sn
    return
  walk node
  
  for el in element_list
    ctx.translate el
  
  assert_pass_down_eq_list element_list, "array decl"
  
  if element_list[0]?.mx_hash.type?
    subtype = element_list[0].mx_hash.type
    node.mx_hash.type = "array<#{subtype}>"
    node.mx_hash.main_type = "array"
    node.mx_hash.subtype_list = [subtype]
  else
    node.mx_hash.type = "array"
  return
# ###################################################################################################
trans.translator_hash["hash"] = translate:(ctx, node)->
  pair_list = []
  walk = (node)->
    for sn in node.value_array
      if sn.mx_hash.hash_key == 'pair'
        pair_list.push sn
      else
        walk sn
    return
  walk node
  
  element_list = []
  
  for el in pair_list
    rvalue_list = []
    id_list = []
    for sn in el.value_array
      if sn.mx_hash.hash_key == 'identifier'
        id_list.push sn
        trans.translator_hash['id'].translate ctx, sn # identifier has no ti
      else if sn.mx_hash.hash_key == 'rvalue'
        rvalue_list.push sn
        ctx.translate sn
    
    if rvalue_list.length == 0
      value = id_list[0]
    else if rvalue_list.length == 1
      value = rvalue_list[0]
    else # if rvalue_list.length == 2
      [key, value] = rvalue_list
      # TODO check key castable to string # same as string iterpolated
    element_list.push value
  
  assert_pass_down_eq_list element_list, "hash decl"
  
  if element_list[0]?.mx_hash.type?
    subtype = element_list[0].mx_hash.type
    node.mx_hash.type = "hash<#{subtype}>"
    node.mx_hash.main_type = "hash"
    node.mx_hash.subtype_list = [subtype]
  else
    node.mx_hash.type = "hash"
  return

# ###################################################################################################

@_type_inference = (ast, opt={})->
  # phase 1 deep
  # found atoms of known types
  # found bigger atoms that can be constructed for lower ones with 1 pass
  trans.go ast
  
  return

@type_inference = (ast, opt, on_end)->
  try
    module._type_inference ast, opt
  catch e
    return on_end e
  on_end null
