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
    void yyerror();
    
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
%}
    

%union{
  int intNum;
  float floatNum;
  char* str; 
}


%token CHAR PRINTF SCANF FOR WHILE INT FLOAT DOUBLE STRUCT CONST IF ELSE RETURN MAIN VOID  
%token OP_MAIS OP_MENOS OP_VEZES OP_DIV OL_AND OL_OR OL_MENOR OL_MENIG OL_MAIOR OL_MAIIG OL_IGUAL OL_DIF INCR DECR
%token ALLOC INCLUDE NOTOP LP RP LC RC LB RB PV VIRGULA REFER
%token <str> IDENTIFIER
%token <str> STRING
%token <intNum> INT_NUM
%token <floatNum> FLOAT_NUM

%start program

%%

/*QUESTAO 1: tem que pensar nesse caso aqui para caso tem outras funcoes, acredito que do jeito que está vai dar erro
quem sabe da para utilizar o metodo do include de usar "include include", permitindo assim a repeticao */

/*QUESTAO 2: vai ter que ver a questao de parametros dentro das chamadas de funcoes */



program: include inicio LP RP LC estrutura RC
;

include: include include
| INCLUDE { adicionaSimbTabela('I', "INCLUDE"); }
;

inicio: tipagem MAIN { adicionaSimbTabela('F', "MAIN"); }
;

estrutura: estrutura declaracao 
| declaracao
;

declaracao: declaravar
| if_statement 
| for_statement 
| while_statement  
| atribuir
| printf_statement
| scanf_statement
| retorno 
;

declaravar: tipagem valor PV
;

tipagem: INT 	{ adicionaSimbTabela('K', "INT"); }
| FLOAT 	{ adicionaSimbTabela('K', "FLOAT"); }
| CHAR 		{ adicionaSimbTabela('K', "CHAR"); }
| VOID 		{ adicionaSimbTabela('K', "VOID"); }
| DOUBLE 	{ adicionaSimbTabela('K', "DOUBLE"); }
;

valor: variaveis VIRGULA valor
| variaveis ALLOC constantes 
| variaveis
;

variaveis: IDENTIFIER { /*Chamando atraves de func do lexico e tratando no sintatico*/ }
| IDENTIFIER { /*Chamando atraves de func do lexico e tratando no sintatico*/ } array
;

array: array LB INT_NUM RB 
| LB INT_NUM RB  
| LB IDENTIFIER RB
;

constantes: INT_NUM { adicionaSimbTabela('C', "INT_NUM"); }
| FLOAT_NUM { adicionaSimbTabela('C', "FLOAT_NUM"); }
| STRING  { adicionaSimbTabela('C', "STRING"); }
;

if_statement: IF { adicionaSimbTabela('K', "IF"); } LP expressao RP tail else ;

else_if: else_if ELSE IF LP expressao RP tail 
| ELSE IF LP expressao RP tail  
| /* empty */
; 

else: ELSE { adicionaSimbTabela('K', "ELSE"); }  else_opc 
|
; 

else_opc: tail  /*para quando eh soh um else*/
| estrutura     /*para quando eh um else if*/
;


for_statement: FOR { adicionaSimbTabela('K', "FOR"); }  LP inicio_for PV expressao PV expressao RP tail 
;

inicio_for: variaveis ALLOC constantes
| tipagem variaveis ALLOC constantes
;


while_statement: WHILE { adicionaSimbTabela('K', "WHILE"); }  LP expressao RP tail 
;

tail: LC estrutura RC;

expressao: expressao operadores expressao 
| expressao oplogicos expressao 
| expressao INCR
| expressao DECR
| NOTOP expressao 
| LP expressao RP 
| variaveis
| sinal constantes
;

operadores: OP_MAIS
| OP_MENOS
| OP_VEZES
| OP_DIV
;

oplogicos: OL_OR
| OL_AND
| OL_IGUAL
| OL_DIF
| OL_MENOR
| OL_MENIG
| OL_MAIOR
| OL_MAIIG
;

atribuir: variaveis ALLOC expressao PV; 

sinal:  OP_MENOS
| /*positivo nao precisa de sinal*/
;

printf_statement: PRINTF  { adicionaSimbTabela('K', "PRINTF"); } printf_args PV
;

printf_args: LP variaveis RP  
| LP STRING RP
| LP STRING VIRGULA printf_params RP  
;

printf_params:  expressao 
| expressao VIRGULA printf_params 
;

scanf_statement:  SCANF { adicionaSimbTabela('K', "SCANF"); }  LP STRING VIRGULA scanf_args RP PV 
;

scanf_args: REFER variaveis VIRGULA scanf_args  
| REFER variaveis  
;

retorno: RETURN { adicionaSimbTabela('K', "RETURN"); } return_param PV
;

return_param: INT_NUM
| IDENTIFIER
| /*vazio*/
;

/*
  FALTA VER A REGRA DO PRINTF E DO SCANF
  FALTA FAZER A TABELA DE SIMB e TREE
*/


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


void yyerror()
{
	/* variáveis definidas no analisador léxico */
    extern int yylineno;    
    extern char *yytext;   

	/* mensagem de erro exibe o símbolo que causou erro e o número da linha */
    fprintf(stderr, " -> Erro na linha %d; ** %s ** <- \n", yylineno, yytext);
    exit(1);
}
