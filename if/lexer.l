%option noyywrap
%{
#include <stdio.h>
#include "y.tab.h"
int add(char *s);
%}
%%
"if"    { printf("IF "); return IF; }
"else"  { printf("ELSE "); return ELSE; }
[a-z]+  { printf("ID(%s) ", yytext);
          yylval=add(yytext); return ID; }
[0-9]+  { printf("NUM(%s) ", yytext);
          yylval=add(yytext); return NUM; }
[ \t\r\n]+ ;
[(){}<;=+*-] { printf("%s ", yytext); return yytext[0]; }
. { printf("\nInvalid character: %s\n", yytext); return yytext[0]; }
%%
