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
sample3   = "2++"
compiled3 = "(2++)"
err3      = "ReferenceError: Invalid left-hand side expression in postfix operation"
sample4   = "++2"
compiled4 = "(++2)"
err4      = "Error: Parsing error. No proper combination found"
sample5   = "p(input)"
compiled5 = "(p)(input)"
err5      = "ReferenceError: input is not defined"
err_bottom= "    <You can see full stack trace in debug mode (-d option or :d in the REPL)>"


describe "public cli", ->
  this.timeout 5000
  this.slow 1200
  before (done)->
    await chipro.exec """
      mkdir -p tmp
      cd tmp || exit 1
      echo '#{sample1}' > 1.ss
      echo '#{sample2}' > 2.ss
      echo '#{sample3}' > 3.ss
      echo '#{sample4}' > 4.ss
      echo '#{sample5}' > 5.ss
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
  
  # ###################################################################################################
  #    REPL
  # ###################################################################################################
  
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
        lines = stderr.split '\n'
        assert.equal lines[0], "ReferenceError: a is not defined"
        assert.equal lines[3], "ReferenceError: input is not defined"
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
          > #{compiled1}
          > #{compiled2}
          > 
          """
        done()
    
    it ":c a | (t)->t | b compiles to multiline", (done)->
      child = chipro.spawn sscript
      output = ""
      child.stdout.on "data", (data)->
        output += data.toString()
      child.stdin.end ":c a | (t)->t | b\n"
      child.on "close", (code)->
        # p output
        assert.equal output, """
          > (a).map((function(t){
            return(b = t)
          }))
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
    
    it "2++ prints just the first entry of stack trace", (done)->
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
        lines = stderr.split '\n'
        assert.equal lines[0],     "ReferenceError: Invalid left-hand side expression in postfix operation"
        assert lines[1].startsWith "    at "
        assert.equal lines[2],     "    <You can see full stack trace in debug mode (-d option or :d in the REPL)>"
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
    
    it ":c #{sample4} prints short error message (first entry of stack trace)", (done)->
      child = chipro.spawn sscript
      stdout = stderr = ""
      child.stdout.on "data", (data)->
        stdout += data.toString()
      child.stderr.on "data", (data)->
        stderr += data.toString()
      child.stdin.end ":c #{sample4}\n"
      child.on "close", (code)->
        # p stdout
        # p stderr
        lines = stderr.split '\n'
        assert.equal lines[0],     err4
        assert lines[1].startsWith "    at "
        assert.equal lines[2],     err_bottom
        assert.equal lines.length, 4
        done()
  
  # ###################################################################################################
  #    Normal work
  # ###################################################################################################
  
  describe "normal work", ->
    it "s-s [12].ss", (done)->
      await chipro.exec "#{sscript} [12].ss", defer err, stdout, stderr
      # p stdout
      assert.equal stdout, output1 + output2
      done err
    
    it "s-s [12].ss -e", (done)->
      await chipro.exec "#{sscript} [12].ss -e", defer err, stdout, stderr
      # p stdout
      assert.equal stdout, output1 + output2
      done err
    
    it "s-s [12].ss -c", (done)->
      await chipro.exec "#{sscript} [12].ss -c", defer err, stdout, stderr
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
    
    it "s-s -c [12].ss -o output", (done)->
      await chipro.exec "#{sscript} -c [12].ss -o output", defer err, stdout, stderr
      # p stdout
      return done err if err
      await
        fs.readFile "output/1.js", "utf8", defer error1, contents1
        fs.readFile "output/2.js", "utf8", defer error2, contents2
      return done error1 if error1
      return done error2 if error2
      assert.equal contents1, compiled1
      assert.equal contents2, compiled2
      done()
    
    it "s-s [12].ss -p", (done)->
      await chipro.exec "#{sscript} [12].ss -p", defer err, stdout, stderr
      # p stdout
      assert.equal stdout, compiled1 + '\n' + compiled2 + '\n'
      done err
    
    it "cat [12].ss | s-s -s", (done)->
      await chipro.exec "cat [12].ss | #{sscript} -s", defer err, stdout, stderr
      # p stdout
      assert.equal stdout, compiled1 + ';\n' + compiled2 + '\n'
      done err
    
    it "cat [12].ss | s-s -sp", (done)->
      await chipro.exec "cat [12].ss | #{sscript} -sp", defer err, stdout, stderr
      # p stdout
      assert.equal stdout, compiled1 + ';\n' + compiled2 + '\n'
      done err
    
    it "cat [12].ss | s-s -se", (done)->
      await chipro.exec "cat [12].ss | #{sscript} -se", defer err, stdout, stderr
      # p stdout
      assert.equal stdout, output1 + output2
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
  
  # ###################################################################################################
  #    Errors
  # ###################################################################################################

  describe "errors", ->
    it "s-s 3.ss              # short message, evaluation error", (done)->
      await chipro.exec "#{sscript} 3.ss", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], "3.ss: #{err3}"
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err
    
    it "s-s 3.ss -d           # long message (full stack trace)", (done)->
      await chipro.exec "#{sscript} 3.ss -d", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], "3.ss: #{err3}"
      for line in lines[1...-1]
        assert line.startsWith "    at "
      assert lines.length > 5
      done err
    
    it "s-s *.ss              # messages from all files are shown; files without errors are executed anyway", (done)->
      await chipro.exec "#{sscript} *.ss", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], "3.ss: #{err3}"
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines[3], "4.ss: #{err4}"
      assert       lines[4].startsWith "    at "
      assert.equal lines[5], err_bottom
      assert.equal lines[6], "5.ss: #{err5}"
      assert       lines[7].startsWith "    at "
      assert.equal lines[8], err_bottom
      assert.equal lines.length, 10
      assert.equal stdout, output1 + output2
      done err
    
    it "s-s 4.ss -c           # compilation error, short message", (done)->
      await chipro.exec "#{sscript} 4.ss -c", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], "4.ss: #{err4}"
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err
    
    it "s-s -c 4.ss -o output # the same", (done)->
      await chipro.exec "#{sscript} -c 4.ss -o output", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], "4.ss: #{err4}"
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err
    
    it "s-s *.ss -c           # all files are compiled except those with errors; short error messages are shown", (done)->
      await chipro.exec "#{sscript} *.ss -c", defer err, stdout, stderr
      return done err if err
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], "4.ss: #{err4}"
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      await
        fs.readFile "1.js", "utf8", defer error1, contents1
        fs.readFile "2.js", "utf8", defer error2, contents2
        fs.readFile "3.js", "utf8", defer error3, contents3
        fs.readFile "5.js", "utf8", defer error5, contents5
      return done error1 if error1
      return done error2 if error2
      return done error3 if error3
      return done error5 if error5
      assert.equal contents1, compiled1
      assert.equal contents2, compiled2
      assert.equal contents3, compiled3
      assert.equal contents5, compiled5
      done()
    
    it "s-s *.ss -p           # the same", (done)->
      await chipro.exec "#{sscript} *.ss -p", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], "4.ss: #{err4}"
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      assert.equal stdout, compiled1 + '\n' + compiled2 + '\n' + compiled3 + '\n' + compiled5 + '\n'
      done err
    
    it "cat 4.ss | s-s -s     # compilation error", (done)->
      await chipro.exec "cat 4.ss | #{sscript} -s", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], err4
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err
    
    it "s-s -e '#{sample3}'   # evaluation error", (done)->
      await chipro.exec "#{sscript} -e '#{sample3}'", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], err3
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err
    
    it "cat 3.ss | s-s -se    # evaluation error", (done)->
      await chipro.exec "cat 3.ss | #{sscript} -se", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], err3
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err
  
  # ###################################################################################################
  #    Local scope is not exposed
  # ###################################################################################################
  
  describe "local scope is not exposed", ->
    it "s-s 5.ss", (done)->
      await chipro.exec "#{sscript} 5.ss", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], "5.ss: #{err5}"
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err
    
    it "s-s -e '#{sample5}'", (done)->
      await chipro.exec "#{sscript} -e '#{sample5}'", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], err5
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err

    it "cat 5.ss | s-s -se", (done)->
      await chipro.exec "cat 5.ss | #{sscript} -se", defer err, stdout, stderr
      # p stderr
      lines = stderr.split '\n'
      assert.equal lines[0], err5
      assert       lines[1].startsWith "    at "
      assert.equal lines[2], err_bottom
      assert.equal lines.length, 4
      done err
