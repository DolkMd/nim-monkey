import tables

type
  Token* = object
    tokenType*: TokenType
    literal*: string
  TokenType* {.pure.} = enum 
    ILLEGAL   = "ILLEGAL"
    EOF       = "EOF"

    IDENT     = "IDENT"
    INT       = "INT"
    STRING    = "STRING"

    ASSIGN    = "="
    PLUS      = "+"
    MINUS     = "-"
    BANG      = "!"
    ASTERISC  = ""
    SLASH     = "/"

    LT        = "<"
    GT        = ">"

    COMMA     = ","
    COLON     = ":"
    SEMICOLON = ";"

    LPAREN    = "("
    RPAREN    = ")"
    LBRACE    = "{"
    RBRACE    = "}"

    FUNCTION  = "FUNCTION"
    LET       = "LET"
    TRUE      = "TRUE"
    FALSE     = "FALSE"
    IF        = "IF"
    ELSE      = "ELSE"
    RETURN    = "RETURN"

    EQ        = "=="
    NOT_EQ    = "!="

    LBRACKET  = "["
    RBRACKET  = "]"


const keywords = {
  "fn": TokenType.FUNCTION,
  "let": TokenType.LET,
}.toTable;

func lookupIndent*(ident: string): TokenType =
    if keywords.hasKey(ident): 
      keywords[ident]
    else:
      TokenType.IDENT
    