%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "type.h"
#define MAX_SYMBOL_TABLE_SIZE 40
#define HASH_SIZE 101

extern int yylex();
extern char* yytext;
void yyerror(const char *s);

// Symbol Table
typedef struct {
    char *idName;
    char *type;
    int size;
} Symbol;

typedef struct SymbolTable {
    Symbol symbols[MAX_SYMBOL_TABLE_SIZE];
    int top;
    struct SymbolTable *next;
} SymbolTable;

SymbolTable *createSymbolTable();
void pushSymbolTable();
void popSymbolTable();
void addSymbolTable(char* name, char* type, int size);
char* searchType(char* name);
int searchSize(char* name);
int isExist(char* name);
void printSymbolTableStack();

char* vectorFillZeros(const char* s, int size);
char* typeCoercion(char* type1, char* type2);
bool arithmeticTypeChecking(char* type1, char* type2);

SymbolTable *symbolTableStack = NULL;

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

%token <sval> FUN MAIN VAR VAL INT REAL PRINT PRINTLN RET
%token <node> NUMBER IDENTIFIER STRING_LITERAL

%type <sval> program functions function block declarations declaration type statements statement param_declarations param_declaration
%type <expression_node> expression vector term factor array_declaration
/* %token T_INT */
/* 先乘除後加減，且定義由左到右運算 */
/* %left '+' '-'
%left '*' '/' */

%%
program:
    { pushSymbolTable(); } functions
    {
        { printSymbolTableStack(); popSymbolTable(); }
        printf("-------------- Info --------------\n");
        printf("| Compile Complete.              |\n");
        printf("| Generating C code...           |\n");
        printf("| Please checkout output.c file. |\n");
        printf("----------------------------------\n");
        FILE *outputFile = fopen("checkResult.c", "w");
        if (outputFile == NULL) {
            fprintf(stderr, "Error opening output.c file\n");
            exit(EXIT_FAILURE);
        }
        fprintf(outputFile, "#include <stdio.h>\n");
        fprintf(outputFile, "#include <stdlib.h>\n");
        fprintf(outputFile, "#include <stdbool.h>\n");
        fprintf(outputFile, "double inner_product_1d_double(int size, double *arr1, double *arr2) { double result = 0.0;for (int i = 0; i < size; i++) {result += arr1[i] * arr2[i];}return result;}\n");
        fprintf(outputFile, "int inner_product_1d_int(int size, int *arr1, int *arr2) {int result = 0.0;for (int i = 0; i < size; i++) {result += arr1[i] * arr2[i];}return result;}\n");
        fprintf(outputFile, "int* add_arrays_1d_int(int size, int* arr1, int* arr2) {int* result = (int*)malloc(size * sizeof(int));if (result == NULL) {printf(\"Memory allocation failed\\n\");exit(1);}for (int i = 0; i < size; i++) {result[i] = arr1[i] + arr2[i];}return result;}\n");
        fprintf(outputFile, "double* add_arrays_1d_double(int size, double* arr1, double* arr2) {double* result = (double*)malloc(size * sizeof(double));if (result == NULL) {printf(\"Memory allocation failed\\n\");exit(1);}for (int i = 0; i < size; i++) {result[i] = arr1[i] + arr2[i];}return result;}        \n");
        fprintf(outputFile, "void print_1d_int(int size, int* result, bool isNewline){printf(\"{ \");for (int i=0;i<size;i++){if (i == size-1) printf(\"%%d }\", result[i]);else printf(\"%%d, \", result[i]);}if (isNewline) printf(\"\\n\");}\n");
        fprintf(outputFile, "void print_1d_double(int size, double* result, bool isNewline){printf(\"{ \");for (int i=0;i<size;i++){if (i == size-1) printf(\"%%g }\", result[i]);else printf(\"%%g, \", result[i]);}if (isNewline) printf(\"\\n\");}\n");

        fprintf(outputFile, "%s\n", $2);
    }
    ;

functions:
    /* empty */
    {
        $$ = strdup("");
    }
    |
    function functions
    {
        $$ = malloc(strlen($1) + strlen($2) + 1);
        strcpy($$, $1);
        strcat($$, $2);
    }
    ;

function:
    FUN MAIN '(' ')' '{'
        { pushSymbolTable(); }
        block
    '}'
    {
        { popSymbolTable(); }
        // printf("function main\n");
        // printf("%s\n", $7);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "int main() {\n%s}", $7);
        $$ = strdup(buffer);
        // printf("int main() {\n");
        // printf("%s", $6);
        // printf("}\n");
    }
    |
    FUN IDENTIFIER { pushSymbolTable(); } '(' param_declarations ')' ':' type '{'
        block
    '}'
    {
        { popSymbolTable(); }
        // printf("function %s\n", $2.sval);
        if (isExist($2.sval)){
            yyerror("ERROR: duplicate declaraction");
            exit(0);
        }
        char* functionName = strdup($8);
        addSymbolTable($2.sval, strcat($8, "-function"), 1);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s %s(%s) {\n%s\n}\n", functionName, $2.sval, $5, $10);
        $$ = strdup(buffer);
        // "%s %s(%s){\n%s\n}", $8.sval, $2.sval, $5, $10
    }
    ;

param_declarations:
    /* empty */
    {
        $$ = strdup("");
    }
    |
    param_declaration ',' param_declarations
    {
        // printf("param_declaration param_declarations\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s, %s", $1, $3);
        $$ = strdup(buffer);
    }
    |
    param_declaration
    {
        $$ = strdup($1);
    }
    ;

param_declaration:
    IDENTIFIER ':' type
    {
        // printf("param_declaration\n");
        if (isExist($1.sval)){
            yyerror("duplicate declaration");
            exit(0);
        }
        addSymbolTable($1.sval, $3, 1);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s %s", $3, $1.sval);
        $$ = strdup(buffer);
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
    |
    { pushSymbolTable(); } '{' block '}'
    {
        { popSymbolTable(); }
        $$ = malloc(strlen("{\n}\n") + strlen($3) +1);
        strcpy($$, "{\n");
        strcat($$, $3);
        strcat($$, "}\n");
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
        if (isExist($2.sval)){
            yyerror("duplicate declaration");
            exit(0);
        }
        $2.type = strdup($4);
        addSymbolTable($2.sval, $2.type, 1);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s = %s;\n", $4, $2.sval, $6.sval);
        $$ = strdup(buffer);
    }
    |
    VAR IDENTIFIER ':' type array_declaration '=' expression ';'
    {
        // printf("declaration - VAR IDENTIFIER ':' type array_declaration '=' expression ';' %s\n", $4);
        if (isExist($2.sval)){
            yyerror("duplicate declaration");
            exit(0);
        }
        $2.type = strdup($4);
        int defSize = $5.size;
        int decSize = $7.size;
        // compare defSize and decSize
        char* filledArray;
        if (defSize < decSize){
            yyerror("too many dimensions");
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
        if (isExist($2.sval)){
            yyerror("duplicate declaration");
            exit(0);
        }
        $2.type = strdup($4);
        addSymbolTable($2.sval, $2.type, 1);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s;\n", $4, $2.sval);
        $$ = strdup(buffer);
    }
    |
    VAR IDENTIFIER ':' type array_declaration ';'
    {
        // printf("declaration2\n");
        if (isExist($2.sval)){
            yyerror("duplicate declaration");
            exit(0);
        }
        $2.type = strdup($4);
        addSymbolTable($2.sval, strcat($2.type, "-vector"), $5.size);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    %s %s%s;\n", $4, $2.sval, $5.sval);
        $$ = strdup(buffer);
    }
    |
    VAL IDENTIFIER ':' type ';'
    {
        // printf("declaration VAL IDENTIFIER : type ;\n");
        if (isExist($2.sval)){
            yyerror("duplicate declaration");
            exit(0);
        }
        strcpy($2.type, "const-");
        addSymbolTable($2.sval, strcat($2.type, $4), 1);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    const %s %s;\n", $4, $2.sval);
        $$ = strdup(buffer);
    }
    |
    VAL IDENTIFIER ':' type '=' expression ';'
    {
        if (isExist($2.sval)){
            yyerror("duplicate declaration");
            exit(0);
        }
        strcpy($2.type, "const-");
        addSymbolTable($2.sval, strcat($2.type, $4), 1);
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    const %s %s = %s;\n", $4, $2.sval, $6.sval);
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
        char* idType = searchType($1.sval);
        if (strcmp(idType, "const-int") == 0 || strcmp(idType, "const-double") == 0){
            yyerror("cannot assign to val type");
            exit(0);
        }
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
        if (strcmp($3.type, "int") == 0 || strcmp($3.type, "const-int") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%d\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "double") == 0 || strcmp($3.type, "const-double") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%g\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "string") == 0){
            // printf("PRINT string\n");
            snprintf(buffer, sizeof(buffer), "    printf(\"%s\");\n", $3.sval);
        }
        else if (strcmp($3.type, "int-vector") == 0){
            snprintf(buffer, sizeof(buffer), "    print_1d_int(%d, %s, 0);\n", $3.size, $3.sval);
        }
        else if (strcmp($3.type, "double-vector") == 0){
            snprintf(buffer, sizeof(buffer), "    print_1d_double(%d, %s, 0);\n", $3.size, $3.sval);
        }
        else if (strcmp($3.type, "int-function") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%d\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "double-function") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%g\", %s);\n", $3.sval);
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
        // printf("type => %s\n", $3.type);
        char buffer[256];
        if (strcmp($3.type, "int") == 0 || strcmp($3.type, "const-int") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%d\\n\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "double") == 0 || strcmp($3.type, "const-double") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%g\\n\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "string") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%s\\n\");\n", $3.sval);
        }
        else if (strcmp($3.type, "int-vector") == 0){
            snprintf(buffer, sizeof(buffer), "    print_1d_int(%d, %s, 1);\n", $3.size, $3.sval);
        }
        else if (strcmp($3.type, "double-vector") == 0){
            snprintf(buffer, sizeof(buffer), "    print_1d_double(%d, %s, 1);\n", $3.size, $3.sval);
        }
        else if (strcmp($3.type, "int-function") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%d\\n\", %s);\n", $3.sval);
        }
        else if (strcmp($3.type, "double-function") == 0){
            snprintf(buffer, sizeof(buffer), "    printf(\"%%g\\n\", %s);\n", $3.sval);
        }
        else {
            printf("ERROR: unknown type\n");
        }
        $$ = strdup(buffer);
    }
    |
    RET expression ';'
    {
        // printf("statement - RET expression\n");
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "    return %s;", $2.sval);
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
        // printf("+\n");
        if (strcmp($1.type, "double-vector") == 0 && strcmp($3.type, "double-vector") == 0){
            if ($1.size == $3.size){
                char buffer[256];
                snprintf(buffer, sizeof(buffer), "add_arrays_1d_double(%d, %s, %s)", $1.size, $1.sval, $3.sval);
                $$ = (struct ExpressionNode){strdup(buffer), "double-vector", $1.size};
            }
            else{
                yyerror("mismatched dimensions");
                exit(0);
            }
        }
        else if (strcmp($1.type, "int-vector") == 0 && strcmp($3.type, "int-vector") == 0){
            if ($1.size == $3.size){
                char buffer[256];
                snprintf(buffer, sizeof(buffer), "add_arrays_1d_int(%d, %s, %s)", $1.size, $1.sval, $3.sval);
                $$ = (struct ExpressionNode){strdup(buffer), "int-vector", $1.size};
            }
            else{
                yyerror("mismatched dimensions");
                exit(0);
            }
        }
        // int int, double double, int double, double int
        else if (arithmeticTypeChecking($1.type, $3.type)){
            char buffer[256];
            snprintf(buffer, sizeof(buffer), "%s + %s", $1.sval, $3.sval);
            $$ = (struct ExpressionNode){strdup(buffer), typeCoercion($1.type, $3.type), 1};
        }
        else {
            yyerror("two argument types are not compatible");
            exit(0);
        }
    }
    |
    expression '-' term
    {
        // printf("-\n");
        if (arithmeticTypeChecking($1.type, $3.type)){
            char buffer[256];
            snprintf(buffer, sizeof(buffer), "%s - %s", $1.sval, $3.sval);
            $$ = (struct ExpressionNode){strdup(buffer), typeCoercion($1.type, $3.type), 1};
            // printf("buffer => %s, type => %s\n", buffer, $1.type);
        }
        else {
            yyerror("two argument types are not compatible");
            exit(0);
        }
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
                yyerror("mismatched dimensions");
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
                yyerror("mismatched dimensions");
                exit(0);
            }
        }
        // int int, double double, int double, double int
        else if (arithmeticTypeChecking($1.type, $3.type)){
            char buffer[256];
            snprintf(buffer, sizeof(buffer), "%s * %s", $1.sval, $3.sval);
            $$ = (struct ExpressionNode){strdup(buffer), typeCoercion($1.type, $3.type), 1};
        }
        else {
            yyerror("Two argument types are not compatible");
            exit(0);
        }
    }
    |
    term '/' factor
    {
        // printf("/\n");
        if (arithmeticTypeChecking($1.type, $3.type)){
            char buffer[256];
            snprintf(buffer, sizeof(buffer), "%s / %s", $1.sval, $3.sval);
            $$ = (struct ExpressionNode){strdup(buffer), typeCoercion($1.type, $3.type), 1};
        }
        else{
            yyerror("Two argument types are not compatible");
            exit(0);
        }
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
    '-' factor
    {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "-%s", $2.sval);
        $$ = (struct ExpressionNode){strdup(buffer), $2.type, 1};
    }
    |
    IDENTIFIER
    {
        // printf("factor - IDENTIFIER\n");
        // printf("id => %s\n", $1.sval);
        $$ = (struct ExpressionNode){$1.sval, searchType($1.sval), searchSize($1.sval)};
        if ($$.type == NULL || $$.size == -1){
            yyerror("not found the identifier\n");
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
    |
    IDENTIFIER '(' vector ')'
    {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "%s( %s )", $1.sval, $3.sval);   
        $$ = (struct ExpressionNode){strdup(buffer), searchType($1.sval), 1};
        if ($$.type == NULL){
            yyerror("not found the identifier\n");
            exit(0);
        }
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
    fprintf(stderr, "ERROR: %s\n", s);
}

SymbolTable *createSymbolTable() {
    SymbolTable *newTable = (SymbolTable *)malloc(sizeof(SymbolTable));
    if (newTable == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    newTable->top = 0;
    newTable->next = NULL;
    return newTable;
}

void pushSymbolTable() {
    SymbolTable *newTable = createSymbolTable();
    newTable->next = symbolTableStack;
    symbolTableStack = newTable;
}

void popSymbolTable() {
    if (symbolTableStack != NULL) {
        SymbolTable *oldTable = symbolTableStack;
        symbolTableStack = symbolTableStack->next;
        free(oldTable);
    } else {
        fprintf(stderr, "No symbol table to pop\n");
    }
}

void addSymbolTable(char* name, char* type, int size) {
    if (symbolTableStack == NULL) {
        fprintf(stderr, "No symbol table found\n");
        return;
    }
    if (symbolTableStack->top >= MAX_SYMBOL_TABLE_SIZE) {
        printf("symbol table is full.\n");
        return;
    }
    for (int i = 0; i < symbolTableStack->top; i++) {
        if (strcmp(symbolTableStack->symbols[i].idName, name) == 0) {
            printf("Already exist.\n");
            return;
        }
    }
    symbolTableStack->symbols[symbolTableStack->top].idName = strdup(name);
    symbolTableStack->symbols[symbolTableStack->top].type = strdup(type);
    symbolTableStack->symbols[symbolTableStack->top].size = size;
    symbolTableStack->top++;
}

char* searchType(char* name) {
    for (SymbolTable *st = symbolTableStack; st != NULL; st = st->next) {
        for (int i = 0; i < st->top; i++) {
            if (strcmp(st->symbols[i].idName, name) == 0) {
                return st->symbols[i].type;
            }
        }
    }
    return NULL;
}

int searchSize(char* name) {
    for (SymbolTable *st = symbolTableStack; st != NULL; st = st->next) {
        for (int i = 0; i < st->top; i++) {
            if (strcmp(st->symbols[i].idName, name) == 0) {
                return st->symbols[i].size;
            }
        }
    }
    return -1;
}

int isExist(char* name) {
    for (SymbolTable *st = symbolTableStack; st != NULL; st = st->next) {
        for (int i = 0; i < st->top; i++) {
            if (strcmp(st->symbols[i].idName, name) == 0) {
                return 1;
            }
        }
    }
    return 0;
}

void printSymbolTableStack() {
    printf("Symbol Table Stack:\n");
    for (SymbolTable *st = symbolTableStack; st != NULL; st = st->next) {
        printf("--- Symbol Table ---\n");
        for (int i = 0; i < st->top; i++) {
            printf("Name: %s, Type: %s, Size: %d\n", st->symbols[i].idName, st->symbols[i].type, st->symbols[i].size);
        }
    }
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

bool arithmeticTypeChecking(char* type1, char* type2){
    /* printf("type1 => %s, type2 => %s\n", type1, type2); */
    if ((
        strcmp(type1, "int") == 0 || strcmp(type1, "double") == 0 
        ||
        strcmp(type1, "const-int") == 0 || strcmp(type1, "const-double") == 0 
        ) 
    && 
        (
        strcmp(type2, "int") == 0 || strcmp(type2, "double") == 0 
        ||
        strcmp(type2, "const-int") == 0 || strcmp(type2, "const-double") == 0 
        )){
            return 1;
        }
    return 0;
}