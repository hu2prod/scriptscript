assert = require 'assert'
util = require 'fy/test_util'

{_tokenize} = require '../tokenizer.coffee'
{_parse   } = require '../grammar.coffee'
full = (t)->
  tok = _tokenize(t)
  _parse(tok, mode_full:true)

describe 'gram section', ()->
  # fuckups
  ###
  a /= b / c
  ###
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
    a?
    a = b
    a += b
    a -= b
    a *= b
    a /= b
    a %= b
    a **= b
    a //= b
    a %%= b
    a <<= b
    a >>= b
    a >>>= b
    a ?= b
    a[b]
    a.b
    a.0
    a .0
    a.rgb
    a.0123
    a .0123
    1
    1.1
    1.
    1e1
    1e+1
    1e-1
    -1e-1
    a()
    a(b)
    a(b,c)
    a(b,c=d)
    # a
    @
    @a
    @.a
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
    + a
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
  
  describe 'macro-block section', ()->
    describe 'array section', ()->
      sample_list = """
        loop
          a
        ---
        if a
          b
      """.split /\n?---\n?/g
      for sample in sample_list
        continue if !sample
        do (sample)->
          it JSON.stringify(sample), ()->
            full sample
  
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
  ###
  string not defined yet
      ---
      {\"a\":b}
      ---
      {'a':b}
  ###
  describe 'hash section', ()->
    sample_list = """
      {}
      ---
      { }
      ---
      {a}
      ---
      {a:b}
      ---
      {1:b}
      ---
      {a,b}
      ---
      {a:1,b:2}
      ---
      {a:1,b}
      ---
      {a,b,c}
      ---
      {
      }
      ---
      {
      
      }
      ---
      {
      
      
      }
      ---
      {
      a
      }
      ---
      {
        a
      }
      ---
      {
        a : b
      }
      ---
      {
        (a) : b
      }
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
      a|b
      ---
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
  
  describe 'function decl section', ()->
    sample_list = """
      ->
      ---
      =>
      ---
      ()->
      ---
      ()->a
      ---
      (a)->a
      ---
      (a,b)->a
      ---
      (a,b=c)->a
      ---
      (a:int)->a
      ---
      (a:int):int->a
      ---
      (a:int):int=>a
      ---
      ()->
        a
      ---
      ()->
        a
        b
    """.split /\n?---\n?/g
    for sample in sample_list
      continue if !sample
      do (sample)->
        it JSON.stringify(sample), ()->
          full sample
  
describe "Gram TODO: all exapmles from coffeescript documentation (oneliners only) should be tokenizable and parsable", ()->
  # check only if it doesn't throw
  
  describe "Overview", ()->
    sample_list = """
      number = 42
      opposite = true
      number = -42 if opposite
      square = (x) -> x * x
      list = [1, 2, 3, 4, 5]
      race = (winner, runners...) -> print winner, runners
      alert "I knew it!" if elvis?
      cubes = (math.cube num for num in list)
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Functions", ()->
    sample_list = """
      square = (x) -> x * x
      cube = (x) -> square(x) * x
      fill = (container, liquid = "coffee") -> "Filling the \#{container} with \#{liquid}..."
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Objects and Arrays", ()->
    sample_list = """
      song = ["do", "re", "mi", "fa", "so"]
      singers = {Jagger: "Rock", Elvis: "Roll"}
      $('.account').attr class: 'active'
      log object.class
      turtle = {name, mask, weapon}
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "If, Else, Unless, and Conditional Assignment", ()->
    sample_list = """
      mood = greatlyImproved if singing
      date = if friday then sue else jill
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Splats…", ()->
    sample_list = """
      awardMedals contenders...
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Loops and Comprehensions", ()->
    sample_list = """
      eat food for food in ['toast', 'cheese', 'wine']
      courses = ['greens', 'caviar', 'truffles', 'roast', 'cake']
      menu i + 1, dish for dish, i in courses
      foods = ['broccoli', 'spinach', 'chocolate']
      eat food for food in foods when food isnt 'chocolate'
      shortNames = (name for name in list when name.length < 5)
      countdown = (num for num in [10..1])
      evens = (x for x in [0..10] by 2)
      browser.closeCurrentTab() for [0...count]
      yearsOld = max: 10, ida: 9, tim: 11
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Array Slicing and Splicing with Ranges", ()->
    sample_list = """
      numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]
      start   = numbers[0..2]
      middle  = numbers[3...-2]
      end     = numbers[-2..]
      copy    = numbers[..]
      numbers[3..6] = [-3, -4, -5, -6]
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Everything is an Expression (at least, as much as possible)", ()->
    sample_list = """
      eldest = if 24 > 21 then "Liz" else "Ike"
      six = (one = 1) + (two = 2) + (three = 3)
      globals = (name for name of window)[0...10]
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Operators and Aliases", ()->
    sample_list = """
      -7 % 5 == -2 # The remainder of 7 / 5
      -7 %% 5 == 3 # n %% 5 is always between 0 and 4
      tabs.selectTabAtIndex((tabs.currentIndex - count) %% tabs.length)
      launch() if ignition is on
      volume = 10 if band isnt SpinalTap
      letTheWildRumpusBegin() unless answer is no
      if car.speed < limit then accelerate()
      winner = yes if pick in [47, 92, 13]
      print inspect "My name is \#{@name}"
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "The Existential Operator", ()->
    sample_list = """
      solipsism = true if mind? and not world?
      speed = 0
      speed ?= 15
      footprints = yeti ? "bear"
      zip = lottery.drawWinner?().address?.zipcode
    """.split /\n/ #"
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Classes, Inheritance, and Super", ()->
    sample_list = """
      sam = new Snake "Sammy the Python"
      tom = new Horse "Tommy the Palomino"
      sam.move()
      tom.move()
      String::dasherize = -> this.replace /_/g, "-"
    """.split /\n/ #"
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Destructuring Assignment", ()->
    sample_list = """
      [theBait, theSwitch] = [theSwitch, theBait]
      weatherReport = (location) -> [location, 72, "Mostly Sunny"]
      [city, temp, forecast] = weatherReport "Berkeley, CA"
      {sculptor} = futurists
      {poet: {name, address: [street, city]}} = futurists
      [open, contents..., close] = tag.split("")
      [first, ..., last] = text.split " "
      {@name, @age, @height = 'average'} = options
      tim = new Person name: 'Tim', age: 4
    """.split /\n/ #"
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  # describe "Bound Functions, Generator Functions", ()->
  
  describe "Embedded JavaScript", ()->
    sample_list = """
      hi = `function() {return [document.title, "Hello JavaScript"].join(": ");}`
      markdown = `function () {return \\`In Markdown, write code like \\\\\\`this\\\\\\`\\`;}`
      ```function time() {return `The time is ${new Date().toLocaleTimeString()}`;}```
    """.split /\n/ #"
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  # describe "Switch/When/Else", ()->
  
  # describe "Try/Catch/Finally", ()->
  
  describe "Chained Comparisons", ()->
    sample_list = """
      healthy = 200 > cholesterol > 60
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "String Interpolation, Block Strings, and Block Comments", ()->
    sample_list = """
      quote  = "A picture is a fact. -- \#{ author }"
      sentence = "\#{ 22 / 7 } is a decent approximation of π"
    """.split /\n/ #"
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  describe "Tagged Template Literals", ()->
    sample_list = """
      upperCaseExpr = (textParts, expressions...) -> textParts.reduce (text, textPart, i) -> text + expressions[i - 1].toUpperCase() + textPart
      greet = (name, adjective) -> upperCaseExpr\"""Hi \#{name}. You look \#{adjective}!\"""
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
  
  # describe "Block Regular Expressions", ()->
  
  describe "Modules", ()->
    sample_list = """
      import 'local-file.coffee'
      import 'coffee-script'
      import _ from 'underscore'
      import * as underscore from 'underscore'
      import { now } from 'underscore'
      import { now as currentTimestamp } from 'underscore'
      import { first, last } from 'underscore'
      import utilityBelt, { each } from 'underscore'
      export default Math
      export square = (x) -> x * x
      export { sqrt }
      export { sqrt as squareRoot }
      export { Mathematics as default, sqrt as squareRoot }
      export * from 'underscore'
      export { max, min } from 'underscore'
    """.split /\n/
    for sample in sample_list
      do (sample)->
        it sample
        # it sample, ()->
        #   full sample
