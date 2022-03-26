import unittest
import options
import domain/monkey/lexer
import domain/monkey/parser
import domain/monkey/ast

suite "parser.nim statement":
    const tests = {
        "let": (
            """
            let x = 5;
            let y = 10;
            let foobar = 838383;
            """, 3,
            "let", 
            @["x", "y", "foobar"],
            proc(statement: ast.Statement): string = 
                let letSmt = cast[ast.LetStatement](statement)
                return letSmt.name.value
        ),
        "return": (
            """
            return 5;
            return 10;
            return 993322;
            """, 3,
            "return",
            @[], 
            proc(statement: ast.Statement): string = ""
        ),
    }
    for value in tests:
        let title = value[0]
        let values = value[1]
        test title:
            let l = newLexer(values[0])
            let p = parser.newParser(l)
            let program = p.parseProgram()

            assert not program.isNone()
            assert program.get().statements.len == values[1]

            let errs  = p.errors()
            for err in errs:
                echo err
                raise

            for idx, tt in values[3]:
                let smt = program.get().statements[idx]
                assert ast.Node(smt).tokenLiteral() == values[2]
                assert tt == values[4](smt)



    
