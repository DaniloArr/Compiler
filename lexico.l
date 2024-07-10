%{
//Este é um exemplo simples de um código Flex que demonstra os conceitos básicos da biblioteca.
//Ele reconhece dois tokens: 'letra' e 'número'.
%}

%option noyywrap

%%
.|\n       ECHO
%%

int main() {
  yyFlexLexer lexer;
  lexer.yylex();
  return 0;
}