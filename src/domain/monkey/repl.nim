from lexer import newLexer
from token import TokenType

const PROMPT = ">> ";

proc repl*(reader: File, writer: File) =
    while true:
        writer.write(PROMPT)
        let scanned = reader.readLine()
        let lexer = newLexer(scanned)
        var tok = lexer.nextToken()
        echo tok
        while tok.typ != token.TokenType.EOF:
            tok = lexer.nextToken()
            echo tok
