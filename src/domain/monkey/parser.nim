import options
import strformat
import std/tables
import lexer, token, ast

type 
    prefixParseFn = proc(): ast.Expression
    infixParseFn = proc(exp: ast.Expression): ast.Expression

type 
    IParser* = tuple
        parseProgram : proc(): Option[ast.Program]
        errors       : proc(): seq[ast.AstException]
    Parser = ref object
        lexer: lexer.ILexer
        curToken: token.Token
        peekToken: token.Token
        errs: seq[ast.AstException]
        prefixParseFns: Table[token.TokenType, prefixParseFn]
        infixParseFns: Table[token.TokenType, infixParseFn]

proc nextToken(self: Parser) 
proc parseProgram(self: Parser): Option[ast.Program] 
proc parseStatement(self: Parser): Option[ast.Statement] 
proc curTokenIs(self: Parser, t: token.TokenType): bool
proc peekTokenIs(self: Parser, t: token.TokenType): bool
proc expectPeek(self: Parser, t: token.TokenType): bool 
proc peekError(self: Parser, t: token.TokenType)

proc newParser*(lexer: lexer.ILexer): IParser = 
    let parser = Parser(
        lexer : lexer,
        errs  : @[],
    )
    return (
        parseProgram: proc(): Option[ast.Program] = parser.parseProgram(),
        errors: proc(): seq[ast.AstException] =  parser.errs
    );

proc nextToken(self: Parser) = 
    self.curToken = self.peekToken
    self.peekToken = self.lexer.nextToken()

proc parseProgram(self: Parser): Option[ast.Program] = 
    let program = ast.Program()
    program.statements = @[]
    while self.curToken.typ != token.TokenType.EOF:
        let smt = self.parseStatement()
        if not smt.isNone(): program.statements.add(smt.get())
        self.nextToken()
    return option(program)

proc parseStatement(self: Parser): Option[ast.Statement] = 
    case self.curToken.typ:

    of token.TokenType.LET: 
        let smt = ast.LetStatement(token: self.curToken)
        if not self.expectPeek(token.TokenType.IDENT): return none[ast.Statement]()
        
        smt.name = ast.Identifier(token: self.curToken, value: self.curToken.literal)
        if not self.expectPeek(token.TokenType.ASSIGN): return none[ast.Statement]()

        while not self.curTokenIs(token.TokenType.SEMICOLON):
            self.nextToken()
        return option(ast.Statement(smt))

    of token.TokenType.RETURN:
        let smt = ast.ReturnStatement(token: self.curToken)
        self.nextToken()
        while not self.curTokenIs(token.TokenType.SEMICOLON):
            self.nextToken()
        return option(ast.Statement(smt))

    else: return none[ast.Statement]()


proc curTokenIs(self: Parser, t: token.TokenType): bool = self.curToken.typ == t
proc peekTokenIs(self: Parser, t: token.TokenType): bool =  self.peekToken.typ == t
proc expectPeek(self: Parser, t: token.TokenType): bool =
    if self.peekTokenIs(t):
        self.nextToken()
        return true
    else: 
        self.peekError(t)
        return false

proc peekError(self: Parser, t: token.TokenType) = self.errs.add(ast.AstException(msg: fmt"expected next token to be {t} got {self.peekToken.typ} instead"))
