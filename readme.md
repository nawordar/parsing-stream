# parsing-stream

A simple package to help build parsers.

```d
import std.uni;
import std.algorithm;
import parsingstream;

auto stream = new parsingStream("a fox jumped over\tthe lazy brown dog");
auto words = ["a", "fox", "jumped", "over", "the", "lazy", "brown", "dog"];

while (stream) {

    auto word = stream.skip.match(&isAlpha);
    assert(words.canFind(word));

}
```

## UTF-16, UTF-32 and binary

You can give a type as an argument to the ParsingStream class to decide the type of the stream — UTF-8 (`char`)
is the default one.

```d
ParsingStream!char;   # UTF-8
ParsingStream!wchar;  # UTF-16
ParsingStream!dchar;  # UTF-32
ParsingStream!ubyte;  # Binary
```

You can also use it in other ways, for example to match tokens:

```d
import my.tokenizer;

struct Token {

    enum Type { ... }

    Type type;
    string content;

}

auto tokens = tokenize("a fox jumped over the lazy brown dog");
auto stream = new ParsingStream!Token(tokens);
```

## TODO

* Finish code coverage.
* Add `look` or `lookAhead`.
* Add an method to `repeat` operations and return an array, preferably `repeat(a => a.action.action)` also with
  an `out` variant.
* Add `untilNext`.
* Add match methods for substrings.
