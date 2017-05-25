require 'fy'
require 'fy/codegen'
{
  Translator
} = require 'gram'
module = @
# ###################################################################################################
#    scope state
# ###################################################################################################
# MAY BE move to trans
current_scope =
  id_map : {} # id -> ast pos list

scope_list = [current_scope]
scope_stack = []

scope_state_reset = ()->
  current_scope =
    id_map : {} # id -> ast pos list

  scope_list = [current_scope]
  scope_stack = []
  return

scope_id_push = (node)->
  current_scope.id_map[node.value] ?= []
  current_scope.id_map[node.value].upush node
  return

_mk_scope = (node)->
  return scope if scope = node.__inject_scope
  
  scope = node.__inject_scope =
    id_map : {}
  
  scope_list.push scope
  scope

scope_push = (node)->
  scope_stack.push current_scope
  current_scope = _mk_scope node
  return
  
scope_pop = ()->
  current_scope = scope_stack.pop()
  return
# ###################################################################################################
#    Type
# ###################################################################################################
class @Type
  main : ''
  nest : []
  
  constructor:()->
    
  eq : (t)->
    return false if @main != t.main
    return false if @nest.length != t.nest.length
    for v,k in @nest
      return false if !v.eq t.nest[k]
    true
  
  toString : ()->
    if @nest.length
      list = []
      for v in @nest
        list.push v.toString()
      "#{@main}<#{list.join ','}>"
    else
      "#{@main}"
  
  can_match : (t)->
    return false if @main != t.main
    return false if @nest.length != t.nest.length
    for v,k in @nest
      continue if v.main == '*'
      v2 = t.nest[k]
      continue if v2.main == '*'
      return false if !v.can_match v2
    true
  
  exchange_missing_info : (t)->
    ret = 0
    for v,k in @nest
      v2 = t.nest[k]
      continue if v.eq v2
      if v.main == v2.main
        ret += v.exchange_missing_info v2
        continue
      
      if v.main == '*'
        @nest[k] = v2
        ret++
      else if v2.main == '*'
        t.nest[k] = v
        ret++
      else
        ### !pragma coverage-skip-block ###
        # Этой ситуации быть не может
        # Иначе сработал бы v.main == v2.main
    ret

mk_type = (str, nest=[])->
  ret = new module.Type
  ret.main = str
  ret.nest = nest
  ret

# ###################################################################################################

assert_pass_down = (ast, type, diagnostics)->
  ret = 0
  if ast.mx_hash.type?
    loop
      break if ast.mx_hash.type.eq type
      if ast.mx_hash.type.can_match type
        ret += ast.mx_hash.type.exchange_missing_info type
        break
      throw new Error "assert pass up failed node='#{ast.value}'['#{ast.mx_hash.type}'] should be type '#{type}'; extra=#{diagnostics}"
  else
    ast.mx_hash.type = type
    ret++
  
  # rvalue unwrap
  if ast.mx_hash.hash_key == 'rvalue'
    ast = ast.value_array[0]
  
  # lvalue patch
  if ast.mx_hash.hash_key == 'lvalue'
    # case @
    # case @id
    # case id
    # case lvalue[rvalue]
    # case lvalue.id
    # case lvalue.octal/decimal
    # LATER destructuring assignment
    
    
    # case id
    [a] = ast.value_array
    if ast.value_array.length == 1 and a.mx_hash.hash_key == 'identifier'
      if !a.mx_hash.type?
        a.mx_hash.type = type
        ret++
      else
        # UNIMPLEMENTED
  return ret

assert_pass_down_eq = (ast1, ast2, diagnostics)->
  ret = 0
  if ast1.mx_hash.type? and ast2.mx_hash.type?
    loop
      break if ast1.mx_hash.type.eq ast2.mx_hash.type
      if ast1.mx_hash.type.can_match ast2.mx_hash.type
        ret += ast1.mx_hash.type.exchange_missing_info ast2.mx_hash.type
        break
      throw new Error "assert pass up eq failed node1='#{ast1.value}'[#{ast1.mx_hash.type}] != node2='#{ast2.value}'[#{ast2.mx_hash.type}]; extra=#{diagnostics}"
  else if !ast1.mx_hash.type? and !ast2.mx_hash.type?
    # nothing
  else if !ast1.mx_hash.type?
    ret += assert_pass_down ast1, ast2.mx_hash.type, "#{diagnostics} ast1 down"
  else #!ast2.mx_hash.type?
    ret += assert_pass_down ast2, ast1.mx_hash.type, "#{diagnostics} ast2 down"
    
  return ret
assert_pass_down_eq_list = (ast_list, type, diagnostics)->
  ret = 0
  # type = undefined
  # if !type?# LATER
  for v in ast_list
    break if type = v.mx_hash.type
  return 0 if !type?
  for v, idx in ast_list
    ret += assert_pass_down v, type, "#{diagnostics} pos #{idx}"
  
  return ret
# ###################################################################################################

trans = new Translator
trans.key = 'ti'
trans.translator_hash['skip'] = translate:(ctx, node)-> 0
trans.translator_hash['pass'] = translate:(ctx, node)->
  child = node.value_array[0]
  ret = ctx.translate child
  ret += assert_pass_down_eq node, child, "pass rule=#{node?.rule?.signature}"
  ret
trans.translator_hash['block'] = translate:(ctx, node)->
  ctx.translate node.value_array[1]

trans.translator_hash['stmt_plus_last'] = translate:(ctx, node)->
  ret = 0
  for v in node.value_array
    continue if v.mx_hash.hash_key == 'eol'
    ret += ctx.translate v
  
  child = node.value_array.last()
  if child.mx_hash.type?
    if !node.mx_hash.type?
      node.mx_hash.type = child.mx_hash.type
      ret++
    else
      # UNIMPLEMENTED
  ret

trans.translator_hash['bracket'] = translate:(ctx, node)->
  child = node.value_array[1]
  ret = ctx.translate child
  ret += assert_pass_down_eq node, child, "bracket"
  ret

trans.translator_hash['this'] = translate:(ctx, node)->
  # LATER
  0

trans.translator_hash['id'] = translate:(ctx, node)->
  ret = 0
  is_prefefined_const = false
  if node.value in ['true', 'false'] # .toLowerCase() ??
    is_prefefined_const = true
    if !node.mx_hash.type?
      node.mx_hash.type = mk_type 'bool'
      ret++
    else
      # UNIMPLEMENTED
  
  if !is_prefefined_const
    if (nest_type = node.value_array[0].mx_hash.type)?
      if !node.mx_hash.type?
        node.mx_hash.type = nest_type
        ret++
      else
        # UNIMPLEMENTED
    
    scope_id_push node.value_array[0]
  
  ret

trans.translator_hash['const'] = translate:(ctx, node)->
  if !node.mx_hash.type?
    ### !pragma coverage-skip-block ###
    throw new Error "You forgot specify type at ti=const"
  unless node.mx_hash.type instanceof module.Type
    node.mx_hash.type = mk_type node.mx_hash.type
  return 0
# ###################################################################################################
#    bin_op
# ###################################################################################################
bin_op_type_table = {}
do ()->
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
    for op in "< <= > >=".split /\s+/
      def_bin op, type,type, "bool"

trans.translator_hash['bin_op'] = translate:(ctx, node)->
  ret = 0
  rvalue_list = []
  bin_op_list = []
  for v in node.value_array
    rvalue_list.push v if v.mx_hash.hash_key == 'rvalue'
    bin_op_list.push v if v.mx_hash.hash_key == 'bin_op'
  
  bin_op_node = bin_op_list[0]
  op = bin_op_node.value
  
  for v in rvalue_list
    ret += ctx.translate v
  
  # cases
  # no type detected - can build system that limits a, b and result
  # 1 type detected  - can build system that limits second and result
  # 2 type detected  - can validate and send result
  # LATER result defined + some args
  
  [a,b] = rvalue_list
  if !a.mx_hash.type? and !b.mx_hash.type?
    # case 1
    # not implemented
  else if a.mx_hash.type? and b.mx_hash.type?
    # case 3
    at = a.mx_hash.type
    bt = b.mx_hash.type
    
    loop
      if op in ['==', '!=']
        if at.eq bt
          _ret = 'bool'
          break
        if at.can_match bt
          ret += at.exchange_missing_info bt
          _ret = 'bool'
          break
    
      key = "#{op},#{at},#{bt}"
      if !_ret = bin_op_type_table[key]
        throw new Error "can't find bin_op=#{op} a=#{at} b=#{bt} node=#{node.value}"
      break
    
    if !node.mx_hash.type?
      node.mx_hash.type = mk_type _ret
      ret++
    else
      # UNIMPLEMENTED
  else
    # case 2
    # not implemented
  
  return ret
# ###################################################################################################
#    assign_bin_op
# ###################################################################################################
trans.translator_hash['assign_bin_op'] = translate:(ctx, node)->
  ret = 0
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
  else if a.mx_hash.type? and b.mx_hash.type?
    # case 3
    if op == ''
      ret += assert_pass_down_eq a, b, "assign_bin_op"
    else
      at = a.mx_hash.type
      bt = b.mx_hash.type
      key = "#{op},#{at},#{bt}"
      if !_ret = bin_op_type_table[key]
        throw new Error "can't find assign_bin_op=#{op} a=#{at} b=#{bt} node=#{node.value}"
      _ret_t = mk_type _ret
      if !_ret_t.eq at
        ### !pragma coverage-skip-block ###
        # ПРИМ. Пока сейчас нет операций у которых a.type != b.type
        throw new Error "assign_bin_op conflict '#{_ret_t}' != '#{at}'"
      
      if !node.mx_hash.type?
        node.mx_hash.type = _ret_t
        ret++
      else
        # UNIMPLEMENTED
  else
    # case 2
    if b.mx_hash.type?
      if op == ''
        ret += assert_pass_down a, b.mx_hash.type, 'assign_bin_op'
        # BYPASSSING missing code coverage
        ret += assert_pass_down node, b.mx_hash.type, 'assign_bin_op'
        # if !node.mx_hash.type?
        #   node.mx_hash.type = b.mx_hash.type
        #   ret++
        # else
        #   # UNIMPLEMENTED
    else # a.mx_hash.type?
      if op == ''
        ret += assert_pass_down b, a.mx_hash.type, 'assign_bin_op'
        if !node.mx_hash.type?
          node.mx_hash.type = a.mx_hash.type
          ret++
        else
          # UNIMPLEMENTED
  
  ret

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
  ret = 0
  rvalue_list = []
  pre_op_list = []
  for v in node.value_array
    rvalue_list.push v if v.mx_hash.hash_key == 'rvalue'
    pre_op_list.push v if v.mx_hash.hash_key == 'pre_op'
  
  pre_op_node = pre_op_list[0]
  op = pre_op_node.value
  
  for v in rvalue_list
    ret += ctx.translate v
  
  # cases
  # no type detected - can build system that limits a, b and result
  # 1 type detected  - can validate and send result
  
  [a] = rvalue_list
  if !a.mx_hash.type?
    # case 1
    # not implemented
  else
    # case 2
    at = a.mx_hash.type
    key = "#{op},#{at}"
    if !_ret = pre_op_type_table[key]
      throw new Error "can't find pre_op=#{op} a=#{at} node=#{node.value}"
    if !node.mx_hash.type?
      node.mx_hash.type = mk_type _ret
      ret++
    else
      # UNIMPLEMENTED
  
  ret

# LATER
# ###################################################################################################
#    post_op
# ###################################################################################################
post_op_type_table = {}
def_post = (op,at,ret)->
  key = "#{op},#{at}"
  post_op_type_table[key] = ret
  return

def_post "++", "int",  "int"
def_post "--", "int",  "int"

# NOTE 1++ is not valid, but passes gram and TI

trans.translator_hash['post_op'] = translate:(ctx, node)->
  ret = 0
  rvalue_list = []
  post_op_list = []
  for v in node.value_array
    rvalue_list.push v if v.mx_hash.hash_key == 'rvalue'
    post_op_list.push v if v.mx_hash.hash_key == 'post_op'
  
  post_op_node = post_op_list[0]
  op = post_op_node.value
  
  for v in rvalue_list
    ret += ctx.translate v
  
  # cases
  # no type detected - can build system that limits a, b and result
  # 1 type detected  - can validate and send result
  
  [a] = rvalue_list
  if !a.mx_hash.type?
    # case 1
    # not implemented
  else
    # case 2
    at = a.mx_hash.type
    key = "#{op},#{at}"
    if !_ret = post_op_type_table[key]
      throw new Error "can't find post_op=#{op} a=#{at} node=#{node.value}"
    if !node.mx_hash.type?
      node.mx_hash.type = mk_type _ret
      ret++
    else
      # UNIMPLEMENTED
  
  ret
# # ###################################################################################################
trans.translator_hash["ternary"] = translate:(ctx, node)->
  ret = 0
  [cond, _s1, vtrue, _s2, vfalse] = node.value_array
  ret += ctx.translate cond
  ret += assert_pass_down cond, mk_type('bool'), 'ternary'
  
  ret += ctx.translate vtrue
  ret += ctx.translate vfalse
  ret += assert_pass_down_eq vtrue, vfalse
  
  if vtrue.mx_hash.type?
    if !node.mx_hash.type?
      node.mx_hash.type = vtrue.mx_hash.type
      ret++
    else
      # UNIMPLEMENTED
  return ret
# ###################################################################################################
trans.translator_hash["array"] = translate:(ctx, node)->
  ret = 0
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
    ret += ctx.translate el
  
  ret += assert_pass_down_eq_list element_list, undefined, "array decl"
  
  if element_list[0]?.mx_hash.type?
    subtype = element_list[0].mx_hash.type
    if !node.mx_hash.type?
      node.mx_hash.type = mk_type "array", [subtype]
      ret++
    else
      # UNIMPLEMENTED
  else
    if !node.mx_hash.type?
      node.mx_hash.type = mk_type "array", [mk_type '*']
      ret++
    else
      # UNIMPLEMENTED
      
  return ret
# ###################################################################################################
trans.translator_hash["hash"] = translate:(ctx, node)->
  ret = 0
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
      else if sn.mx_hash.hash_key == 'rvalue'
        rvalue_list.push sn
        ret += ctx.translate sn
    
    if rvalue_list.length == 0
      value = id_list[0]
      scope_id_push value
    else if rvalue_list.length == 1
      value = rvalue_list[0]
    else # if rvalue_list.length == 2
      [key, value] = rvalue_list
      # TODO check key castable to string # same as string iterpolated
    element_list.push value
  
  ret += assert_pass_down_eq_list element_list, undefined, "hash decl"
  
  if element_list[0]?.mx_hash.type?
    subtype = element_list[0].mx_hash.type
    if !node.mx_hash.type?
      node.mx_hash.type = mk_type "hash", [subtype]
      ret++
    else
      # UNIMPLEMENTED
  else
    if !node.mx_hash.type?
      node.mx_hash.type = mk_type "hash", [mk_type '*']
      ret++
    else
      # UNIMPLEMENTED
  return ret
# ###################################################################################################
#    access
# ###################################################################################################

trans.translator_hash['access_stub'] = translate:(ctx, node)->
  child = node.value_array[0]
  ret = ctx.translate child
  # unimplemented
  # ret += assert_pass_down_eq node, child, "pass"
  ret
# ###################################################################################################
#    function
# ###################################################################################################
type_ast_to_obj = (ast)->
  # NOTE WRONG. Need proper handle <>
  mk_type ast.value

trans.translator_hash['func_stub'] = translate:(ctx, node)->
  ret = 0
  function_body = null
  arg_list_node = null
  ret_type_node = null
  for v in node.value_array
    arg_list_node = v if v.mx_hash.hash_key == 'arg_list'
    function_body = v if v.mx_hash.hash_key == 'function_body'
    ret_type_node = v if v.mx_hash.hash_key == 'type'
  
  scope_push node
  # TODO translate arg default values
  arg_list = []
  if arg_list_node?
    walk = (node)->
      for v in node.value_array
        if v.mx_hash.hash_key == 'arg'
          arg_list.push v
        else
          walk v
      return
    walk arg_list_node
    for v in arg_list
      for sn in v.value_array
        if sn.mx_hash.hash_key == 'identifier'
          scope_id_push sn
        else if sn.mx_hash.hash_key == 'rvalue'
          ctx.translate sn
  
  if function_body?
    ret += ctx.translate function_body
  scope_pop()
  
  arg_type_list = []
  if ret_type_node?
    arg_type_list.push type_ast_to_obj ret_type_node
  else
    arg_type_list.push mk_type 'void'
  
  for v in arg_list
    type = null
    rvalue = null
    if v.value_array.length == 3
      [id,_skip,type_or_rvalue] = v.value_array
      type  = type_or_rvalue if type_or_rvalue.mx_hash.hash_key == 'type'
      rvalue= type_or_rvalue if type_or_rvalue.mx_hash.hash_key == 'rvalue'
    else
      [id] = v.value_array
    if type?
      type_str = type_ast_to_obj type
      assert_pass_down id, type_str, "func arg '#{id.value}'"
    if rvalue?
      assert_pass_down_eq id, rvalue, "func arg '#{id.value}'"
    arg_type_list.push id.mx_hash.type or mk_type "*"
  
  craft_type = mk_type "function", arg_type_list
  
  assert_pass_down node, craft_type, "function"
  ret
# ###################################################################################################
#    access
# ###################################################################################################

trans.translator_hash['macro_stub'] = translate:(ctx, node)->
  ret = 0
  block = null
  for v in node.value_array
    block = v if v.mx_hash.hash_key == 'block'
  
  ret += ctx.translate block
  ret
# ###################################################################################################
#    string_interpolated
# ###################################################################################################

trans.translator_hash['string_inter_pass'] = translate:(ctx, node)->
  ret = 0
  for v in node.value_array
    if v.mx_hash.hash_key == 'rvalue'
      ret += ctx.translate v
      # TODO check v.mx_hash.type castable to string
  ret
# ###################################################################################################
#    scope id pass
# ###################################################################################################

scope_id_pass = ()->
  ret = 0
  for scope in scope_list
    for k,list of scope.id_map
      # p list.map((t)->t.mx_hash) # DEBUG
      ret += assert_pass_down_eq_list list, undefined, "scope_id_pass '#{k}'"
  
  # p "scope_id_pass=#{ret}" # DEBUG
  return ret

# ###################################################################################################

@_type_inference = (ast, opt={})->
  scope_state_reset()
  change_count = 0
  for i in [0 .. 10] # MAGIC
    # phase 1 deep
    # found atoms of known types
    # found bigger atoms that can be constructed for lower ones with 1 pass
    
    # change_count = +trans.go ast # avoid sink point
    trans.reset()
    change_count = trans.translate ast
    
    # phase 2 same scope id lookup
    change_count += scope_id_pass()
    # p "change_count=#{change_count}" # DEBUG
    if change_count == 0
      return
  
  ### !pragma coverage-skip-block ###
  throw new Error "Type inference error. Out of lookup limit change_count(left)=#{change_count}"
  

@type_inference = (ast, opt, on_end)->
  try
    module._type_inference ast, opt
  catch e
    return on_end e
  on_end null
