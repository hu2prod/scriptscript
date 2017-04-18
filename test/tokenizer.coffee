assert = require 'assert'
util = require './util'

g = require '../tokenizer.coffee'

describe 'tokenizer section', ()->
  it "a", ()->
    v = g._tokenize "a"
    assert.equal v.length, 1

  it "1", ()->
    v = g._tokenize "1"
    assert.equal v.length, 1
    assert.equal v[0][0].mx_hash.hash_key, "numeric_constant"

  it "0777", ()->
    v = g._tokenize "0777"
    assert.equal v.length, 1
    assert.equal v[0][0].mx_hash.hash_key, "numeric_constant_octal"

  it "0xabcd8", ()->
    v = g._tokenize "0xabcd8"
    assert.equal v.length, 1
    assert.equal v[0][0].mx_hash.hash_key, "numeric_constant_hex"

  it "0XABCD8", ()->
    v = g._tokenize "0XABCD8"
    assert.equal v.length, 1
    assert.equal v[0][0].mx_hash.hash_key, "numeric_constant_hex"

  it "0xAbCd8", ()->
    v = g._tokenize "0xAbCd8"
    assert.equal v.length, 1
    assert.equal v[0][0].mx_hash.hash_key, "numeric_constant_hex"


