import options
import strformat
import strutils, pegs, unicode
import std/tables
import lexer, token, ast

var traceLevel = 0
const traceIdentPlaceholder  = "\t"
proc tracePrint(fs: string) = echo fmt"{traceIdentPlaceholder.repeat(traceLevel - 1)}{fs}"
proc trace(msg: string): string =
    traceLevel += 1
    # tracePrint(fmt"BEGIN {msg}")
    return msg
proc untrace(msg: string) =
    # tracePrint(fmt"END {msg}")
    traceLevel -= 1
 
type Priority* {.pure.} = enum
    _
    LOWEST
    EQUALS
    LESSGREATER
    SUM
    PRODUCT
    PREFIX
    CALL

const precedences = {
    token.TokenType.EQ: Priority.EQUALS,
    token.TokenType.NOT_EQ: Priority.EQUALS,
    token.TokenType.LT: Priority.LESSGREATER,
    token.TokenType.GT: Priority.LESSGREATER,
    token.TokenType.PLUS: Priority.SUM,
    token.TokenType.MINUS: Priority.SUM,
    token.TokenType.SLASH: Priority.PRODUCT,
    token.TokenType.ASTERISC: Priority.PRODUCT,
}.toTable

type
    prefixParseFn = proc(): ast.Expression
    infixParseFn = proc(exp: ast.Expression): ast.Expression
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
proc expectPeek(self: Parser, t: token.TokenType): bool 
proc curPrecedence(self: Parser): Priority
proc peekPrecedence(self: Parser): Priority
proc peekError(self: Parser, t: token.TokenType)
proc noPrefixFnError(self: Parser, t: token.TokenType)
proc parseProgram(self: Parser): Option[ast.Program] 
proc parseStatement(self: Parser): Option[ast.Statement] 
proc parseExpression(self: Parser, priority: Priority): Option[ast.Expression]
proc parseGroupedExpression(self: Parser): Option[ast.Expression]
proc parseIdentifier(self: Parser): ast.Expression 
proc parseIntegerliteral(self: Parser): ast.Expression
proc parsePrefixExpression(self: Parser): ast.Expression
proc parseInfixExpression(self: Parser, left: Option[ast.Expression]): ast.Expression
proc parseBoolean(self: Parser): ast.Expression

func curTokenIs(self: Parser, t: token.TokenType): bool
func peekTokenIs(self: Parser, t: token.TokenType): bool

proc newParser*(lexer: lexer.ILexer): IParser = 
    let parser = Parser(
        lexer : lexer,
        errs  : @[],
    )

    parser.nextToken()
    parser.nextToken()

    proc registerPrefix(t: token.TokenType, fn: prefixParseFn) = parser.prefixParseFns[t] = fn
    registerPrefix(token.TokenType.IDENT, proc(): ast.Expression = parser.parseIdentifier())
    registerPrefix(token.TokenType.INT, proc(): ast.Expression = parser.parseIntegerliteral())
    registerPrefix(token.TokenType.BANG, proc(): ast.Expression = parser.parsePrefixExpression())
    registerPrefix(token.TokenType.MINUS, proc(): ast.Expression = parser.parsePrefixExpression())
    registerPrefix(token.TokenType.TRUE, proc(): ast.Expression = parser.parseBoolean())
    registerPrefix(token.TokenType.FALSE, proc(): ast.Expression = parser.parseBoolean())
    registerPrefix(token.TokenType.LPAREN, proc(): ast.Expression = 
        let gpExp =parser.parseGroupedExpression()
        return if gpExp.isNone(): ast.Expression() else: gpExp.get()
    )

    proc registerInfix(t: token.TokenType, fn: infixParseFn) = parser.infixParseFns[t] = fn
    registerInfix(token.TokenType.PLUS, proc(e: ast.Expression): ast.Expression = parser.parseInfixExpression(option(e)))
    registerInfix(token.TokenType.MINUS, proc(e: ast.Expression): ast.Expression = parser.parseInfixExpression(option(e)))
    registerInfix(token.TokenType.SLASH, proc(e: ast.Expression): ast.Expression = parser.parseInfixExpression(option(e)))
    registerInfix(token.TokenType.ASTERISC, proc(e: ast.Expression): ast.Expression = parser.parseInfixExpression(option(e)))
    registerInfix(token.TokenType.EQ, proc(e: ast.Expression): ast.Expression = parser.parseInfixExpression(option(e)))
    registerInfix(token.TokenType.NOT_EQ, proc(e: ast.Expression): ast.Expression = parser.parseInfixExpression(option(e)))
    registerInfix(token.TokenType.LT, proc(e: ast.Expression): ast.Expression = parser.parseInfixExpression(option(e)))
    registerInfix(token.TokenType.GT, proc(e: ast.Expression): ast.Expression = parser.parseInfixExpression(option(e)))

    return (
        parseProgram: proc(): Option[ast.Program] = parser.parseProgram(),
        errors: proc(): seq[ast.AstException] =  parser.errs
    );

proc nextToken(self: Parser) = 
    self.curToken = self.peekToken
    self.peekToken = self.lexer.nextToken()

proc expectPeek(self: Parser, t: token.TokenType): bool =
    if self.peekTokenIs(t):
        self.nextToken()
        return true
    else: 
        self.peekError(t)
        return false

proc curPrecedence(self: Parser): Priority = return if precedences.hasKey(self.curToken.typ): precedences[self.curToken.typ] else: Priority.LOWEST
proc peekPrecedence(self: Parser): Priority = return if precedences.hasKey(self.peekToken.typ): precedences[self.peekToken.typ] else: Priority.LOWEST
proc peekError(self: Parser, t: token.TokenType) = self.errs.add(ast.AstException(msg: fmt"expected next token to be {t} got {self.peekToken.typ} instead"))
proc noPrefixFnError(self: Parser, t: token.TokenType) = self.errs.add(ast.AstException(msg: fmt"no prefix parse function for {$t} found"))

proc parseProgram(self: Parser): Option[ast.Program] = 
    let program = ast.Program(statements:  @[])
    while not self.curTokenIs token.TokenType.EOF:
        let smt = self.parseStatement()
        if not smt.isNone():
            program.statements.add(smt.get())
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

    else:
        defer: untrace(trace("parseExpressionStatement"))
        let smt = ast.ExpressionStatement(token: self.curToken)
        smt.expression = self.parseExpression(Priority.LOWEST)
        if self.peekTokenIs token.TokenType.SEMICOLON:
            self.nextToken()
        return option(ast.Statement(smt))

proc parseIdentifier(self: Parser): ast.Expression =  
    ast.Identifier(token: self.curToken, value: self.curToken.literal)

proc parseIntegerliteral(self: Parser): ast.Expression = 
    let msg = trace("parseIntegerliteral")
    defer: untrace(msg)
    ast.IntegerLiteral(value: parseInt(self.curToken.literal), token: self.curToken)

proc parseExpression(self: Parser, priority: Priority): Option[ast.Expression] =
    let msg = trace("parseExpression")
    defer: untrace(msg)

    if not self.prefixParseFns.hasKey(self.curToken.typ): 
        self.noPrefixFnError(self.curToken.typ)
        return none[ast.Expression]()

    let prefix = self.prefixParseFns[self.curToken.typ]
    var leftExp = prefix()
    while not self.peekTokenIs(token.TokenType.SEMICOLON) and ord(priority) < ord(self.peekPrecedence()):
        if not self.infixParseFns.hasKey(self.peekToken.typ):
            return none[ast.Expression]()
        let infix = self.infixParseFns[self.peekToken.typ]
        self.nextToken()
        leftExp = infix(leftExp)

    return option(leftExp)

proc parsePrefixExpression(self: Parser): ast.Expression = 
    let msg = trace("parsePrefixExpression")
    defer: untrace(msg)

    let expression = ast.PrefixExpression(
        token: self.curToken, 
        operator: self.curToken.literal
    )
    self.nextToken()
    expression.right = self.parseExpression(Priority.PREFIX)
    return expression

proc parseInfixExpression(self: Parser, left: Option[ast.Expression]): ast.Expression =
    let msg = trace("parseInfixExpression")
    defer: untrace(msg)
    let expressoion = ast.InfixExpression(
        token: self.curToken, 
        operator: self.curToken.literal,
        left: left,
    )
    let precedence = self.curPrecedence()
    self.nextToken()
    expressoion.right = self.parseExpression(precedence)

    return expressoion

proc parseBoolean(self: Parser): ast.Expression =
    return ast.Boolean(token: self.curToken, value: self.curTokenIs(token.TokenType.TRUE))

proc parseGroupedExpression(self: Parser): Option[ast.Expression] =
    self.nextToken()

    let exp = self.parseExpression(Priority.LOWEST)
    if not self.expectPeek(token.TokenType.RPAREN):
        return none[ast.Expression]()
    
    return exp

func curTokenIs(self: Parser, t: token.TokenType): bool = self.curToken.typ == t
func peekTokenIs(self: Parser, t: token.TokenType): bool =  self.peekToken.typ == t
