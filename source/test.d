module test;

import parsingstream;

import std.uni;
import std.stdio;
import std.algorithm;

// README example.
unittest {

    auto stream = parsingStream("a fox jumped over\tthe lazy brown dog");
    auto words = ["a", "fox", "jumped", "over", "the", "lazy", "brown", "dog"];

    while (stream) {

        // `skip` jumps over whitespace
        auto word = stream.skip.match(a => a.isAlpha);
        assert(words.canFind(word));

    }

}

// Typing test, to check whether alternative types work.
unittest {

    parsingStream();
    auto a = ParsingStream!wchar();
    auto b = ParsingStream!dchar();
    auto c = ParsingStream!ubyte();

}
