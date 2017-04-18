assert = require 'assert'
util = require './util'

g = require '../tokenizer.coffee'

describe 'tokenizer generic section', ()->
  # ###################################################################################################
  #    aux
  # ###################################################################################################
  it 'ltrim', ()->
    assert.equal g.ltrim('123', ' '), '123'
    assert.equal g.ltrim(' 123', ' '), '123'
    assert.equal g.ltrim('  123', ' '), '123'
    assert.equal g.ltrim('123 ', ' '), '123 '
    assert.equal g.ltrim('123  ', ' '), '123  '
    assert.equal g.ltrim('123', '12'), '3'
    assert.equal g.ltrim('12123', '12'), '3'
    assert.equal g.ltrim('1213', '12'), '13'
    return
  # ###################################################################################################
  #    Node
  # ###################################################################################################
  it 'Node clone + cmp', ()->
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = ['123']
    n2 = n1.clone()
    util.json_eq n1, n2
    assert n1.cmp n2
    return
   
  it 'Node cmp missing mx_hash', ()->
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = ['123']
    
    n2 = new g.Node
    # n2.mx_hash.a = '123' # missing mx_hash
    n2.value = '123'
    n2.value_array = ['123']
    
    assert !n1.cmp n2
   
  it 'Node cmp wrong value', ()->
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = ['123']
    
    n2 = new g.Node
    n2.mx_hash.a = '123' # missing mx_hash
    n2.value = '1234'
    n2.value_array = ['123']
    
    assert !n1.cmp n2
  
  it 'Node str_uid', ()->
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = ['123']
    assert.equal n1.str_uid(), '123 {"a":"123"}'
    return
  
  it 'Node name', ()->
    in_n1 = new g.Node
    in_n1.mx_hash.hash_key = 'k1'
    in_n2 = new g.Node
    in_n2.mx_hash.hash_key = 'k2'
    
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = [
      in_n1
      in_n2
    ]
    ret = n1.name('k1')
    assert.equal ret.length, 1
    assert.equal ret[0], in_n1
    return
  
  # ###################################################################################################
  #    Tokenizer
  # ###################################################################################################
  it 'regex id', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/)
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    assert.equal list[0].length, 2 # because use base
    return
  
  it 'regex id no base', ()->
    t = new g.Tokenizer
    t.use_base = false
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/)
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    assert.equal list[0].length, 1
    return
  
  it 'regex id atparse pass', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/, (ret_proxy, v)->
      n = new g.Node
      n.mx_hash.hash_key = 'id_patch'
      ret_proxy.push [n]
      return
    )
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id_patch'
    return
  
  it 'regex id atparse noadd no base', ()->
    t = new g.Tokenizer
    t.use_base = false
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/, (ret_proxy, v)->
      return
    )
    list = t.go 'a'
    assert.equal list.length, 0
    return
  
  # it 'regex id atparse reject', ()->
    # t = new g.Tokenizer
    # t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/, (ret_proxy, v)->
      # if /^if/.test v
        # @reject()
        # return
      # ret_proxy.push [v]
      # return
    # )
    # t.parser_list.push (new g.Token_parser 'if', /^if/)
    # list = t.go 'ifa'
    # pp list
    # assert.equal list[0][0].mx_hash.hash_key, 'id'
    # assert.equal list[0][0].value, 'id'
    # return
  
  it 'regex id repeat letters', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/)
    list = t.go 'aa'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'regex id with unused regex', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'if', /^if/)
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/)
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'regex id fll', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'if', /^if/)
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'regex id/num discard_fll', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z0-9]+/).fll_discard('0123456789')
    t.parser_list.push (new g.Token_parser 'num', /^[0-9]+/)
    list = t.go '123'
    assert.equal list[0][0].mx_hash.hash_key, 'num'
    return
  
  it 'multiple call regex id', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'regex identifier bin_op', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'identifier', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    t.parser_list.push  new g.Token_parser 'bin_op',   /^[\+\-\*\/]/
    token_list = t.go "a+b"
    assert.equal token_list[0][0].mx_hash.hash_key, 'identifier'
    assert.equal token_list[1][0].mx_hash.hash_key, 'bin_op'
    assert.equal token_list[2][0].mx_hash.hash_key, 'identifier'
    return
  
  it 'fll reject test', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'a', /^a/).fll_add('a')
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    list = t.go 'ab'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'can\'t parse', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    assert.throws ()->
      t.go '123'
    return
  
  it 'multiple parse', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    t.parser_list.push (new g.Token_parser 'id2', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    token_list = t.go 'abc'
    assert.equal token_list[0][0].mx_hash.hash_key, 'id'
    assert.equal token_list[0][1].mx_hash.hash_key, 'id2'
    return
  
  it 'single parse with atparse_unique_check', ()->
    t = new g.Tokenizer
    t.atparse_unique_check = true
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    t.go 'abc'
    return
  
  it 'multiple parse with atparse_unique_check', ()->
    t = new g.Tokenizer
    t.atparse_unique_check = true
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    t.parser_list.push (new g.Token_parser 'id2', /^[_a-zA-Z][_a-zA-Z0-9]*/).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    util.throws ()->
      t.go 'abc'
    return
  