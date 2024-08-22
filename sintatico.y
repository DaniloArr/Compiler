%{
    /* COMO RODAR 
    	yacc -v -d sintatico.y
    	lex lexico.l
    	gcc y.tab.c -o exec -lfl
    */
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include"lex.yy.c"
    
    extern int yylex();
    extern int yyparse();
    extern FILE *yyin;

    int buscaSimbRepetido(char *);
    void adicionaSimbTabela(char, const char *); 
    void getIdentifier(char, const char *); 
    void salvaTipagemVar();
    void salvaTipagemConst(char *);
    
    void verificaVarDeclarada(char *);
    int verificaPalavraReservada(char *);
    void multiplaDeclaracao(char *);
    char *getTipagem(char *);
    int countErroSemantico = 0;
    int countWarningSemantico = 0;
    char errors[10][100];
    char warnings[10][100];
    char arrayPalavrasReservadas[15][15] = {"int", "float", "char", "void", "if", "else", "for", "while", "main", "return", "include", "printf", "scanf"};

    void yyerror(const char *s);


    char tipo[10];
    extern int contaLinha;
    int count = 0;
    int f;
    
    int yylex();

    
    struct tabela {
            char* simbolo;
            char* token;
            char* tipoToken;
            /*  __TIPO TOKENS__
            INCLUDES -> includes pertencentes as bibliotecas do C
            KEYWORDS -> palavras reservadas: int, for, void, char
            VARIAVEIS-> declaracoes feitas pelo usuario
            CONST    -> qualquer letra, numero ou palavra
            FUNCAO   -> palavras reservadas para nomear funcoes especificas
            */
            char* tipagem;
            int linha;
            struct tabela *next;
    };

    typedef struct tabela tabela;  

    tabela *inicio;
    tabela *final;

    struct arvore* criaArvore(struct arvore *noEsq, struct arvore *noDir, char *token);
    void printArvore(struct arvore *);

    struct arvore *topo;

    struct arvore {
      struct arvore *noEsq;
      struct arvore *noDir;
      char *token;
    };

    
%}
    

%union{
      struct variaveis {
        char nome[50];
        struct arvore* noArv;
      } noObj;

      struct variaveis1 {
        char nome[50];
        struct arvore* noArv;
        char typeVar[10];
      } noObj1;
}


%token <noObj> CHAR PRINTF SCANF FOR INT FLOAT DOUBLE IF ELSE RETURN MAIN VOID OP_MAIS OP_MENOS OP_VEZES OP_DIV OL_AND OL_OR OL_MENOR OL_MENIG OL_MAIOR OL_MAIIG OL_IGUAL OL_DIF INCDEC ALLOC INCLUDE NOTOP LP RP LC RC LB RB PV VIRGULA REFER IDENTIFIER STRING INT_NUM FLOAT_NUM CHARACTER 
%type  <noObj> program include inicio estrutura tipagem declaracao valor variaveis array declaravar if_statement else else_opc for_statement inicio_for printf_statement scanf_statement retorno tail operadores op_logicos printf_args printf_params scanf_args return_param functions function function_head parameters types_param declara_func param
%type  <noObj1> atribuir receive_value expressao constantes chama_func var_aux 
%start program 

%%

program: include declara_func inicio LP RP LC estrutura RC functions {
    struct arvore *ramo1 = criaArvore($2.noArv, $9.noArv, "function");
    struct arvore *ramo2 = criaArvore($7.noArv, ramo1, "main");
    $3.noArv = ramo2;
    $$.noArv = criaArvore($1.noArv, $3.noArv, "program");
    topo = $$.noArv;
  }
| include inicio LP RP LC estrutura RC functions {
    struct arvore *ramo1 = criaArvore(NULL, $8.noArv, "function");
    struct arvore *ramo2 = criaArvore($6.noArv, ramo1, "main");
    $2.noArv = ramo2;
    $$.noArv = criaArvore($1.noArv, $2.noArv, "program");
    topo = $$.noArv;
  }
;

include: include include { $$.noArv = criaArvore($1.noArv, $2.noArv, "INCLUDES"); }
| INCLUDE { adicionaSimbTabela('I', "INCLUDE"); } { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
;

declara_func: tipagem IDENTIFIER { adicionaSimbTabela('F', "FUNCTION"); } LP types_func RP PV { 
  $2.noArv = criaArvore(NULL, NULL, $2.nome); 
  $$.noArv = criaArvore($2.noArv , NULL, "declara_func"); 
} 
;

types_func: type_func 
| 
;

type_func: tipagem VIRGULA type_func
| tipagem
;

inicio: tipagem MAIN { adicionaSimbTabela('F', "MAIN"); }
| tipagem IDENTIFIER { adicionaSimbTabela('F', "FUNCTION"); } { $$.noArv = criaArvore(NULL, NULL, $2.nome); }
;

functions: function function  { $$.noArv = criaArvore($1.noArv, $2.noArv, "+1FUNC"); }
| function { $$.noArv = $1.noArv; }
| { $$.noArv = NULL; }
;

function: function_head tail { $$.noArv = criaArvore($1.noArv, $2.noArv, "bloco_func"); }
;

function_head: inicio LP param_func RP { $$.noArv = $1.noArv; }
;

param_func: parameters 
| 
;

parameters: tipagem IDENTIFIER VIRGULA parameters { getIdentifier('V', $2.nome); }
| tipagem IDENTIFIER { getIdentifier('V', $2.nome); }
;

estrutura: declaracao  { $$.noArv = $1.noArv; }
| declaracao estrutura { $$.noArv = criaArvore($1.noArv, $2.noArv, "estrutura"); }
;

declaracao: declaravar  { $$.noArv = $1.noArv; }
| chama_func            { $$.noArv = $1.noArv; } 
| if_statement          { $$.noArv = $1.noArv; } 
| for_statement         { $$.noArv = $1.noArv; }
| atribuir              { $$.noArv = $1.noArv; }
| printf_statement      { $$.noArv = $1.noArv; }
| scanf_statement       { $$.noArv = $1.noArv; }
| retorno               { $$.noArv = $1.noArv; }
;

declaravar: tipagem valor PV { $$.noArv = $2.noArv; }
;

tipagem: INT 	{ salvaTipagemVar(); adicionaSimbTabela('K', "INT"); }
| FLOAT 	{ salvaTipagemVar(); adicionaSimbTabela('K', "FLOAT"); }
| CHAR 		{ salvaTipagemVar(); adicionaSimbTabela('K', "CHAR"); }
| VOID 		{ salvaTipagemVar(); adicionaSimbTabela('K', "VOID"); }
| DOUBLE 	{ salvaTipagemVar(); adicionaSimbTabela('K', "DOUBLE"); }
;


valor: variaveis VIRGULA valor  { $$.noArv = criaArvore($1.noArv, $3.noArv, ""); }
| variaveis ALLOC constantes  { 

  char *tipag = getTipagem($1.nome);
  if(strcmp(tipag, $3.typeVar) == 0){
    $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome);
  } else {
    if(strcmp(tipag, "int") == 0){
        if(strcmp($3.typeVar, "string") == 0){

          sprintf(warnings[countWarningSemantico], "Linha %d: Declaracao da variavel \"%s\" como \'int\' para \'char*\' sem cast. \n", contaLinha, $1.nome);
          countWarningSemantico++;

          struct arvore *ramo = criaArvore(NULL, $3.noArv, "semCast");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $3.noArv, "parseInt");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        }
      } else if(strcmp(tipag, "float") == 0){
        if(strcmp($3.typeVar, "string") == 0){
          sprintf(errors[countErroSemantico], "Linha %d: Variavel \"%s\" do tipo \'float\' incompativel com o tipo \'char*\' da variavel %s. \n", contaLinha, $1.nome, $3.nome);
          countErroSemantico++;

          struct arvore *ramo = criaArvore(NULL, $3.noArv, "invalid");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $3.noArv, "parseFloat");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        }
      } else if(strcmp(tipag, "char") == 0) {
        if(strcmp($3.typeVar, "string") == 0){
          sprintf(warnings[countWarningSemantico], "Linha %d: Declaracao da variavel \"%s\" como \'char\' para \'char*\' sem cast. \n", contaLinha, $1.nome);
          countWarningSemantico++;

          struct arvore *ramo = criaArvore(NULL, $3.noArv, "semCast");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $3.noArv, "toChar");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        }
      }
  }
  
}
  
| variaveis ALLOC var_aux     { 

  char *tipag = getTipagem($1.nome);
  if(strcmp(tipag, $3.typeVar) == 0){
    $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome);
  } else {
    if(strcmp(tipag, "int") == 0){
        if(strcmp($3.typeVar, "string") == 0){

          sprintf(warnings[countWarningSemantico], "Linha %d: Declaracao da variavel \"%s\" como \'int\' para \'char*\' sem cast. \n", contaLinha, $1.nome);
          countWarningSemantico++;

          struct arvore *ramo = criaArvore(NULL, $3.noArv, "semCast");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $3.noArv, "parseInt");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        }
      } else if(strcmp(tipag, "float") == 0){
        if(strcmp($3.typeVar, "string") == 0){
          sprintf(errors[countErroSemantico], "Linha %d: Variavel \"%s\" do tipo \'float\' incompativel com o tipo \'char*\' da variavel %s. \n", contaLinha, $1.nome, $3.nome);
          countErroSemantico++;

          struct arvore *ramo = criaArvore(NULL, $3.noArv, "invalid");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $3.noArv, "parseFloat");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        }
      } else if(strcmp(tipag, "char") == 0) {
        if(strcmp($3.typeVar, "string") == 0){
          sprintf(warnings[countWarningSemantico], "Linha %d: Declaracao da variavel \"%s\" como \'char\' para \'char*\' sem cast. \n", contaLinha, $1.nome);
          countWarningSemantico++;

          struct arvore *ramo = criaArvore(NULL, $3.noArv, "semCast");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $3.noArv, "toChar");
          $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
        }
      }
  }
}
| variaveis { $$.noArv = $1.noArv; }
;

variaveis: IDENTIFIER  array   { 
  getIdentifier('A', $1.nome); 
  $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| IDENTIFIER { 
  getIdentifier('V', $1.nome); 
  $$.noArv = criaArvore(NULL, NULL, $1.nome); }
;

var_aux: IDENTIFIER  array   { 
  strcpy($$.nome, $1.nome);
  char *tipag = getTipagem($1.nome);
  sprintf($$.typeVar, tipag);
  verificaVarDeclarada($1.nome); 
  $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| IDENTIFIER   { 
  strcpy($$.nome, $1.nome);
  char *tipag = getTipagem($1.nome);
  sprintf($$.typeVar, tipag);
  verificaVarDeclarada($1.nome); 
  $$.noArv = criaArvore(NULL, NULL, $1.nome); }
;


array: array LB INT_NUM RB 
| LB INT_NUM RB  
| LB IDENTIFIER RB  { verificaVarDeclarada($2.nome);} 
;

constantes: INT_NUM { salvaTipagemConst("int"); sprintf($$.typeVar, "int"); adicionaSimbTabela('C', "INT_NUM");   $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| FLOAT_NUM         { salvaTipagemConst("float"); sprintf($$.typeVar, "float"); adicionaSimbTabela('C', "FLOAT_NUM"); $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| STRING            { salvaTipagemConst("string"); sprintf($$.typeVar, "string"); adicionaSimbTabela('C', "STRING");    $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| CHARACTER         { salvaTipagemConst("char"); sprintf($$.typeVar, "char"); adicionaSimbTabela('C', "CHARACTER"); $$.noArv = criaArvore(NULL, NULL, $1.nome); }
;

if_statement: IF { adicionaSimbTabela('K', "IF"); } LP expressao RP tail else {
    struct arvore *iff = criaArvore($4.noArv, $6.noArv, $1.nome);
    $$.noArv = criaArvore(iff, $7.noArv, "ifelse");
  };

else: ELSE { adicionaSimbTabela('K', "ELSE"); }  else_opc { $$.noArv = criaArvore(NULL, $3.noArv, $1.nome); }
| /*sem else*/ { $$.noArv = NULL; }
; 

else_opc: tail { $$.noArv = $1.noArv; } /*para quando eh soh um else*/
| estrutura    { $$.noArv = $1.noArv; } /*para quando eh um else if*/
;

for_statement: FOR { adicionaSimbTabela('K', "FOR"); }  LP inicio_for PV expressao PV expressao RP tail {
    struct arvore *cond1 = criaArvore($6.noArv, $8.noArv, "COND 2");
    struct arvore *cond2 = criaArvore($4.noArv, cond1, "COND 1");
    $$.noArv = criaArvore(cond2, $10.noArv, $1.nome);
  }
;

inicio_for: IDENTIFIER ALLOC constantes  { $1.noArv = criaArvore(NULL, NULL, $1.nome); $$.noArv = criaArvore($1.noArv, $3.noArv, "="); }
| tipagem IDENTIFIER ALLOC constantes    { $2.noArv = criaArvore(NULL, NULL, $2.nome); $$.noArv = criaArvore($2.noArv, $4.noArv, "="); }
;

tail: LC estrutura RC { $$.noArv = $2.noArv; }
;

/* ______________ */

expressao: expressao operadores expressao { 
  if(strcmp($1.typeVar, $3.typeVar) == 0){
    sprintf($$.typeVar, $1.typeVar);
    $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome);  
  } else {
    if(strcmp($1.typeVar, "int") == 0){
      if(strcmp($3.typeVar, "float") == 0){
        struct arvore *ramo = criaArvore(NULL, $1.noArv, "opIntFloat");
        sprintf($$.typeVar, $3.typeVar);
        $$.noArv = criaArvore(ramo, $3.noArv, $2.nome);

      } else if(strcmp($3.typeVar, "char") == 0){
        struct arvore *ramo = criaArvore(NULL, $1.noArv, "opIntChar");
        sprintf($$.typeVar, $1.typeVar);
        $$.noArv = criaArvore(ramo, $3.noArv, $2.nome);

      } else {
        struct arvore *ramo = criaArvore(NULL, $1.noArv, "opIntChar*");
        sprintf($$.typeVar, $3.typeVar);
        $$.noArv = criaArvore(ramo, $3.noArv, $2.nome);
      }
    } else if(strcmp($1.typeVar, "float") == 0){
      if(strcmp($3.typeVar, "int")== 0){
        struct arvore *ramo = criaArvore(NULL, $3.noArv, "opFloatInt");
        sprintf($$.typeVar, $1.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);

      } else if(strcmp($3.typeVar, "char")){
        struct arvore *ramo = criaArvore(NULL, $3.noArv, "opFloatChar");
        sprintf($$.typeVar, $1.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);

      } else {
        sprintf(errors[countErroSemantico], "Linha %d: Operacao invalida entre \'float\' e \'char*\'. \n", contaLinha, $1.nome);
        countErroSemantico++;

        struct arvore *ramo = criaArvore(NULL, $3.noArv, "invalid");
        sprintf($$.typeVar, $3.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
      }
    } else if(strcmp($1.typeVar, "char") == 0){
      if(strcmp($3.typeVar, "float") == 0){
        struct arvore *ramo = criaArvore(NULL, $3.noArv, "opCharFloat");
        sprintf($$.typeVar, $1.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
      } else if(strcmp($3.typeVar, "int") == 0){
        struct arvore *ramo = criaArvore(NULL, $3.noArv, "opCharInt");
        sprintf($$.typeVar, $1.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
      } else {
        struct arvore *ramo = criaArvore(NULL, $3.noArv, "opCharChar*");
        sprintf($$.typeVar, $3.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
      }
    } else {
      if(strcmp($3.typeVar, "float") == 0){
        struct arvore *ramo = criaArvore(NULL, $3.noArv, "opChar*Float");
        sprintf($$.typeVar, $1.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
      } else if(strcmp($3.typeVar, "int") == 0){
        struct arvore *ramo = criaArvore(NULL, $3.noArv, "opChar*Int");
        sprintf($$.typeVar, $3.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
      } else {
        struct arvore *ramo = criaArvore(NULL, $3.noArv, "opChar*Char");
        sprintf($$.typeVar, $1.typeVar);
        $$.noArv = criaArvore($1.noArv, ramo, $2.nome);
      }
    }
  }
}
| expressao op_logicos expressao          { $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome); }
| expressao INCDEC      { $2.noArv = criaArvore(NULL, NULL, $2.nome); $$.noArv = criaArvore($1.noArv, $2.noArv, "INCDEC"); }
| NOTOP expressao       { $1.noArv = criaArvore(NULL, NULL, $1.nome); $$.noArv = criaArvore($1.noArv, $2.noArv, "DIFF"); }
| var_aux               { strcpy($$.nome, $1.nome); sprintf($$.typeVar, $1.typeVar); $$.noArv = $1.noArv; }
| constantes            { strcpy($$.nome, $1.nome); sprintf($$.typeVar, $1.typeVar); $$.noArv = $1.noArv; }
| chama_func            { $$.noArv = $1.noArv; }
;

operadores: OP_MAIS
| OP_MENOS
| OP_VEZES
| OP_DIV
;

op_logicos: OL_OR
| OL_AND
| OL_IGUAL
| OL_DIF
| OL_MENOR
| OL_MENIG
| OL_MAIOR
| OL_MAIIG
;

atribuir: IDENTIFIER array { verificaVarDeclarada($1.nome); } ALLOC receive_value {
    $1.noArv = criaArvore(NULL, NULL, $1.nome);
    char *typeIdent = getTipagem($1.nome);
    if(strcmp(typeIdent,$5.typeVar) == 0){
      $$.noArv = criaArvore($1.noArv, $5.noArv, $4.nome);
    } else {
      if(strcmp(typeIdent, "int") == 0){
        if(strcmp($5.typeVar, "string")== 0){

          sprintf(warnings[countWarningSemantico], "Linha %d: Declaracao da variavel \"%s\" como \'int\' para \'char*\' sem cast. \n", contaLinha, $1.nome);
          countWarningSemantico++;

          struct arvore *ramo = criaArvore(NULL, $5.noArv, "semCast");
          $$.noArv = criaArvore($1.noArv, ramo, $4.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $5.noArv, "parseInt");
          $$.noArv = criaArvore($1.noArv, ramo, $4.nome);
        }
      } else if(strcmp(typeIdent, "float") == 0){
        if(strcmp($5.typeVar, "string") == 0){
          sprintf(errors[countErroSemantico], "Linha %d: Variavel \"%s\" do tipo \'float\' incompativel com o tipo \'char*\'. \n", contaLinha, $1.nome);
          countErroSemantico++;

          struct arvore *ramo = criaArvore(NULL, $5.noArv, "invalid");
          $$.noArv = criaArvore($1.noArv, ramo, $4.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $5.noArv, "parseFloat");
          $$.noArv = criaArvore($1.noArv, ramo, $4.nome);
        }
      } else if(strcmp(typeIdent, "char") == 0){  
        if(strcmp($5.typeVar, "string") == 0){
          sprintf(errors[countErroSemantico], "Linha %d: Variavel \"%s\" do tipo \'float\' incompativel com o tipo \'char*\'. \n", contaLinha, $1.nome);
          countErroSemantico++;

          struct arvore *ramo = criaArvore(NULL, $5.noArv, "invalid");
          $$.noArv = criaArvore($1.noArv, ramo, $4.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $5.noArv, "parseFloat");
          $$.noArv = criaArvore($1.noArv, ramo, $4.nome);
        }
      }
    }
  }
| IDENTIFIER { verificaVarDeclarada($1.nome); } ALLOC receive_value {
    $1.noArv = criaArvore(NULL, NULL, $1.nome);
    char *typeIdent = getTipagem($1.nome);

    if(strcmp(typeIdent,$4.typeVar) == 0){
      $$.noArv = criaArvore($1.noArv, $4.noArv, $3.nome);
    } else {
      if(strcmp(typeIdent, "int") == 0){
        if(strcmp($4.typeVar, "string") == 0){

          sprintf(warnings[countWarningSemantico], "Linha %d: Declaracao da variavel \"%s\" como \'int\' para \'char*\' sem cast. \n", contaLinha, $1.nome);
          countWarningSemantico++;

          struct arvore *ramo = criaArvore(NULL, $4.noArv, "invalid");
          $$.noArv = criaArvore($1.noArv, ramo, $3.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $4.noArv, "parseInt");
          $$.noArv = criaArvore($1.noArv, ramo, $3.nome);
        }
      } else if(strcmp(typeIdent, "float") == 0){
        if(strcmp($4.typeVar, "string") == 0){
          sprintf(errors[countErroSemantico], "Linha %d: Variavel \"%s\" do tipo \'float\' incompativel com o tipo \'char*\'. \n", contaLinha, $1.nome);
          countErroSemantico++;

          struct arvore *ramo = criaArvore(NULL, $4.noArv, "invalid");
          $$.noArv = criaArvore($1.noArv, ramo, $3.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $4.noArv, "parseFloat");
          $$.noArv = criaArvore($1.noArv, ramo, $3.nome);
        }
      } else if(strcmp(typeIdent, "char") == 0) {
        if(strcmp($4.typeVar, "string") == 0){
          sprintf(warnings[countWarningSemantico], "Linha %d: Declaracao da variavel \"%s\" como \'char\' para \'char*\' sem cast. \n", contaLinha, $1.nome);
          countWarningSemantico++;

          struct arvore *ramo = criaArvore(NULL, $4.noArv, "semCast");
          $$.noArv = criaArvore($1.noArv, ramo, $3.nome);
        } else {
          struct arvore *ramo = criaArvore(NULL, $4.noArv, "toChar");
          $$.noArv = criaArvore($1.noArv, ramo, $3.nome);
        }
      }
    }
  }
; 

receive_value: expressao PV { $$.noArv = $1.noArv; }
| chama_func { $$.noArv = $1.noArv; }
;

printf_statement: PRINTF { adicionaSimbTabela('K', "PRINTF"); } printf_args PV { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
;

printf_args: LP var_aux RP  
| LP STRING RP
| LP STRING VIRGULA printf_params RP  
;

printf_params:  param 
| param VIRGULA printf_params 
;

param: constantes {  $$.noArv = $1.noArv;  }
| var_aux  {  $$.noArv = $1.noArv; }
;

scanf_statement:  SCANF { adicionaSimbTabela('K', "SCANF"); }  LP STRING VIRGULA scanf_args RP PV { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
;

scanf_args: REFER var_aux VIRGULA scanf_args  
| REFER var_aux  
;

retorno: RETURN { adicionaSimbTabela('K', "RETURN"); } return_param PV { $1.noArv = criaArvore(NULL, NULL, $1.nome); $$.noArv = criaArvore($1.noArv, $3.noArv, "RETURN"); }
;

return_param: constantes {  $$.noArv = $1.noArv;  }
| IDENTIFIER  {  $$.noArv = criaArvore(NULL, NULL, $1.nome); verificaVarDeclarada($1.nome); }
| /*vazio*/   {  $$.noArv = NULL;  }
;

chama_func: IDENTIFIER { verificaVarDeclarada($1.nome); } LP types_param RP PV { 
    strcpy($$.nome, $1.nome);
    char *tipag = getTipagem($1.nome); 
    sprintf($$.typeVar, tipag); 
    
    $1.noArv = criaArvore(NULL, NULL, $1.nome); 
    $$.noArv = criaArvore($1.noArv, $4.noArv, "call_func"); 
  }
;

types_param: IDENTIFIER { $$.noArv = criaArvore(NULL, NULL, $1.nome); verificaVarDeclarada($1.nome); }
| STRING                { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| CHARACTER             { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
|                       { $$.noArv = NULL; }
;


%%

int main() {
  FILE* arq;
  arq = fopen("entrada.txt", "r");
  
  if (arq == NULL){
    printf("Problemas na CRIACAO do arquivo\n");
    return 0;
  }
  
  yyin = arq;

  yyparse(); 

  fclose(arq);

  printf("\n\n");
  printf("\tTABELA DE SIMBOLOS \n\n");
  printf("_______________________________________\n\n");
  printf("SIMBOLO - TKN - TIPO_TKN - TIPAGEM - LINHA \n\n");


  tabela *tabSimb;
  tabSimb = inicio;

  while(tabSimb != NULL){
      printf("%s - %s - %s - %s - %d\n", 
      tabSimb->simbolo, 
      tabSimb->token, 
      tabSimb->tipoToken, 
      tabSimb->tipagem,
      tabSimb->linha
      );
      tabSimb = tabSimb->next;
  }

	/*
    while(tabSimb != NULL){
    printf("%s - %s - %s -  %d\n", 
      tabSimb->simbolo, 
      tabSimb->token, 
      tabSimb->tipoToken, 
      tabSimb->linha
    );
    tabSimb = tabSimb->next;
  }
    

    for(i=0;i<count;i++) {
		free(tabelaSimbolos[i].simbolo);
		free(tabelaSimbolos[i].token);
    free(tabelaSimbolos[i].tipoToken);
	}*/
	printf("\n\n");
  printf("_______________________________________\n\n");
  printf("IMPRIMINDO ARVORE \n\n");
  printArvore(topo);
  printf("\n\n");

  printf("_______________________________________\n\n");
  printf("VERIFICANDO SEMANTICA \n\n");

  if(countErroSemantico > 0) {
		printf("Foram encontrados %d erros: \n", countErroSemantico);
		for(int i = 0; i < countErroSemantico; i++){
			printf("\t -> %s", errors[i]);
		}
	} 

  if(countWarningSemantico > 0){
    printf("Foram encontrados %d warnings: \n", countWarningSemantico);
		for(int i = 0; i < countWarningSemantico; i++){
			printf("\t -> %s", warnings[i]);
		}
  }
  if((countErroSemantico == 0) && (countWarningSemantico == 0)){
		printf("NENHUM ERRO NA ANALISE SEMANTICA - DEUS EH BOM ");
	}

  printf("\n\n");
  return 0;
}

int buscaSimbRepetido(char *simb) { 
  tabela *tabSimb;
  tabSimb = inicio;
  while(tabSimb != NULL){
    if(strcmp(tabSimb->simbolo, simb) == 0) {   
          return 1;
          break;  
      }
    tabSimb = tabSimb->next;
  }
  return 0;
}

void adicionaSimbTabela(char tipoTkn, const char *tkn) {
  
  tabela *tabSimb;

  int simboloRepetido = 0;

  tabSimb = (tabela *) malloc(sizeof(tabela)); 
  tabSimb->simbolo = malloc(strlen(yytext) + 1);
  tabSimb->token = malloc(strlen(tkn) + 1);
  tabSimb->tipoToken = malloc(8);
  tabSimb->tipagem = malloc(11);
  if(inicio == NULL){
    inicio = tabSimb;
    final = tabSimb;
  } else {
    simboloRepetido = buscaSimbRepetido(yytext);
  }

  if(simboloRepetido == 0) {
    strcpy(tabSimb->simbolo, yytext);
    strcpy(tabSimb->token, tkn);
    
    tabSimb->linha = contaLinha;

    switch(tipoTkn) {
        case 'I':
            strcpy(tabSimb->tipoToken, "Include");
            strcpy(tabSimb->tipagem, "N/A");
            break;
        case 'K':
            strcpy(tabSimb->tipoToken, "Keyword");
            strcpy(tabSimb->tipagem, "N/A");
            break;
        case 'V':
            strcpy(tabSimb->tipoToken, "Variavel");
            strcpy(tabSimb->tipagem, tipo);
            break;
        case 'C':
            strcpy(tabSimb->tipoToken, "Const");
            strcpy(tabSimb->tipagem, tipo);
            break;
        case 'F':
            strcpy(tabSimb->tipoToken, "Funcao");
            strcpy(tabSimb->tipagem, tipo);
            break;
    }

    if(final != tabSimb){
      final->next = tabSimb;
      final = tabSimb;
    }

  }

}

void getIdentifier(char tipoTkn, const char *id) {
  
  char *idVar;
  idVar = malloc(strlen(id) + 1);
  strcpy(idVar, id);

  if (verificaPalavraReservada(idVar) == 1){
    return;
  }
  
  tabela *tabSimb;
  
  
  int simboloRepetido = 0;

  tabSimb = (tabela *) malloc(sizeof(tabela)); 
  tabSimb->simbolo = malloc(strlen(id) + 1);
  //IDENTIFIER
  tabSimb->token = malloc(11);
  //Variavel
  tabSimb->tipoToken = malloc(9);
  //tipagem
  tabSimb->tipagem = malloc(11);

  if(inicio == NULL){
    inicio = tabSimb;
    final = tabSimb;
  } else {
    simboloRepetido = buscaSimbRepetido(idVar);
  }

  if(simboloRepetido == 0) {
    strcpy(tabSimb->simbolo, id);
    strcpy(tabSimb->token, "IDENTIFIER");
    if( 'V' == tipoTkn ){
      strcpy(tabSimb->tipoToken, "var");
    } else {
      strcpy(tabSimb->tipoToken, "array");
    }
    strcpy(tabSimb->tipagem, tipo);
    tabSimb->linha = contaLinha;

    if(final != tabSimb){
      final->next = tabSimb;
      final = tabSimb;
    }
  } else {
    multiplaDeclaracao(idVar);
  }
}


struct arvore* criaArvore(struct arvore *noEsq, struct arvore *noDir, char *token) {
  struct arvore *novoNoh = (struct arvore*) malloc(sizeof(struct arvore));
  char *strToken = (char*) malloc(strlen(token) + 1);
  strcpy(strToken, token);

  novoNoh->noEsq = noEsq;
  novoNoh->noDir = noDir;
  novoNoh->token = strToken;

  return(novoNoh);
}

void printArvore(struct arvore *arv){
  if (arv->noEsq) {
		printArvore(arv->noEsq);
	}
	printf("%s, ", arv->token);
	if (arv->noDir) {
		printArvore(arv->noDir);
	}
}

/**/

void salvaTipagemVar() {
	strcpy(tipo, yytext);
}

void salvaTipagemConst(char *type){
  strcpy(tipo, type);
}

/*FUNCTIONS SEMANTICAS*/

/*fazer um código semantico para verificar se a variavel foi inicia */
void verificaVarDeclarada(char *id){
  int varDeclarada = 0;
  extern int yylineno; 
  tabela *tabSimb;
  tabSimb = (tabela *) malloc(sizeof(tabela)); 

  if(inicio == NULL){
    inicio = tabSimb;
    final = tabSimb;
  } else {
    varDeclarada = buscaSimbRepetido(id);    
  }
  if(varDeclarada == 0) {        
      sprintf(errors[countErroSemantico], "Linha %d: Variavel \"%s\" nao declarada \n", yylineno, id);  
      countErroSemantico++;    
  }
}

int verificaPalavraReservada(char *id){
  extern int yylineno; 
  for(int i=0; i<15; i++){
    if(!strcmp(arrayPalavrasReservadas[i], strdup(id))){
        sprintf(errors[countErroSemantico], "Linha %d: Variavel utilizada: \"%s\" estah usando um termo reservado\n", yylineno, id);
        countErroSemantico++;
      return 1;
    }
  }
  return 0;
}

void multiplaDeclaracao(char *id){
  extern int yylineno; 
  sprintf(errors[countErroSemantico], "Linha %d: Variavel \"%s\" ja declarada anteriormente\n", yylineno, id);
  countErroSemantico++;
}

char *getTipagem(char *var){
  tabela *tabSimb;
  tabSimb = inicio;
  while(tabSimb != NULL){
    if(strcmp(tabSimb->simbolo, var) == 0) {   
          return tabSimb->tipagem; 
      }
    tabSimb = tabSimb->next;
  }
}

void verificaTipagemRetorno(char *valor){
  char *main_datatype = getTipagem("main");
	char *return_datatype = getTipagem(valor);
}

/*fazer um código semantico para verificar se o valor que ela tá recebendo é do mesmo tipo*/



void yyerror(const char *s)
{
    extern int yylineno;    // Linha atual do código sendo analisado
    extern char *yytext;    // Último token lido pelo analisador léxico

    fprintf(stderr, " -> Erro na linha %d; ** %s ** <- \n", yylineno, yytext);
    exit(1);
}