assert = require 'assert'
util = require 'fy/test_util'

{_tokenize} = require '../tokenizer.coffee'
{_parse   } = require '../grammar.coffee'
full = (t)->_parse _tokenize t
{go} = require '../index.coffee'

describe 'gram section', ()->
  sample_list = """
    a
    +a
    a+b
    1
    a+1
    a+a+a
    (a)
    a+a*a
  """.split /\n/g
  for sample in sample_list
    do (sample)->
      it sample, ()->
        full sample
  
  it '1a1 throw', ()->
    util.throws ()->
      full '1a1'
  
  it 'public endpoint should work', (done)->
    await go '1', {}, defer(err, res)
    pp err
    assert !(err?)
    await go '1 КИРИЛИЦА', {}, defer(err, res)
    assert err?
    await go '1a1', {}, defer(err, res)
    assert err?
    done()
  
