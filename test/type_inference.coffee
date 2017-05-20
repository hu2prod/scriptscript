assert = require 'assert'
util = require 'fy/test_util'

{_tokenize} = require '../tokenizer.coffee'
{_parse   } = require '../grammar.coffee'
{_type_inference, type_inference} = require '../type_inference.coffee'
full = (t)->
  tok = _tokenize(t)
  ast = _parse(tok, mode_full:true)
  _type_inference ast[0], {}
  ast[0]

describe 'type_inference section', ()->
  describe 'const', ()->
    kv =
      "1"   : "int"
      "0777": "int"
      "0x1" : "int"
      "0b1" : "int"
      "1.0" : "float"
      "'1'" : "string"
      '"1"' : "string"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type, v
  
  # describe 'special const', ()->
  #   kv = 
  #     # '"1#{a}2"' : "string" # Wake me up when sting interpolation comes...
  #   for k,v of kv
  #     do (k,v)->
  #       it JSON.stringify(k), ()->
  #         ast = full k
  #         assert.equal ast.mx_hash.type, v
  describe 'bin op', ()->
    kv =
      "1+1" : "int"
      "1-1" : "int"
      "1*1" : "int"
      "1//1" : "int"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type, v
  
  describe "can't detect", ()->
    it "a + 1", ()->
      ast = full "a + 1"
      assert.equal ast.mx_hash.type, undefined
    
    it "1 + a", ()->
      ast = full "1 + a"
      assert.equal ast.mx_hash.type, undefined
    
    it "a + b", ()->
      ast = full "a + b"
      assert.equal ast.mx_hash.type, undefined
  
  describe 'external interface', ()->
    it "ok", (done)->
      tok = _tokenize "1"
      ast = _parse(tok, mode_full:true)
      
      await type_inference ast[0], {}, defer(err)
      assert !err?
      done()
    
    it "fail", (done)->
      tok = _tokenize "1*'1'"
      ast = _parse(tok, mode_full:true)
      
      await type_inference ast[0], {}, defer(err)
      assert err?
      done()