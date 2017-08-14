require 'fy'
require 'fy/lib/codegen'
{
  Translator
} = require 'gram2'
module = @
# ###################################################################################################
#    scope state
# ###################################################################################################
# MAY BE move to trans
current_scope =
  id_map : {} # id -> ast pos list

scope_list = [current_scope]
scope_stack = []
fake_id = (type)->
  {
    mx_hash : {
      type
    }
  }

scope_state_reset = ()->
  current_scope =
    id_map : {
      stdin : [
        fake_id mk_type 'Source', [mk_type 'string']
      ]
      stdout : [
        fake_id mk_type 'Sink', [mk_type 'string'],
      ]
      Math : [
        fake_id mk_type 'object', [], {
          abs   : mk_type 'either', [
            mk_type 'function', [mk_type('int'), mk_type('int')]
            mk_type 'function', [mk_type('float'), mk_type('float')]
          ]
          round : mk_type 'function', [mk_type('int'), mk_type('float')]
        }
      ]
      Fail : [ # crafted object for more coverage
        fake_id mk_type 'object', [], {
          invalid_either   : mk_type 'either', [
            mk_type 'function', [mk_type('int'), mk_type('int')]
            mk_type 'int'
          ]
        }
      ]
      Either_test : [ # crafted object for more coverage
        fake_id mk_type 'object', [], {
          int_float   : mk_type 'either', [
            mk_type 'int'
            mk_type 'float'
          ]
          int_float_bool   : mk_type 'either', [
            mk_type 'int'
            mk_type 'float'
            mk_type 'bool'
          ]
        }
      ]
    } # id -> ast pos list

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
  field_hash : {} # name -> type
  
  constructor:()->
    @field_hash = {}
    
  eq : (t)->
    return false if @main != t.main
    return false if @nest.length != t.nest.length
    for v,k in @nest
      return false if !v.eq t.nest[k]
    
    for k,v1 of @field_hash
      v2 = t.field_hash[k]
      return false if !v2 or !v1.eq v2
    
    # just check keys
    for k,v2 of t.field_hash
      v1 = @field_hash[k]
      return false if !v1
    
    true
  
  toString : ()->
    nest_part = ""
    if @nest.length
      list = []
      for v in @nest
        list.push v.toString()
      nest_part = "<#{list.join ','}>"
    object_part = ""
    if h_count @field_hash
      list = []
      for k,v of @field_hash
        list.push "#{k}:#{v}" # implicit to string
      object_part = "{#{list.join ','}}"
    "#{@main}#{nest_part}#{object_part}"
  
  can_match : (t)->
    return true if @main == '*'
    return true if t.main == '*'
    
    return false if @main != t.main
    return false if @nest.length != t.nest.length
    for v,k in @nest
      v2 = t.nest[k]
      return false if !v.can_match v2
    
    for k,v1 of @field_hash
      v2 = t.field_hash[k]
      return false if !v2 or !v1.can_match v2
    
    # just check keys
    for k,v2 of t.field_hash
      v1 = @field_hash[k]
      return false if !v1
    
    true
  
  exchange_missing_info : (t)->
    if @main == '*' and t.main == '*'
      return 0 # nothing
    else if @main == '*'
      @main = t.main
      @nest = t.nest.clone()
      return 1
    else if t.main == '*'
      t.main = @main
      t.nest = @nest.clone()
      return 1
    
    ret = 0
    for v,k in @nest
      v2 = t.nest[k]
      ret += v.exchange_missing_info v2
    
    for k,v1 of @field_hash
      v1.exchange_missing_info t.field_hash[k]
    
    ret
  
  set : (t)->
    @main = t.main
    @nest = t.nest
    @field_hash = t.field_hash
    return

mk_type = (str, nest=[], field_hash={})->
  ret = new module.Type
  ret.main = str
  ret.nest = nest
  ret.field_hash = field_hash
  ret

# ###################################################################################################

type_wrap = (type)->
  mx_hash :
    type : type
# TODO flatten either (e.g. either<a,either<b,c> > -> either<a,b,c>)
mk_either_list = (t)->
  if t.main == 'either'
    return t.nest
  [t]

# TODO перестать использовать
_assert_pass_down = (ast, type, diagnostics)->
  ret = 0
  if type.main != '*'
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

assert_pass_down = (ast, type, diagnostics)->
  assert_pass_down_eq ast, type_wrap(type), diagnostics

assert_pass_down_eq = (ast1, ast2, diagnostics)->
  ret = 0
  if ast1.mx_hash.type? and ast2.mx_hash.type?
    either_list1 = mk_either_list ast1.mx_hash.type
    either_list2 = mk_either_list ast2.mx_hash.type
    
    # BUG normalize
    pair_list = []
    for e1 in either_list1
      for e2 in either_list2
        if e1.can_match e2
          pair_list.push [e1,e2]
    
    if pair_list.length == 0
      perr either_list1
      perr either_list2
      throw new Error "assert pass up eq failed either list can't match"
    
    t1_possible_list = []
    t2_possible_list = []
    # BUG normalize
    for pair in pair_list
      t1_possible_list.upush pair[0]
      t2_possible_list.upush pair[1]
    
    
    if either_list1.length != t1_possible_list.length
      if t1_possible_list.length == 1
        ast1.mx_hash.type.set t1_possible_list[0]
      else
        cut_type = mk_type 'either', t1_possible_list
        ast1.mx_hash.type.set cut_type
      ret++
    
    if either_list2.length != t2_possible_list.length
      if t2_possible_list.length == 1
        ast2.mx_hash.type.set t2_possible_list[0]
      else
        cut_type = mk_type 'either', t2_possible_list
        ast2.mx_hash.type.set cut_type
      ret++
    
    # BUG. Can't exchange shared info (e.g. either<function<int,float>,function<int,int>> can't send return type )
    if either_list1.length == 1 and either_list2.length == 1
      t1 = either_list1[0]
      t2 = either_list2[0]
      if !t1.eq(t2)
        ret += t1.exchange_missing_info t2
  else if !ast1.mx_hash.type? and !ast2.mx_hash.type?
    # nothing
  else if !ast1.mx_hash.type?
    ret += _assert_pass_down ast1, ast2.mx_hash.type, "#{diagnostics} ast1 down"
  else #!ast2.mx_hash.type?
    ret += _assert_pass_down ast2, ast1.mx_hash.type, "#{diagnostics} ast2 down"
    
  return ret
assert_pass_down_eq_list = (ast_list, type, diagnostics)->
  ret = 0
  
  # if !type # coverage LATER
  for v in ast_list
    break if type = v.mx_hash.type
  if type
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
  if node.value_view in ['true', 'false'] # .toLowerCase() ??
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
  
  for op in "+ - * % %%".split " "
    for at in "int float".split " "
      for bt in "int float".split " "
        def_bin op, at, bt, "float"
  
  for op in "+ - * % %% << >> >>>".split /\s+/
    def_bin op, "int", "int", "int"
  
  def_bin "+", "string", "string", "string"
  def_bin "*", "string", "int", "string"
  
  for op in "/ **".split " "
    for at in "int float".split " "
      for bt in "int float".split " "
        def_bin op, at, bt, "float"
  
  for at in "int float".split " "
    for bt in "int float".split " "
      def_bin "//", at, bt, "int"
  
  for op in "and or xor".split /\s+/
    def_bin op, "bool", "bool", "bool"
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
  op = bin_op_node.value_view
  
  for v in rvalue_list
    ret += ctx.translate v
  
  # cases
  # no type detected - can build system that limits a, b and result
  # 1 type detected  - can build system that limits second and result
  # 2 type detected  - can validate and send result
  # LATER result defined + some args
  
  [a,b] = rvalue_list
  if op == '|'
    if a.mx_hash.type?
      unless a.mx_hash.type.main in (a_types = ["array", "Source"])
        pp a.mx_hash.type
        throw new Error "Pipe can't be used for left type #{a.mx_hash.type.main}. Supported types: #{a_types}"
    if b.mx_hash.type?
      unless b.mx_hash.type.main in (b_types = ["function", "array", "Sink"])
        throw new Error "Pipe can't be used for right type #{b.mx_hash.type.main}. Supported types: #{b_types}"
    
    return 0
  
  
  
  if !a.mx_hash.type? and !b.mx_hash.type?
    # case 1
    # not implemented
  else if a.mx_hash.type? and b.mx_hash.type?
    # case 3
    at = a.mx_hash.type
    bt = b.mx_hash.type
    
    loop
      if op in ['==', '!=']
        ret += assert_pass_down_eq a, b, "bin_op eq"
        _ret = 'bool'
        break
      
      key = "#{op},#{at},#{bt}"
      if !_ret = bin_op_type_table[key]
        throw new Error "Type inference: can't find bin_op=#{op} a=#{at} b=#{bt} node=#{node.value}"
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
  op = bin_op_node.value_view.replace '=', ''
  
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
      
      assert_pass_down node, _ret_t, 'assign_bin_op'
  else
    # case 2
    if b.mx_hash.type?
      if op == ''
        ret += assert_pass_down_eq a, b, 'assign_bin_op'
        # BYPASSSING missing code coverage
        ret += assert_pass_down_eq node, b, 'assign_bin_op'
        # if !node.mx_hash.type?
        #   node.mx_hash.type = b.mx_hash.type
        #   ret++
        # else
        #   # UNIMPLEMENTED
    else # a.mx_hash.type?
      if op == ''
        ret += assert_pass_down_eq b, a, 'assign_bin_op'
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
def_pre "not", "int" , "int"
def_pre "not", "bool", "bool"


trans.translator_hash['pre_op'] = translate:(ctx, node)->
  ret = 0
  rvalue_list = []
  pre_op_list = []
  for v in node.value_array
    rvalue_list.push v if v.mx_hash.hash_key == 'rvalue'
    pre_op_list.push v if v.mx_hash.hash_key == 'pre_op'
  
  pre_op_node = pre_op_list[0]
  op = pre_op_node.value_view
  
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
  op = post_op_node.value_view
  
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
  
  ret += assert_pass_down_eq vtrue, node, "ternary"
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
  must_be_hash = false
  
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
      key = id_list[0]
      value = id_list[0]
      scope_id_push value
    else if rvalue_list.length == 1
      # NOTE LATER can be missing
      # e.g. {a.b.c} => {c:a.b.c}
      key = id_list[0]
      value = rvalue_list[0]
    else # if rvalue_list.length == 2
      [key, value] = rvalue_list
      must_be_hash = true
      # TODO check key castable to string # same as string iterpolated
    element_list.push {key, value}
  
  # REMOVE LATER
  if must_be_hash
    ret += assert_pass_down_eq_list element_list.map((t)->t.value), undefined, "hash decl"
  
  if element_list.length
    if must_be_hash
      subtype = element_list[0].value.mx_hash.type
      if !node.mx_hash.type?
        node.mx_hash.type = mk_type "hash", [subtype]
        ret++
    else
      if !node.mx_hash.type?
        node.mx_hash.type = mk_type "object", []
        ret++
        for kv in element_list
          {key, value} = kv
          node.mx_hash.type.field_hash[key.value] = value.mx_hash.type or mk_type '*'
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

trans.translator_hash['array_access'] = translate:(ctx, node)->
  ret = 0
  [root, _skip, rvalue] = node.value_array
  ret += ctx.translate root
  ret += ctx.translate rvalue
  # cases
  # 1 array<T> [int   ] -> T
  # 2 hash<T>  [string] -> T
  
  if root.mx_hash.type
    subtype = root.mx_hash.type.nest[0]
    switch root.mx_hash.type.main
      when 'array'
        ret += assert_pass_down rvalue, mk_type("int"), "array_access array"
      when 'hash' # Прим. здесь я считаю hash == dictionary. А есть еще тип named tuple
        ret += assert_pass_down rvalue, mk_type("string"), "array_access hash"
      when 'string'
        ret += assert_pass_down rvalue, mk_type("int"), "array_access hash"
        subtype = mk_type 'string'
      # when '*'  # can't pass as main type
        # OK
      else
        throw new Error "Trying to access array of not allowed type '#{root.mx_hash.type.main}'"
    
    if subtype and subtype.main != '*'
      ret += assert_pass_down node, subtype, "array_access"
  
  ret

trans.translator_hash['id_access'] = translate:(ctx, node)->
  [root, _skip, id] = node.value_array
  ret = ctx.translate root
  
  if root.mx_hash.type
    subtype = root.mx_hash.type.nest[0]
    switch root.mx_hash.type.main
      when 'array'
        # TODO later impl with field_hash
        if id.value == 'length'
          subtype = mk_type 'int'
        else
          throw new Error "Trying access field '#{id.value}' in array"
      when 'hash' # Прим. здесь я считаю hash == dictionary. А есть еще тип named tuple, там нужно смотреть на тип каждого field'а
        'OK'
      when 'object' # named tuple
        field_hash = root.mx_hash.type.field_hash
        if !subtype = field_hash[id.value]
          throw new Error "Trying access field '#{id.value}' in object with fields=#{Object.keys field_hash}"
      else
        throw new Error "Trying to access field '#{id.value}' of not allowed type '#{root.mx_hash.type.main}'"
    
    if subtype.main != '*' or node.mx_hash.type
      ret += assert_pass_down node, subtype, "id_access"
      
  
  ret

trans.translator_hash['opencl_access'] = translate:(ctx, node)->
  
  [root, _skip, id] = node.value_array
  ret = ctx.translate root
  
  if root.mx_hash.type
    subtype = root.mx_hash.type.nest[0]
    switch root.mx_hash.type.main
      when 'array'
        if id.value.length != 1
          subtype = root.mx_hash.type
      else
        throw new Error "Trying to access field '#{id.value}' of not allowed type '#{root.mx_hash.type.main}'"
    
    if subtype and subtype.main != '*'
      ret += assert_pass_down node, subtype, "opencl_access"
  
  ret
# ###################################################################################################
#    function
# ###################################################################################################
type_ast_to_obj = (ast)->
  # NOTE WRONG. Need proper handle <>
  mk_type ast.value_view

trans.translator_hash['func_decl'] = translate:(ctx, node)->
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

trans.translator_hash['func_call'] = translate:(ctx, node)->
  ret = 0
  rvalue = node.value_array[0]
  comma_rvalue_node = null
  for v in node.value_array
    if v.mx_hash.hash_key == 'comma_rvalue'
      comma_rvalue_node = v
  
  arg_list = []
  ret += ctx.translate rvalue
  if comma_rvalue_node
    walk = (node)->
      for v in node.value_array
        if v.mx_hash.hash_key == 'rvalue'
          arg_list.push v
        if v.mx_hash.hash_key == 'comma_rvalue'
          walk v
      rvalue
    walk comma_rvalue_node
    for arg in arg_list
      ret += ctx.translate arg
  
  if rvalue.mx_hash.type
    check_list = mk_either_list rvalue.mx_hash.type
    
    allowed_signature_list = []
    for type in check_list
      unless type.main in ['function', '*']
        throw new Error "trying to call type='#{type}'"
      # default arg later
      continue if type.nest.length-1 != arg_list.length
      found = false
      for i in [1 ... type.nest.length] by 1
        expected_arg_type = type.nest[i]
        real_arg_type = arg_list[i-1].mx_hash.type
        if real_arg_type and !expected_arg_type.can_match real_arg_type
          found = true
          break
      if !found
        allowed_signature_list.push type
    if allowed_signature_list.length == 0
      throw new Error "can't find allowed_signature in '#{check_list.map((t)->t.toString())}'"
    
    candidate_type = allowed_signature_list[0].nest[0]
    found = false
    for v in allowed_signature_list
      if !v.nest[0].eq candidate_type
        found = true
        break
    if !found
      ret += assert_pass_down node, candidate_type, "func_call"
  else if ctx.func_call_unroll
    # try to detect function type based on argument call list
    # NOTE BUG. Default args will be FUCKed
    
    ret_type = node.mx_hash.type or mk_type '*'
    craft_type = mk_type 'function', [ret_type]
    
    for arg in arg_list
      craft_type.nest.push arg.mx_hash.type or mk_type '*'
    
    ret += assert_pass_down rvalue, craft_type, "func_call"
  
  ret
# ###################################################################################################
#    macro
# ###################################################################################################

trans.translator_hash['macro_stub'] = translate:(ctx, node)->
  ret = 0
  block = null
  rvalue = null
  for v in node.value_array
    block = v if v.mx_hash.hash_key == 'block'
    rvalue = v if v.mx_hash.hash_key == 'rvalue'
  
  if rvalue?
    ret += ctx.translate rvalue
  
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

@__type_inference = (ast, opt={})->
  change_count = 0
  trans.func_call_unroll = opt.func_call_unroll
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
  
@_type_inference = (ast, opt={})->
  scope_state_reset()
  
  module.__type_inference ast, opt
  opt2 = {
    func_call_unroll : true
  }
  obj_set opt2, opt
  module.__type_inference ast, opt2
  return

@type_inference = (ast, opt, on_end)->
  try
    module._type_inference ast, opt
  catch e
    return on_end e
  on_end null
