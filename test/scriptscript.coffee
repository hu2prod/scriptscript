require "fy"
fs = require 'fs'
chipro = require 'child_process'
assert = require "assert"

sscript   = "../bin/scriptscript"
sample1   = "2 + 2"
sample2   = "console.log(///ab+c///)"
compiled1 = "(2+2)"
compiled2 = "(console.log)(/ab+c/)"
output1   = ""
output2   = "/ab+c/\n"
res1      = "4"
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
  
  after -> 
    process.chdir ".."
    await chipro.exec "rm -rf tmp", defer err, stdout, stderr
    throw err if err
    # p stdout
  
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
  
  # it "compiles to stdout", (done)->
  #   await chipro.exec "#{sscript} -p sample.ss", defer err, stdout, stderr
  #   # p stdout
  #   assert.equal stdout, compiled + '\n'
  #   done err
  
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
  
