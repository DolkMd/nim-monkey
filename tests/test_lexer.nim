import unittest
import std/strutils
import std/tables

from domain/monkey/lexer import newLexer
from domain/monkey/token import TokenType

suite "lexer.nim":
  test "lexer next token":
    const cases = {
        "=+(){},;": @[
            (TokenType.ASSIGN, "="),
            (TokenType.PLUS, "+"),
            (TokenType.LPAREN, "("),
            (TokenType.RPAREN, ")"),
            (TokenType.LBRACE, "{"),
            (TokenType.RBRACE, "}"),
            (TokenType.COMMA, ","),
            (TokenType.SEMICOLON, ";"),
            (TokenType.EOF, ""),
        ]
    }.toTable;
    for text, tests in cases:
        let lexer = newLexer(text)
        for want in tests:
            let tk = lexer.nextToken()
            check(want[0] == tk.tokenType)
            check(want[1] == tk.literal)