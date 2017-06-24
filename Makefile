SRC = $(wildcard src/*.coffee)
LIB = $(SRC:src/%.coffee=lib/%.js)

all: $(LIB)

lib/%.js: src/%.coffee
	iced -o lib -c $?
