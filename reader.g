#header
<<
#include <string>
#include <iostream>
#include <map>
using namespace std;

// struct to store inprintion about tokens
typedef struct {
    string kind;
    string text;
} Attrib;

// function to fill token inprintion (predeclaration)
void zzcr_attr(Attrib *attr, int type, char *text);

// fields forAST nodes
#define AST_FIELDS string kind; string text;
#include "ast.h"

// macro to create a new AST node (and function predeclaration)
#define zzcr_ast(as,attr,ttype,textt) as=createASTnode(attr,ttype,textt)
AST* createASTnode(Attrib* attr,int ttype, char *textt);
>>

<<
#include <cstdlib>
#include <cmath>

//global structures
AST* root;

// function to fill token inprintion
void zzcr_attr(Attrib *attr, int type, char *text) {
    if(type == ID) {
        attr->kind = "ID";
        attr->text = text;
    } else if(type == NUM) {
        attr->kind = "NUM";
        attr->text = text;
    } else {
        attr->kind = text;
        attr->text = "";
    }
}

// function to create a new AST node
AST* createASTnode(Attrib* attr, int type, char* text) {
    AST* as = new AST;
    as->kind = attr->kind;
    as->text = attr->text;
    as->right = NULL;
    as->down = NULL;
    return as;
}

/// create a new "list" AST node with one element
AST* createASTlist(AST* child) {
    AST* as = new AST;
    as->kind = "list";
    as->right = NULL;
    as->down = child;
    return as;
}

AST* child(AST* a, int n) {
    AST* c = a->down;
    for(int i = 0; c != NULL && i < n; i++) {
        c = c->right;
    }
    return c;
}

void printExpr(AST* a) {
    cout << "(";
    if(a->kind == "NOT") {
        cout << "NOT ";
        printExpr(child(a, 0));
    } else if(a->kind == "AND" || a->kind == "OR") {
        cout << a->kind << " ";
        printExpr(child(a, 0));
        printExpr(child(a, 1));
    } else if(a->kind == ">") {
        cout << "Gt ";
        printExpr(child(a, 0));
        printExpr(child(a, 1));
    } else if(a->kind == "=") {
        cout << "Eq ";
        printExpr(child(a, 0));
        printExpr(child(a, 1));
    } else if(a->kind == "+") {
        cout << "Plus ";
        printExpr(child(a, 0));
        printExpr(child(a, 1));
    } else if(a->kind == "-") {
        cout << "Minus ";
        printExpr(child(a, 0));
        printExpr(child(a, 1));
    } else if(a->kind == "*") {
        cout << "Times ";
        printExpr(child(a, 0));
        printExpr(child(a, 1));
    } else if(a->kind == "ID") {
        cout << "Var \"" << a->text << "\"";
    } else if(a->kind == "NUM") {
        cout << "Const " << a->text;
    }
    cout << ")";
}

void print(AST* a) {
    cout << "(";
    if(a->kind == "list") {
        cout << "Seq [";
        AST* b = child(a, 0);
        bool first = true;
        while(b != NULL) {
            if(!first) {
                cout << ", ";
            } else {
                first = false;
            }
            print(b);
            b = b->right;
        }
        cout << "]";
    } else if(a->kind == "INPUT") {
        cout << "Input ";
        print(child(a, 0));
    } else if(a->kind == ":=") {
        cout << "Assign ";
        print(child(a, 0));
        printExpr(child(a, 1));
    } else if(a->kind == "PRINT") {
        cout << "Print ";
        printExpr(child(a, 0));
    } else if(a->kind == "POP") {
        cout << "Pop ";
        print(child(a, 0));
        print(child(a, 1));
    } else if(a->kind == "PUSH") {
        cout << "Push ";
        print(child(a, 0));
        printExpr(child(a, 1));
    } else if(a->kind == "SIZE") {
        cout << "Size ";
        print(child(a, 0));
        print(child(a, 1));
    } else if(a->kind == "EMPTY") {
        cout << "Empty ";
        print(child(a, 0));
    } else if(a->kind == "WHILE") {
        cout << "Loop ";
        printExpr(child(a, 0));
        print(child(a, 1));
    } else if(a->kind == "IF") {
        cout << "Cond ";
        printExpr(child(a, 0));
        print(child(a, 1));
        AST* aux = child(a, 2);
        if(aux != NULL) {
            print(child(a, 2));
        } else {
            cout << "(Seq [])";
        }
    } else if(a->kind == "ID") {
        cout << "\"" << a->text << "\"";
    }
    cout << ")";
}

int main() {
    root = NULL;
    ANTLR(program(&root), stdin);
    print(root);
}
>>

#lexclass START

#token WHILE "WHILE"
#token DO "DO"
#token END "END"
#token IF "IF"
#token THEN "THEN"
#token ELSE "ELSE"
#token ASSIGN ":="
#token INPUT "INPUT"
#token PRINT "PRINT"
#token EMPTY "EMPTY"
#token PUSH "PUSH"
#token POP "POP"
#token SIZE "SIZE"
#token EQUAL "\="
#token OR "OR"
#token AND "AND"
#token NOT "NOT"
#token BIGGER "\>"
#token MINUS "\-"
#token SUM "\+"
#token MULT "\*"
#token NUM "[0-9]+"
#token ID "[a-zA-Z][0-9a-zA-Z]*"
#token SPACE "[\ \n]" << zzskip();>>

program: ops;
ops: (op)* <<#0=createASTlist(_sibling);>>;
op: whileLoop | ifCond | input | print | empty | size | pop | push | assign;

input: INPUT^ ID;
print: PRINT^ termNum;
empty: EMPTY^ ID;
pop: POP^ ID ID;
push: PUSH^ ID termNum;
size: SIZE^ ID ID;
assign: ID ASSIGN^ expr;
whileLoop: WHILE^ expr DO! ops END!;
ifCond: IF^ expr THEN! ops ((ELSE! ops) | ) END!;

expr: termBool ((AND^ | OR^) termBool)*;
termBool: (NOT^ termBool) | (termNum ((BIGGER^ | EQUAL^) termNum)*);
termNum: operand ((SUM^ | MINUS^ | MULT^) operand)*;
operand: NUM | ID;
