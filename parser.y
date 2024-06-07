%{
#include <stdio.h>
#include <stdlib.h>
#include "type.h"
extern int yylex();
extern char* yytext;
void yyerror(const char *s);

// c file

%}
%union {
    int integer;
    double real;
    char string[200];
    char character;
    int boolean;
};


%token <string> VAR TYPE
%token <integer> T_INT RESERVED NUMBER
/* %token T_INT */
/* 先乘除後加減，且定義由左到右運算 */
%left '+' '-'
%left '*' '/'

%%
prog:
    RESERVED VAR '(' ')' '{' {  }
        stmts
    '}'
    ;

stmts:
    /* empty string */
    | stmt ';' stmts
    ;

stmt:
    declaration
    ;


declaration:
    RESERVED VAR ':' TYPE { printf("%s : %s\n", $2, $4); }
    | RESERVED VAR ':' TYPE '=' T_INT { printf("%s : %s = %d\n", $2, $4, $6); }
    ; 

%%

int main() {
    return yyparse();
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
