**module under construction**
# scriptscript
### Install

    npm i [-g] hu2prod/scriptscript

The global install adds these commands (which are mutual aliases) to your shell:

    s-s
    sscript
    s10t

### Usage

    s-s                         start REPL
    s-s -i                      start REPL
    s-s -d                      start REPL in debug mode (with full stack traces)
    s-s *.ss                    exec files sequentially
    s-s *.ss -e                 exec files sequentially
    s-s *.ss -c                 compile files to the same folder
    s-s *.ss -co output         compile files and put to the "output" folder
    s-s *.ss -p                 compile and print out results to stdout

    s-s -s                      read stdin and write compiled JavaScript to stdout
    s-s -sp                     read stdin and write compiled JavaScript to stdout
    s-s -se                     read stdin and exec

    s-s -i "some_code()"        compile argument and print compiled JavaScript
    s-s -i "some_code()" -p     compile argument and print compiled JavaScript
    s-s -e "some_code()"        eval argument

### REPL

    > 2+2
    4
    > :c 2+2
    '(2+2)'
    > 2++
    ReferenceError: Invalid left-hand side expression in postfix operation
        at try_eval (/usr/lib/node_modules/scriptscript/lib/scriptscript.js:52:14)
        <You can see full stack trace in debug mode (-d option or :d in the REPL)>
    > :d 2++
    ReferenceError: Invalid left-hand side expression in postfix operation
      <FULL STACK TRACE GOES HERE>
    > p("Hello world!")         # all globals from 'fy' are available
    Hello world!
    undefined

### Options

Short | Long | Description
----- | ---- | -----------
-s | --stdin | read stdin; -p is assumed unless -e provided
-p | --print | print out compiled JavaScript to stdout
-c | --compile | compile files to the same folder, extension is replaced with '.js'
-o | --output | compile files to the specified folder; -c is required
-i | --input | compile argument and print compiled JavaScript; -p assumed unless -e provided; start a REPL if no argument provided
-e | --exec | eval compiled code
-d | --debug | debug mode (print out full stack traces and some additional information)

### Test

    npm i                       # ensure you have all dev dependencies
    npm test                    # also passes results to coveralls
    npm run test-simple         # no pass to coveralls
    npm run test-watch          # no report generating, just watch that all is ok
    npm run test-grep <pattern> # run selected test sections only; a grep pattern is required
    time npm run test-perf      # show test execution time without instrumentation

### Test lifehacks

    npm run test-watch -- --grep tok    # tokenizer only
    npm run test-watch -- --grep gram   # grammar only
    npm run test-watch -- --grep infer  # type inference only
    npm run test-watch -- --grep trans  # translator only
