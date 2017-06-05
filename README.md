**module under construction**
# scriptscript
install

    npm i hu2prod/scriptscript

test

    npm i                       # ensure you have all dev dependencies
    npm test                    # also passes results to coveralls
    npm run test-simple         # no pass to coveralls
    npm run test-watch          # no report generating, just watch that all is ok
    npm run test-grep <pattern> # run selected test sections only; a grep pattern is required

test lifehacks

    npm run test-watch -- --grep tok    # tokenizer only
    npm run test-watch -- --grep gram   # grammar only
    npm run test-watch -- --grep infer  # type inference only
    npm run test-watch -- --grep trans  # translator only
