require 'fy'
module = @

# ###################################################################################################
#    generic
# ###################################################################################################
@ltrim = (text, subtext)->
  len = subtext.length
  loop
    if subtext == text.substr 0, len
      text = text.substr len
      continue
    break
  text

class @Node
  mx_hash     : {}
  penetration_hash: {}
  value       : ''
  value_array   : []
  
  constructor   : (value = '', mx_hash = {})->
    @mx_hash    = mx_hash
    @value      = value
    @penetration_hash= {}
    @value_array  = []
  
  cmp       : (t) ->
    for k,v of @mx_hash
      return false if v != t.mx_hash[k]
    return false if @value != t.value
    # penetration_hash ?
    true
  
  name : (name)->
    ret = []
    for v in @value_array
      ret.push v if v.mx_hash.hash_key == name
    ret
  
  str_uid : ()->
    "#{@value} #{JSON.stringify @mx_hash}"
  
  clone : ()->
    ret = new module.Node
    for k,v of @
      continue if typeof v == 'function'
      ret[k] = clone v unless ret[k] == v
    ret

class @Token_parser
  name    : ''
  regex   : ''
  atparse : null
  first_letter_list : []
  first_letter_list_discard : {}
  
  constructor : (@name, @regex, @atparse=null)->
    @first_letter_list = []
    @first_letter_list_discard = {}
  
  fll_add  : (first_letter_list)->
    @first_letter_list = first_letter_list.split ''
    @
  
  fll_discard  : (first_letter_list)->
    for ch in first_letter_list.split ''
      @first_letter_list_discard[ch] = true
    @

class @Tokenizer
  parser_list   : []
  text          : null
  atparse_unique_check : false
  _is_prepared  : false
  _is_tail_space: false
  use_base      : true
  
  @first_char_table     : {}
  @positive_symbol_table: {}
  @non_marked_rules     : []
  reject_target         : null
  
  constructor : ()->
    @parser_list= []
    @first_char_table     = {}
    @positive_symbol_table= {}
    @non_marked_rules     = []
  
  # rword : (text, case_sensitive = false)->
    # text = RegExp.escape text
    # @parser_list.push new module.Token_parser 'reserved_word', new RegExp "^"+text, if case_sensitive then '' else 'i'
  
  text_set:(text)->
    # @text = module.ltrim(text, ' \t')
    @text = text
  
  regex     : (regex)->
    ret = regex.exec(@text)
    return null if !ret
    @text = @text.substr ret[0].length
    @_is_tail_space = /^\s/.test @text
    @text = module.ltrim(@text, ' \t')
    ret
  
  initial_prepare_table: ()->
    @positive_symbol_table = {}
    @non_marked_rules = []
    for v in @parser_list
      if v.first_letter_list.length > 0
        for ch in v.first_letter_list
          @positive_symbol_table[ch] ?= []
          @positive_symbol_table[ch].push v
      else
        @non_marked_rules.push v
    
    @_is_prepared = true
    return
  
  prepare_table : ()->
    @first_char_table = {}
    for i in [0 ... @text.length]
      ch = @text[i]
      continue if @first_char_table[ch]?
      list = []
      if @positive_symbol_table[ch]?
        for v in @positive_symbol_table[ch]
          list.push v
      for v in @non_marked_rules
        list.push v unless v.first_letter_list_discard[ch]?
      @first_char_table[ch] = list
    return
  
  reject : ()->
    @need_reject = true
    new_loc_arr = []
    for v in @loc_arr
      continue if v == @reject_target
      new_loc_arr.push v
    
    arr_set @loc_arr, new_loc_arr
    return
  
  go      : (text)->
    @text_set text
    @initial_prepare_table() if !@_is_prepared
    @prepare_table()
    if @use_base
      add_base = (add_list)->
        node = add_list[0].clone()
        node.mx_hash.hash_key = 'base'
        add_list.push node
        return
    else
      add_base = ()->
    @ret_debug = ret = []
    while @text.length > 0
      found = false
      @loc_arr = loc_arr = []
      # for v in @parser_list # плесень для отладки
      for v in @first_char_table[@text[0]]
        # ###################################################################################################
        #  Добавить проверку первой буквы
        # ###################################################################################################
        reg_ret = v.regex.exec(@text)
        if reg_ret?
          node = new module.Node
          node.mx_hash.hash_key = v.name
          node.regex = v.regex # parasite
          node.value = reg_ret[0]
          node.atparse = v.atparse if v.atparse?
          loc_arr.push node
      throw new Error "can't tokenize '#{@text.substr(0,100)}'..." if loc_arr.length == 0
      loop
        @need_reject = false
        @loc_arr_refined = loc_arr_refined = []
        max_length = 0
        for v in loc_arr
          max_length = v.value.length if max_length < v.value.length
        for v in loc_arr
          loc_arr_refined.push v if v.value.length == max_length
        
        ret_proxy_list = []
        for v in loc_arr_refined
          @reject_target = v
          ret_proxy_list.push ret_proxy = []
          if v.atparse?
            v.atparse.call @, ret_proxy, v
          else
            ret_proxy.push [v]
        
        if @need_reject
          continue
        break
      
      @regex loc_arr_refined[0].regex
      
      for v in loc_arr_refined
        v.mx_hash.tail_space = +@_is_tail_space
      
      if @atparse_unique_check
        if ret_proxy_list.length > 1
          puts loc_arr_refined
          throw new Error "atparse unique failed. Multiple regex pretending"
      else if ret_proxy_list.length > 1
        united_length = ret_proxy_list[0].length # token list length
        if united_length>1
          throw new Error("united_length > 1 not implemented")
        for v in ret_proxy_list
          if v.length != united_length
            puts ret_proxy_list
            throw new Error("no united length")
      
      if ret_proxy_list.length > 1
        add_list = []
        # only for united_length == 1
        for v in ret_proxy_list
          list = v[0]
          if list
            for v2 in list
              add_list.push v2
        if add_list.length
          add_base add_list
          ret.push add_list 
      else if ret_proxy_list.length == 1
        list = ret_proxy_list[0]
        if list.length == 1
          add_list = list[0]
          add_base add_list
          ret.push add_list
        else
          for v in list
            ret.push v
      else
        throw new Error("ret_proxy_list.length == 0 -> not parsed")
    ret

# ###################################################################################################
#    specific
# ###################################################################################################
# API should be async by default in case we make some optimizations in future
@_tokenize = (str, opt)->
  ret = []
  
  ret

@tokenize = (str, opt, on_end)->
  try
    res = module._tokenize str, opt
  catch e
    return on_end e
  on_end null, res