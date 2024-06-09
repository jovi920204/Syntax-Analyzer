%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "type.h"
extern int yylex();
extern char* yytext;
void yyerror(const char *s);
void addSymbolTable(char* name, char* type);
char* searchType(char* name);

struct dataType{
    char *idName;
    char *type;
}symbolTable[40];
int symbolTableTop = 0;

%}


%union {
    int ival;
    float fval;
    char *sval;
    struct Node{
        char *sval;
        char *type;
    }node;
};

%token <sval> FUN MAIN VAR VAL INT REAL PRINT
%token <node> NUMBER IDENTIFIER STRING_LITERAL
%token MULTIPLY

%type <sval> program function block declarations declaration type statements statement
%type <node> expression term factor
/* %token T_INT */
/* 先乘除後加減，且定義由左到右運算 */
/* %left '+' '-'
%left '*' '/' */

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
        // printf("block - declarations statements\n");
        $$ = malloc(strlen($1) + strlen($2) + 1);
        strcpy($$, $1);
        strcat($$, $2);
    }
    ;

declarations:
    /* empty */
    {
        // printf("declarations - empty\n");
        $$ = strdup(""); 
    }
    |
    declaration declarations
    {
        // printf("declarations - declaration declarations\n");
        $$ = malloc(strlen($1) + strlen($2) + 1);
        strcpy($$, $1);
        strcat($$, $2);
    }
    ;

declaration:
    /* 	var area: real = radius + radius - pi; */
    VAR IDENTIFIER ':' type '=' expression ';'
    {
        // printf("declaration1 %s\n", $4);
        $2.type = strdup($4);
        // TODO: symbol table
        addSymbolTable($2.sval, $2.type);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s = %s;\n", $4, $2.sval, $6.sval);
        $$ = strdup(buffer);
    }
    |
    VAR IDENTIFIER ':' type ';'
    {
        // printf("declaration2\n");
        $2.type = strdup($4);
        // TODO: symbol table
        addSymbolTable($2.sval, $2.type);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s;\n", $4, $2.sval);
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
    /* empty */ 
    {
        // printf("statements - empty\n");
        $$ = strdup(""); 
    }
    |
    statement statements
    {
        // printf("statements - statement statements\n");
        $$ = malloc(strlen($1) + strlen($2) + 1);
        strcpy($$, $1);
        strcat($$, $2);
    }
    ;

statement:
    IDENTIFIER '=' expression ';'
    {
        // printf("statement - IDENTIFIER = expression ;\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s = %s;\n", $1.sval, $3.sval);
        // printf("statement ID = expr ;\n");
        $$ = strdup(buffer);
    }
    |
    PRINT '(' expression ')' ';'
    {
        // printf("statement - PRINT ( expression ) ;\n");
        char buffer[256];
        if (strcmp($3.type, "int") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%d\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "double") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%lf\", %s);\n", $3.sval);
        }
        else {
            // printf("PRINT string\n");
            snprintf(buffer, sizeof(buffer), "    printf(\"%s\");\n", $3.sval);
        }
        $$ = strdup(buffer);
    }
    ;

expression:
    term
    {
        // printf("expression term\n");
        $$ = (struct Node){$1.sval, $1.type};
    }
    |
    expression '+' term
    {  
        // TODO: maintain the coercion
        // printf("+\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s + %s", $1.sval, $3.sval);
        $$ = (struct Node){strdup(buffer), $1.type};
    }
    |
    expression '-' term
    {
        // TODO: maintain the coercion
        // printf("-\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s - %s", $1.sval, $3.sval);
        $$ = (struct Node){strdup(buffer), $1.type};
        // printf("buffer => %s, type => %s\n", buffer, $1.type);
    }
    ;

term:
    term '*' factor
    {
        // printf("*\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s * %s", $1.sval, $3.sval);
        $$ = (struct Node){strdup(buffer), $1.type};
    }
    |
    term '/' factor
    {
        // printf("/\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s / %s", $1.sval, $3.sval);
        $$ = (struct Node){strdup(buffer), $1.type};
    }
    |
    factor
    {
        // printf("term - factor\n");
        $$ = (struct Node){$1.sval, $1.type};
    }
    ;

factor:
    '(' expression ')'
    {
        // printf("factor ( expression )\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "( %s )", $2.sval);
        $$ = (struct Node){strdup(buffer), $2.type};
    }
    |
    IDENTIFIER
    {
        // printf("factor - IDENTIFIER\n");
        // printf("id => %s\n", $1.sval);
        $$ = (struct Node){$1.sval, searchType($1.sval)};
        // printf("done\n");
    }
    |
    NUMBER
    {
        // printf("factor - NUMBER\n");
        // printf("num => %s\n", $1.sval);
        // printf("type = %s\n", $1.type);
        $$ = (struct Node){$1.sval, $1.type};
    }
    |
    STRING_LITERAL
    {
        // printf("factor - STRING_LITERAL ;\n");
        // printf("string => %s\n", $1.sval);
        $$ = (struct Node){$1.sval, $1.type};
    }
    ;
%%

int main() {
    return yyparse();
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

/* addSymbolTable(char* idName, char* type) */
void addSymbolTable(char* name, char* type){
    /* printf("add Sym\n"); */
    if (symbolTableTop > 40){
        printf("symbol table is full.\n");
        return;
    }
    if (searchType(name) == NULL){
        symbolTable[symbolTableTop].idName = name;
        symbolTable[symbolTableTop].type = type;
        symbolTableTop += 1;
    }
    else{
        printf("Already exist.\n");
    }
    /* printf("done\n"); */
}
/* search */
char* searchType(char* name){
    for (int i=0;i<symbolTableTop;i++){
        if (strcmp(symbolTable[i].idName, name) == 0){
            return symbolTable[i].type;
        }
    }
    return NULL;
}