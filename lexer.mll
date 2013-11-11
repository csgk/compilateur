(* Analyseur lexical pour miniC++ *)

{
  open Lexing
  open Parser
   
  exception Lexing_error of string

  (* tables des mots-cl�s *)
  let kwd_tbl = 
    [
      "class", CLASS; "else", ELSE; "false", FALSE;
      "for", FOR; "if", IF; "int", INT; "new", NEW;
      "NULL", NULL; "public", PUBLIC; "return", RETURN;
      "this", THIS; "true", TRUE; "virtual", VIRTUAL;
      "void", VOID; "while", WHILE
    ]
  
  (* TODO: v�rifier qu'on n'a pas un nom de classe dynamique *)
  (* d�termine si on a un identifieur ou un mot cl� *)
  let id_or_kwd = 
    let h = Hashtbl.create 17 in
    List.iter (fun (s,t) -> Hashtbl.add h s t) kwd_tbl;
    fun s -> 
      let s = String.lowercase s in (* la casse n'est pas significative *)
      try List.assoc s kwd_tbl with _ -> IDENT s

  (* va � la ligne suivante en incr�mentant la r�f�rence de ligne *)
  let newline lexbuf =
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <- 
      { pos with pos_lnum = pos.pos_lnum + 1; pos_bol = pos.pos_cnum }

}

let digit = ['0'-'9']
let alpha = ['a'-'Z' 'a'-'Z']
let ident = (alpha | '_') (alpha | '_' | digit)*
let integer = '0' | ['1'-'9'] digit* | '0' octal_digit+ | '0x' hexa_digit+
let octal_digit = ['0'-'7']
let hexa_digit = ['0'-'9' 'a'-'f' 'A'-'F']
(* Il faut enlever le '\' et le '"' *)
let carac = [32-33 (* 34 : " *) 35-91 (*92 : \ *) 93-127] | "\\" | "\"" | "\n" | "\t" | "\x" hexa_digit hexa_digit
let string = \" carac* \"
let space = [' ' '\t']

rule token = parse
  | "\n"    { newline lexbuf; token lexbuf }
  | space+  { token lexbuf }
  | ident as id { id_or_kwd id }
  | '='     { ASSIGN }
  | "||"    { OR }
  | "&&"    { AND }
  | "=="    { EQ }
  | "!="    { NEQ }
  | '<'     { LT }
  | "<="    { LE }
  | '>'     { GT }
  | ">="    { GE }
(* Il faut int�grer le support des op�rateurs unaires '+', '-' et '*' *)
  | '+'     { PLUS }
  | '-'     { MINUS }
  | '*'     { TIMES }
  | '/'     { DIV }
  | '%'     { MOD }
  | '!'     { NEG }
  | "++"    { INCR }
  | "--"    { DECR }
  | '('     { LPAREN }
  | ')'     { RPAREN }
  | '.'     { DOT }
  | "()"    { CALL }
  | "->"    { POINTER }
  | ','     { COMMA }
  | ':'     { COLON }
  | ";"     { SEMICOLON }
  | "/*"    { comment lexbuf }
(* On a un "//", on va � la ligne suivante et on r��value *)
  | "//"    { newline lexbuf; token lexbuf }
(* Maladroit ? *)
  | integer as s { CST (int_of_string s) }
  | eof     { raise (Lexing_error "reached end of file") }
  | _ as c  { raise (Lexing_error ("illegal character: " ^ String.make 1 c)) }

and comment = parse
  | "*/"    { token lexbuf }
  | _       { comment lexbuf }
  | eof     { raise (Lexing_error ("unterminated comment")) }
