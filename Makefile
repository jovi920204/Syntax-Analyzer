# Compiler and flags
CC = gcc
CFLAGS = -ll

# Bison and Flex files
BISON_FILE = parser.y
FLEX_FILE = scanner.l

# Generated files
BISON_C_FILE = y.tab.c
BISON_H_FILE = y.tab.h
FLEX_C_FILE = lex.yy.c

# Output executable
OUTPUT = syntax_analyzer

# Test input file
TEST_INPUT ?= test_input.txt

# Test C file
TEST_C_FILE = checkResult.c
TEST_C_OUTPUT = checkResult

.PHONY: all clean test

all: $(OUTPUT)

$(OUTPUT): $(FLEX_C_FILE) $(BISON_C_FILE)
	$(CC) -o $@ $^ $(CFLAGS)

$(BISON_C_FILE) $(BISON_H_FILE): $(BISON_FILE)
	yacc -d $(BISON_FILE)

$(FLEX_C_FILE): $(FLEX_FILE)
	lex $(FLEX_FILE)

test: $(BISON_C_FILE) $(FLEX_C_FILE) $(OUTPUT)
	./$(OUTPUT) < $(TEST_INPUT)

testC: $(TEST_C_FILE)
	$(CC) -o $(TEST_C_OUTPUT) $(TEST_C_FILE)
	./$(TEST_C_OUTPUT)

clean:
	rm -f $(OUTPUT) $(BISON_C_FILE) $(BISON_H_FILE) $(FLEX_C_FILE)
