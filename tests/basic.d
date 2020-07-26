module tests.basic;

import parsingstream;

import std.uni;
import std.stdio;
import std.string;
import std.algorithm;

// README example.
unittest {

    auto stream = ParsingStream!char("a fox jumped over\tthe lazy brown dog");
    auto words = ["a", "fox", "jumped", "over", "the", "lazy", "brown", "dog"];

    while (stream) {

        // `skip` jumps over whitespace
        auto word = stream.skip.match(a => a.isAlpha);
        assert(words.canFind(word));

    }

}

// Typing test, to check whether alternative types work.
unittest {

    auto a = ParsingStream!char();
    auto b = ParsingStream!wchar();
    auto c = ParsingStream!dchar();
    auto d = ParsingStream!ubyte();

}

// Line counting test
unittest {

    auto stream = ParsingStream!char("one\ntwo\r\nthree\rfour");

    size_t line = 0;
    while (stream) {

        line++;

        // Pass over the word on the current line
        stream.skip.match(a => a.isAlpha);

        assert(stream.lineNumber == line, "got %s expected %s".format(stream.lineNumber, line));

    }

    assert(line == 4);

}
