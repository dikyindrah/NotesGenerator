%{
#include <iostream>
#include <fstream>
#include <algorithm>
#include <string>
using namespace std;
%}
%option noyywrap
%state items
%x PREPROCESSOR
%x CODE
%x MATH
%%
%{
string trim(const string& str, int l, int r);
void replaceAll(string& str, const string& find, const string& repl);
void prepare(string& str);
int itemslevel=0;
bool bold=false;
bool italic=false;
bool footnote=false;
%}
<PREPROCESSOR>{
    ^#(?i:end)" "*$  { BEGIN(INITIAL); }
    .|\n             { }
}
<CODE>{
    ^"```"$         { cout << "\\end{lstlisting}"; BEGIN(INITIAL); }
    [[:print:]]    { cout << yytext; }
    .           {}
}
<MATH>{
    
    "{{"    { cout << "\\left\\{\\begin{array}{lll}"; }
    "}}"    { cout << "\\end{array}\\right."; }
    "->"    { cout << "\\rightarrow " ; }
    "-->"   { cout << "\\longrightarrow " ; }
    "=>"    { cout << "\\Rightarrow " ; }
    "==>"   { cout << "\\Longrightarrow " ; }

    "<->"   { cout << "\\leftrightarrow " ; }
    "<-->"  { cout << "\\longleftrightarrow " ; }
    "<=>"   { cout << "\\Leftrightarrow " ; }
    "<==>"  { cout << "\\Longleftrightarrow " ; }

    "<-"    { cout << "\\leftarrow " ; }
    "<--"   { cout << "\\longleftarrow " ; }
    "<="    { cout << "\\Leftarrow " ; }
    "<=="   { cout << "\\Longleftarrow " ; }

    "|"     { cout << "\\, |\\,"; }
    "¬"     { cout << "\\neg "; }
    
    \\\$    { cout << yytext; }
    \$\$?      { cout << yytext; BEGIN(INITIAL); }
    .       { cout << yytext; }
}

^#(?i:pre)" "*$  { BEGIN(PREPROCESSOR); }



^.*\n\*\*\*+      { string str = string(yytext);
                    str = str.substr(0,str.find("\n"));
                    prepare(str);
                    cout << "\\unit{" << str << "}"; 
                  }
^.*\n"=="=+       { string str = string(yytext);
                    str = str.substr(0,str.find("\n")); 
                    prepare(str);
                    cout << "\\unitsection{" << str << "}"; 
                  }
^.*\n"--"-+       { string str = string(yytext);
                    str = str.substr(0,str.find("\n")); 
                    prepare(str);
                    cout << "\\unitsubsection{" << str << "}"; 
                  }

\$\$?      {cout << yytext; BEGIN(MATH); }

"__"      { if(!italic){
                cout << "\\textit{"; 
            }else if(bold){
                cout << "}}\\textbf{";
            }else{
                cout << "}";
            }
            italic=!italic;
          }
"**"      { if(!bold){
                cout << "\\textbf{"; 
            }else if(italic){
                cout << "}}\\textit{";
            }else{
                cout << "}";
            }
            bold=!bold; 
          }
"!!"([^!\n]"!"?)*"!!"      { 
                            string str = trim(yytext,2,2);
                            prepare(str);
                            cout << "\\keyword{" << str << "}";
                            transform(str.begin(),str.end(),str.begin(),[](unsigned char c){ return tolower(c);});
                            cout << "\\label{kw:"<< str <<"}"; 
                           }
`([^`])*`     {
                            string str = trim(yytext,1,1);
                            prepare(str);
                            cout << "\\codeword{" << str << "}";
                           }

"_("            { if(!footnote){
                    cout << "\\footnote{"; 
                    footnote=true;
                  }
                }
")_"            { if(footnote){
                    cout << "}";
                    footnote=false;
                  }
                }

"(("(?i:fixme)"))" { 
                    static int fm=0;
                    cout << "\\fixme\\label{fixme" << fm++ << "} "; 
                   }
^"```".*$   {   
                string spec = trim(yytext,3,0);
                string lang = spec, file = spec;
                if(spec.substr(0,5) == "file:"){
                    spec = spec.substr(5);
                    size_t lastcolon = spec.find_last_of(':');
                    if(lastcolon != string::npos){
                        file = spec.substr(0,lastcolon);
                        lang = spec.substr(lastcolon+1);
                    }
                    ifstream fin(file);
                    if(fin.good()){
                        cout << endl << "\\lstset{language=" << lang << "}" << endl;
                        cout << "\\begin{lstlisting}" << endl; 
                        string line;
                        getline(fin, line);
                        while(!fin.eof()){
                            cout << line << endl;
                            getline(fin, line);
                        }
                    }else{
                        static int filefm=0;
                        cout << "\\fixme\\label{fixme" << filefm++ << "} "; 
                        cout << file << " not found" << endl;
                        cout << "\\begin{lstlisting}" << endl; 
                    }
                    fin.close();
                }else{
                    cout << endl << "\\lstset{language=" << lang << "}" << endl;
                    cout << "\\begin{lstlisting}"; 
                }
                BEGIN(CODE);                 
            }

"{*"" "*\n*     { cout << "\\begin{itemize}"; itemslevel++; }
"*}"" "*\n*     { cout << "\\end{itemize}"; itemslevel--; }
"{#"" "*\n*     { cout << "\\begin{enumerate}"; itemslevel++; }
"#}"" "*\n*     { cout << "\\end{enumerate}"; itemslevel--; }
"{."" "*\n*     { cout << "\\begin{itemize}[label={}]"; itemslevel++; }
".}"" "*\n*     { cout << "\\end{itemize}"; itemslevel--; }

^[ \t]*-        { if(itemslevel <= 0){
                    cout << yytext;
                  }else{
                    cout << "\\item ";
                  }
                }
^[ \t]*"+"[^\.\:\n]+    {   if(itemslevel <= 0){
                                cout << yytext;
                            }else{
                                string s(yytext);
                                int p = s.find('+');
                                cout << "\\item ";
                                if(itemslevel%2 == 1){
                                    cout << "\\textbf{";
                                }else{
                                    cout << "\\textit{";
                                }
                                cout << s.substr(p+1,s.size()-p) << "}";
                            }
                        }

"¬"     { cout << "$\\neg$ "; }
"<"     { cout << "$<$"; }
">"     { cout << "$>$"; }
"_"     { cout << "\\_"; }
                
"->"    { cout << "$\\rightarrow$ " ; }
"-->"   { cout << "$\\longrightarrow$ " ; }
"=>"    { cout << "$\\Rightarrow$ " ; }
"==>"   { cout << "$\\Longrightarrow$ " ; }

"<->"   { cout << "$\\leftrightarrow$ " ; }
"<-->"  { cout << "$\\longleftrightarrow$ " ; }
"<=>"   { cout << "$\\Leftrightarrow$ " ; }
"<==>"  { cout << "$\\Longleftrightarrow$ " ; }

"<-"    { cout << "$\\leftarrow$ " ; }
"<--"   { cout << "$\\longleftarrow$ " ; }
"<="    { cout << "$\\Leftarrow$ " ; }
"<=="   { cout << "$\\Longleftarrow$ " ; }

\n\n?        { cout << "\n\n"; }
\n+"  "[^-+]    { cout << "\n\n\\hspace{5 mm}" << *string(yytext).rbegin(); }
.            { cout << yytext; }


%%

string trim(const string& str, int l, int r){
    return str.substr(l,str.length()-l-r);
}
void replaceAll(string& str, const string& f, const string& repl){
    int idx=str.find(f);
    int n = f.size();
    while(idx != string::npos){
        str.replace(idx,n,repl);
        idx+=n+1;
        idx=str.find(f,idx);
    }
}
void prepare (string& str){
    replaceAll(str,"_","\\_");
    replaceAll(str,"$","\\$");
}
int main(int argc, char** argv){
    if (argc == 1){
        yylex();
    }else{
        for(int i = 1; i < argc; i++){
            yyin = fopen(argv[i],"r");
            if(!yyin){
                cerr << "Couldn't open " << argv[i] << endl;
            }else{
                yylex();
            }
        }
    }
    return 0;
}

