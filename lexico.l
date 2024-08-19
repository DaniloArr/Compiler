%{

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "y.tab.h"

int contaLinha = 1;


void yyerror();
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
character \'{ascii}*\'
tk_point  "*"{id}
tk_include ^"#include"[ ]*<.+\.h>
incdec "++"|"--"



%%
printf		                { strcpy(yylval.noObj.nome,(yytext)); printf("PRINTF: [ %s ] \n ", yytext); return PRINTF; }
scanf  	      	            { strcpy(yylval.noObj.nome,(yytext)); printf("SCANF: [ %s ] \n ", yytext); return SCANF; }
for	   	                    { strcpy(yylval.noObj.nome,(yytext)); printf("FOR: [ %s ] \n ", yytext); return FOR; }
int	    	                { strcpy(yylval.noObj.nome,(yytext)); printf("INT: [ %s ] \n ", yytext); return INT; }
float	  	                { strcpy(yylval.noObj.nome,(yytext)); printf("FLOAT: [ %s ] \n ", yytext); return FLOAT; }
double		                { strcpy(yylval.noObj.nome,(yytext)); printf("DOUBLE: [ %s ] \n ", yytext); return DOUBLE; }
char	  	                { strcpy(yylval.noObj.nome,(yytext)); printf("CHAR: [ %s ] \n ", yytext); return CHAR; }
if                          { strcpy(yylval.noObj.nome,(yytext)); printf("IF: [ %s ] \n ", yytext); return IF; }
else                        { strcpy(yylval.noObj.nome,(yytext)); printf("ELSE: [ %s ] \n ", yytext); return ELSE; }
return	 	                { strcpy(yylval.noObj.nome,(yytext)); printf("RETURN: [ %s ] \n ", yytext); return RETURN; }
main                        { strcpy(yylval.noObj.nome,(yytext)); printf("MAIN: [ %s ] \n ", yytext); return MAIN; }
void	      	            { strcpy(yylval.noObj.nome,(yytext)); printf("VOID: [ %s ] \n ", yytext); return VOID; }
{tk_include}	            { strcpy(yylval.noObj.nome,(yytext)); printf("INCLUDE: [ %s ] \n ", yytext); return INCLUDE; }
{string}                    { strcpy(yylval.noObj.nome,(yytext)); printf("STRING: [ %s ] \n ", yytext); return STRING; }
{character}                 { strcpy(yylval.noObj.nome,(yytext)); printf("CHARACTER: [ %s ] \n ", yytext); return CHARACTER; } 
{letra}({letra}|{digito})*  { strcpy(yylval.noObj.nome,(yytext)); printf("IDENTIFIER: [ %s ] \n ", yytext); return IDENTIFIER; }
"+"                         { strcpy(yylval.noObj.nome,(yytext)); printf("OP_MAIS: [ %s ] \n ", yytext); return OP_MAIS; }
"-"                         { strcpy(yylval.noObj.nome,(yytext)); printf("OP_MENOS: [ %s ] \n ", yytext); return OP_MENOS; }
"*"                         { strcpy(yylval.noObj.nome,(yytext)); printf("OP_VEZES: [ %s ] \n ", yytext); return OP_VEZES; }
"/"                         { strcpy(yylval.noObj.nome,(yytext)); printf("OP_DIV: [ %s ] \n ", yytext); return OP_DIV; }
{incdec}		            { strcpy(yylval.noObj.nome,(yytext)); printf("INCDEC: [ %s ] \n ", yytext); return INCDEC; }
"&&"                        { strcpy(yylval.noObj.nome,(yytext)); printf("OL_AND: [ %s ] \n ", yytext); return OL_AND; }	
"||"                        { strcpy(yylval.noObj.nome,(yytext)); printf("OL_OR: [ %s ] \n ", yytext); return OL_OR; }		
"<"                         { strcpy(yylval.noObj.nome,(yytext)); printf("OL_MENOR: [ %s ] \n ", yytext); return OL_MENOR; }
"<="                        { strcpy(yylval.noObj.nome,(yytext)); printf("OL_MENIG: [ %s ] \n ", yytext); return OL_MENIG; }	
">"                         { strcpy(yylval.noObj.nome,(yytext)); printf("OL_MAIOR: [ %s ] \n ", yytext); return OL_MAIOR; }
">="                        { strcpy(yylval.noObj.nome,(yytext)); printf("OL_MAIIG: [ %s ] \n ", yytext); return OL_MAIIG; }	
"!"		                    { strcpy(yylval.noObj.nome,(yytext)); printf("NOTOP: [ %s ] \n ", yytext); return NOTOP; }
"=="                        { strcpy(yylval.noObj.nome,(yytext)); printf("OL_IGUAL: [ %s ] \n ", yytext); return OL_IGUAL; }
"!="                        { strcpy(yylval.noObj.nome,(yytext)); printf("OL_DIF: [ %s ] \n ", yytext); return OL_DIF; }
"="                         { strcpy(yylval.noObj.nome,(yytext)); printf("ALLOC : [ %s ] \n ", yytext); return ALLOC; }
"&"				            { strcpy(yylval.noObj.nome,(yytext)); printf("REFER : [ %s ] \n ", yytext); return REFER; }
"("		                    { strcpy(yylval.noObj.nome,(yytext)); printf("LP: [ %s ] \n ", yytext); return LP; } 		
")"		                    { strcpy(yylval.noObj.nome,(yytext)); printf("RP: [ %s ] \n ", yytext); return RP; }		
"{"		                    { strcpy(yylval.noObj.nome,(yytext)); printf("LC: [ %s ] \n ", yytext); return LC; }		
"}"		                    { strcpy(yylval.noObj.nome,(yytext)); printf("RC: [ %s ] \n ", yytext); return RC; }		
"["		                    { strcpy(yylval.noObj.nome,(yytext)); printf("LB: [ %s ] \n ", yytext); return LB; }		
"]"		                    { strcpy(yylval.noObj.nome,(yytext)); printf("RB: [ %s ] \n ", yytext); return RB; }		
","       	                { strcpy(yylval.noObj.nome,(yytext)); printf("VIRGULA: [ %s ] \n ", yytext); return VIRGULA; }
{decimal}                   { strcpy(yylval.noObj.nome,(yytext)); printf("FLOAT_NUM: [ %s ] \n ", yytext); return FLOAT_NUM; }
{integer}                   { strcpy(yylval.noObj.nome,(yytext)); printf("INT_NUM: [ %s ] \n ", yytext); return INT_NUM; }
";"		                    { strcpy(yylval.noObj.nome,(yytext)); printf("PV: [ %s ] \n ", yytext); return PV; }
[\n]                        { contaLinha++; }
[ \t]*                      { ; }
.                           {  return *yytext; }

%%
//{letra}({letra}|{digito})*  { getIdentifier(yytext); strcpy(yylval.noObj.nome,(yytext)); printf("IDENTIFIER: [ %s ] \n ", yytext); return IDENTIFIER; }
