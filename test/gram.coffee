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
    a|b
    a|b|c
    -a+b
    ~a
    !a
    typeof a
    not a
    void a
    new a
    delete a
    a + b
    a - b
    a * b
    a / b
    a % b
    a ** b
    a // b
    a %% b
    a and b
    a && b
    a or b
    a || b
    a < b
    a <= b
    a == b
    a > b
    a >= b
    a != b
    a << b
    a >> b
    a >>> b
    a instanceof b
    a++
    a--
    a+ b
    a +b
    a + b
  """.split /\n/g
  # NOTE a +b is NOT bin_op. It's function call
  for sample in sample_list
    do (sample)->
      it sample, ()->
        full sample
  sample_list = """
    a +
      b
  """.split /\n?---\n?/g
  for sample in sample_list
    continue if !sample
    do (sample)->
      it JSON.stringify(sample), ()->
        full sample
  
  sample_list = """
    a++++
    a++ ++
    a+
    кирилица
    a === b
    a !== b
    ++a
    --a
  """.split /\n/g
  for sample in sample_list
    do (sample)->
      it "#{sample} should not parse", ()->
        util.throws ()->
          full sample
  
  it 'a+a*a priority',  ()->
    ret = full 'a+a*a'
    rvalue = ret[0].value_array
    assert.equal rvalue[0].value_array[1].value, "+"
  
  it 'a*a+a priority',  ()->
    ret = full 'a*a+a'
    rvalue = ret[0].value_array
    assert.equal rvalue[0].value_array[1].value, "+"
  
  it 'void a+a priority',  ()->
    ret = full 'void a+a'
    rvalue = ret[0].value_array
    assert.equal rvalue[0].value_array[0].value, "void"
  
  it '-a+b priority',  ()->
    ret = full '-a+b'
    rvalue = ret[0].value_array
    assert.equal rvalue[0].value_array[1].value, "+"
  
  it 'loop\\n  b'#,  ()->
    # full """
    # loop
    #   b
    # """
  
  it '1a1 throw', ()->
    util.throws ()->
      full '1a1'
  
  describe 'array section', ()->
    sample_list = """
      []
      ---
      [ ]
      ---
      [a]
      ---
      [a,b]
      ---
      [a,b,c]
      ---
      [
      ]
      ---
      [
      
      ]
      ---
      [
      
      
      ]
      ---
      [
      a
      ]
      ---
      [
        a
      ]
      ---
    """.split /\n?---\n?/g
    for sample in sample_list
      continue if !sample
      do (sample)->
        it JSON.stringify(sample), ()->
          full sample
    # sample_list = """
    #   [a
    #   ]
    #   ---
    #   [
    #   a]
    # """.split /\n?---\n?/g
    # for sample in sample_list
    #   continue if !sample
    #   do (sample)->
    #     it "#{JSON.stringify(sample)} bad codestyle not parsed", ()-> # или говнокодеры должны страдать
    #       util.throws ()->
    #         full sample
  describe 'pipe section', ()->
    sample_list = """
      a | | b
      ---
      a | b | c
      ---
      a |
        | b
      ---
      a |
        | b | c
      ---
      a |
        | b
        | c
      ---
      a |
        | b
        | c | d
      ---
      a |
        | b | c
        | d | e
    """.split /\n?---\n?/g
    for sample in sample_list
      continue if !sample
      do (sample)->
        it JSON.stringify(sample), ()->
          full sample
  
  it 'public endpoint should work', (done)->
    await go '1', {}, defer(err, res)
    assert !(err?)
    await go '1 КИРИЛИЦА', {}, defer(err, res)
    assert err?
    await go '1a1', {}, defer(err, res)
    assert err?
    done()
  
describe "Gram TODO", ()->
  it "all exapmles from coffeescript documentation (oneliners only) should be tokenizable and parsable"
  # check only if it doesn't throw