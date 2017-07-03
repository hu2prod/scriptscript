**module under construction**
# scriptscript
install

    npm i hu2prod/scriptscript

usage

    s-s                     start REPL
    s-s -i                  start REPL (bug/feature)
    s-s *.ss                exec files sequentially
    s-s *.ss -e             exec files sequentially
    s-s *.ss -c             compile files to the same folder
    s-s *.ss -co output     compile files and put to the "output" folder
    s-s *.ss -p             compile and print out results to stdout

    s-s -s                  read stdin and write compiled JavaScript to stdout
    s-s -sp                 read stdin and write compiled JavaScript to stdout
    s-s -se                 read stdin and exec

    s-s -i "some_code()"    compile argument and print compiled JavaScript
    s-s -i "some_code()" -p compile argument and print compiled JavaScript
    s-s -e "some_code()"    eval argument

test

    npm i                       # ensure you have all dev dependencies
    npm test                    # also passes results to coveralls
    npm run test-simple         # no pass to coveralls
    npm run test-watch          # no report generating, just watch that all is ok
    npm run test-grep <pattern> # run selected test sections only; a grep pattern is required
    time npm run test-perf      # show test execution time without instrumentation

test lifehacks

    npm run test-watch -- --grep tok    # tokenizer only
    npm run test-watch -- --grep gram   # grammar only
    npm run test-watch -- --grep infer  # type inference only
    npm run test-watch -- --grep trans  # translator only
