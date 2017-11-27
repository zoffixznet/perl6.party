A Primer to New Readable Syntax of Perl 6 Regex


One of Perl 6's awesomest features are Grammars: a well-structured collection of regexes. But what makes Perl 6 Grammars trully great is they use Perl 6's very own new and improved regex syntax.

Many languages use PCRE, or similar, syntax for regexes, which while fairly concise, becomes a monster to maintain as complexity grows. Programatic regex "explainers" as well as various frameworks that try to make the syntax more readable exist that try to ameliourate that problem. Perl 6, on the other hand, said enough is enough, and trailblazed a brand new syntax for regexes. Syntax that's more readable and more powerful than the status quo.

Today, we'll examine some of that juicy syntax. We won't cover everything, but enough of the good bits to give the curious minds a taste of the Perl 6 world. Let's begin!

## Make Yourself Comfortable

The very first thing to notice about Perl 6 regexes is whitespace is not significant, by default:

    say '42foos' ~~ /42  foos/;
    # OUTPUT: «｢42foos｣␤»

Comments can be used just the same as in the rest of the code and so can strings. That is, if you plan to match a literal string, you can quote it and not worry about escaping any metacharacters inside. Spaces *inside* the quoted strings are *not* ignored:

    say 'I love Perl 6' ~~ /
        I \s+
        $<verb>=[ 'love' | 'like' ] # An alternation with a named capture
        ' ' # just a quoted space
        'Perl 6'
    /

    # OUTPUT:
    # ｢I love Perl 6｣
    #  verb => ｢love｣

This makes it very comfortable to separate the literal data you're trying to
match from the regex-specific metacharacters. Ever heard of a "Leaning Toothpick Syndrome"? It's when you're trying to use special characters, like the backslash, literally. They need escaping with more backslashes. Things get out of hand pretty fast, especially if you're trying to double-escape things to produce an escaped result to hand out to something. Among the sea of backslashes at can be tough to see which ones are merely escapes and which one are part of the data.

Perl 6 solves this problem with its corner bracket quoters that have all special characters, including the backslash escapes, disabled. And since Perl 6 regexes allow you to quote your literal match strings, the corner quoters come in handy in this situation:

    say ｢\\zofbox\MeowMix\ZofferTunes.mp3｣ ~~ /
        ｢\\｣ $<box>   = \w+
        ｢\｣  $<album> = \w+
        ｢\｣  $<tune>  = .+
    /;

    # OUTPUT:
    # ｢\\zofbox\MeowMix\ZofferTunes.mp3｣
    #  box => ｢zofbox｣
    #  album => ｢MeowMix｣
    #  tune => ｢ZofferTunes.mp3｣

Not a single backslash that shouldn't be there!

## Keep The Good Things

Despite being heavily improved, Perl 6 regexes still have many of the familiar elements:

    with "foo42" {
        say m/ \w+ /;  # ｢foo42｣ # match letter, digit, or _
        say m/ \d+ /;  # ｢42｣    # match digit (any Unicode digit)
        say m/ .*  /;  # ｢foo42｣ # 0 or more characters
        say m/ .+  /;  # ｢foo42｣ # 1 or more characters
        say m/ .+? /;  # ｢f｣     # 1 or more characters, frugal match
    }

Although, the `.` metacharacter matches *any* character and does not require any regex modifiers to match a newline character. Similarly, all special-casing was removed from `^` and `$` metacharacters. They match at the start and end of the *string,* not line, and do not have any modifiers to affect their behaviour. To match beginning or end of line, just double these up: `^^` and `$$`. Also, the `$` now always matches the end of string, without paying any regard to the newline character.

    with "foo42\nbar♥\n" {
        say so m/'♥'    $/; # False
        say so m/'♥' \n $/; # True
        say so m/'♥'   $$/; # True

        say so m/ 42   $ /; # False
        say so m/ 42  $$ /; # True
        say so m/ ^  bar /; # False
        say so m/ ^^ bar /; # True
        say so m/ ^  foo /; # True
        say so m/ ^^ foo /; # True
    }

And if you feel a bit overwhelmed with all the new syntax, use the `P5` adverb on the regex to turn on the Perl 5 regex mode:

    say "foo100bar3bar42" ~~ /<.after 3> .+ <.before 42>/;
    say "foo100bar3bar42" ~~ m:P5/(?<=3).+(?=42)/;

    # OUTPUT:
    # ｢bar｣
    # ｢bar｣

Not all of the features are supported by this mode, but it should be sufficient as training wheels, while you learn the more powerful Perl 6 regexes.

## Throw Out The Bad Things