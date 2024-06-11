%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "type.h"
extern int yylex();
extern char* yytext;
void yyerror(const char *s);
void addSymbolTable(char* name, char* type, int size);
char* searchType(char* name);
int searchSize(char* name);
char* vectorFillZeros(const char* s, int size);
char* typeCoercion(char* type1, char* type2);

struct dataType{
    char *idName;
    char *type;
    int size;
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
    struct ExpressionNode{
        char *sval;
        char *type;
        int size;
    }expression_node;
};

%token <sval> FUN MAIN VAR VAL INT REAL PRINT PRINTLN
%token <node> NUMBER IDENTIFIER STRING_LITERAL
%token MULTIPLY

%type <sval> program function block declarations declaration type statements statement
%type <expression_node> expression vector term factor array_declaration
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
        printf("#include <stdlib.h>\n");
        printf("double inner_product_1d_double(int size, double *arr1, double *arr2) {\n");
        printf("    double result = 0.0;\n");
        printf("    for (int i = 0; i < size; i++) {\n");
        printf("        result += arr1[i] * arr2[i];\n");
        printf("    }\n");
        printf("    return result;\n");
        printf("}\n");

        printf("int inner_product_1d_int(int size, int *arr1, int *arr2) {\n");
        printf("    int result = 0.0;\n");
        printf("    for (int i = 0; i < size; i++) {\n");
        printf("        result += arr1[i] * arr2[i];\n");
        printf("    }\n");
        printf("    return result;\n");
        printf("}\n");

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
        addSymbolTable($2.sval, $2.type, 1);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s = %s;\n", $4, $2.sval, $6.sval);
        $$ = strdup(buffer);
    }
    |
    VAR IDENTIFIER ':' type array_declaration '=' expression ';'
    {
        // printf("declaration - VAR IDENTIFIER ':' type array_declaration '=' expression ';' %s\n", $4);
        $2.type = strdup($4);
        int defSize = $5.size;
        int decSize = $7.size;
        // compare defSize and decSize
        char* filledArray;
        if (defSize < decSize){
            yyerror("ERROR: mismatched dimensions");
            exit(0);
        }
        else {
            filledArray = vectorFillZeros($7.sval, defSize);
        }
        addSymbolTable($2.sval, strcat($2.type, "-vector"), $5.size);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s%s = %s;\n", $4, $2.sval, $5.sval, filledArray);
        $$ = strdup(buffer);
    }
    |
    VAR IDENTIFIER ':' type ';'
    {
        // printf("declaration2\n");
        $2.type = strdup($4);
        // TODO: symbol table
        addSymbolTable($2.sval, $2.type, 1);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s;\n", $4, $2.sval);
        $$ = strdup(buffer);
    }
    |
    VAR IDENTIFIER ':' type array_declaration ';'
    {
        // printf("declaration2\n");
        $2.type = strdup($4);
        // TODO: symbol table
        addSymbolTable($2.sval, strcat($2.type, "-vector"), $5.size);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s%s;\n", $4, $2.sval, $5.sval);
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

array_declaration:
    /* array_declaration '[' expression ']'
    {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s[%s]", $1, $3.sval);
        $$ = (struct ExpressionNode){strdup(buffer), "string", };
    }
    | */
    '[' expression ']'
    {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "[%s]", $2.sval);
        $$ = (struct ExpressionNode){strdup(buffer), "string", atoi($2.sval)};
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
        else if (strcmp($3.type, "string") == 0){
            // printf("PRINT string\n");
            snprintf(buffer, sizeof(buffer), "    printf(\"%s\");\n", $3.sval);
        }
        else {
            printf("ERROR: unknown type\n");
        }
        $$ = strdup(buffer);
    }
    |
    PRINTLN '(' expression ')' ';'
    {
        // printf("statement - PRINTLN ( expression ) ;\n");
        char buffer[256];
        if (strcmp($3.type, "int") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%d\\n\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "double") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%lf\\n\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "string") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%s\\n\");\n", $3.sval);
        }
        else {
            printf("ERROR: unknown type\n");
        }
        $$ = strdup(buffer);
    }
    ;

expression:
    term
    {
        // printf("expression term\n");
        $$ = (struct ExpressionNode){$1.sval, $1.type, $1.size};
    }
    |
    expression '+' term
    {  
        // TODO: maintain the coercion
        // printf("+\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s + %s", $1.sval, $3.sval);
        $$ = (struct ExpressionNode){strdup(buffer), typeCoercion($1.type, $3.type), 1};
    }
    |
    expression '-' term
    {
        // TODO: maintain the coercion
        // printf("-\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s - %s", $1.sval, $3.sval);
        $$ = (struct ExpressionNode){strdup(buffer), typeCoercion($1.type, $3.type), 1};
        // printf("buffer => %s, type => %s\n", buffer, $1.type);
    }
    ;

term:
    term '*' factor
    {
        // printf("*\n");
        if (strcmp($1.type, "double-vector") == 0 && strcmp($3.type, "double-vector") == 0){
            if ($1.size == $3.size){
                char buffer[256];
                snprintf(buffer, sizeof(buffer), "inner_product_1d_double(%d, %s, %s)", $1.size, $1.sval, $3.sval);
                $$ = (struct ExpressionNode){strdup(buffer), "double", 1};
            }
            else{
                yyerror("ERROR: mismatched dimensions");
                exit(0);
            }
        }
        else if (strcmp($1.type, "int-vector") == 0 && strcmp($3.type, "int-vector") == 0){
            if ($1.size == $3.size){
                char buffer[256];
                snprintf(buffer, sizeof(buffer), "inner_product_1d_int(%d, %s, %s)", $1.size, $1.sval, $3.sval);
                $$ = (struct ExpressionNode){strdup(buffer), "int", 1};
            }
            else{
                yyerror("ERROR: mismatched dimensions");
                exit(0);
            }
        }
        // int int, double double, int double, double int
        else if ((strcmp($1.type, "int") == 0 || strcmp($1.type, "double") == 0) && (strcmp($3.type, "int") == 0 || strcmp($3.type, "double") == 0)){
            char buffer[256];
            snprintf(buffer, sizeof(buffer), "%s * %s", $1.sval, $3.sval);
            $$ = (struct ExpressionNode){strdup(buffer), typeCoercion($1.type, $3.type), 1};
        }
        else {
            yyerror("ERROR: Two argument types are not compatible");
            exit(0);
        }
    }
    |
    term '/' factor
    {
        // printf("/\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s / %s", $1.sval, $3.sval);
        $$ = (struct ExpressionNode){strdup(buffer), typeCoercion($1.type, $3.type), 1};
    }
    |
    factor
    {
        // printf("term - factor\n");
        $$ = (struct ExpressionNode){$1.sval, $1.type, $1.size};
    }
    ;

factor:
    '(' expression ')'
    {
        // printf("factor ( expression )\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "( %s )", $2.sval);
        $$ = (struct ExpressionNode){strdup(buffer), $2.type, 1};
    }
    |
    IDENTIFIER
    {
        // printf("factor - IDENTIFIER\n");
        // printf("id => %s\n", $1.sval);
        $$ = (struct ExpressionNode){$1.sval, searchType($1.sval), searchSize($1.sval)};
        if ($$.type == NULL || $$.size == -1){
            yyerror("ERROR: Not found the identifier\n");
            exit(0);
        }
        // printf("done\n");
    }
    |
    NUMBER
    {
        // printf("factor - NUMBER\n");
        // printf("num => %s\n", $1.sval);
        // printf("type = %s\n", $1.type);
        $$ = (struct ExpressionNode){$1.sval, $1.type, 1};
    }
    |
    STRING_LITERAL
    {
        // printf("factor - STRING_LITERAL ;\n");
        // printf("string => %s\n", $1.sval);
        $$ = (struct ExpressionNode){$1.sval, $1.type, 1};
    }
    |
    '{' vector '}'
    {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "{ %s }", $2.sval);   
        $$ = (struct ExpressionNode){strdup(buffer), "vector", $2.size};
    }
    ;

vector:
    expression ',' vector
    {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s, %s", $1.sval, $3.sval);
        $$ = (struct ExpressionNode){strdup(buffer), strdup("vector"), $1.size + $3.size};
    }
    |
    expression
    {
        $$ = (struct ExpressionNode){strdup($1.sval), strdup($1.type), $1.size};
    }
    |
    {
        $$ = (struct ExpressionNode){"", "unknown", 0};
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
void addSymbolTable(char* name, char* type, int size){
    /* printf("add Sym\n"); */
    if (symbolTableTop > 40){
        printf("symbol table is full.\n");
        return;
    }
    if (searchType(name) == NULL){
        symbolTable[symbolTableTop].idName = name;
        symbolTable[symbolTableTop].type = type;
        symbolTable[symbolTableTop].size = size;
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

int searchSize(char* name){
    for (int i=0;i<symbolTableTop;i++){
        if (strcmp(symbolTable[i].idName, name) == 0){
            return symbolTable[i].size;
        }
    }
    return -1;
}

char* vectorFillZeros(const char* s, int size) {
    int count = 0;
    const char* p = s;
    int isEmpty = strcmp(s, "{  }") == 0;
    while (*p) {
        if (*p == ',') {
            count++;
        }
        p++;
    }
    count++;
    if (isEmpty) {
        count = 0;
    }

    int zerosToAdd = size - count;
    if (zerosToAdd <= 0) {
        return strdup(s);
    }

    int newSize = strlen(s) + zerosToAdd * 3 + 1;
    char* result = (char*)malloc(newSize);
    if (!result) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    if (isEmpty) {
        strcpy(result, "{ ");
    } else {
        strncpy(result, s, strlen(s) - 2);
        result[strlen(s) - 2] = '\0';
    }
    for (int i = 0; i < zerosToAdd; i++) {
        if (i != 0 || !isEmpty) {
            strcat(result, ", ");
        }
        strcat(result, "0");
    }

    strcat(result, " }");
    return result;
}

char* typeCoercion(char* type1, char* type2){
    if (strcmp(type1, "double") == 0 || strcmp(type2, "double") == 0){
        return "double";
    }
    return "int";
}