/* File:  scanner.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
 */

%{

/* The text within this first region delimited by %{ and %} is assumed to
 * be C/C++ code and will be copied verbatim to the lex.yy.c file ahead
 * of the definitions of the yylex() function. Add other header file inclusions
 * or C++ variable declarations/prototypes that are needed by your code here.
 */

#include <string.h>
#include <ctype.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"



YYSTYPE yylval;  // manually declared for pp1, later Yacc provides


struct yyltype yylloc; // manually dclared for pp1, later Yacc provides


static void DoBeforeEachAction(); 
#define YY_USER_ACTION DoBeforeEachAction();

#define TAB_SIZE 8

int lineno, colno;
%}

 
PUNCTUATION        ([!;,.[\]{}()])
ARITHMETIC         ([-+*/%])
RELATIONAL         ([<>=])
OPERATOR           ({ARITHMETIC}|{RELATIONAL})
DECIMAL            ([0-9]+)
HEXADECIMAL        (0[xX][0-9a-fA-F]+)
CHARS              (\"[^\"\n]*\")
BOOLEAN            (true|false)   
INTEGER            ({DECIMAL}|{HEXADECIMAL})   
FLOAT              ({DECIMAL}\.{DECIMAL}?((E|e)(\+|\-)?{DECIMAL})?)
IDENTIFIER         ([a-zA-Z][a-zA-Z0-9_]*)

%x COMMENT
%%             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section. 
  */ 

 /* skip over white space */
[\n]                   { colno = 1; lineno++; }
[\t]                   { colno += TAB_SIZE - colno % TAB_SIZE + 1; }
[ ]                    ;

 /* recognize all keywords and return the correct token from scanner.h */
void                   { return T_Void; }
int                    { return T_Int; }
double                 { return T_Double; }
bool                   { return T_Bool; }
string                 { return T_String; }
class                  { return T_Class; }
interface              { return T_Interface; }
null                   { return T_Null; }
this                   { return T_This; }
extends                { return T_Extends; }
implements             { return T_Implements; }
for                    { return T_For; }
while                  { return T_While; }
if                     { return T_If; }
else                   { return T_Else; }
return                 { return T_Return; }
break                  { return T_Break; }
new                    { return T_New; }
NewArray               { return T_NewArray; }
Print                  { return T_Print; }
ReadInteger            { return T_ReadInteger; }
ReadLine               { return T_ReadLine; }

 
{PUNCTUATION} |
{OPERATOR}             { return yytext[0]; }


 /* recognize two-character operators and return the correct token */
\<=                    { return T_LessEqual; }
\>=                    { return T_GreaterEqual; }
==                     { return T_Equal; }
!=                     { return T_NotEqual; }
\[\]                   { return T_Dims; }
&&                     { return T_And; }
\|\|                   { return T_Or; }

 
{CHARS}                  { 
                           yylval.stringConstant = strdup(yytext);
                           return T_StringConstant;
                         }
{BOOLEAN}                { 
                           if (strcmp("true", yytext) == 0)
                               yylval.boolConstant = true;
                           else
                   yylval.boolConstant = false;
                           return T_BoolConstant;
                         }
{DECIMAL}                { 
                           yylval.integerConstant = strtol(yytext, NULL, 10); return T_IntConstant; 
             }
{HEXADECIMAL}            {
                          yylval.integerConstant = strtol(yytext, NULL, 16); 
              return T_IntConstant;
                         }
{FLOAT}                  { 
                           yylval.doubleConstant = atof(yytext); return T_DoubleConstant; 
             }

 
{IDENTIFIER}             { 
                          if (yyleng > MaxIdentLen)
                        ReportError::LongIdentifier(&yylloc, yytext);
              strncpy(yylval.identifier, yytext, MaxIdentLen);
              yylval.identifier[MaxIdentLen] = '\0';   
              
              return T_Identifier;
                }

\/\/.*\n                { 
                          lineno++; 
              colno = 1;
            }
\/\*.*\*\/              ;

 /* consume multi-line comments 
  * report unterminated comment
  */

\/\*                    { BEGIN COMMENT; }
<COMMENT>.              ;
<COMMENT>[\r\n]         { 
                          lineno++; 
                          colno = 1;
            }
<COMMENT>\*\/           { BEGIN INITIAL; }
<COMMENT><<EOF>>        { 
              ReportError::UntermComment();
              BEGIN INITIAL;
            }

 /* report lexical error for improper strings 
  * and invalid characters
  */
\"[^\"\n]*\n            { 
                          ReportError::UntermString(&yylloc, yytext);       
              lineno++;
              colno = 1;
            } 

 /* all other characters are reported as errors */
.                       { 
                          ReportError::UnrecogChar(&yylloc, yytext[0]);     
            }

%%




void InitScanner()
{
    bool yy_flex_debug;
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = true;
    lineno = 1;
    colno = 1;
}



static void DoBeforeEachAction()
{
  yylloc.first_line = yylloc.last_line = lineno;

  yylloc.first_column = colno;
  yylloc.last_column = colno + yyleng - 1;
  colno = colno + yyleng;
}
int yywrap()
{
return (1);
}