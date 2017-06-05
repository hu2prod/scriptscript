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
      "1"     : "int"
      "0777"  : "int"
      "0x1"   : "int"
      "0b1"   : "int"
      "1.0"   : "float"
      "'1'"   : "string"
      '"1"'   : "string"
      "true"  : "bool"
      "false" : "bool"
      "a"     : undefined
      "@"     : undefined
      "'1'\n1": "int" # test stmt_plus
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
  
  # describe 'special const', ()->
  #   kv = 
  #     # '"1#{a}2"' : "string" # Wake me up when sting interpolation comes...
  #   for k,v of kv
  #     do (k,v)->
  #       it JSON.stringify(k), ()->
  #         ast = full k
  #         assert.equal ast.mx_hash.type?.toString(), v
  describe 'bin op', ()->
    kv =
      "a+b"           : undefined
      "1+1"           : "int"
      "1-1"           : "int"
      "1*1"           : "int"
      "1//1"          : "int"
      "1<<1"          : "int"
      "1>>1"          : "int"
      "1>>>1"         : "int"
      "1 and 1"       : "int"
      "1 or 1"        : "int"
      "true and true" : "bool"
      "true or  true" : "bool"
      "1 == 1"        : "bool"
      "1 != 1"        : "bool"
      "1 >  1"        : "bool"
      "1 >= 1"        : "bool"
      "1 <  1"        : "bool"
      "1 <= 1"        : "bool"
      "1.0 == 1.0"    : "bool"
      "1.0 != 1.0"    : "bool"
      "1.0 >  1.0"    : "bool"
      "1.0 >= 1.0"    : "bool"
      "1.0 <  1.0"    : "bool"
      "1.0 <= 1.0"    : "bool"
      "'1' == '1'"    : "bool"
      "'1' != '1'"    : "bool"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    
    list = """
      1+'1'
      'a' or 'b'
      'a' or 1
    """.split "\n"
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'assign op', ()->
    kv =
      "a=b"         : undefined
      "a=1"         : "int"
      "b=a=1"       : "int"
      "a+=b+=c"     : undefined
      "a=1\na"      : "int"
      "a=1\nb=a"    : "int"
      "a=1\nb=a\nb" : "int"
      # reverse pass
      "b=a\na=1\nb" : "int"
      "a=1\na=b\nb" : "int"
      "a=1\na+=b\nb" : undefined
      # add coverage
      "a=c=d=e=f\na=1\na=b\nb" : "int"
      "a=c=d=e=f\nb=1\na=b\na" : "int"
      "a=(b=e)\ne=d\nd=c\nc=1\na=1\nb" : "int" # не срабатывает
      "a=(b=f)\nf=e\ne=d\nd=c\nc=1\na=1\nb" : "int" # не срабатывает
      # TOO LONG !!!
      # "a=(b=g)\ng=f\nf=e\ne=d\nd=c\nc=1\na=1\nb" : "int" # не срабатывает
      # redundant
      "a=e=f\na=1\nf=z=1\ne" : "int"
      "a=e=f\na=z=1\nf=1\ne" : "int"
      "a=e=f\na=1\nf=z\nz=1\ne" : "int"
      "a=e=f\na=z\nz=1\nf=1\ne" : "int"
      
      "a+=1"         : undefined # попытка записать в неинициализированную переменную.
      "a=1\nb=1\na+=b"  : "int"
      "a=(c)\na=1\nc"  : "int"
      # "a=(b=c)\na=1\nc"  : "int" # FAILS because no bin_op pass up
      
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    
    list = """
      a=1
      a='1'
      ---
      a=1
      b='1'
      b=a
      ---
      a=1
      b='1'
      c=a
      c=b
      ---
      a=1
      a+='1'
      ---
      a='1'
      a+=1
      ---
      a='1'
      b=1
      a+=b
    """.split /\n?---\n?/g
    ###
      a=1
      b='1'
      c=a
      c=d
    ###
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'pre op', ()->
    kv =
      "+a"       : undefined
      "-1"       : "int"
      "~1"       : "int"
      "+'1'"     : "float"
      "!true"    : "bool"
      "not true" : "bool"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      +1
    """.split "\n"
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'post op', ()->
    kv =
      "a++"       : undefined
      "a=1\na++"  : "int"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      a='1'
      a++
    """.split /\n?---\n?/g
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  # WRONG. Must be lvalue with proper type !!!
  # describe 'post op', ()->
    # kv =
      # "a++" : "int"
      # "a--" : "int"
    # for k,v of kv
      # do (k,v)->
        # it JSON.stringify(k), ()->
          # ast = full k
          # assert.equal ast.mx_hash.type?.toString(), v
  describe 'expr', ()->
    kv =
      "(1)" : "int"
      "(a)" : undefined
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
  
  describe 'ternary', ()->
    kv =
      "true?1:2": "int"
      "a?1:2"   : "int"
      "a?b:2"   : "int"
      "a?1:b"   : "int"
      "a?a:b"   : "bool"
      "a?a:a"   : "bool"
      # "!!1?a:a"   : "bool"
      "@?a:a"   : undefined
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      1?a:b
      '1'?a:b
      a?1:'1'
    """.split "\n"
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'array', ()->
    kv =
      "[]"      : "array<*>"
      "[1]"     : "array<int>"
      "[[1]]"   : "array<array<int>>"
      "[1,1]"   : "array<int>"
      "[1,1,1]" : "array<int>"
      "[a,1,1]" : "array<int>"
      "[1,a,1]" : "array<int>"
      "[1,1,a]" : "array<int>"
      "[1,a,a]" : "array<int>"
      "[a,1,a]" : "array<int>"
      "[a,a,1]" : "array<int>"
      "[]  == []"   : "bool"
      "[1] == [1]"  : "bool"
      "[]  == [1]"  : "bool"
      "[1] == []"   : "bool"
      
      "[[]]  == [[]]"   : "bool"
      "[[1]] == [[1]]"  : "bool"
      "[[]]  == [[1]]"  : "bool"
      "[[1]] == [[]]"   : "bool"
      
      "a=[]\na=[1]" : "array<int>"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      [1,'1']
      [1] == ['1']
    """.split "\n"
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'hash', ()->
    kv =
      "{}"      : "hash<*>"
      "{a:1}"   : "hash<int>"
      "{a,b:1}" : "hash<int>"
      "{(a):1}" : "hash<int>"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      {a:1,b:'1'}
    """.split "\n"
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'array access', ()->
    kv =
      "a[b]"                : undefined
      
      # * should not pass as main type
      "arr=[]\narr[0]"        : undefined
      "arr=[]\na=arr[0]\na"   : undefined
      "arr=[]\na=arr[0]\na[b]": undefined
      
      "a='1'\na[b]"         : "string"
      "a='1'\na[b]\nb"      : "int"
      
      "a=[1]\na[b]"         : "int"
      "a=[1]\na[b]\nb"      : "int"
      
      "a=['1']\na[b]"       : "string"
      "a=['1']\na[b]\nb"    : "int"
      
      "a={a:1}\na[b]"       : "int"
      "a={a:1}\na[b]\nb"    : "string"
      
      "a={a:'1'}\na[b]"     : "string"
      "a={a:'1'}\na[b]\nb"  : "string"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      a = 1
      a[b]
    """.split /\n?---\n?/g
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'id access', ()->
    kv =
      "a.b"             : undefined
      "a = []\na.length": "int"
      "a = {}\na.b"     : undefined
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      a = []
      a.b
      ---
      a = 1
      a.b
    """.split /\n?---\n?/g
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'opencl access', ()->
    kv =
      "a.0"             : undefined
      "a.1"             : undefined
      "a.01"            : undefined
      "a.11"            : undefined
      
      "a = []\na.0"     : undefined
      "a = []\na.1"     : undefined
      
      "a = [1]\na.0"     : "int"
      "a = [1]\na.1"     : "int"
      
      "a = [1]\na.01"    : "array<int>"
      "a = [1]\na.11"    : "array<int>"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      a = {}
      a.0
    """.split /\n?---\n?/g
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe 'function', ()->
    kv =
      "->"          : "function<void>"
      "():int->1"   : "function<int>"
      "(a)->"       : "function<void,*>"
      "(a:int)->"   : "function<void,int>"
      "(a)->\n  a=1": "function<void,int>"
      "(a,b)->\n  a=1": "function<void,int,*>"
      
      "((a,b)->a=1) == ((a,b)->b='1')": "bool"
      "((a,b)->b='1') == ((a,b)->a=1)": "bool"
      
      "((a)->a=[]) == ((a)->a=[1])": "bool"
      "((a)->a=([])) == ((a)->a=[1])": "bool"
      
      "(a=1)->": "function<void,int>"
      "(a=[],b=a)->b=[1]": "function<void,array<int>,array<int>>"
      
      "((a,b)->a=1) == ((a,b)->)": "bool"
      "((a,b)->) == ((a,b)->a=1)": "bool"
      "((a,b=1)->a=1) == ((a,b=1)->)": "bool"
      "((a,b=1)->) == ((a,b=1)->a=1)": "bool"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          ast = full k
          assert.equal ast.mx_hash.type?.toString(), v
    list = """
      -> == (a)->
      (a)->a=1 == (a)->a='1'
    """.split "\n"
    for v in list
      do (v)->
        it JSON.stringify(v), ()->
          util.throws ()->
            full v
  
  describe "can't detect", ()->
    it "a + 1", ()->
      ast = full "a + 1"
      assert.equal ast.mx_hash.type?.toString(), undefined
    
    it "1 + a", ()->
      ast = full "1 + a"
      assert.equal ast.mx_hash.type?.toString(), undefined
    
    it "a + b", ()->
      ast = full "a + b"
      assert.equal ast.mx_hash.type?.toString(), undefined
  
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
  
