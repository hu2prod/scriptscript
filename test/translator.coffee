assert = require 'assert'
util = require 'fy/test_util'

{_tokenize} = require '../tokenizer.coffee'
{_parse   } = require '../grammar.coffee'
{_translate, translate} = require '../translator.coffee'
{_type_inference} = require '../type_inference.coffee'

full = (t)->
  tok = _tokenize(t)
  ast = _parse(tok, mode_full:true)
  _type_inference ast[0], {}
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
  """.split /\n/g #"
  for sample in sample_list
    do (sample)->
      it JSON.stringify(sample), ()->
        assert.equal full(sample), sample
  
  # ensure bracket
  kv =
    '((a))': '(a)'
    '((a)+(b))': '((a)+(b))'
  for k,v of kv
    do (k,v)->
      it "#{k} -> #{v}", ()->
        assert.equal full(k), v
  
  # bracketed
  sample_list = """
    typeof a
    new a
    delete a
    a++
    a--
  """.split /\n/g
  for sample in sample_list
    do (sample)->
      it JSON.stringify(sample), ()->
        assert.equal full(sample), "(#{sample})"
  
  describe "bin op", ()->
    sample_list = """
      a+b
      a=b
      a==b
      a!=b
      a<b
      a<=b
      a>b
      a>=b
    """.split /\n/g
    for sample in sample_list
      do (sample)->
        it JSON.stringify(sample), ()->
          assert.equal full(sample), "(#{sample})"
    kv =
      "true or false"  : "(true||false)"
      "1 or 2"  : "(1|2)"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
    
    sample_list = """
      a or b
    """.split /\n/g
    for sample in sample_list
      do (sample)->
        it JSON.stringify(sample), ()->
          util.throws ()->
            full(sample)
  
  describe "pre op", ()->
    kv =
      "not a"   : "!a"
      "void a"  : "null"
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
  
  describe "strings non-interpolated", ()->
    kv =
      '""'            : '""'
      '"abcd"'        : '"abcd"'
      '"\\""'         : '"\\""'
      '"\\a"'         : '"\\a"'
      "''"            : '""'
      "'abcd'"        : '"abcd"'
      "'\"'"          : '"\\""'
      "'\"\"'"        : '"\\"\\""'
      '""""""'        : '""'
      "''''''"        : '""'
      '"""abcd"""'    : '"abcd"'
      "'''abcd'''"    : '"abcd"'
      '""" " """'     : '" \\" "'
      '""" "" """'    : '" \\"\\" "'
      "'''\"'''"      : '"\\""'
      "'''\"\"'''"    : '"\\"\\""'
      "'a\#{b}c'"     : '"a\#{b}c"'
      "'''a\#{b}c'''" : '"a\#{b}c"'
    for k,v of kv
      do (k,v)->
        it "#{k} -> #{v}", ()->
          assert.equal full(k), v

    sample_list = """
      '''a\#{b}'
      'a\#{b}'''
    """.split '\n'
    for sample in sample_list
      do (sample)->
        it "#{sample} throws", ()->
          util.throws ()->
            full(sample)
  
  describe "strings interpolated", ()->
    kv =
      '"a#{b+c}d"'        : '"a"+(b+c)+"d"'
      '"a#{b+c}d#{e+f}g"' : '"a"+(b+c)+"d"+(e+f)+"g"'
      '"a#{b+c}d#{e+f}g#{h+i}j"' : '"a"+(b+c)+"d"+(e+f)+"g"+(h+i)+"j"'
      '"a{} #{b+c} {} #d"': '"a{} "+(b+c)+" {} #d"'
      '"a{ #{b+c} } # #{d} } #d"': '"a{ "+(b+c)+" } # "+(d)+" } #d"'
      '"""a#{b}c"""'        : '"a"+(b)+"c"'
      "'''a\#{b}c'''"       : '"a#{b}c"'
      '"a\\#{#{b}c"'        : '"a\\#{"+(b)+"c"'
      '"a\\#{a}#{b}c"'      : '"a\\#{a}"+(b)+"c"'
      '"#{}"'               : '""'
      '"a#{}"'              : '"a"'
      '"#{}b"'              : '"b"'
      '"a#{}b"'             : '"ab"'
      '"#{}#{}"'            : '""'
      '"#{}#{}#{}"'         : '""'
      '"#{}#{}#{}#{}"'      : '""'
      '"a#{}#{}"'           : '"a"'
      '"#{1}#{}"'           : '""+(1)'
      '"#{}b#{}"'           : '"b"'
      '"#{}#{2}"'           : '""+(2)'
      '"#{}#{}c"'           : '"c"'
      '"a#{1}#{}"'          : '"a"+(1)'
      '"a#{}b#{}"'          : '"ab"'
      '"a#{}#{2}"'          : '"a"+(2)'
      '"a#{}#{}c"'          : '"ac"'
      '"#{1}b#{}"'          : '""+(1)+"b"'
      '"#{1}#{2}"'          : '""+(1)+(2)'
      '"#{1}#{}c"'          : '""+(1)+"c"'
      '"#{1}#{2}c"'         : '""+(1)+(2)+"c"'
      '"#{1}b#{}c"'         : '""+(1)+"bc"'
      '"a#{1}b#{}c"'        : '"a"+(1)+"bc"'
      '"a#{}b#{}c"'         : '"abc"'
      '"#{2+2}#{3-8}"'      : '""+(2+2)+(3-8)'
      '"a#{-8}"'            : '"a"+(-8)'
      '"#{[]}"'             : '""+([])'
      '"""a#{2+2}b"""'      : '"a"+(2+2)+"b"'
    for k,v of kv
      do (k,v)->
        it "#{k} -> #{v}", ()->
          assert.equal full(k), v
    
    describe "fuckups", ()->
      fuckups =
        '""" " #{1}"""'       : '" \\" "+1'   # LATER
        '"#{5 #comment}"'     : '""+5'
        '"#{5 #{comment}"'    : '""+5'
      for k, v of fuckups
        do (k, v)->
          it "#{k} -> #{v}"
    
    sample_list = '''
      """a#{b}"
      "a#{b}"""
      "a#{{}}"
    '''.split '\n'
    # Note that "#{{}}" is valid IcedCoffeeScript (though "#{{{}}}" isn't)
    for sample in sample_list
      do (sample)->
        it "#{sample} throws", ()->
          util.throws ()->
            full(sample)
  
  describe "regexp", ()->
    kv =
      '/ab+c/iiiiiiiiiiiiiii' : '/ab+c/iiiiiiiiiiiiiii'
      '///ab+c///i'           : '/ab+c/i'
      '//////'                : '/(?:)/'        # this is invalid IcedCoffeeScript
      '/// / ///'             : '/\\//'         # escape /
      '/// / // ///'          : '/\\/\\/\\//'   # more /-s to be escaped
      '/// a b + c ///'       : '/ab+c/'        # spaces to be ignored
      '///\ta\tb\t+\tc\t///'  : '/ab+c/'        # tabs to be ignored as well
      '///ab+c #comment///'   : '/ab+c/'        # comment
      '///ab+c#omment///'     : '/ab+c#omment/' # comments should be preceded by whitespace
      '///ab+c \\#omment///'  : '/ab+c\\#omment/'
      '///[#]///'             : '/[#]/'
      '''///multiline
      lalala
      tratata///'''           : '/multilinelalalatratata/'
      '''///multiline
      with # a comment
      # and
      some continuation
      ///'''                  : '/multilinewithsomecontinuation/'
      '/// ///'               : '/(?:)/'     # O_O
      '''///
      ///'''                  : '/(?:)/'     # multiline O_O
      '''///   # comment
      ///'''                  : '/(?:)/'     # multiline O_O with comment
    for k,v of kv
      do (k,v)->
        it "#{k} -> #{v}", ()->
          assert.equal full(k), v
  
  describe "regexp todo", ()->
    todo =
      '/todo interpolation with flags/'  : '/todo interpolation with flags/'
    for k, v of todo
      do (k, v)->
        it "#{k} -> #{v}"
  
  describe "regexp interpolation", ()->
    kv =
      '///ab+c\\#{///'                  : '/ab+c\\#{/'  # interpolation escaped
      '///ab+c #comment #{2+2} de+f///' : 'RegExp("ab+c"+(2+2)+"de+f")'
      '''///ab+c #comment #{2+2} de+f
      another line # with a comment
      # one more comment #{4+4}///'''   : 'RegExp("ab+c"+(2+2)+"de+fanotherline"+(4+4))'

      # The following samples are borrowed from the string interpolation section:
      '///a#{b+c}d///'                : 'RegExp("a"+(b+c)+"d")'
      '///a#{b+c}d#{e+f}g///'         : 'RegExp("a"+(b+c)+"d"+(e+f)+"g")'
      '///a#{b+c}d#{e+f}g#{h+i}j///'  : 'RegExp("a"+(b+c)+"d"+(e+f)+"g"+(h+i)+"j")'
      '///a{} #{b+c} {} #d///'        : 'RegExp("a{}"+(b+c)+"{}")'
      '///a{ #{b+c} } # #{d} } #d///' : 'RegExp("a{"+(b+c)+"}"+(d)+"}")'
      '///a\\#{#{b}c///'              : 'RegExp("a\\#{"+(b)+"c")'
      '///a\\#{a}#{b}c///'            : 'RegExp("a\\#{a}"+(b)+"c")'
      '///#{}///'                     : 'RegExp("")'  # this is invalid IcedCoffeeScript
      '///a#{}///'                    : 'RegExp("a")'
      '///#{}b///'                    : 'RegExp("b")'
      '///a#{}b///'                   : 'RegExp("ab")'
      '///#{}#{}///'                  : 'RegExp("")'  # this is invalid IcedCoffeeScript
      '///#{}#{}#{}///'               : 'RegExp("")'  # this is invalid IcedCoffeeScript
      '///#{}#{}#{}#{}///'            : 'RegExp("")'  # this is invalid IcedCoffeeScript
      '///a#{}#{}///'                 : 'RegExp("a")'
      '///#{1}#{}///'                 : 'RegExp(""+(1))'
      '///#{}b#{}///'                 : 'RegExp("b")'
      '///#{}#{2}///'                 : 'RegExp(""+(2))'
      '///#{}#{}c///'                 : 'RegExp("c")'
      '///a#{1}#{}///'                : 'RegExp("a"+(1))'
      '///a#{}b#{}///'                : 'RegExp("ab")'
      '///a#{}#{2}///'                : 'RegExp("a"+(2))'
      '///a#{}#{}c///'                : 'RegExp("ac")'
      '///#{1}b#{}///'                : 'RegExp(""+(1)+"b")'
      '///#{1}#{2}///'                : 'RegExp(""+(1)+(2))'
      '///#{1}#{}c///'                : 'RegExp(""+(1)+"c")'
      '///#{1}#{2}c///'               : 'RegExp(""+(1)+(2)+"c")'
      '///#{1}b#{}c///'               : 'RegExp(""+(1)+"bc")'
      '///a#{1}b#{}c///'              : 'RegExp("a"+(1)+"bc")'
      '///a#{}b#{}c///'               : 'RegExp("abc")'
      '///#{2+2}#{3-8}///'            : 'RegExp(""+(2+2)+(3-8))'
      '///a#{-8}///'                  : 'RegExp("a"+(-8))'
      '///#{[]}///'                   : 'RegExp(""+([]))'
    for k, v of kv
      do (k, v)->
        it "#{k} -> #{v}", ()->
          assert.equal full(k), v
    
  describe "regexp invalid", ()->
    sample_list = '''
      /// ////
      /// /// ///
      ///a#{{}}///
    '''.split '\n'
    # Note that "#{{}}" is valid IcedCoffeeScript (though "#{{{}}}" isn't)
    for sample in sample_list
      do (sample)->
        it "#{sample} throws", ()->
          util.throws ()->
            full(sample)
  
  
  describe "hash", ()->
    kv =
      "{a}"     : "{a:a}"
      "a:1"     : "{a:1}"
      "a:1,b:1"     : "{a:1,b:1}"
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
  
  describe "access", ()->
    kv =
      "a.b"        : "a.b"
      "a[b]"       : "a[b]"
      "a.0"        : "a[0]"
      "a.1"        : "a[1]"
      "a.01"       : "[a[0],a[1]]"
      "a.12"       : "[a[1],a[2]]"
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
      "(a,b=(1))->" : """
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
      
      """
      ->
        a=1
        b=a
      """       : """
        (function(){
          (a=1)
          (b=a)
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
      while a
        b
      """       : """
        while(a) {
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
  
  # TEMP impl tests
  describe "pipeline", ()->
    kv =
      """
      [1] | a
      """       : """
        a = [1]
        """
      """
      fn = ()->
      [1] | fn
      """       : """
        (fn=(function(){}))
        ([1]).map(fn)
        """
      """
      fn = ()->
      ([1]) | fn
      """       : """
        (fn=(function(){}))
        ([1]).map(fn)
        """
      """
      fn = ()->
      [1] | fn | b
      """       : """
        (fn=(function(){}))
        b = ([1]).map(fn)
        """
      """
      b = []
      fn = ()->
      [1] | fn | b
      """       : """
        (b=[])
        (fn=(function(){}))
        b = ([1]).map(fn)
        """
      
    for k,v of kv
      do (k,v)->
        it JSON.stringify(k), ()->
          assert.equal full(k), v
    sample_list =
      """
      1 | a
      ---
      a = 1
      [1] | a
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
    await go '1 or true', {}, defer(err, res)
    assert err?
    await go '1a1', {}, defer(err, res)
    assert err?
    
    # LATER not translated
    # await go '1+"1"', {}, defer(err, res)
    # assert err?
    await go '__test_untranslated', {}, defer(err, res)
    assert err?
    done()