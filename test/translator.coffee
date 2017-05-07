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
  """.split /\n/g
  for sample in sample_list
    do (sample)->
      it sample, ()->
        assert.equal full(sample), sample
  
  kv =
    "+a"      : "+a"
    "-a"      : "-a"
    "typeof a": "(typeof a)"
    "not a"   : "!a"
  for k,v of kv
    do (k,v)->
      it k, ()->
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
    
    # TEMP
    await go '#1', {}, defer(err, res)
    assert err?
    # LATER not translated
    # await go '1+"1"', {}, defer(err, res)
    # assert err?
    done()