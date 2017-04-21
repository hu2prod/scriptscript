assert = require 'assert'
util = require './util'

g = require '../tokenizer.coffee'

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
  
  describe "mixed operators", ()->
    for v in "+ -".split " "
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
    for v in "* / % ** // %% << >> >>> & | ^ && || ^^ and or xor instanceof ? . ?. :: ?:: .. ...".split " "
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
    
