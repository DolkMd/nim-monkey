from token import Token, TokenType
from strformat import fmt

func newToken(tokenType: TokenType, ch: char): Token =  Token(typ: tokenType, literal: $ch)
func isLetter(ch: char): bool = ch in {'a'..'z', 'A'..'Z', '_'}
func isDigit(ch: char): bool = ch in {'0'..'9'}
func isSpace(ch: char): bool = ch in [' ', '\t', '\n']

type ILexer* = tuple
  nextToken: proc(): Token
type Lexer = ref object
  input: string
  position: int
  readPosition: int
  ch: char

proc next(self: Lexer): void
proc nextToken*(self: Lexer): Token
proc nextNumber(self: Lexer): string
proc nextIdentifier(self: Lexer): string
proc skipWhitespace(self: Lexer): void
proc peek(self: Lexer): char

proc newLexer*(input: string): ILexer =
  let lexer = Lexer(input: input)
  lexer.next()
  return (
    nextToken: proc(): Token = lexer.nextToken()
  )

proc peek(self: Lexer): char =
  return if self.readPosition >= self.input.len: '\0'
  else: char(self.input[self.readPosition])

proc next(self: Lexer): void =
  if self.readPosition >= self.input.len:
    self.ch = '\0'
  else:
    self.ch = self.input[self.readPosition]
  self.position = self.readPosition
  self.readPosition += 1

proc readWhile(self: Lexer, judge: proc(ch: char): bool): string =
  let position = self.position;
  while judge(self.ch):
    self.next()
  return self.input[position..<self.position]

proc nextNumber(self: Lexer): string = self.readWhile(isDigit) 
proc nextIdentifier(self: Lexer): string = self.readWhile(isLetter) 
proc skipWhitespace(self: Lexer) = discard self.readWhile(isSpace)

proc nextToken*(self: Lexer): Token =
  self.skipWhitespace()
  case self.ch
  of '=': 
    if self.peek() == '=':
      let ch = self.ch
      self.next()
      result = Token(typ: TokenType.EQ, literal: fmt"{ch}{self.ch}")
    else: result = newToken(TokenType.ASSIGN, self.ch)
  of ';': result = newToken(TokenType.SEMICOLON, self.ch)
  of '(': result = newToken(TokenType.LPAREN, self.ch)
  of ')': result = newToken(TokenType.RPAREN, self.ch)
  of ',': result = newToken(TokenType.COMMA, self.ch)
  of '+': result = newToken(TokenType.PLUS, self.ch)
  of '-': result = newToken(TokenType.MINUS, self.ch)
  of '!':
    if self.peek() == '=':
      let ch = self.ch
      self.next()
      result = Token(typ: TokenType.NOT_EQ, literal: fmt"{ch}{self.ch}")
    else: result = newToken(TokenType.BANG, self.ch)
  of '/': result = newToken(TokenType.SLASH, self.ch)
  of '*': result = newToken(TokenType.ASTERISC, self.ch)
  of '<': result = newToken(TokenType.LT, self.ch)
  of '>': result = newToken(TokenType.GT, self.ch)
  of '{': result = newToken(TokenType.LBRACE, self.ch)
  of '}': result = newToken(TokenType.RBRACE, self.ch)
  of '\0': result = newToken(EOF, '\0')
  else:
    if isLetter(self.ch):
      result.literal = self.nextIdentifier()
      result.typ = token.lookupIndent(result.literal)
      return
    elif isDigit(self.ch):
      result.typ = TokenType.INT
      result.literal = self.nextNumber()
      return
    else: result = newToken(token.TokenType.ILLEGAL, self.ch)
  self.next()