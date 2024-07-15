%{
// flex++ arq_flex.l
// g++ lex.yy.cc -std=c++11 -o exec


//	flex arq_flex.l
//	gcc -o exec lex.yy.c -lfl

//	./exec

//{space}           { printf("SPACE: %s (%d)\n", yytext); }

#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>

extern int yylex();
extern FILE *yyin;



%}
%option noyywrap

letra     [a-zA-Z]
delim     [ \t\n]
space     {delim}+
num       [0-9]
integer   [-]?{num}+
decimal   {num}+(\.{num}+)
id        {letra}[a-zA-Z0-9\_]*
operator  "+"|"-"|"*"|"/" 
op_logic  "&&"|"||"|"<"|"<="|"=>"|">"|"=="|"!=" 
alloc     "="|"+="|"-="
tk_print  "printf"
tk_scan   "scanf"	
tk_loop	  "while"|"for"|"do"
tk_type	  "int"|"float"|"char"|"struct"
key_words "return"|"if"|"else"|"switch"|"case"|"default"|"main"|"break"|"strlen"
tk_include ^"#include"[ ]*<.+\.h>
tk_lp	   "("
tk_rp      ")"          
tk_lc      "{"
tk_rc	   "}"
tk_lb      "["
tk_rb      "]"
tk_pv	   ";"


%%
{decimal}         { printf("FLOAT: %s", yytext); }
{letra}           { printf("CHAR: %s", yytext); }
{tk_print}	  { printf("TK_PRINT: %s ", yytext); }
{tk_scan}  	  { printf("TK_SCAN: %s ", yytext); }
{tk_loop} 	  { printf("TK_LOOP: %s ", yytext); }
{tk_type} 	  { printf("TK_TYPE: %s ", yytext); }
{key_words} 	  { printf("KEY_WORDS: %s ", yytext); }
{id}              { printf("VAR Identifier: %s", yytext ); }
{operator}        { printf("OPERATOR: %s", yytext ); }
{op_logic}        { printf("OPERATOR LOGIC: %s ", yytext); }
{alloc}           { printf("RECEIVE: %s ", yytext); }
{tk_include}	  { printf("INCLUDE: %s ", yytext); }
{tk_lp}		  { printf("LP (: %s ", yytext); }
{tk_rp}		  { printf("RP ): %s ", yytext); }
{tk_lc}		  { printf("LC {: %s ", yytext); }
{tk_rc}		  { printf("RC }: %s ", yytext); }
{tk_lb}		  { printf("LB [: %s ", yytext); }
{tk_rb}		  { printf("RB ]: %s ", yytext); }
{integer}         { printf("INT: %s", yytext); }
{tk_pv}		  { printf("FIM: %s", yytext); }
 .                { printf("Unrecognized character: %s", yytext ); }

%%

int main() {
  FILE* arq;
  arq = fopen("entrada_comp.txt", "r");
  
  if (arq == NULL){
    printf("Problemas na CRIACAO do arquivo\n");
    return 0;
  }
  
  yyin = arq;
  yylex(); 
  
  fclose(arq);
  
  return 0;
}

