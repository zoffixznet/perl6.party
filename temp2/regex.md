A Primer to New Readable Syntax of Perl 6 Regex


One of Perl 6's awesomest features are Grammars: a well-structured collection of regexes. But what makes Perl 6 Grammars trully great is they use Perl 6's very own new and improved regex syntax.

Many languages use PCRE, or similar, syntax for regexes, which while fairly concise, becomes a monster to maintain as complexity grows. Programatic regex "explainers" as well as various frameworks that try to make the syntax more readable exist that try to ameliourate that problem. Perl 6, on the other hand, said enough is enough, and trailblazed a brand new syntax for regexes. Syntax that's more readable and more powerful than the status quo.

Today, we'll examine some of that juicy syntax. We won't cover everything, but enough of the good bits to give the curious minds a taste of the Perl 6 world. Let's begin!

## Make Yourself Comfortable

The very first thing to notice about Perl 6 regexes is whitespace is not significant, by default:

    say '42foos' ~~ /42  foos/;
    # OUTPUT: «｢42foos｣␤»

Comments can be used just the same as in the rest of the code and so can strings. That is, if you plan to match a literal string, you can quote it; spaces inside quoted strings are *not* ignored:

    say 'I love Perl 6' ~~ /
        I \s+
        $<verb>=[ 'love' | 'like' ] # An alternation with a named capture
        ' ' # just a quoted space
        'Perl 6'
    /

    # OUTPUT:
    # ｢I love Perl 6｣
    #  verb => ｢love｣
