%% title: Perl 6: Zero-Denominator Rationals
%% date: 2018-02-23
%% desc: Dividing by zero in Perl 6
%% draft: true

Through a strange quirk of fate, I keep returning to do various work defining
how zero-denominator rational numbers behave in Perl 6 in various constructs.
So today, I figured I talk about those strange-looking beasts. Don't worry, no
Universes were imploded during creation of this article!

<img class="img-thumbnail img-responsive center-block"
    src="/assets/pics/divided-by-zero.jpg" alt="">

## A 30-Second Primer to Perl 6 Rationals

Perl 6 uses rational numbers out of the box. The following statement prints
`True` in Perl 6, while in many other languages it would erroneously
give `False`, due to imprecision of floating point math:

    say 0.1 + 0.2 == 0.3; # OUTPUT: «True␤»

The ``Rat`` and ``FatRat`` are the two core ``Rational`` types. The
``Rat`` type will keep being a ``Rational`` as long as its denominator
can is fewer than 64 bits (after reduction of the rational number to the lowest
denominator), otherwise, it gets converted to a ``Num`` type,  which is just
your off-the-shelf double-precision floating point type. The ``Rat`` is the
type you get when you use decimal numbers, e.g. `1.42`, fractions written
using Unicode characters, e.g. `¾`, or a ``Rat`` literal synax
with angle brackets, e.g. `<1/2>`.

The ``FatRat`` type does not degenerate into a ``Num`` and instead lets its denominator grow as large as it needs to be. The ``FatRat`` is also the most
"infectious" of
``Numeric`` types: any mathematical operation with it with some other
``Numeric``would result in a ``FatRat`` answer. Why isn't ``FatRat`` the
default and only ``Rational``? Because when these get large enough, they
degrade performance and most users do not need huge amounts of precision.

The ``Rat`` type is what you get when you divide some ``Numeric``s, e.g. two
``Int``s:

    say (2/4).^name; # OUTPUT: «True␤»

In such a case, the `/` division operator doesn't actually divide anything; it
can be seen as a *constructor* for a ``Rat`` object. We can dump the **nu**merator and **de**nominator of a ``Rational`` using the ``.nude`` method:

    say (2/4).nude; # OUTPUT: «(1 2)␤»

As you can see, our fraction got reduced to the lowest denominator, with the
result being a ``Rat`` object with `1` for numerator and `2` for denominator.

Since no division takes place, it's not surprising that you can use zero
as denominator:

    say (42/0).nude; # OUTPUT: «(42 0)␤»

## Imploding the Universe