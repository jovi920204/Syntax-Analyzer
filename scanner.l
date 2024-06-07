%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"

char strbuffer[200];
int line_no = 1;
void yyerror(const char *s);

#define T_VAR                0
#define T_VAL                1
#define T_BOOL               2
#define T_CHAR               3
#define T_INT                4
#define T_REAL               5
#define T_TRUE               6
#define T_FALSE              7
#define T_CLASS              8
#define T_IF                 9
#define T_ELSE               10
#define T_FOR                11
#define T_WHILE              12
#define T_DO                 13
#define T_SWITCH             14
#define T_CASE               15
#define T_FUN                16
#define T_RET                17
#define T_OPERATOR           18
#define T_MINUS              19
#define T_SINGLE_QUOTE       20
#define T_DOUBLE_QUOTE       21
#define T_LEFT_PARENTHESE    22
#define T_RIGHT_PARENTHESE   23
#define T_LEFT_BRACKET       24
#define T_RIGHT_BRACKET      25
#define T_LEFT_BRACE         26
#define T_RIGHT_BRACE        27
#define T_ASIGN              28
#define T_EQUAL_CMP          29
#define T_INEQUAL_CMP        30
#define T_LARGER_THAN        31
#define T_SMALLER_THAN       32
#define T_LARGER_EQUAL       33
#define T_SMALLER_EQUAL      34
#define T_ESCAPE_SEQUENCE    35
#define T_COMMA              36
#define T_COLON              37
#define T_SEMI               38
#define T_INT_CONST          39
#define T_REAL_CONST         40
#define T_CHAR_CONST         41
#define T_ID                 42
#define T_STRING             43

%}

%x S_COMMENT
%x M_COMMENT
%x STRINGS

INT         [0-9]+
REAL        {INT}+\.{INT}+
VARIABLE    [_a-zA-Z][_0-9a-zA-Z]*
W           [ \t]+
ASCII       [ -~]
TERMINAL    (";"|","|":"|"("|")"|"["|"]"|"{"|"}"|"+"|"-"|"*"|"/"|"=")

%%

"//"                { BEGIN S_COMMENT; }
<S_COMMENT>[^\n]*   { ; }
<S_COMMENT>\n       { BEGIN 0; line_no++; }

"/*"                { BEGIN M_COMMENT; }
<M_COMMENT>"*/"     { BEGIN(INITIAL); }
<M_COMMENT>\n       { line_no++; }
<M_COMMENT>.        { }
<M_COMMENT><<EOF>>  { yyerror("Invalid character"); yyterminate(); }
"*/"                { yyerror("Invalid character"); yyterminate(); }

["]                     { BEGIN STRINGS; strbuffer[0] = '\0'; printf("dq-String: %d, ", T_STRING); }
<STRINGS>["]            { BEGIN 0; strcpy(yylval.string, strbuffer); printf("%s\n", yylval.string); }
<STRINGS>[\\][\\]        { strcat(strbuffer, "\\"); }
<STRINGS>[\\][n]        { strcat(strbuffer, "\n"); }
<STRINGS>[\\][t]        { strcat(strbuffer, "\t"); }
<STRINGS>[\\][']        { strcat(strbuffer, "\'"); }
<STRINGS>[\\]["]        { strcat(strbuffer, "\""); }
<STRINGS>[\\][?]        { strcat(strbuffer, "\?"); }
<STRINGS>[\\]           { yyerror("Invalid character"); yyterminate(); }
<STRINGS><<EOF>>        { yyerror("Invalid character"); yyterminate(); }
<STRINGS>\n             { strcat(strbuffer, yytext); line_no++; } 
<STRINGS>{ASCII}        { strcat(strbuffer, yytext); }


'\\'                                { yyerror("Invalid character"); yyterminate(); }
'(\\\\|\\n|\\t|\\\'|\\\"|\\\?)'     { printf("single-quote: %d, %c%c\n", T_CHAR_CONST, yytext[1], yytext[2]); }
'\\.'                               { printf("single-quote: %d, %c\n", T_CHAR_CONST, yytext[2]); } 
'[^']'                              { printf("single-quote: %d, %c\n", T_CHAR_CONST, yytext[1]); }

"var"               { return (RESERVED); }
"val"               { printf("keyword: %d, %s\n", T_VAL, yytext); }
"bool"              { printf("keyword: %d, %s\n", T_BOOL, yytext); }
"char"              { printf("keyword: %d, %s\n", T_CHAR, yytext); }
"int"               { sscanf(yytext, "%s", yylval.string); return (TYPE); }
"real"              { printf("keyword: %d, %s\n", T_REAL, yytext); }
"true"              { printf("keyword: %d, %s\n", T_TRUE, yytext); }
"false"             { printf("keyword: %d, %s\n", T_FALSE, yytext); }
"class"             { printf("keyword: %d, %s\n", T_CLASS, yytext); }
"if"                { printf("keyword: %d, %s\n", T_IF, yytext); }
"else"              { printf("keyword: %d, %s\n", T_ELSE, yytext); }
"for"               { printf("keyword: %d, %s\n", T_FOR, yytext); }
"while"             { printf("keyword: %d, %s\n", T_WHILE, yytext); }
"do"                { printf("keyword: %d, %s\n", T_DO, yytext); }
"switch"            { printf("keyword: %d, %s\n", T_SWITCH, yytext); }
"case"              { printf("keyword: %d, %s\n", T_CASE, yytext); }
"fun"               { return (RESERVED); }
"ret"               { printf("keyword: %d, %s\n", T_RET, yytext); }

"=="                { printf("EQUAL_CMP: %d, %s\n", T_EQUAL_CMP, yytext); }
"!="                { printf("INEQUAL_CMP: %d, %s\n", T_INEQUAL_CMP, yytext); }
">"                 { printf("LARGER_THAN: %d, %s\n", T_LARGER_THAN, yytext); }
"<"                 { printf("SMALLER_THAN: %d, %s\n", T_SMALLER_THAN, yytext); }
">="                { printf("LARGER_EQUAL: %d, %s\n", T_LARGER_EQUAL, yytext); }
"<="                { printf("SMALLER_EQUAL: %d, %s\n", T_SMALLER_EQUAL, yytext); }

"\\\\"              { printf("ESCAPE_SEQUENCE: %d, %s\n", T_ESCAPE_SEQUENCE, yytext); }
"\\n"               { printf("ESCAPE_SEQUENCE: %d, %s\n", T_ESCAPE_SEQUENCE, yytext); }
"\\t"               { printf("ESCAPE_SEQUENCE: %d, %s\n", T_ESCAPE_SEQUENCE, yytext); }
"\\\'"              { printf("ESCAPE_SEQUENCE: %d, %s\n", T_ESCAPE_SEQUENCE, yytext); }
"\\\""              { printf("ESCAPE_SEQUENCE: %d, %s\n", T_ESCAPE_SEQUENCE, yytext); }
"\\\?"              { printf("ESCAPE_SEQUENCE: %d, %s\n", T_ESCAPE_SEQUENCE, yytext); }

{TERMINAL}          { return (yytext[0]); }
{INT}               { printf("INT_CONST: %d, %s\n", T_INT_CONST, yytext); }
{REAL}              { printf("REAL_CONST: %d, %s\n", T_REAL_CONST, yytext); }
{VARIABLE}          { sscanf(yytext, "%s", yylval.string); return (VAR); }

\n                  { line_no++; }
{W}                 { /* Ignore whitespace */ }

.                   { yyerror("invalid character"); yyterminate(); } 

%%

int yywrap(void){
    return 1;
}