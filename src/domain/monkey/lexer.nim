from token import Token, TokenType

func newToken(tokenType: TokenType, ch: char): Token =  Token(tokenType: tokenType, literal: $ch)
func isLetter(ch: char): bool = ch in {'a'..'z', 'A'..'Z', '_'}

type ILexer* = tuple
  nextToken: proc(): Token
type Lexer = ref object
  input: string
  position: int
  readPosition: int
  ch: char

proc readChar(self: Lexer): void
proc nextToken*(self: Lexer): Token

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

proc nextToken*(self: Lexer): Token =
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
  else:
    result.literal = ""
    result.tokenType = TokenType.EOF
  self.readChar()