require "fy"
fs = require 'fs'
chipro = require 'child_process'
assert = require "assert"

sscript  = "../bin/scriptscript"
sample   = "console.log(///ab+c///)"
compiled = "(console.log)(/ab+c/)"
output   = "/ab+c/\n"

describe "cli", ->
  this.timeout 10000
  before (done)-> 
    await chipro.exec """
      mkdir -p tmp
      cd tmp || exit 1
      echo '#{sample}' > in.ss
      cp in.ss sample.ss
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
  
  it "without arguments starts a REPL"
  
  it "compiles to stdout", (done)->
    await chipro.exec "#{sscript} -p sample.ss", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, compiled + '\n'
    done err
  
  it "compiles to a file", (done)->
    await chipro.exec "#{sscript} -c in.ss", defer err, stdout, stderr
    # p stdout
    out = fs.readFileSync "in.js", "utf8"
    assert.equal out, compiled
    done err
  
  it "-e - exec", (done)->
    await chipro.exec "#{sscript} -e '#{sample}'", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, output
    done err
  
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
  
