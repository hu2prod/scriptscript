require 'fy'
require 'fy/codegen'
{
  Translator
  un_op_translator_holder
  un_op_translator_framework
  bin_op_translator_holder
  bin_op_translator_framework
} = require 'gram2'
module = @

# ###################################################################################################
trans = new Translator
trans.trans_skip =
  indent : true
  dedent : true
  eol    : true

trans.trans_value =
  bracket       : true
  comma         : true
  pair_separator: true
  arrow_function: true

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
      if node.mx_hash.eol_pass and v.mx_hash.hash_key == 'eol'
        list.push "\n"
    else if fn = trans.trans_token[v.mx_hash.hash_key]
      list.push fn v.value_view
    else if trans.trans_value[v.mx_hash.hash_key]?
      list.push v.value
    else
      list.push ctx.translate v
  if delimiter = node.mx_hash.delimiter
    delimiter = ' ' if delimiter == "'[SPACE]'"
    list = [ list.join(delimiter) ]
  list

trans.translator_hash['value']  = translate:(ctx, node)->node.value_view
trans.translator_hash['deep']   = translate:(ctx, node)->
  list = deep ctx, node
  list.join('')
trans.translator_hash['block']   = translate:(ctx, node)->
  list = deep ctx, node
  make_tab list.join(''), '  '
# ###################################################################################################
#    bin_op
# ###################################################################################################

do ()->
  holder = new bin_op_translator_holder
  for v in bin_op_list = "+ - * /".split ' '
    holder.op_list[v]  = new bin_op_translator_framework "($1$op$2)"
    v = v+"="
    holder.op_list[v]  = new bin_op_translator_framework "($1$op$2)"

  for v in bin_op_list = "= == != < <= > >=".split ' '
    holder.op_list[v]  = new bin_op_translator_framework "($1$op$2)"
  trans.translator_hash['bin_op'] = translate:(ctx, node)->
    op = node.value_array[1].value_view
    # PORTING BUG gram2
    node.value_array[1].value = node.value_array[1].value_view
    if op in ['or', 'and']
      # needs type inference
      [a,_skip,b] = node.value_array
      a_tr = ctx.translate a
      b_tr = ctx.translate b
      
      if !a.mx_hash.type? or !b.mx_hash.type?
        throw new Error "can't translate op=#{op} because type inference can't detect type of arguments"
      if !a.mx_hash.type.eq b.mx_hash.type
        # не пропустит type inference
        ### !pragma coverage-skip-block ###
        throw new Error "can't translate op=#{op} because type mismatch #{a.mx_hash.type} != #{b.mx_hash.type}"
      switch a.mx_hash.type.toString()
        when 'int'
          return "(#{a_tr}|#{b_tr})"
        when 'bool'
          return "(#{a_tr}||#{b_tr})"
        else
          # не пропустит type inference
          ### !pragma coverage-skip-block ###
          throw new Error "op=#{op} doesn't support type #{a.mx_hash.type}"
    
    holder.translate ctx, node
# ###################################################################################################
#    pre_op
# ###################################################################################################
do ()->
  holder = new un_op_translator_holder
  holder.mode_pre()
  for v in un_op_list = "~ + - !".split ' '
    holder.op_list[v]  = new un_op_translator_framework "$op$1"

  holder.op_list["not"]  = new un_op_translator_framework "!$1"
  holder.op_list["void"] = new un_op_translator_framework "null"

  for v in un_op_list = "typeof new delete".split ' '
    holder.op_list[v]  = new un_op_translator_framework "($op $1)"
  # trans.translator_hash['pre_op'] = holder
  # PORTING BUG UGLY FIX gram2
  trans.translator_hash['pre_op'] = translate:(ctx, node)->
    node.value_array[0].value = node.value_array[0].value_view
    holder.translate ctx, node

# ###################################################################################################
#    post_op
# ###################################################################################################
do ()->
  holder = new un_op_translator_holder
  holder.mode_post()
  for v in un_op_list = ["++", '--']
    holder.op_list[v]  = new un_op_translator_framework "($1$op)"
  # trans.translator_hash['post_op'] = holder
  # PORTING BUG UGLY FIX gram2
  trans.translator_hash['post_op'] = translate:(ctx, node)->
    node.value_array[0].value = node.value_array[1].value_view
    holder.translate ctx, node

# ###################################################################################################
#    str
# ###################################################################################################

trans.translator_hash['string_singleq'] = translate:(ctx, node)->
  '"' + (node.value[1...-1].replace /"/g, '\\"') + '"'

trans.translator_hash['block_string'] = translate:(ctx, node)->
  '"' + (node.value[3...-3].replace /"/g, '\\"') + '"'

trans.translator_hash['string_interpolation'] = translate:(ctx, node)->
  children = node.value_array
  ret = switch children.length
    when 0, 1
      node.value
    when 2
      ctx.translate(children[0])[...-2] + children[1].value[1...]
    when 3
      ctx.translate(children[0])[...-2] + '"+' + ctx.translate(children[1]) + '+"' + children[2].value[1...]
  if children.last().mx_hash.hash_key[-3...] == "end"
    ret = ret.replace /"""/g, '"'
    ret = ret.replace /\+""/g, ''
  ret

# ###################################################################################################
#    hash
# ###################################################################################################
trans.translator_hash["hash_pair_simple"] = translate:(ctx,node)->
  [key, _skip, value] = node.value_array
  "#{key.value}:#{ctx.translate value}"
trans.translator_hash["hash_pair_auto"] = translate:(ctx,node)->
  [value] = node.value_array
  "#{value.value}:#{value.value}"
trans.translator_hash['hash_wrap']   = translate:(ctx, node)->
  list = deep ctx, node
  "{"+list.join('')+"}"
# ###################################################################################################
#    access
# ###################################################################################################
trans.translator_hash["field_access"] = translate:(ctx,node)->
  [root, _skip, field] = node.value_array
  "#{ctx.translate root}.#{field.value}"
trans.translator_hash["array_access"] = translate:(ctx,node)->
  [root, _skip, field, _skip] = node.value_array
  "#{ctx.translate root}[#{ctx.translate field}]"
trans.translator_hash["opencl_access"] = translate:(ctx,node)->
  [root, _skip, field] = node.value_array
  root_tr = ctx.translate root
  key = field.value
  if key.length == 1
    return "#{root_tr}[#{key}]"
  # TODO ref
  ret = []
  for k in key
    ret.push "#{root_tr}[#{k}]"
  "[#{ret.join ','}]"
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
#    macro-block
# ###################################################################################################
trans.macro_block_condition_hash =
  "if" : (ctx, condition, block)->
    """
    if (#{ctx.translate condition}) {
      #{make_tab ctx.translate(block), '  '}
    }
    """
  "while" : (ctx, condition, block)->
    """
    while(#{ctx.translate condition}) {
      #{make_tab ctx.translate(block), '  '}
    }
    """
trans.macro_block_hash =
  "loop" : (ctx, block)->
    """
    while(true) {
      #{make_tab ctx.translate(block), '  '}
    }
    """

trans.translator_hash['macro_block'] = translate:(ctx,node)->
  if node.value_array.length == 2
    [name_node, body] = node.value_array
    name = name_node.value
    if !(fn = trans.macro_block_hash[name])?
      if trans.macro_block_condition_hash[name]?
        throw new Error "Missed condition for block '#{name}'"
      throw new Error "unknown conditionless macro block '#{name}'"
    fn ctx, body
  else
    [name_node, condition, body] = node.value_array
    name = name_node.value
    if !(fn = trans.macro_block_condition_hash[name])?
      if trans.macro_block_hash[name]?
        throw new Error "Extra condition for block '#{name}'"
      throw new Error "unknown conditionless macro block '#{name}'"
    fn ctx, condition, body
# ###################################################################################################

@_translate = (ast, opt={})->
  trans.go ast

@translate = (ast, opt, on_end)->
  try
    res = module._translate ast, opt
  catch e
    return on_end e
  on_end null, res
