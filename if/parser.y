%{
#include <stdio.h>
#include <string.h>
int yylex(void);
void yyerror(const char *s);

/* a, b, c are indexes in word; c is a label number for L, B, J. */
typedef struct { char op; int a,b,c,move; } Quad;
Quad q[100], opt[100];
char word[100][20];
int places=1, n=0, k=0, temp=0;

int add(char *s) {
    for(int i=1;i<places;i++)
        if(strcmp(word[i],s)==0) return i;
    strcpy(word[places],s);
    return places++;
}
void emit(char op,int a,int b,int c) {
    q[n].op=op; q[n].a=a; q[n].b=b; q[n].c=c;
    n++;
}
int gen(char op,int a,int b) {
    char s[20];
    sprintf(s,"T%d",++temp);
    int c=add(s);
    emit(op,a,b,c);
    return c;
}
%}
%token IF ELSE ID NUM
%left '+' '-'
%left '*'
%%
program : IF '(' test ')' '{' list '}' tail ;
test    : ID '<' expr { emit('B',$1,$3,2); } ;
tail    : { emit('L',0,0,2); }
        | ELSE { emit('J',0,0,3); emit('L',0,0,2); }
          '{' list '}' { emit('L',0,0,3); } ;
list    : stmt | list stmt ;
stmt    : ID '=' expr ';' { emit('=',$3,0,$1); } ;
expr    : ID | NUM
        | expr '+' expr { $$=gen('+',$1,$3); }
        | expr '-' expr { $$=gen('-',$1,$3); }
        | expr '*' expr { $$=gen('*',$1,$3); }
        | '(' expr ')' { $$=$2; } ;
%%
void yyerror(const char *s) { printf("\nSyntax error: %s\n",s); }

/* There is no loop, so code motion does not apply. */
void optimize(void) {
    for(int i=0;i<n;i++) opt[k++]=q[i];
}

/* target=0 prints TAC; target=1 prints simple machine instructions. */
void show(Quad code[],int count,int target) {
    for(int i=0;i<count;i++) {
        Quad p=code[i];
        char *a=word[p.a], *b=word[p.b], *c=word[p.c];
        if(p.op=='L') printf("L%d:\n",p.c);
        else if(p.op=='J') printf(target ? "JMP L%d\n" : "goto L%d\n",p.c);
        else if(p.op=='B') {
            if(target) printf("LOAD R0, %s\nCMP R0, %s\nJGE L%d\n",a,b,p.c);
            else printf("ifFalse %s < %s goto L%d\n",a,b,p.c);
        } else if(target) {
            printf("LOAD R0, %s\n",a);
            if(p.op!='=') printf("%s R0, %s\n",
                p.op=='+' ? "ADD" : p.op=='-' ? "SUB" : "MUL",b);
            printf("STORE %s, R0\n",c);
        } else if(p.op=='=') printf("%s = %s\n",c,a);
        else printf("%s = %s %c %s\n",c,a,p.op,b);
    }
}
int main(void) {
    puts("TOKENS:");
    if(yyparse()) return 1;
    puts("\n\nSyntax correct\n\nTAC:");
    show(q,n,0);
    optimize();
    puts("\nOPTIMIZED TAC:"); show(opt,k,0);
    puts("\nTARGET CODE:"); show(opt,k,1);
    return 0;
}
