from token import Token, TokenType
from strformat import fmt

func newToken(tokenType: TokenType, ch: char): Token =  Token(tokenType: tokenType, literal: $ch)
func isLetter(ch: char): bool = ch in {'a'..'z', 'A'..'Z', '_'}
func isDigit(ch: char): bool = ch in {'0'..'9'}

type ILexer* = tuple
  nextToken: proc(): Token
type Lexer = ref object
  input: string
  position: int
  readPosition: int
  ch: char

proc readChar(self: Lexer): void
proc nextToken*(self: Lexer): Token
proc readIdentifier(self: Lexer): string
proc skipWhitespace(self: Lexer): void


proc newLexer*(input: string): ILexer =
  let lexer = Lexer(input: input)
  lexer.readChar()
  return (
    nextToken: proc(): Token = lexer.nextToken()
  )

proc readChar(self: Lexer): void =
  if self.readPosition >= self.input.len:
    self.ch = '\0'
  else:
    self.ch = self.input[self.readPosition]
  self.position = self.readPosition
  self.readPosition += 1


proc readNumber(self: Lexer): string = 
  let position = self.position;
  while isDigit(self.ch):
    self.readChar()
  return self.input[position..<self.position]

proc readIdentifier(self: Lexer): string =
  let position = self.position;
  while isLetter(self.ch):
    self.readChar()
  return self.input[position..<self.position]

proc skipWhitespace(self: Lexer) =
  while self.ch in [' ', '\t', '\n']:
    self.readChar()
    discard
 
proc nextToken*(self: Lexer): Token =
  self.skipWhitespace()

  case self.ch
  of '=':
    result = newToken(TokenType.ASSIGN, self.ch)
  of ';':
    result = newToken(TokenType.SEMICOLON, self.ch)
  of '(':
    result = newToken(TokenType.LPAREN, self.ch)
  of ')':
    result = newToken(TokenType.RPAREN, self.ch)
  of ',':
    result = newToken(TokenType.COMMA, self.ch)
  of '+':
    result = newToken(TokenType.PLUS, self.ch)
  of '{':
    result = newToken(TokenType.LBRACE, self.ch)
  of '}':
    result = newToken(TokenType.RBRACE, self.ch)
  of '\0':
    result = newToken(EOF, '\0')
  else:
    if isLetter(self.ch):
      result.literal = self.readIdentifier()
      result.tokenType = token.lookupIndent(result.literal)
      return
    elif isDigit(self.ch):
      result.tokenType = TokenType.INT
      result.literal = self.readNumber()
      return
    else:
      result = newToken(token.TokenType.ILLEGAL, self.ch)
  self.readChar()