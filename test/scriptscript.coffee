require "fy"
fs = require 'fs'
chipro = require 'child_process'
assert = require "assert"

ss = "../bin/scriptscript"

describe "cli", ->
  this.timeout 10000
  before (done)-> 
    await chipro.exec """
      mkdir -p tmp
      cd tmp || exit 1
      echo "///ab+c///" > in.ss
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
  
  it "without arguments prints usage information", (done)->
    await chipro.exec "#{ss}", defer err, stdout, stderr
    # p stderr
    assert stderr.includes "Usage"
    done()
  
  it "compiles to stdout", (done)->
    await chipro.exec "#{ss} -c sample.ss", defer err, stdout, stderr
    # p stdout
    assert.equal stdout, "/ab+c/"
    done err
  
  it "compiles to a file", (done)->
    await chipro.exec "#{ss} -c in.ss -O out.js", defer err, stdout, stderr
    # p stdout
    out = fs.readFileSync "out.js", "utf8"
    assert.equal out, "/ab+c/"
    done err
  
