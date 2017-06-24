SRC = $(wildcard src/*.coffee)
LIB = $(SRC:src/%.coffee=lib/%.js)

all: $(LIB)

lib/%.js: src/%.coffee
	iced -o lib -c $?


# all: lib/grammar.js lib/index.js lib/run.js lib/scriptscript.js lib/tokenizer.js lib/translator.js lib/type_inference.js

# lib/grammar.js: src/grammar.coffee
# 	iced -o lib -c $?
# lib/index.js: src/index.coffee
# 	iced -o lib -c $?
# lib/run.js: src/run.coffee
# 	iced -o lib -c $?
# lib/scriptscript.js: src/scriptscript.coffee
# 	iced -o lib -c $?
# lib/tokenizer.js: src/tokenizer.coffee
# 	iced -o lib -c $?
# lib/translator.js: src/translator.coffee
# 	iced -o lib -c $?
# lib/type_inference.js: src/type_inference.coffee
# 	iced -o lib -c $?
