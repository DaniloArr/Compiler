%{

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "y.tab.h"

int contaLinha = 1;


void yyerror(const char *s);
extern void getIdentifier(const char *id);
%}

%option noyywrap
%option yylineno


ascii	  [ -~]
letra     [a-zA-Z]
digito    [0-9]
integer   [-]?{digito}+
decimal   [-]?{digito}+(\.{digito}+)
id        {letra}({letra}|{digito})*
string	  \"{ascii}*\"
tk_point  "*"{string}
tk_include ^"#include"[ ]*<.+\.h>



%%
printf		                { printf("PRINTF: [ %s ] \n ", yytext); return PRINTF; }
scanf  	      	            { printf("SCANF: [ %s ] \n ", yytext); return SCANF; }
for	   	                    { printf("FOR: [ %s ] \n ", yytext); return FOR; }
while	 	                { printf("WHILE: [ %s ] \n ", yytext); return WHILE; }
int	    	                { printf("INT: [ %s ] \n ", yytext); return INT; }
float	  	                { printf("FLOAT: [ %s ] \n ", yytext); return FLOAT; }
double		                { printf("DOUBLE: [ %s ] \n ", yytext); return DOUBLE; }
char	  	                { printf("CHAR: [ %s ] \n ", yytext); return CHAR; }
struct		                { printf("STRUCT: [ %s ] \n ", yytext); return STRUCT; }
const	 	                { printf("CONST: [ %s ] \n ", yytext); return CONST; }
if                          { printf("IF: [ %s ] \n ", yytext); return IF; }
else                        { printf("ELSE: [ %s ] \n ", yytext); return ELSE; }
return	 	                { printf("RETURN: [ %s ] \n ", yytext); return RETURN; }
main                        { printf("MAIN: [ %s ] \n ", yytext); return MAIN; }
void	      	            { printf("VOID: [ %s ] \n ", yytext); return VOID; }
{tk_include}	            { printf("INCLUDE: [ %s ] \n ", yytext); return INCLUDE; }
{string}                    { yylval.str = strdup(yytext); printf("STRING: [ %s ] \n ", yytext); return STRING; }
{letra}({letra}|{digito})*  { getIdentifier(yytext); yylval.str = strdup(yytext); printf("IDENTIFIER: [ %s ] \n ", yytext); return IDENTIFIER; }
"+"                         { printf("OP_MAIS: [ %s ] \n ", yytext); return OP_MAIS; }
"-"                         { printf("OP_MENOS: [ %s ] \n ", yytext); return OP_MENOS; }
"*"                         { printf("OP_VEZES: [ %s ] \n ", yytext); return OP_VEZES; }
"/"                         { printf("OP_DIV: [ %s ] \n ", yytext); return OP_DIV; }
"++"		                { printf("INCR: [ %s ] \n ", yytext); return INCR; }
"--"                        { printf("DECR: [ %s ] \n ", yytext); return DECR; }
"&&"                        { printf("OL_AND: [ %s ] \n ", yytext); return OL_AND; }	
"||"                        { printf("OL_OR: [ %s ] \n ", yytext); return OL_OR; }		
"<"                         { printf("OL_MENOR: [ %s ] \n ", yytext); return OL_MENOR; }
"<="                        { printf("OL_MENIG: [ %s ] \n ", yytext); return OL_MENIG; }	
">"                         { printf("OL_MAIOR: [ %s ] \n ", yytext); return OL_MAIOR; }
">="                        { printf("OL_MAIIG: [ %s ] \n ", yytext); return OL_MAIIG; }	
"!"		                    { printf("NOTOP: [ %s ] \n ", yytext); return NOTOP; }
"=="                        { printf("OL_IGUAL: [ %s ] \n ", yytext); return OL_IGUAL; }
"!="                        { printf("OL_DIF: [ %s ] \n ", yytext); return OL_DIF; }
"="                         { printf("ALLOC : [ %s ] \n ", yytext); return ALLOC; }
"("		                    { printf("LP: [ %s ] \n ", yytext); return LP; } 		
")"		                    { printf("RP -> [ %s ] \n ", yytext); return RP; }		
"{"		                    { printf("LC -> [ %s ] \n ", yytext); return LC; }		
"}"		                    { printf("RC -> [ %s ] \n ", yytext); return RC; }		
"["		                    { printf("LB -> [ %s ] \n ", yytext); return LB; }		
"]"		                    { printf("RB -> [ %s ] \n ", yytext); return RB; }		
","       	                { printf("VIRGULA: [ %s ] \n ", yytext); return VIRGULA; }
{decimal}                   { yylval.floatNum = atof(yytext); printf("FLOAT_NUM: [ %s ] \n ", yytext); return FLOAT_NUM; }
{integer}                   { yylval.intNum = atoi(yytext); printf("INT_NUM: [ %s ] \n ", yytext); return INT_NUM; }
";"		                    { printf("PV: [ %s ] \n ", yytext); return PV; }
[\n]                        { contaLinha++; }
[ \t]*                      { ; }
.                           {  return yytext[0]; }

%%