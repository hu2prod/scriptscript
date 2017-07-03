require "fy"
fs = require 'fs'
chipro = require 'child_process'
assert = require "assert"

sscript   = "../bin/scriptscript"
sample1   = "2 + 2"
compiled1 = "(2+2)"
output1   = ""
res1      = "4"
sample2   = "console.log(///ab+c///)"
compiled2 = "(console.log)(/ab+c/)"
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
  
  it "without options executes files sequentially", (done)->
    await chipro.exec "#{sscript} *.ss", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, output1 + output2
    done err
  
  it "*.ss -e", (done)->
    await chipro.exec "#{sscript} *.ss -e", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, output1 + output2
    done err
  
  it "*.ss -c", (done)->
    await chipro.exec "#{sscript} *.ss -c", defer err, stdout, stderr
    # p stdout
    done err if err
    await
      fs.readFile "1.js", "utf8", defer err1, contents1
      fs.readFile "2.js", "utf8", defer err2, contents2
    done err1 if err1
    done err2 if err2
    assert.equal contents1, compiled1
    assert.equal contents2, compiled2
    done()
  
  it "*.ss -co output", (done)->
    await chipro.exec "#{sscript} *.ss -co output", defer err, stdout, stderr
    # p stdout
    done err if err
    await
      fs.readFile "output/1.js", "utf8", defer err1, contents1
      fs.readFile "output/2.js", "utf8", defer err2, contents2
    done err1 if err1
    done err2 if err2
    assert.equal contents1, compiled1
    assert.equal contents2, compiled2
    done()
  
  it "*.ss -p", (done)->
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
  
  it "FIXME cat *.ss | s-s -s" # need semicolon after (2+2)
  
  it "cat 2.ss | s-s -se", (done)->
    await chipro.exec "cat 2.ss | #{sscript} -se", defer err, stdout, stderr
    p stdout
    assert.equal stdout, output2
    done err
  
  it "s-s -i '#{sample2}'", (done)->
    await chipro.exec "#{sscript} -i '#{sample2}'", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, compiled2
    done err
  
  it "s-s -i '#{sample2}' -p", (done)->
    await chipro.exec "#{sscript} -i '#{sample2}' -p", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, compiled2
    done err
  
  it "s-s -e '#{sample2}'", (done)->
    await chipro.exec "#{sscript} -e '#{sample2}'", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, output2
    done err
  
  # it "compiles to a file", (done)->
  #   await chipro.exec "#{sscript} -c in.ss", defer err, stdout, stderr
  #   # p stdout
  #   out = fs.readFileSync "in.js", "utf8"
  #   assert.equal out, compiled
  #   done err
  
  # it "-e - exec", (done)->
  #   await chipro.exec "#{sscript} -e '#{sample}'", defer err, stdout, stderr
  #   # p stdout
  #   assert.equal stdout, output
  #   done err
  
  # it "compiles to a file", (done)->
  #   await chipro.exec "#{ss} -c in.ss -O out.js", defer err, stdout, stderr
  #   # p stdout
  #   out = fs.readFileSync "out.js", "utf8"
  #   assert.equal out, "/ab+c/"
  #   done err
  
  # it "compiles to a file", (done)->
  #   await chipro.exec "#{ss} -c in.ss -O out.js", defer err, stdout, stderr
  #   # p stdout
  #   out = fs.readFileSync "out.js", "utf8"
  #   assert.equal out, "/ab+c/"
  #   done err
  
