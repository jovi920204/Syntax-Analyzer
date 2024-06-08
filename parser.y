%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "type.h"
extern int yylex();
extern char* yytext;
void yyerror(const char *s);

%}


%union {
    int ival;
    float fval;
    char *sval;
};

%token <sval> FUN MAIN VAR VAL INT REAL PRINT IDENTIFIER STRING_LITERAL
%token <fval> NUMBER
%token MULTIPLY

%type <sval> program function block declarations declaration type statements statement expression term

/* %token T_INT */
/* 先乘除後加減，且定義由左到右運算 */
%left '+' '-'
%left '*' '/'

%%
program:
    function
    ;

function:
    FUN MAIN '(' ')' '{'
        block
    '}'
    {
        printf("#include <stdio.h>\n");
        printf("int main() {\n");
        printf("%s", $6);
        printf("}\n");
    }
    ;

block:
    declarations statements
    {
        $$ = malloc(strlen($1) + strlen($2) + 1);
        strcpy($$, $1);
        strcat($$, $2);
    }
    ;

declarations:
    /* empty */ { ; }
    |
    declaration declarations
    {
        // printf("declarations\n");
        $$ = strdup($1);
    }
    ;

declaration:
    VAR IDENTIFIER ':' type '=' expression ';'
    {
        // printf("declaration1\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s = %s;\n", $4, $2, $6);
        $$ = strdup(buffer);
    }
    |
    VAR IDENTIFIER ':' type ';'
    {
        // printf("declaration2\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s;\n", $4, $2);
        $$ = strdup(buffer);
    }
    ;

type:
    INT 
    { 
        // printf("type int\n");
        $$ = strdup("int"); 
    }
    |
    REAL
    {
        // printf("type real\n");
        $$ = strdup("double"); 
    }
    ;

statements:
    /* empty */ { $$ = strdup(""); }
    |
    statement statements
    {
        $$ = malloc(strlen($1) + strlen($2) + 1);
        strcpy($$, $1);
        strcat($$, $2);
    }
    ;

statement:
    IDENTIFIER '=' expression ';'
    {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s = %s;\n", $1, $3);
        $$ = strdup(buffer);
    }
    |
    PRINT '(' expression ')' ';'
    {
        // printf( expression );
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    printf(\"%%d\\n\", %s);\n", $3);
        $$ = strdup(buffer);
    }
    |
    PRINT '(' STRING_LITERAL ')' ';'
    {

    }
    ;

expression:
    term
    /* |
    expression MULTIPLY term
    {

    } */
    ;

term:
    IDENTIFIER
    {
        $$ = strdup($1);
    }
    |
    NUMBER { 
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%f", $1);
        $$ = strdup(buffer);
    }
    ;
%%

int main() {
    return yyparse();
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
