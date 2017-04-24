assert = require 'assert'
util = require 'fy/test_util'

g = require '../tokenizer.coffee'
pub = require '../index.coffee'

describe 'tokenizer section', ()->
  describe "identifier", ()->
    it "should tokenize 'qwerty' as identifier", ()->
      v = g._tokenize "qwerty"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "identifier"
    
    it "should tokenize 'myvar123' as identifier", ()->
      v = g._tokenize "myvar123"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "identifier"
    
    it "should tokenize 'someCamelCase' as identifier", ()->
      v = g._tokenize "someCamelCase"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "identifier"
    
    it "should tokenize 'some_snake_case' as identifier", ()->
      v = g._tokenize "some_snake_case"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "identifier"
    
    it "should tokenize 'CAPSLOCK' as identifier", ()->
      v = g._tokenize "CAPSLOCK"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "identifier"
    
    it "should tokenize '$' as identifier", ()->
      v = g._tokenize "$"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "identifier"
    
    it "should tokenize '$scope' as identifier", ()->
      v = g._tokenize "$scope"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "identifier"
  
  describe "integer literals", ()->
    it "should tokenize '142857' as decimal_literal", ()->
      v = g._tokenize "142857"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "decimal_literal"
    
    it "should tokenize '0' as decimal_literal", ()->
      v = g._tokenize "0"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "decimal_literal"
    
    it "should tokenize '0777' as octal_literal", ()->
      v = g._tokenize "0777"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "octal_literal"
    
    it "should tokenize '0o777' as octal_literal", ()->
      v = g._tokenize "0o777"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "octal_literal"
    
    it "should tokenize '0O777' as octal_literal", ()->
      v = g._tokenize "0O777"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "octal_literal"
    
    it "should tokenize '0xabcd8' as hexadecimal_literal", ()->
      v = g._tokenize "0xabcd8"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "hexadecimal_literal"
    
    it "should tokenize '0XABCD8' as hexadecimal_literal", ()->
      v = g._tokenize "0XABCD8"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "hexadecimal_literal"
    
    it "should tokenize '0xAbCd8' as hexadecimal_literal", ()->
      v = g._tokenize "0xAbCd8"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "hexadecimal_literal"
    
    it "should tokenize '0b10101' as binary_literal", ()->
      v = g._tokenize "0b10101"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "binary_literal"
    
    it "should tokenize '0B10101' as binary_literal", ()->
      v = g._tokenize "0B10101"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "binary_literal"
    
    it "should tokenize '-1' as 2 tokens", ()->
      v = g._tokenize "-1"
      assert.equal v.length, 2
      assert.equal v[0][0].mx_hash.hash_key, "unary_operator"
      assert.equal v[1][0].mx_hash.hash_key, "decimal_literal"
  
  
  describe "mixed operators", ()->
    for v in "+ -".split " "
    # for v in "+ - ?".split " "
      do (v)->
        it "should tokenize '#{v}' as unary_operator and binary_operator", ()->
          v = g._tokenize v
          assert.equal v.length, 1
          assert.equal v[0][0].mx_hash.hash_key, "unary_operator"
          assert.equal v[0][1].mx_hash.hash_key, "binary_operator"
  
  describe "unary operators", ()->
    for v in "~ ! ++ -- not typeof new delete".split " "
      do (v)->
        it "should tokenize '#{v}' as unary_operator", ()->
          v = g._tokenize v
          assert.equal v.length, 1
          assert.equal v[0][0].mx_hash.hash_key, "unary_operator"
  
  describe "binary operators", ()->
    for v in "* / % ** // %% << >> >>> & | ^ && || ^^ and or xor instanceof in of is isnt ? . ?. :: ?:: .. ...".split " "
      do (v)->
        it "should tokenize '#{v}' as binary_operator", ()->
          v = g._tokenize v
          assert.equal v.length, 1
          assert.equal v[0][0].mx_hash.hash_key, "binary_operator"
  
  describe "binary operators assign", ()->
    for v in "+ - * / % ** // %% << >> >>> & | ^ && || ^^ and or xor ?".split " "
      v += "="
      do (v)->
        it "should tokenize '#{v}' as binary_operator", ()->
          v = g._tokenize v
          assert.equal v.length, 1
          assert.equal v[0][0].mx_hash.hash_key, "binary_operator"
  
  describe "binary operators compare", ()->
    # !== === 
    for v in "< > <= >= == !=".split " "
      do (v)->
        it "should tokenize '#{v}' as binary_operator", ()->
          v = g._tokenize v
          assert.equal v.length, 1
          assert.equal v[0][0].mx_hash.hash_key, "binary_operator"
  
  describe "function", ()->
    for v in "-> =>".split " "
      do (v)->
        it "should tokenize '#{v}' as arrow_function", ()->
          v = g._tokenize v
          assert.equal v.length, 1
          assert.equal v[0][0].mx_hash.hash_key, "arrow_function"
  
  describe "this", ()->
    it "should tokenize '@' as this", ()->
      v = g._tokenize "@"
      assert.equal v.length, 1
      assert.equal v[0][0].mx_hash.hash_key, "this"
    
    it "should tokenize '@a' as this and identifier", ()->
      v = g._tokenize "@a"
      assert.equal v.length, 2
      assert.equal v[0][0].mx_hash.hash_key, "this"
      assert.equal v[1][0].mx_hash.hash_key, "identifier"
  
  
  describe "brackets", ()->
    for v in "()[]{}"
      do (v)->
        it "should tokenize '#{v} as bracket", ()->
          tl = g._tokenize v
          assert.equal tl.length, 1
          assert.equal tl[0][0].mx_hash.hash_key, "bracket"
  
    it "should parse '(a)->a' as 5 tokens", ()->
      tl = g._tokenize "(a)->a"
      assert.equal tl.length, 5
      assert.equal tl[0][0].mx_hash.hash_key, "bracket"
      assert.equal tl[1][0].mx_hash.hash_key, "identifier"
      assert.equal tl[2][0].mx_hash.hash_key, "bracket"
      assert.equal tl[3][0].mx_hash.hash_key, "arrow_function"
      assert.equal tl[4][0].mx_hash.hash_key, "identifier"
  
  
  describe "floats", ()->
    for v in [
      ".1",
      "1.",
      "1.1",
      "1.e10",
      "1.e+10",
      "1.e-10",
      "1.1e10",
      ".1e10",
      "1e10",
      "1e+10",
      "1e-10"
    ]
      do (v)->
        it "should parse '#{v}' as float_literal", ()->
          tl = g._tokenize v
          assert.equal tl.length, 1
          assert.equal tl[0][0].mx_hash.hash_key, "float_literal"
    
    it "should parse '1.1+1' as 3 tokens", ()->
      tl = g._tokenize "1.1+1"
      assert.equal tl.length, 3
      assert.equal tl[0][0].mx_hash.hash_key, "float_literal"
      assert.equal tl[1][0].mx_hash.hash_key, "unary_operator"
      assert.equal tl[1][1].mx_hash.hash_key, "binary_operator"
      assert.equal tl[2][0].mx_hash.hash_key, "decimal_literal"
    
    it "should parse '1e+' as 3 tokens", ()->
      tl = g._tokenize "1e+"
      assert.equal tl.length, 3
      assert.equal tl[0][0].mx_hash.hash_key, "decimal_literal"
      assert.equal tl[1][0].mx_hash.hash_key, "identifier"
      assert.equal tl[2][0].mx_hash.hash_key, "unary_operator"
      assert.equal tl[2][1].mx_hash.hash_key, "binary_operator"
    
    it "should parse '1e' as 2 tokens", ()->
      tl = g._tokenize "1e"
      assert.equal tl.length, 2
      assert.equal tl[0][0].mx_hash.hash_key, "decimal_literal"
      assert.equal tl[1][0].mx_hash.hash_key, "identifier"
  
  
  describe "TODO", ()->
    # it "should parse 'true' as bool_const"
    # it "should parse 'false' as bool_const"
    it "should parse '# wpe ri32p q92p 4rpu34iqwr349i+-+-*/*/ \\n' as comment"
    it "should parse 'a + b' as 3 tokens"
    it "should parse 'a + b' as 'a ', '+ ', 'b'"
    it "should parse whitespace: all except for \\n, \\r "
    it "should parse whitespace: all except for \\n, \\r "
    it "should parse 'a / b / c' as 5 tokens (not regexp!)"
    it "should parse 'a/b/c' as 3 tokens with regexp in the middle"
    it "should parse 'a/b' as 3 tokens without regexp"
    it "should parse 'a//b' as 3 tokens without regexp"
    # regexp must contain at least one symbol excluding whitespace
    # escape policy for string constant should apply for regex
  
  
  it "public endpoint should works", (done)->
    await pub.tokenize "id", {}, defer(err, v)
    assert.equal v.length, 1
    assert.equal v[0][0].mx_hash.hash_key, "identifier"
    
    await pub.tokenize "wtf кирилица", {}, defer(err, v)
    assert err?
    
    done()
  