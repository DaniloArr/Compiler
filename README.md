# Compiler

Criando um compilar. Dividindo nas etapas entre analisador léxico, sintático e semântico.

# Requisitos

- Ter instalado as ferramentas Flex e GNU Bison

# Como rodar

yacc -v -d sintatico.y
lex lexico.l
gcc y.tab.c -o exec -lfl
