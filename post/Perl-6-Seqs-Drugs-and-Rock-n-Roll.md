%% title: Perl 6: Seqs, Drugs, And Rock'n'Roll
%% date: 2017-06-20
%% desc: Detailed descripton of Seq type and the sequence operator
%% draft: true

I vividly recall my first steps in Perl 6 were just a couple of months before
Perl 6's first stable release in December 2015. Around that time, Larry Wall
was presenting Perl 6 and showed a neat feature—the sequence operator—and it
got me amazed about just how powerful the language is:

    # First 12 even numbers:
    say (2, 4 … ∞)[^12];      # OUTPUT: (2 4 6 8 10 12 14 16 18 20 22 24)

    # First 10 powers of 2:
    say (2, 2², 2³ … ∞)[^10]; # OUTPUT: (2 4 8 16 32 64 128 256 512 1024)

    # First 13 Fibonacci numbers:
    say (1, 1, *+* … ∞)[^13]; # OUTPUT: (1 1 2 3 5 8 13 21 34 55 89 144 233)

The ellipsis (`…`) is the sequence operator and the stuff it makes is the `Seq`
object. And today, a year and a half later, I hope to pass my amazement to a
new batch of future Perl 6 programmers, by explaining the sequence operator in
detail. But first, I'll talk about what `Seq`s are all about.

Note: I'll be using the fancy Unicode operators and symbols. If you don't like
them, consult with the [Texas Equivalents page](https://docs.perl6.org/language/unicode_texas) for the equivalent ASCII-only way to type those
elements.

# PART I: What the Seq is all this about?
