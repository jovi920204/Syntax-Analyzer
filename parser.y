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

%token <sval> FUN MAIN VAR VAL INT REAL PRINT STRING_LITERAL
%token <node> NUMBER IDENTIFIER
%token MULTIPLY

%type <sval> program function block declarations declaration type statements statement
%type <node> expression
%type <node> term
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
    /* empty */ { $$ = strdup(""); }
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
        $2.sval = strdup($6.sval);
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
        snprintf(buffer, sizeof(buffer), "    %s = %s;\n", $1.sval, $3.sval);
        $$ = strdup(buffer);
    }
    |
    PRINT '(' expression ')' ';'
    {
        // printf( expression );
        char buffer[256];
        if (strcmp($3.type, "int") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%d\\n\", %s);\n", $3.sval);
        }
        else {
            snprintf(buffer, sizeof(buffer), "    printf(\"%%lf\\n\", %s);\n", $3.sval);
        }
        $$ = strdup(buffer);
    }
    |
    PRINT '(' STRING_LITERAL ')' ';'
    {

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
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s + %s", $1.sval, $3.sval);
        $$ = (struct Node){strdup(buffer), $1.type};
    }
    |
    expression '-' term
    {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s + %s", $1.sval, $3.sval);
        $$ = (struct Node){strdup(buffer), $1.type};
    }
    /* |
    expression MULTIPLY term
    {

    } */
    ;

term:
    IDENTIFIER
    {
        // printf("term IDENTIFIER\n");
        $$ = (struct Node){$1.sval, searchType($1.sval)};
    }
    |
    NUMBER
    { 
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