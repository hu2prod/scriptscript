assert = require 'assert'
util = require 'fy/test_util'

{_tokenize} = require '../tokenizer.coffee'
{_parse   } = require '../grammar.coffee'
{_translate, translate} = require '../translator.coffee'
full = (t)->
  tok = _tokenize(t)
  ast = _parse(tok, mode_full:true)
  _translate ast[0], {}
{go} = require '../index.coffee'

describe 'translator section', ()->
  sample_list = """
    a
    1
    1.0
    1e6
    0x1
    0777
    (a)
    +a
    -a
    []
    [1]
    [1,2]
    [a]
    {}
    {a:1}
    a ? b : c
    "abcd"
    'abcd'
  """.split /\n/g
  for sample in sample_list
    do (sample)->
      it JSON.stringify(sample), ()->
        assert.equal full(sample), sample
  
  # bracketed
  sample_list = """
    typeof a
    new a
    delete a
    a++
    a--
    a+b
    a=b
  """.split /\n/g
  for sample in sample_list
    do (sample)->
      it JSON.stringify(sample), ()->
        assert.equal full(sample), "(#{sample})"
  
  describe "pre op", ()->
    kv =
      "not a"   : "!a"
      "void a"  : "null"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
  
  describe "hash", ()->
    kv =
      "{a}"     : "{a:a}"
      "a:1"     : "{a:1}"
      "{\na:b\nc:d}": "{a:b,c:d}"
      # "{(a):b}" : "(_t={},_t[a]=b,_t)"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
  
  describe "array", ()->
    kv =
      "[\n]"        : "[]"
      "[\na\nb]"    : "[a,b]"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
  
  describe "comment", ()->
    kv =
      "#a"  : "//a"
      "a#a" : "a//a"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
  
  describe "function", ()->
    kv =
      "->"        : "(function(){})"
      "->a"       : """
        (function(){
          return(a)
        })
        """
      "()->"      : "(function(){})"
      "(a)->"     : "(function(a){})"
      "(a,b)->"   : "(function(a, b){})"
      "(a,b=1)->" : """
        (function(a, b){
          b=b==null?(1):b;
        })"""
      "(a,b=1):number->" : """
        (function(a, b){
          b=b==null?(1):b;
        })"""
      "(a)->a"    : """
        (function(a){
          return(a)
        })
        """
      "(a)->\n  a"    : """
        (function(a){
          a
        })
        """
      "->\n  a"    : """
        (function(){
          a
        })
        """
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
        # TEMP  same
        k2 = k.replace "->", "=>"
        it JSON.stringify(k2), ()->
          assert.equal full(k2), v
    # TEMP throws
    kv =
      "(a:number)->"     : "(function(a){})"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          util.throws ()->
            full(k)
  
  describe "macro-block", ()->
    kv =
      """
      if a
        b
      """       : """
        if (a) {
          b
        }
        """
      """
      loop
        b
      """       : """
        while(true) {
          b
        }
        """
      # LATER
      # """
      # c = if a
        # b
      # """       : """
        # if (a) {
          # c = b
        # }
        # """
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
    sample_list =
      """
      if
        b
      ---
      loop a
        b
      ---
      wtf a
        b
      ---
      wtf
        b
      """.split /\n?---\n?/
    for v in sample_list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full(v)
  
  it 'test translate exception', (done)->
    await translate null, {}, defer(err)
    assert err?
    done()
  
  it 'public endpoint should work', (done)->
    await go 'a', {}, defer(err, res)
    assert !(err?)
    await go 'a КИРИЛИЦА', {}, defer(err, res)
    assert err?
    await go '1a1', {}, defer(err, res)
    assert err?
    
    # LATER not translated
    # await go '1+"1"', {}, defer(err, res)
    # assert err?
    await go '__test_untranslated', {}, defer(err, res)
    assert err?
    done()