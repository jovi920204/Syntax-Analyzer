yacc -d parser.y
lex scanner.l
cc lex.yy.c y.tab.c -o B11015030 
./B11015030 sample/sample1.qv