%% title: Perl 6: Seqs, Drugs, And Rock'n'Roll (Part 3)
%% date: 2017-06-27
%% desc: How to make your very own Iterator object
%% draft: true

This is the third part in the series! Be sure you
[read Part I](https://perl6.party/post/Perl-6-Seqs-Drugs-and-Rock-n-Roll), where we discuss
what ``Seq|s`` are and how to ``.cache`` them, as well as
[read Part II](https://perl6.party/post/Perl-6-Seqs-Drugs-and-Rock-n-Roll)
where we talk about ``Iterator|s`` that power the``Seq|s``.

Today, we return to what inspired this series: the power of the Seqeuence
Operator. We'll learn how it works as well examine some of the more advanced
uses of it that help you cut down on the code needed to make a ``Seq``. Without
further ado, I present: …

# PART III: …

The Sequence Operator is code point `U+2026 HORIZONTAL ELLIPSIS […]` that looks
like tightly-packed three dots. For those for whom typing Unicode is not a
strongpoint, as with all Perl 6 Unicode operators, a
[Texas variant](https://docs.perl6.org/language/unicode_texas.html) exists,
which is just the three separate dots: `...`

Be on the look out for Sequence Operator's younger brother, the
[`Range` operator](https://docs.perl6.org/routine/...html) that consists of
*two* dots (`..`) and merely creates ``Range| objects``. If you use a method
call on `$_` topic variable as the end point, be sure to include a space before
it, as otherwise the compiler will think you're trying to use the Sequence
Operator and not the [`Range` operator](https://docs.perl6.org/routine/...html):

    # WRONG:
    with -42 { say 5...abs } # OUTPUT: «===SORRY!=== Error while compiling»

    # RIGHT:
    with -42 { say 5.. .abs } # OUTPUT: «5..42␤»

    # Even better:
    with -42 { say 5 .. .abs } # OUTPUT: «5..42␤»

But back to the star of the hour. Let's see what arguments the Sequence
Operator likes to take!

## From A to B

As the name suggests, the Sequence Operator creates sequences, which are
represented using ``Seq`` objects we're now so familiar with. The simplest
form of the operator is the most brotherly to the [`Range` operator](https://docs.perl6.org/routine/...html) and consists of two arguments that are
``Numeric``:

    put 1…5;  # OUTPUT: «1 2 3 4 5␤»
    put 1..5; # OUTPUT: «1 2 3 4 5␤»

However, unlike the end points of the [`Range` operator](https://docs.perl6.org/routine/...html), the Sequence Operator's end points do not have to be
one higher than the first to produce values, so you can use the Sequence
Operator to, for example, create descending sequences of numbers:

    put 5…1;  # OUTPUT: «5 4 3 2 1␤»
    put 5..1; # OUTPUT: «␤»

The increments are made with the ``.succ`` method called on the starting
``Numeric`` and decrements are made with the ``.pred`` method. For example,
if we mix in a role that overrides those methods