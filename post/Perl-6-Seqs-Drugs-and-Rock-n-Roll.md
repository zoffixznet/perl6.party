%% title: Perl 6: Seqs, Drugs, And Rock'n'Roll
%% date: 2017-06-20
%% desc: Detailed descripton of Seq type and the sequence operator
%% draft: true

I vividly recall my first steps in Perl 6 were just a couple of months before
Perl 6's first stable release in December 2015. Around that time, Larry Wall
was presenting and showed a neat feature—the sequence operator—and it
got me amazed about just how powerful the language is:

    # First 12 even numbers:
    say (2, 4 … ∞)[^12];      # OUTPUT: (2 4 6 8 10 12 14 16 18 20 22 24)

    # First 10 powers of 2:
    say (2, 2², 2³ … ∞)[^10]; # OUTPUT: (2 4 8 16 32 64 128 256 512 1024)

    # First 13 Fibonacci numbers:
    say (1, 1, *+* … ∞)[^13]; # OUTPUT: (1 1 2 3 5 8 13 21 34 55 89 144 233)

The ellipsis (`…`) is the sequence operator and the stuff it makes is the `Seq`
object. And today, a year and a half later, I hope to pass on my amazement to a
new batch of future Perl 6 programmers, by explaining the sequence operator in
detail. But first, I'll talk about what `Seq`s are.

Note: I'll be using the fancy Unicode operators and symbols in this article.
If you don't like them, consult with the [Texas Equivalents page](https://docs.perl6.org/language/unicode_texas)
for the equivalent ASCII-only way to type those elements.

# PART I: What the Seq is all this about?

The `Seq` stands for *Sequence* and the `Seq` object provides a one-shot way
to iterate over a sequence of stuff. New values can be generated on demand—and
in fact, it's perfectly possible to create infinite sequences—and already-
generated values are discarded, never to be seen again, although, there's a
way to cache them, as we'll see.

Sequences are driven by `Iterator` objects that are responsible for generating
values. However, in many cases you don't have to create `Iterator`s directly
or use their methods while iterating a `Seq`. One way to generate a `Seq` is
using the sequence operator, which we'll examine in PART II. In this section,
we'll talk about `gather`/`take` as well as contructing `Seqs` from our very
own `Iterator` objects.

## I gather you'll take me to...

The `gather` statement and `take` routine are similar to "generators" and "yield" statement in some other languages:

    my $stuff = gather {
        take 'me away'
        say 'A secret place';
        say 'A sweet escape';
        take 'MEEE AWAAAAY';
        say 'to better days';
        take 'MEEE AWAAAAYYYY';
        say 'A hiding place';
        # https://www.youtube.com/watch?v=0btXhLdAuAc
    }
