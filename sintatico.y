%{
    /* COMO RODAR 
    	yyac -v -d sintatico.y
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

    extern int contaLinha;
    int count = 0;
    int f;
    
    int yylex();

	  void getIdentifier(const char *id); 
    void yyerror(const char *s);
    
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
}


%token <noObj> CHAR PRINTF SCANF FOR INT FLOAT DOUBLE IF ELSE RETURN MAIN VOID OP_MAIS OP_MENOS OP_VEZES OP_DIV OL_AND OL_OR OL_MENOR OL_MENIG OL_MAIOR OL_MAIIG OL_IGUAL OL_DIF INCDEC ALLOC INCLUDE NOTOP LP RP LC RC LB RB PV VIRGULA REFER IDENTIFIER STRING INT_NUM FLOAT_NUM CHARACTER 
%type  <noObj> program include inicio estrutura tipagem declaracao valor variaveis array constantes expressao receive_value declaravar if_statement else else_opc for_statement inicio_for atribuir printf_statement scanf_statement retorno tail operadores op_logicos sinal printf_args printf_params scanf_args return_param functions function function_head param_func parameters chama_func types_param
%start program 

%%

/*QUESTAO 1: tem que pensar nesse caso aqui para caso tem outras funcoes, acredito que do jeito que está vai dar erro
quem sabe da para utilizar o metodo do include de usar "include include", permitindo assim a repeticao */

/*QUESTAO 2: vai ter que ver a questao de parametros dentro das chamadas de funcoes */


/*da para tentar colocar mais um function_opt antes do inicio e só rearranjar no ramo1 criaArvore(1°func, 2°func, "function");*/
program: include inicio LP RP LC estrutura RC functions {
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

inicio: tipagem MAIN { adicionaSimbTabela('F', "MAIN"); }
| tipagem IDENTIFIER { adicionaSimbTabela('F', "FUNCTION"); }
;

functions: function function  { $$.noArv = criaArvore($1.noArv, $2.noArv, "+1FUNC"); }
| function { $$.noArv = $1.noArv; }
| { $$.noArv = NULL; }
;

function: function_head tail { $$.noArv = criaArvore($2.noArv, NULL, "bloco_func"); }
;

function_head: inicio LP param_func RP
;

param_func: parameters { $$.noArv = $1.noArv; }
| { $$.noArv = NULL; }
;

parameters: tipagem IDENTIFIER VIRGULA parameters 
| tipagem IDENTIFIER 
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

tipagem: INT 	{ adicionaSimbTabela('K', "INT"); }
| FLOAT 	{ adicionaSimbTabela('K', "FLOAT"); }
| CHAR 		{ adicionaSimbTabela('K', "CHAR"); }
| VOID 		{ adicionaSimbTabela('K', "VOID"); }
| DOUBLE 	{ adicionaSimbTabela('K', "DOUBLE"); }
;

valor: variaveis VIRGULA valor  { $$.noArv = criaArvore($1.noArv, $3.noArv, ""); }
| variaveis ALLOC constantes    { $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome); }
| variaveis ALLOC variaveis     { $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome); }
| variaveis { $$.noArv = $1.noArv; }
;

variaveis: IDENTIFIER { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| IDENTIFIER  array   { $$.noArv = criaArvore(NULL, NULL, $1.nome);  }
;

array: array LB INT_NUM RB 
| LB INT_NUM RB  
| LB IDENTIFIER RB
;

constantes: INT_NUM { adicionaSimbTabela('C', "INT_NUM");   $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| FLOAT_NUM         { adicionaSimbTabela('C', "FLOAT_NUM"); $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| STRING            { adicionaSimbTabela('C', "STRING");    $$.noArv = criaArvore(NULL, NULL, $1.nome); }
| CHARACTER         { adicionaSimbTabela('C', "CHARACTER"); $$.noArv = criaArvore(NULL, NULL, $1.nome); }
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

inicio_for: variaveis ALLOC constantes  { $$.noArv = criaArvore($1.noArv, $3.noArv, "="); }
| tipagem variaveis ALLOC constantes    { $$.noArv = criaArvore($1.noArv, $3.noArv, "="); }
;

tail: LC estrutura RC { $$.noArv = $2.noArv; }
;

expressao: expressao operadores expressao { $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome); }
| expressao op_logicos expressao          { $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome); }
| expressao INCDEC      { $2.noArv = criaArvore(NULL, NULL, $2.nome); $$.noArv = criaArvore($1.noArv, $2.noArv, "INCDEC"); }
| NOTOP expressao       { $1.noArv = criaArvore(NULL, NULL, $1.nome); $$.noArv = criaArvore($1.noArv, $2.noArv, "DIFF"); }
| variaveis             { $$.noArv = $1.noArv; }
| sinal constantes      { $$.noArv = criaArvore($1.noArv, $2.noArv, "valor"); }
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

atribuir: variaveis ALLOC receive_value {
    $1.noArv = criaArvore(NULL, NULL, $1.nome);
    $$.noArv = criaArvore($1.noArv, $3.noArv, $2.nome);
  }
; 

receive_value: expressao PV { $$.noArv = $1.noArv; }
| chama_func { $$.noArv = $1.noArv; }
;

sinal:  OP_MENOS { $$.noArv = criaArvore(NULL, NULL, "-"); }
| { $$.noArv = NULL; } 
;

printf_statement: PRINTF { adicionaSimbTabela('K', "PRINTF"); } printf_args PV { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
;

printf_args: LP variaveis RP  
| LP STRING RP
| LP STRING VIRGULA printf_params RP  
;

printf_params:  expressao 
| expressao VIRGULA printf_params 
;

scanf_statement:  SCANF { adicionaSimbTabela('K', "SCANF"); }  LP STRING VIRGULA scanf_args RP PV { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
;

scanf_args: REFER variaveis VIRGULA scanf_args  
| REFER variaveis  
;

retorno: RETURN { adicionaSimbTabela('K', "RETURN"); } return_param PV { $1.noArv = criaArvore(NULL, NULL, $1.nome); $$.noArv = criaArvore($1.noArv, $3.noArv, "RETURN"); }
;

return_param: INT_NUM {  $$.noArv = criaArvore(NULL, NULL, $1.nome);  }
| IDENTIFIER  {  $$.noArv = criaArvore(NULL, NULL, $1.nome);  }
| /*vazio*/   {  $$.noArv = NULL;  }
;

chama_func: IDENTIFIER LP types_param RP PV { 
    $1.noArv = criaArvore(NULL, NULL, $1.nome); 
    $$.noArv = criaArvore($1.noArv, $3.noArv, "call_func"); 
  }
;

types_param: IDENTIFIER { $$.noArv = criaArvore(NULL, NULL, $1.nome); }
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
  printf("SIMBOLO - TKN - TIPO_TKN - LINHA \n\n");


  tabela *tabSimb;
  tabSimb = inicio;

  while(tabSimb != NULL){
    printf("%s - %s - %s - %d\n", 
      tabSimb->simbolo, 
      tabSimb->token, 
      tabSimb->tipoToken, 
      tabSimb->linha
    );
    tabSimb = tabSimb->next;
  }

	/*for(i=0;i<count;i++) {
		free(tabelaSimbolos[i].simbolo);
		free(tabelaSimbolos[i].token);
    free(tabelaSimbolos[i].tipoToken);
	}*/
	printf("\n\n");
  printf("_______________________________________\n\n");
  printf("IMPRIMINDO ARVORE \n\n");
  printArvore(topo);
  
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
            break;
        case 'K':
            strcpy(tabSimb->tipoToken, "Keyword");
            break;
        case 'V':
            strcpy(tabSimb->tipoToken, "Variavel");
            break;
        case 'C':
            strcpy(tabSimb->tipoToken, "Const");
            break;
        case 'F':
            strcpy(tabSimb->tipoToken, "Funcao");
            break;
    }

    if(final != tabSimb){
      final->next = tabSimb;
      final = tabSimb;
    }

  }

}

void getIdentifier(const char *id) {
  tabela *tabSimb;

  char *idVar;
  idVar = malloc(strlen(id) + 1);
  strcpy(idVar, id);
  int simboloRepetido = 0;

  tabSimb = (tabela *) malloc(sizeof(tabela)); 
  tabSimb->simbolo = malloc(strlen(id) + 1);
  //IDENTIFIER
  tabSimb->token = malloc(11);
  //Variavel
  tabSimb->tipoToken = malloc(9);

  if(inicio == NULL){
    inicio = tabSimb;
    final = tabSimb;
  } else {
    simboloRepetido = buscaSimbRepetido(idVar);
  }

  if(simboloRepetido == 0) {
    strcpy(tabSimb->simbolo, id);
    strcpy(tabSimb->token, "IDENTIFIER");
    strcpy(tabSimb->tipoToken, "Variavel");
    tabSimb->linha = contaLinha;

    if(final != tabSimb){
      final->next = tabSimb;
      final = tabSimb;
    }
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

/*fazer um código semantico para verificar se a variavel foi inicia */
/*fazer um código semantico para verificar se o valor que ela tá recebendo é do mesmo tipo*/



void yyerror(const char *s)
{
    extern int yylineno;    // Linha atual do código sendo analisado
    extern char *yytext;    // Último token lido pelo analisador léxico

    fprintf(stderr, " -> Erro na linha %d; ** %s ** <- \n", yylineno, yytext);
    exit(1);
}
