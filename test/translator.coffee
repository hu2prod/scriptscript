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
  
  kv =
    "not a"   : "!a"
    "void a"  : "null"
    "{a}"     : "{a:a}"
    "a:1"     : "{a:1}"
    "[\n]"        : "[]"
    "[\na\nb]"    : "[a,b]"
    "{\na:b\nc:d}": "{a:b,c:d}"
    "#a"  : "//a"
    "a#a" : "a//a"
    # "{(a):b}" : "(_t={},_t[a]=b,_t)"
  for k,v of kv
    do (k,v)->
      it JSON.stringify(k), ()->
        assert.equal full(k), v
  
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