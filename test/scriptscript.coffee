require "fy"
fs = require 'fs'
chipro = require 'child_process'
assert = require "assert"

sscript   = "../bin/scriptscript"
sample1   = "2 + 2"
compiled1 = "(2+2)"
output1   = ""
res1      = "4"
sample2   = "p(///ab+c///)"
compiled2 = "(p)(/ab+c/)"
output2   = "/ab+c/\n"
res2      = "undefined"

describe "public cli", ->
  this.timeout 5000
  before (done)->
    await chipro.exec """
      mkdir -p tmp
      cd tmp || exit 1
      echo '#{sample1}' > 1.ss
      echo '#{sample2}' > 2.ss
    """, defer err, stdout, stderr
    throw err if err
    # p stdout
    process.chdir "tmp"
    done()
  
  after (done)->
    process.chdir ".."
    await chipro.exec "rm -rf tmp", defer err, stdout, stderr
    throw err if err
    # p stdout
    done()
  
  describe "repl", ->
    it "without arguments starts a REPL", (done)->
      child = chipro.spawn sscript
      output = ""
      child.stdout.on "data", (data)->
        output += data.toString()
      child.stdin.write sample1 + '\n'
      child.stdin.end   sample2 + '\n'
      child.on "close", (code)->
        # p output
        assert.equal output, """
          > #{output1}#{res1}
          > #{output2}#{res2}
          > 
          """
        done()
    
    it "s-s -i also starts a REPL", (done)->
      child = chipro.spawn sscript, ["-i"]
      output = ""
      child.stdout.on "data", (data)->
        output += data.toString()
      child.stdin.write sample1 + '\n'
      child.stdin.end   sample2 + '\n'
      child.on "close", (code)->
        # p output
        assert.equal output, """
          > #{output1}#{res1}
          > #{output2}#{res2}
          > 
          """
        done()
    
    it "local scope is not exposed to the repl", (done)->
      child = chipro.spawn sscript
      stdout = stderr = ""
      child.stdout.on "data", (data)->
        stdout += data.toString()
      child.stderr.on "data", (data)->
        stderr += data.toString()
      child.stdin.write "a\n"
      child.stdin.end "input\n"
      child.on "close", (code)->
        # p stdout
        # p stderr
        assert.equal stderr, """
          a is not defined
          input is not defined

          """
        done()
    
    it ":c 2+2 compiles code instead of evaluating", (done)->
      child = chipro.spawn sscript
      output = ""
      child.stdout.on "data", (data)->
        output += data.toString()
      child.stdin.write ":c #{sample1}\n"
      child.stdin.end   ":c #{sample2}\n"
      child.on "close", (code)->
        # p output
        assert.equal output, """
          > '#{compiled1}'
          > '#{compiled2}'
          > 
          """
        done()
    
    it ":d 2++ prints full stack trace", (done)->
      child = chipro.spawn sscript
      stdout = stderr = ""
      child.stdout.on "data", (data)->
        stdout += data.toString()
      child.stderr.on "data", (data)->
        stderr += data.toString()
      child.stdin.end   ":d 2++\n"
      child.on "close", (code)->
        # p stdout
        # p stderr
        assert stderr.startsWith "ReferenceError: Invalid left-hand side expression in postfix operation\n"
        assert.equal stderr.search(/\ +at .+:\d+:\d+/), 71  # first stack trace entry
        assert stderr.length > 500
        done()
    
    it "2++ prints just the error message", (done)->
      child = chipro.spawn sscript
      stdout = stderr = ""
      child.stdout.on "data", (data)->
        stdout += data.toString()
      child.stderr.on "data", (data)->
        stderr += data.toString()
      child.stdin.end   "2++\n"
      child.on "close", (code)->
        # p stdout
        # p stderr
        assert.equal stderr, "Invalid left-hand side expression in postfix operation\n"
        done()
  
    it "2++ prints full stack trace if -d option is used", (done)->
      child = chipro.spawn sscript, ["-d"]
      stdout = stderr = ""
      child.stdout.on "data", (data)->
        stdout += data.toString()
      child.stderr.on "data", (data)->
        stderr += data.toString()
      child.stdin.end   "2++\n"
      child.on "close", (code)->
        # p stdout
        # p stderr
        assert stderr.startsWith "ReferenceError: Invalid left-hand side expression in postfix operation\n"
        assert.equal stderr.search(/\ +at .+:\d+:\d+/), 71  # first stack trace entry
        assert stderr.length > 500
        done()
  
  
  it "s-s *.ss", (done)->
    await chipro.exec "#{sscript} *.ss", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, output1 + output2
    done err
  
  it "s-s *.ss -e", (done)->
    await chipro.exec "#{sscript} *.ss -e", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, output1 + output2
    done err
  
  it "s-s *.ss -c", (done)->
    await chipro.exec "#{sscript} *.ss -c", defer err, stdout, stderr
    # p stdout
    return done err if err
    await
      fs.readFile "1.js", "utf8", defer err1, contents1
      fs.readFile "2.js", "utf8", defer err2, contents2
    return done err1 if err1
    return done err2 if err2
    assert.equal contents1, compiled1
    assert.equal contents2, compiled2
    done()
  
  it "s-s *.ss -co output", (done)->
    await chipro.exec "#{sscript} *.ss -co output", defer err, stdout, stderr
    # p stdout
    return done err if err
    await
      fs.readFile "output/1.js", "utf8", defer err1, contents1
      fs.readFile "output/2.js", "utf8", defer err2, contents2
    return done err1 if err1
    return done err2 if err2
    assert.equal contents1, compiled1
    assert.equal contents2, compiled2
    done()
  
  it "s-s *.ss -p", (done)->
    await chipro.exec "#{sscript} *.ss -p", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, compiled1 + '\n' + compiled2 + '\n'
    done err
  
  it "cat *.ss | s-s -s", (done)->
    await chipro.exec "cat *.ss | #{sscript} -s", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, compiled1 + '\n' + compiled2 + '\n'
    done err
  
  it "cat *.ss | s-s -sp", (done)->
    await chipro.exec "cat *.ss | #{sscript} -sp", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, compiled1 + '\n' + compiled2 + '\n'
    done err
  
  it "FIXME cat *.ss | s-s -se" # need semicolon after (2+2)
  
  it "cat 2.ss | s-s -se", (done)->
    await chipro.exec "cat 2.ss | #{sscript} -se", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, output2
    done err
  
  it "s-s -i '#{sample2}'", (done)->
    await chipro.exec "#{sscript} -i '#{sample2}'", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, compiled2 + '\n'
    done err
  
  it "s-s -i '#{sample2}' -p", (done)->
    await chipro.exec "#{sscript} -i '#{sample2}' -p", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, compiled2 + '\n'
    done err
  
  it "s-s -e '#{sample2}'", (done)->
    await chipro.exec "#{sscript} -e '#{sample2}'", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, output2
    done err
