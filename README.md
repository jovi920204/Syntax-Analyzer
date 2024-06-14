# Makefile Usage
## Commands
- Compile Yacc and Lex without execution
```bash=
$ make all
```
- Compile Yacc and Lex and execute with testdata
```bash=
$ make test TEST_INPUT=<testdataPath>
```
- Compile C code and execute the program `resultCheck.c` (using gcc)
```bash=
$ make testC
```
- Delete `y.tab.c`, `y.tab.h`, `lex.yy.c`
```bash=
$ make clean
```

## Example Execution
- Compile and test `testdata/sample1.qv`
```bash=
$ make test TEST_INPUT=testdata/sample1.qv
```
