require 'fy'
require 'fy/lib/codegen'
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
        list.push ";\n"
    else if fn = trans.trans_token[v.mx_hash.hash_key]
      list.push fn v.value
    else if trans.trans_value[v.mx_hash.hash_key]?
      list.push v.value
    else
      list.push ctx.translate v
  if delimiter = node.mx_hash.delimiter
    # delimiter = ' ' if delimiter == "'[SPACE]'" # not used -> commented
    list = [ list.join(delimiter) ]
  list

trans.translator_hash['value']  = translate:(ctx, node)->node.value_view
trans.translator_hash['deep']   = translate:(ctx, node)->
  list = deep ctx, node
  list.join('')
trans.translator_hash['block']   = translate:(ctx, node)->
  list = deep ctx, node
  make_tab list.join(''), '  '
ensure_bracket = (t)->
  return t if t[0] == "(" and t[t.length-1] == ")"
  "(#{t})"
# ###################################################################################################
#    bin_op
# ###################################################################################################

do ()->
  holder = new bin_op_translator_holder
  for v in "+ - * / % += -= *= /= %= = < <= > >= << >> >>>".split ' '
    holder.op_list[v]     = new bin_op_translator_framework "($1$op$2)"
  holder.op_list["**"]  = new bin_op_translator_framework "Math.pow($1, $2)"
  holder.op_list["//"]  = new bin_op_translator_framework "Math.floor($1 / $2)"
  holder.op_list["%%"]  = new bin_op_translator_framework "(_tmp_b=$2,($1 % _tmp_b + _tmp_b) % _tmp_b)"
  holder.op_list["**="] = new bin_op_translator_framework "$1 = Math.pow($1, $2)"
  holder.op_list["//="] = new bin_op_translator_framework "$1 = Math.floor($1 / $2)"
  holder.op_list["%%="] = new bin_op_translator_framework "$1 = (_tmp_b=$2,($1 % _tmp_b + _tmp_b) % _tmp_b)"
  holder.op_list["=="]  = new bin_op_translator_framework "($1===$2)"
  holder.op_list["!="]  = new bin_op_translator_framework "($1!==$2)"
  
  trans.translator_hash['bin_op'] = translate:(ctx, node)->
    op = node.value_array[1].value_view
    # PORTING BUG gram2
    node.value_array[1].value = node.value_array[1].value_view
    
    # return is implied, I actually mean it. This if block is intended to be the last statement in the function.
    if op of holder.op_list
      holder.translate ctx, node
    else
      [a,_skip,b] = node.value_array
      a_tr = ctx.translate a
      b_tr = ctx.translate b
      logical_or_bitwise = (char) ->
        postfix = if op[-1..] == '=' then '=' else ''
        if a.mx_hash.type.toString() == "int"         # type inference ensures the second operand to be int
          "(#{a_tr}#{char}#{postfix}#{b_tr})"
        else                                          # type inference ensures operands to be bools
          if char == '^'
            if postfix
              "(#{a_tr}=!!(#{a_tr}^#{b_tr}))"
            else
              "(!!(#{a_tr}#{char}#{b_tr}))"
          else if postfix
            "(#{a_tr}=(#{a_tr}#{char}#{char}#{b_tr}))"
          else
            "(#{a_tr}#{char}#{char}#{b_tr})"
      switch op
        when "and", "and="
          logical_or_bitwise '&'
        when "or", "or="
          logical_or_bitwise '|'
        when "xor", "xor="
          logical_or_bitwise '^'
        when '|'
          # pipes logic
          if b.mx_hash.type?
            switch b.mx_hash.type.main
              when "function"
                nest = b.mx_hash.type.nest
                # NOTE 1st nest == return type
                if nest.length == 2 # is_map
                  "#{ensure_bracket a_tr}.map(#{b_tr})"
                else if nest.length == 3
                  ###
                    TODO
                    Array.prototype.async_map -> ?Promise?
                    ?Promise?.prototype (need all Array stuff)
                  ###
                  if nest[2].main == 'function' # async map
                    "#{ensure_bracket a_tr}.async_map(#{b_tr})"
                  else # reduce
                    "#{ensure_bracket a_tr}.reduce(#{b_tr})"
                else if nest.length == 4
                  if nest[3].main == 'function' # async reduce
                    "#{ensure_bracket a_tr}.async_reduce(#{b_tr})"
                  else
                    throw new Error "unknown pipe function signature [1]"
                else
                  throw new Error "unknown pipe function signature [2]"
              when "array"
                "#{b_tr} = #{a_tr}"
              when "Sink"
                """
                var ref = #{ensure_bracket a_tr};
                for (var i = 0, len = ref.length; i < len; i++) {
                  #{b_tr}(ref[i]);
                }
                """
              # else для switch не нужен т.к. не пропустит type inference
          else
            "#{b_tr} = #{a_tr}"
        else
          ### !pragma coverage-skip-block ###
          throw new Error "Translator: can't figure out how to translate '#{op}'"
    
    # Don't put code down here below if block without a good reason (unless you're ready for refactoring).
    # The preceding block should remain the last statement in the function as long as possible.
    

    # Here is some old code (maybe del later):

    # if op in ['or', 'and']
    #   # needs type inference
    #   [a,_skip,b] = node.value_array
    #   a_tr = ctx.translate a
    #   b_tr = ctx.translate b
      
    #   if !a.mx_hash.type? or !b.mx_hash.type?
    #     throw new Error "can't translate op=#{op} because type inference can't detect type of arguments"
    #   if !a.mx_hash.type.eq b.mx_hash.type
    #     # не пропустит type inference
    #     ### !pragma coverage-skip-block ###
    #     throw new Error "can't translate op=#{op} because type mismatch #{a.mx_hash.type} != #{b.mx_hash.type}"
    #   switch a.mx_hash.type.toString()
    #     when 'int'
    #       return "(#{a_tr}|#{b_tr})"
    #     when 'bool'
    #       return "(#{a_tr}||#{b_tr})"
    #     else
    #       # не пропустит type inference
    #       ### !pragma coverage-skip-block ###
    #       throw new Error "op=#{op} doesn't support type #{a.mx_hash.type}"
    
# ###################################################################################################
#    pre_op
# ###################################################################################################
do ()->
  holder = new un_op_translator_holder
  holder.mode_pre()
  for v in un_op_list = "~ + - !".split ' '
    holder.op_list[v]  = new un_op_translator_framework "$op$1"

  holder.op_list["void"] = new un_op_translator_framework "null"

  for v in un_op_list = "typeof new delete".split ' '
    holder.op_list[v]  = new un_op_translator_framework "($op $1)"
  # trans.translator_hash['pre_op'] = holder
  # PORTING BUG UGLY FIX gram2
  trans.translator_hash['pre_op'] = translate:(ctx, node)->
    op = node.value_array[0].value_view
    node.value_array[0].value = node.value_array[0].value_view
    if op == "not"
      a = node.value_array[1]
      a_tr = ctx.translate a
      if !a.mx_hash.type
        throw new Error "can't translate not operation because no type inferenced"
      if a.mx_hash.type.toString() == "int"
        "~#{a_tr}"
      else
        "!#{a_tr}"   # type inference ensures bool
    else
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
    node.value_array[1].value = node.value_array[1].value_view
    holder.translate ctx, node

# ###################################################################################################
#    str
# ###################################################################################################
trans.translator_hash['string_singleq'] = translate:(ctx, node)->
  s = node.value_view[1...-1]
  s = s.replace /"/g, '\\"'
  s = s.replace /^\s+/g, ''
  s = s.replace /\s+$/g, ''
  s = s.replace /\s*\n\s*/g, ' '
  '"' + s + '"' #"

trans.translator_hash['string_doubleq'] = translate:(ctx, node)->
  s = node.value_view
  s = s.replace /^"\s+/g, '"'
  s = s.replace /\s+"$/g, '"'
  s = s.replace /\s*\n\s*/g, ' '

trans.translator_hash['block_string_singleq'] = translate:(ctx, node)->
  s = node.value_view[3...-3]
  s = s.replace /^\n/g, ''
  s = s.replace /\n$/g, ''
  s = s.replace /\n/g, '\\n'
  s = s.replace /"/g, '\\"'
  '"' + s + '"'

trans.translator_hash['block_string_doubleq'] = trans.translator_hash['block_string_singleq'] # for now...

trans.translator_hash['string_interpolation_prepare'] = translate:(ctx, node)->
  ret = switch node.mx_hash.hash_key
    when 'st1_start'
      node.value_view[1...-2]   # '"text#{'   -> 'text'
      .replace(/^\s+/g, '')
      .replace /\s*\n\s*/g, ' '
    when 'st3_start'
      node.value_view[3...-2]   # '"""text#{' -> 'text'
    when 'st_mid'
      node.value_view[1...-2]   # '}text#{'   -> 'text'
    when 'st1_end'
      node.value_view[1...-1]   # '}text"'    -> 'text'
      .replace(/\s+$/g, '')
      .replace /\s*\n\s*/g, ' '
    when 'st3_end'
      node.value_view[1...-3]   # '}text"""'  -> 'text'
  ret = ret.replace /"/, '\\"'

trans.translator_hash['string_interpolation_put_together'] = translate:(ctx, node)->
  children = node.value_array
  ret = switch children.length
    when 2
      ctx.translate(children[0]) + ctx.translate(children[1])
    when 3
      ctx.translate(children[0]) + '"+' + ensure_bracket(ctx.translate(children[1])) + '+"' + ctx.translate(children[2])
  if children.last().mx_hash.hash_key[-3...] == "end"
    ret = '("' + ret + '")'
    ret = ret.replace /\+""/g, ''   # some cleanup
  ret

trans.translator_hash['string_interpolation_put_together_m1'] = translate:(ctx, node)->
  children = node.value_array
  ret = switch children.length
    when 2
      ctx.translate(children[0]) + ctx.translate(children[1]).replace /\s*\n\s*/g, ' '
    when 3
      ctx.translate(children[0]) + '"+' + ensure_bracket(ctx.translate(children[1])) + '+"' + ctx.translate(children[2]).replace /\s*\n\s*/g, ' '
  ret

# ###################################################################################################
#    regexp
# ###################################################################################################

trans.translator_hash['block_regexp'] = translate:(ctx, node)->
  [_skip, body, flags] = node.value_view.split "///"  # '///ab+c///imgy' -> ['', 'ab+c', 'imgy']
  body = body.replace /\s#.*/g, ''    # comments
  body = body.replace /\s/g, ''       # whitespace
  if body == ""
    body = "(?:)"
  else
    body = body.replace /\//g, '\\/'  # escaping forward slashes
  '/' + body + '/' + flags

trans.translator_hash['regexp_interpolation_prepare'] = translate:(ctx, node)->
  switch node.mx_hash.hash_key
    when 'rextem_start'
      ret = node.value_view[3...-2]   # '///ab+c#{' -> 'ab+c'
    when 'rextem_mid'
      ret = node.value_view[1...-2]   # '}ab+c#{' -> 'ab+c'
    when 'rextem_end'
      [body, flags] = node.value_view.split "///"   # '}ab+c///imgy' -> ['}ab+c', 'imgy']
      node.flags = flags
      ret = body[1...]                # '}ab+c' -> 'ab+c'
  ret = ret.replace /\s#.*/g, ''      # comments
  ret = ret.replace /\s/g, ''         # whitespace
  ret = ret.replace /"/g, '\\"'       # escaping quotes

trans.translator_hash['regexp_interpolation_put_together'] = translate:(ctx, node)->
  children = node.value_array
  ret = switch children.length
    when 2
      ctx.translate(children[0]) + ctx.translate(children[1])
    when 3
      ctx.translate(children[0]) + '"+' + ensure_bracket(ctx.translate(children[1])) + '+"' + ctx.translate(children[2])
  last = children.last()
  if last.mx_hash.hash_key == "rextem_end"
    ret += """","#{last.flags}""" if last.flags
    ret = """RegExp("#{ret}")"""
    ret = ret.replace /\+""/g, ''   # 'RegExp("a"+"b")' -> 'RegExp("ab")'
  ret

# ###################################################################################################
#    bracket
# ###################################################################################################
trans.translator_hash["bracket"] = translate:(ctx,node)->
  ensure_bracket ctx.translate node.value_array[1]
# ###################################################################################################
#    ternary
# ###################################################################################################
trans.translator_hash["ternary"] = translate:(ctx,node)->
  [cond, _s1, tnode, _s2, fnode] = node.value_array
  "#{ctx.translate cond} ? #{ctx.translate tnode} : #{ctx.translate fnode}"

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
#    array
# ###################################################################################################
trans.translator_hash["num_array"] = translate:(ctx, node)->
  # [_skip1, a, _skip2, b, _skip3] = node.value_array
  a = +node.value_array[1].value_view
  b = +node.value_array[3].value_view
  if b - a > 20
    """
    (function() {
      var results = [];
      for (var i = #{a}; i <= #{b}; i++){ results.push(i); }
      return results;
    })()
    """
  else if a - b > 20
    """
    (function() {
      var results = [];
      for (var i = #{a}; i >= #{b}; i--){ results.push(i); }
      return results;
    })()
    """
  else
    "[#{[a..b].join ", "}]"

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
  walk = (arg)->
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
      else if arg.value_array[1].value == ","
        walk arg.value_array[0]
        walk arg.value_array[2]
        return
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
      name : name_node.value or name_node.value_view
      type : null
      default_value
    }
    return
  if node.value_array[0].value == '(' and node.value_array[2].value == ')'
    arg_list_node = node.value_array[1]
    for arg in arg_list_node.value_array
      continue if arg.value == ","
      walk arg
  
  body_node = node.value_array.last()
  body_node = null if body_node.value in ["->", "=>"] # no body
  
  
  arg_str_list = []
  default_arg_str_list = []
  for arg in arg_list
    arg_str_list.push arg.name
    if arg.default_value
      default_arg_str_list.push """
        #{arg.name}=#{arg.name}==null?#{ensure_bracket arg.default_value}:#{arg.name};
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
trans.translator_hash["func_call"] = translate:(ctx,node)->
  rvalue = node.value_array[0]
  comma_rvalue_node = null
  for v in node.value_array
    if v.mx_hash.hash_key == 'comma_rvalue'
      comma_rvalue_node = v
  
  arg_list = []
  func_code = ensure_bracket ctx.translate rvalue
  if comma_rvalue_node
    walk = (node)->
      for v in node.value_array
        if v.mx_hash.hash_key == 'rvalue'
          arg_list.push ctx.translate v
        if v.mx_hash.hash_key == 'comma_rvalue'
          walk v
      rvalue
    walk comma_rvalue_node
  
  "#{func_code}(#{arg_list.join ', '})"
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
