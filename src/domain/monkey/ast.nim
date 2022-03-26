import token, std/strutils
import std/sequtils
import options
import strformat

type AstException* = object of Exception

type Expression* = object of RootObj
type 
    Node* = ref object of RootObj
        token*: token.Token
    Statement* = ref object of Node
    Identifier* = ref object of Statement
        value*: string

method tokenLiteral*(self: Node): string {.base.} = return self.token.literal
method `$`*(self: Node): string {.base.} = ""
method statementNode(self: Statement): void {.base.} = return
method expressionNode*(self: Statement): void {.base.} = return

type 
    LetStatement* = ref object of Statement
        name*: Identifier
        value*: Option[Expression]
    ReturnStatement* = ref object of Statement
        value: Option[Expression]
    ExpressionStatement* = ref object of Statement
        value*: Option[Expression]

proc `$`*(self: LetStatement): string =
    let value = if self.value.isNone(): $self.value.get() else: ""
    return fmt"{self.tokenLiteral()} {$self.name} = {value};"

proc `$`*(self: ReturnStatement): string =
    let value = if self.value.isNone(): $self.value.get() else: ""
    return fmt"{self.tokenLiteral()} = {value};"

proc `$`*(self: ExpressionStatement): string =
    return if self.value.isNone(): $self.value.get() else: ""

type Program* = ref object
    statements*: seq[Statement]
proc tokenLiteral*(self: Program): string =
   return if self.statements.len > 0: cast[Node](self.statements[0]).tokenLiteral()
    else: ""

proc `$`*(self: Program): string =
    return toSeq(self.statements)
        .map(proc(s: Statement): string = $s)
        .join(" ")