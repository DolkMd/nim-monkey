import token, std/strutils
import std/sequtils
import options
import strformat

func optString(v: Option): string = return if not v.isNone(): $v.get() else: ""

type AstException* = object of CatchableError

type 
    Node* = ref object of RootObj
        token*: token.Token
    Statement* = ref object of Node
    Expression* = ref object of Node
    Identifier* = ref object of Expression
        value*: string

method tokenLiteral*(self: Node): string {.base.} =  self.token.literal
method `$`*(self: Node): string {.base.} = self.token.literal
method statementNode(self: Statement): void {.base.} = return
method expressionNode*(self: Expression): void {.base.} = return

type
    LetStatement* = ref object of Statement
        name*: Identifier
        value*: Option[Expression]
    ReturnStatement* = ref object of Statement
        value*: Option[Expression]
    ExpressionStatement* = ref object of Statement
        expression*: Option[Expression]
    BlockStatement* = ref object of Statement
        statements*: seq[Statement]

method `$`*(self: LetStatement): string = fmt"{self.tokenLiteral()} {$self.name} = {optString(self.value)};"
method `$`*(self: ReturnStatement): string = fmt"{self.tokenLiteral()} = {optString(self.value)};"
method `$`*(self: ExpressionStatement): string = return optString(self.expression)
method `$`*(self: BlockStatement): string = toSeq(self.statements).map(proc(s: Statement): string = $s).join("")

type 
    IntegerLiteral* = ref object of Expression
        value*: int64
    Boolean* = ref object of Expression
        value*: bool
    PrefixExpression* = ref object of Expression
        operator*: string
        right*: Option[Expression]
    InfixExpression* = ref object of Expression
        left*: Option[Expression]
        operator*: string
        right*: Option[Expression]
    IfExpression* = ref object of Expression
        condition*: Expression
        consequence*: Option[BlockStatement]
        alternative*: Option[BlockStatement]

method `$`*(self: PrefixExpression): string = fmt"({$self.operator}{optString(self.right)})"
method `$`*(self: InfixExpression): string = fmt"({optString(self.left)} {$self.operator} {optString(self.right)})"
method `$`*(self: IfExpression): string = return 
    if self.alternative.isSome(): fmt"if{self.condition} {optString(self.consequence)} else {optString(self.alternative)}"
    else:  fmt"if{self.condition} {optString(self.consequence)}"
    

type Program* = ref object
    statements*: seq[Statement]

proc tokenLiteral*(self: Program): string = return if self.statements.len > 0: cast[Node](self.statements[0]).tokenLiteral() else: ""
proc `$`*(self: Program): string = 
    return toSeq(self.statements)
        .map(proc(s: Statement): string = $s)
        .join("")
