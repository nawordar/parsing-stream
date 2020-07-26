module parsingstream;

import std.conv;
import std.uni;
import std.exception;

debug import std.stdio;

private enum IsChar(T) = is(T == char) || is(T == wchar) || is(T == dchar);

alias StringStream = ParsingStream!char;

/// This class takes a string and lets you perform simple matching operations to help in writing simple parsers
/// and keep your code readable.
struct ParsingStream(T = char) {

    alias TString = immutable(T)[];
    alias Checker = bool delegate(T);

    /// String we are operating on.
    TString subject;

    /// Current index.
    size_t index;

    /// Current line number.
    size_t lineNumber = 1;

    /// True if the previous character was a carriage return. Used to ignore following line feeds.
    protected bool passedCR;

    /// Create the stream.
    this(TString subject) {

        this.subject = subject;

    }

    /// Returns: true if there is still something left to parse.
    bool opCast(T : bool)() const {

        return index < subject.length;

    }

    // Stepping
    struct {

        /// Match the current character against the function, return true if matched and proceed to the next character.
        ///
        /// Params:
        ///     check = Function to match against.
        ///     character = Reference which will be replaced with the character.
        bool step(Checker check, out T character) {

            // If there is no character left, fail the match
            if (!this) return false;

            // Get the character
            character = subject[index];

            // Check it
            if (check(character)) {

                // Line feed (not CRLF)
                if (character == '\n' && !passedCR) {

                    lineNumber += 1;

                }

                // Carriage return
                else if (character == '\r') {

                    lineNumber += 1;
                    passedCR = true;

                }

                // Other/CRLF — end the break
                else passedCR = false;

                index += 1;
                return true;

            }

            return false;

        }

        /// ditto
        bool step(Checker check) {

            T ignore;
            return step(check, ignore);

        }

        ///
        static if (is(T == char))
        unittest {

            auto stream = StringStream("hello");
            char ch;
            assert( stream.step(a => a == 'h'));  // First character
            assert(!stream.step(a => a == 'l'));  // Second character is an "e", won't match
            assert( stream.step(a => a == 'e'));  // Didn't progress, we can try again
            assert( stream.step(a => a == 'l'));  // Now this will match

            // Using a reference
            assert( stream.step(a => isAlpha(a), ch));
            assert(ch == 'l');

        }

        /// Match the current character against the function and return it.
        ///
        /// Params:
        ///     check = Function to match against.
        /// Throws: MatchException if the character wasn't matched.
        T enforceStep(Checker check) {

            T character;

            // Check if matches
            step(check, character)

                // And throw an exception if it doesn't
                .enforce!MatchException("Match failed.");

            // Return the character
            return character;

        }

        ///
        static if (is(T == char))
        unittest {

            auto stream = StringStream("hello");

            // Matcher for "h" and "e"
            ParsingStream.Checker check = a => a == 'h' || a == 'e';

            assert(stream.enforceStep(check) == 'h');
            assert(stream.enforceStep(check) == 'e');
            assertThrown(stream.enforceStep(check));

        }

        /// A chainable version of this method. Matches the current character against the function and gives it via
        /// a reference argument.
        ///
        /// Returns: Self, for chaining.
        /// Params:
        ///     check = Function to match against.
        ///     match = Matched character (output).
        /// Throws: MatchException if the character wasn't matched.
        ref ParsingStream!T enforceStep(Checker check, out T match) {

            match = enforceStep(check);
            return this;

        }

        ///
        static if (is(T == char))
        unittest {

            auto stream = StringStream("hi!");
            char a, b, c;
            ParsingStream.Checker check = x => x.isAlpha;

            stream
                .enforceStep(check, a)
                .enforceStep(check, b);

            assert(a == 'h');
            assert(b != 'e');
            assertThrown!MatchException(stream.enforceStep(check, c));

        }

    }

    // Matching
    struct {

        /// Match all next characters against the function until it returns `false`.
        ///
        /// Params:
        ///     check = Function to match against.
        /// Returns: All matched characters.
        TString match(Checker check) {

            TString result;
            T lastChar;

            // Step until failure
            while (step(check, lastChar)) {

                result ~= [lastChar];

            }

            return result;

        }

        ///
        static if (is(T == char))
        unittest {

            auto stream = StringStream("This is a sentence.");
            ParsingStream.Checker check = a => a.isAlpha;

            // Match whole words
            assert(stream.skip.match(check) == "This");
            assert(stream.skip.match(check) == "is");
            assert(stream.skip.match(check) != "not");
            assert(stream.skip.match(check) == "sentence");

        }

        /// Match all next characters against the function until it returns `false`.
        ///
        /// Throws: MatchException if didn't match anything
        /// Params:
        ///     check = Function to match against.
        /// Returns: All matched characters.
        TString enforceMatch(Checker check) {

            auto result = match(check);
            enforce!MatchException(result.length > 0, "Empty match.");
            return result;

        }

        ///
        static if (is(T == char))
        unittest {

            auto stream = StringStream("This is a sentence");
            ParsingStream.Checker check = a => a.isAlpha;


            assert(stream.enforceMatch(check) == "This");

            // Will fail, there is some whitespace before — remember to skip()!
            assertThrown(stream.enforceMatch(check));

            assert(stream.skip.enforceMatch(check) == "is");

        }

        /// A chainable version of the method. Matches all next characters against the function until it returns `false`.
        ///
        /// Throws: MatchException if didn't match anything
        /// Params:
        ///     check = Function to match against.
        ///     match = Matched string (output).
        /// Returns: Self, for chaining.
        ref ParsingStream!T enforceMatch(Checker check, out TString match) {

            match = enforceMatch(check);
            return this;

        }

        ///
        static if (is(T == char))
        unittest {

            auto stream = StringStream("This is a sentence");
            ParsingStream.Checker check = a => a.isAlpha;
            string a, b, c;

            assertNotThrown(stream
                .skip.enforceMatch(check, a)
                .skip.enforceMatch(check, b)
            );

            assert(a == "This" && b == "is");

            // No .skip!
            assertThrown(stream.enforceMatch(check, c));

        }

    }

    // Matching until
    struct {

        /// Match all next characters against the function until it returns `true`
        ///
        /// Params:
        ///     check = Function to match against.
        /// Returns: All matched characters.
        TString matchUntil(Checker check) {

            return this.match(ch => !check(ch));

        }

        ///
        static if (is(T == char))
        unittest {

            auto stream = StringStream("This is a sentence");

            assert(stream.skip.matchUntil(ch => ch == ' ') == "This");
            assert(stream.skip.matchUntil(ch => ch == ' ') == "is");
            assert(stream.skip.matchUntil(ch => ch == 'n') == "a se");
            assert(!stream.step(a => a == 't'));

        }

        /// Match all next characters against the function until it returns `true`
        ///
        /// Params:
        ///     check = Function to match against.
        /// Returns: All matched characters.
        /// Throws: MatchException if didn't match anything
        TString enforceUntil(Checker check) {

            auto match = matchUntil(check);
            enforce!MatchException(match.length > 0, "Empty match.");
            return match;

        }

        /// A chainable variant of the function. Match all next characters against the function until it returns `true`
        ///
        /// Params:
        ///     check = Function to match against.
        ///     match = Matched characters (output).
        /// Returns: Self, for chaining.
        /// Throws: MatchException if didn't match anything
        ref ParsingStream!T enforceUntil(Checker check, out TString match) {

            match = enforceUntil(check);
            return this;

        }

    }

    // Skipping
    struct {

        /// Skip one character, without matching.
        ref ParsingStream!T skipOne() {

            step(_ => true);
            return this;

        }

        /// Skip all characters until one doesn't match, for built-in chars, Unicode whitespace is the default.
        ///
        /// Params:
        ///     check = Function to match against.
        /// Returns: the stream, to allow chaining with other methods.
        ref ParsingStream!T skip(Checker check) {

            match(check);
            return this;

        }

        static if (is(T == char) || is(T == wchar) || is(T == dchar)) {

            /// ditto
            ref ParsingStream!T skip() {

                match(a => isWhite(a));
                return this;

            }

        }

        /// Skip all characters until one matches.
        ///
        /// Params:
        ///     check = Function to match against.
        /// Returns: the stream, to allow chaining with other methods.
        ref ParsingStream!T skipUntil(Checker check) {

            matchUntil(check);
            return this;

        }

        /// Skip a single character if it matches.
        /// Params:
        ///     check = Function to match against.
        /// Returns: the stream, to allow chaining with other methods.
        ref ParsingStream!T skipStep(Checker check) {

            step(check);
            return this;

        }

        ///
        static if (is(T == char))
        unittest {

            auto stream = StringStream("  white  = space(stuff)");

            assert(stream.skip().match(a => a.isAlpha) == "white");

        }

    }

}

/// ditto
deprecated("Use StringStream instead.")
ParsingStream!char parsingStream(string content = "") {

    return ParsingStream!char(content);

}

/// An exception thrown if a match fails.
class MatchException : Exception {

    /// Create a match exception
    this(string content) {

        super(content);

    }

    /// Create a match exception
    this(string content, string file, size_t line) {

        super(content, file, line);

    }

}
