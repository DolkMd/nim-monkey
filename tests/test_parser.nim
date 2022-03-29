import unittest
import options
import strformat

import domain/monkey/lexer
import domain/monkey/parser
import domain/monkey/ast

proc testLiteralExpression[T](exp: ast.Expression, value: auto): bool =
    let ident = T(exp)
    check:
        ident.value == value
        ident.tokenLiteral == value
proc testInfixExpression(exp: ast.Expression, left: auto, operator: string, right: auto) =
    let opExp = ast.InfixExpression(exp)
    check:
        testLiteralExpression(opExp.left, left)
        opExp.operator == operator
        testLiteralExpression(opExp.right, right)

suite "parser.nim statement":
    test "program  string":
        const cases = @[
            ("-a * b","((-a) * b)"),
            ("!-a","(!(-a))"),
            ("a + b + c","((a + b) + c)"),
            ("a + b - c","((a + b) - c)"),
            ("a * b * c", "((a * b) * c)"),
            ("a * b / c", "((a * b) / c)"),
            ("a + b / c", "(a + (b / c))"),
            ("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
            ("3 + 4; -5 * 5", "(3 + 4)((-5) * 5)"),
            ("5 > 4 == 3 < 4","((5 > 4) == (3 < 4))"),
            ("5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"),
            ("3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
            ("true","true"),
            ("false","false"),
            ("3 > 5 == false","((3 > 5) == false)"),
            ("3 < 5 == true","((3 < 5) == true)"),
            ("1 + (2 + 3) + 4","((1 + (2 + 3)) + 4)"),
            ("(5 + 5) * 2","((5 + 5) * 2)"),
            ("2 / (5 + 5)","(2 / (5 + 5))"),
            ("(5 + 5) * 2 * (5 + 5)","(((5 + 5) * 2) * (5 + 5))"),
            ("-(5 + 5)","(-(5 + 5))"),
            ("!(true == true)","(!(true == true))"),
            ("a + add(b * c) + d","((a + add((b * c))) + d)"),
            ("add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))","add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"),
            ("add(a + b + c * d / f + g)","add((((a + b) + ((c * d) / f)) + g))"),
        ]

        for values in cases:
            let l = newLexer(values[0])
            let p = parser.newParser(l)
            let program = p.parseProgram()
            echo  fmt"'{values[1]}', {$program.get()}", values[1] == $program.get()
    const tests = {
        "let": (
            @["""
            let x = 5;
            let y = 10;
            let foobar = 838383;
            """], 
            3,
            proc(statements: seq[ast.Statement], inputIdx: int): void = 
                for idx, tt in @["x", "y", "foobar"]:
                    let smt = cast[ast.LetStatement](statements[idx])
                    check:
                        ast.Node(smt).tokenLiteral() == "let"
                        tt == smt.name.value
        ),
        "return": (
            @["""
            return 5;
            return 10;
            return 993322;
            """],
            3,
            proc(statements: seq[ast.Statement], inputIdx: int): void = return
        ),
        "identigier express": (
            @["foobar;"],
            1,
            proc(statements: seq[ast.Statement], inputIdx: int): void = 
                let expSmt = ast.ExpressionStatement(statements[0])
                let ident = ast.Identifier(expSmt.expression.get())

                check:
                    ident.value == "foobar"
                    ident.tokenLiteral() == "foobar"
        ),
        "integer literal expression": (
            @["5;"],
            1,
            proc(statements: seq[ast.Statement], inputIdx: int): void = 
                let expSmt = ast.ExpressionStatement(statements[0])
                let literal = ast.IntegerLiteral(expSmt.expression.get())
                check:
                    literal.value == 5
                    literal.tokenLiteral() == "5"
        ),
        "parsing prefix expressions": (
            @["!5", "-15"],
            1,
            proc(statements: seq[ast.Statement], inputIdx: int): void =
                let expSmt = ast.ExpressionStatement(statements[0])
                let preExp = ast.PrefixExpression(expSmt.expression.get())
                let integ = ast.IntegerLiteral(preExp.right.get())
                let checks = proc(operator: string, value: int64, literal: string) = 
                    check:
                        preExp.operator == operator
                        integ.value == value
                        integ.tokenLiteral() == literal
                
                case inputIdx:
                of 0: checks("!", 5, "5")
                of 1: checks("-", 15, "15")
                else: return
        ),
        "parsing infix expressions": (
            @[
                "5 + 5;",
                "5 - 5;",
                "5 * 5;",
                "5 / 5;",
                "5 > 5;",
                "5 < 5;",
                "5 == 5;",
                "5 != 5;",
                "true == true",
                "true != false",
                "false == false",
            ],
            1,
            proc(statements: seq[ast.Statement], inputIdx: int): void =
                let expSmt = ast.ExpressionStatement(statements[0])
                let inExp = ast.InfixExpression(expSmt.expression.get())
                
                proc checksInt(operator: string, leftv, rightv: any, lefts, rights: string) = 
                    let left = ast.IntegerLiteral(inExp.left.get())
                    let right = ast.IntegerLiteral(inExp.right.get())
                    check:
                        inExp.operator == operator
                        left.value == leftv
                        left.tokenLiteral() == lefts
                        right.value == rightv
                        right.tokenLiteral() == rights
                proc checksBool(operator: string, leftv, rightv: any, lefts, rights: string) = 
                    let left = ast.Boolean(inExp.left.get())
                    let right = ast.Boolean(inExp.right.get())
                    check:
                        inExp.operator == operator
                        left.value == leftv
                        left.tokenLiteral() == lefts
                        right.value == rightv
                        right.tokenLiteral() == rights
                
                case inputIdx:
                of 0: checksInt("+", 5, 5, "5", "5")
                of 1: checksInt("-", 5, 5, "5", "5")
                of 2: checksInt("*", 5, 5, "5", "5")
                of 3: checksInt("/", 5, 5, "5", "5")
                of 4: checksInt(">", 5, 5, "5", "5")
                of 5: checksInt("<", 5, 5, "5", "5")
                of 6: checksInt("==", 5, 5, "5", "5")
                of 7: checksInt("!=", 5, 5, "5", "5")
                of 8: checksBool("==", true, true, "true", "true")
                of 9: checksBool("!=", true, false, "true", "false")
                of 10: checksBool("==", false, false, "false", "false")
                else: return
        ),
        "bool expression": (
            @["true;", "false;"],
            1,
            proc(statements: seq[ast.Statement], inputIdx: int): void =
                let expSmt = ast.ExpressionStatement(statements[0])
                let boolExp = ast.Boolean(expSmt.expression.get())
                case inputIdx:
                of 0: check(boolExp.value == true)
                of 1: check(boolExp.value == false)
                else: discard
        ),
        "if expression": (
            @["true;", "false;"],
            1,
            proc(statements: seq[ast.Statement], inputIdx: int): void =
                let expSmt = ast.ExpressionStatement(statements[0])
                let boolExp = ast.Boolean(expSmt.expression.get())
                case inputIdx:
                of 0: check(boolExp.value == true)
                of 1: check(boolExp.value == false)
                else: discard
        ),
    }
    for value in tests:
        let title = value[0]
        let values = value[1]
        test title:
            for idx, input in values[0]:
                let l = newLexer(input)
                let p = parser.newParser(l)
                let program = p.parseProgram()

                assert not program.isNone()
                assert program.get().statements.len == values[1]

                let errs  = p.errors()
                for err in errs:
                    echo err
                    raise
                values[2](program.get().statements, idx)
