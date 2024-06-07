%{
#include <stdio.h>
#include <stdlib.h>
extern int yylex();
extern char* yytext;
void yyerror(const char *s);

// c file

%}
%union {
  unsigned int integer;
  double real;
  char string[200];
  char character;
  int boolean;
};


%token RESERVED VAR NUMBER
%token TYPE
%token INT_CONST

%left '+' '-'

%type <string> VAR
%type <string> TYPE

%%
prog:
    stmts
    ;

stmts:
    RESERVED VAR '(' ')' '{' {  }
        stmts
    '}'
    | stmt
    ;

stmt:
    RESERVED VAR ':' TYPE ';' { printf("var = %s, type = %s\n", $2, $4); }
    | VAR '=' INT_CONST 
    ;
// input:
//     | input line
//     ;

// line:
//     '\n'
//     | exp '\n'   { printf("Result: %d\n", $1); }
//     ;

// exp:
//     NUMBER         { $$ = atoi(YYStext); }
//     | exp '+' exp  { $$ = $1 + $3; }
//     | exp '-' exp  { $$ = $1 - $3; }
//     ;

%%

int main() {
    return yyparse();
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
