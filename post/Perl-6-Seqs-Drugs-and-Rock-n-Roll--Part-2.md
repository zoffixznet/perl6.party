%% title: Perl 6: Seqs, Drugs, And Rock'n'Roll (Part 2)
%% date: 2017-06-20
%% desc: How to make your very own Iterator object
%% draft: true

This is the second part in the series! Be sure you
[read Part I first](/post/Perl-6-Seqs-Drugs-and-Rock-n-Roll) where we discuss
what `T`Seq``s are and how to `R`.cache`` them.

Today, we'll take the `T`Seq`` apart and see what's up in it; what drives it;
and how to make it do exactly what we want.

# PART II: That Iterated Quickly

The main piece that makes a `Seq` do its thing is
an object that does the [`Iterator`](https://docs.perl6.org/type/Iterator)
role. It's *this* object that knows how to generate the next value, whenever
we try to pull a value from a `Seq`, or push all of its values somewhere, or
simply discard all of the remaining values.

Keep in mind that you never need to use `Iterator`'s methods directly,
when making use of a `Seq` as a source of values. They're are called
indirectly under the hood in various Perl 6 constructs. The usecase for calling
those methods yourself is often when making an `Iterator` that's fed by another
`Iterator`, as we'll see.

## Pull my finger...

In its most basic form, an `Iterator` object needs to provide only one method:
`.pull-one`

    my $seq := Seq.new: class :: does Iterator {
        method pull-one {
            return $++ if $++ < 4;
            IterationEnd
        }
    }.new;

    .say for $seq;

    # OUTPUT:
    # 0
    # 1
    # 2
    # 3

Above, we create a `Seq` using its
[`.new` method](https://docs.perl6.org/type/Seq#method_new) that expects an
instantiated [`Iterator`](https://docs.perl6.org/type/Iterator), for which
we use an anonymous `class` that does the role and provides a single
`.pull-one` method that uses a pair of
[anonymous variables](https://docs.perl6.org/syntax/$) to generate 4 numbers,
one per call, and then returns
[`IterationEnd` constant](https://docs.perl6.org/type/Iterator#IterationEnd) to signal the `Iterator`
does not have any more values to produce.

The Iterator protocol **forbids** attempting to fetch more values from an
`Iterator` once it generated the
[`IterationEnd`](https://docs.perl6.org/type/Iterator#IterationEnd) value, so
your `Iterator`'s methods may assume they'll never get called again past that
point.

## Where's the rest of the family?

The `Iterator` role defines several more methods, but other than `.pull-one`
they're optional to implement. The extra methods are there for optimization
purposes that let you take shortcuts depending on how the sequence is iterated
over.

Let's build a `Seq` that hashes a bunch of data using
[`Crypt::Bcrypt` module](https://modules.perl6.org/repo/Crypt::Bcrypt)
(run `zef install Crypt::Bcrypt` to install it). We'll
start with the most basic `Iterator` that provides `.pull-one` method and
then we'll optimize it to perform better in different circumstances.

    use Crypt::Bcrypt;

    sub hash-it (*@stuff) {
        Seq.new: class :: does Iterator {
            has @.stuff;
            method pull-one {
                @!stuff
                    ?? bcrypt-hash( @!stuff.shift, :15rounds )
                    !! IterationEnd
            }
        }.new: :@stuff
    }

    my $hashes := hash-it <foo bar ber>;
    for $hashes {
        say "Fetched value #{++$} {now - INIT now}";
        say "\t$_";
    }

    # OUTPUT:
    # Fetched value #1 2.26035863
    #     $2b$15$ZspycxXAHoiDpK99YuMWqeXUJX4XZ3cNNzTMwhfF8kEudqli.lSIa
    # Fetched value #2 4.49311657
    #     $2b$15$GiqWNgaaVbHABT6yBh7aAec0r5Vwl4AUPYmDqPlac.pK4RPOUNv1K
    # Fetched value #3 6.71103435
    #     $2b$15$zq0mf6Qv3Xv8oIDp686eYeTixCw1aF9/EqpV/bH2SohbbImXRSati

In the above program, we wrapped all the `Seq` making stuff inside
a `sub` called `hash-it`. We [slurp](https://docs.perl6.org/type/Signature#Types_of_Slurpy_Array_Parameters) all the positional
arguments given to that sub and instantiate a new `Seq` with an anonymous
`class` as an `Iterator`. We use attribute `@!stuff` to store the stuff we
need to hash. In the `.pull-one` method we check if we still have
`@!stuff` to hash; if we do, we [shift](https://docs.perl6.org/routine/shift)
a value off `@!stuff` and hash it, using 15 rounds to make the hashing algo
take some time. Lastly, we added a `say` statement to measure
how long the program has been running for each iteration. From the output,
we see it takes about 2.2 seconds to produce a single hash.

### Skipping breakfast

Using a `for` loop, is not the only way to use the `Seq` returned by our
hashing routine. What if some user doesn't care about the first few hashes?
For example, they could write a piece of code like this:

    my $hash = hash-it(<foo bar ber>).skip(2).head;
    say "Made hash {now - INIT now}";
    say bcrypt-match 'ber', $hash;

    # OUTPUT:
    # Made hash 6.6813790
    # True

We've used `bcrypt-match` routine to ensure the hash we got matches our
third input string and it does, but look at the timing in the output. It took
`6.7s` to produce that single hash!

In fact, the things will look the worse the more items the user tries to skip.
If the user calls our `hash-it` with a ton of items and then tries to
[`.skip`](https://docs.perl6.org/routine/skip) the first 1,000,000 elements to
get at the 1,000,001<sup>st</sup> hash, they'll be waiting for about
25 days for that single hash to be produced.

The reason is our basic operator only knows how to `.pull-one`, so the
skip operation still generates the hashes, just to discard them. Since the
values our `Iterator` generates do not depend on previous values, we can
implement one of the optimizing methods to skip iterations cheaply:

    use Crypt::Bcrypt;

    sub hash-it (*@stuff) {
        Seq.new: class :: does Iterator {
            has @.stuff;
            method pull-one {
                @!stuff
                    ?? bcrypt-hash( @!stuff.shift, :15rounds )
                    !! IterationEnd
            }
            method skip-one {
                return False unless @!stuff;
                @!stuff.shift;
                True
            }
        }.new: :@stuff
    }

    my $hash = hash-it(<foo bar ber>).skip(2).head;
    say "Made hash {now - INIT now}";
    say bcrypt-match 'ber', $hash;

    # OUTPUT:
    # Made hash 2.2548012
    # True

We added a `.skip-one` method to our `Iterator` that instead of hashing a
value, simply discards it. It needs to return a truthy value, if there was
a value to be skipped, or falsy value if there weren't any values to skip.

Now, the `.skip` method called on our `Seq` uses
that method to cheaply skip through 2 items and then uses `.pull-one` to
generate the third hash. Look at the timing now: 2.2s; the time it takes to
generate a single hash.

However, we can kick it up a notch. While we won't notice a difference with
our 3-item `Seq`, that user who was attempting to skip 1,000,000 items won't
get the 2.2s time to generate the 1,000,000th hash. They would also have to
wait for 1,000,000 calls to `.skip-one`, `@!stuff.shift` and `so @!stuff`. To
optimize skipping over *a bunch of items*, we can implement the
`.skip-at-least` (for brievity, just our `Iterator` class is shown):

    class :: does Iterator {
        has @.stuff;
        method pull-one {
            @!stuff
                ?? bcrypt-hash( @!stuff.shift, :15rounds )
                !! IterationEnd
        }
        method skip-one {
            return False unless @!stuff;
            @!stuff.shift;
            True
        }
        method skip-at-least (Int \n) {
            n == @!stuff.splice: 0, n
        }
    }

The `.skip-at-least` method takes an `Int $n` items to skip. It should
skip as many as it can, and return a truthy value if it was able to skip
`$n` items, and falsy value if the number of skipped items was less than `$n`.
Now, the user who skips 1,000,000 items will only have to suffer through
a single [.splice](https://docs.perl6.org/routine/splice) call.

For the sake of completeness, there's another skipping method defined by
`Iterator`: `.skip-at-least-pull-one`. It follows the same semantics as
`.skip-at-least`, except with `.pull-one` semantics for return values. Its
default implemention involves just calling those two methods, short-circuiting
and returning `IterationEnd` if the `.skip-at-least` returned a falsy value,
and it is very likely good enough for all `Iterator`s. The method exists as a
convenience for `Iterator` *users* who call methods on `Iterators` and (at the
moment) it's not used in core Rakudo Perl 6 by any methods that can be
called on users' `Seq`s.

## A so, so count...

There are two more optimization methods possible: `R`.bool-only``
and `R`.count-only``. The first one returns `True` or `False`, depending on
whether there are still items that can be generated by the `T`Iterator``. The
second one returns the number of items the `T`Iterator`` can still produce.
**Importantly** these methods **must** be able to do that ***without***
exhausting
the `T`Iterator``. In other words, after finding these methods implemented,
the user of our `T`Iterator`` can call them and afterwards should still be
able to `R`.pull-one`` all of the items, as if the methods were never called.

Let's make an `T`Iterator`` that will take an `T`Iterable`` and `R`.rotate`` it
once per iteration of our `T`Iterator`` until its `R`tail`` is its `R`head``.
Basically, we want this:

    .say for rotator 1, 2, 3, 4;

    # OUTPUT:
    # [2 3 4 1]
    # [3 4 1 2]
    # [4 1 2 3]

This iterator will serve our purpose. For a less "made-up" example, try to find
implementations of iterators for `R`combinations`` and `R`permutations``
routines in [Perl 6 compiler's source code](https://github.com/rakudo/rakudo/).

Here's a sub that creates our `T`Seq`` with our shiny `T`Iterator`` along
with some code that operates on it and some timings for different stages of
the program:

    sub rotator (*@stuff) {
        Seq.new: class :: does Iterator {
            has int $!n;
            has int $!steps = 1;
            has     @.stuff is required;

            submethod TWEAK { $!n = @!stuff − 1 }

            method pull-one {
                if $!n-- > 0 {
                    LEAVE $!steps = 1;
                    [@!stuff .= rotate: $!steps]
                }
                else {
                    IterationEnd
                }
            }
            method skip-one {
                $!n > 0 or return False;
                $!n--; $!steps++;
                True
            }
            method skip-at-least (\n) {
                if $!n > all 0, n {
                    $!steps += n;
                    $!n     −= n;
                    True
                }
                else {
                    $!n = 0;
                    False
                }
            }
        }.new: stuff => [@stuff]
    }

    my $rotations := rotator ^5000;

    if $rotations {
        say "Time after getting Bool: {now - INIT now}";

        say "We got $rotations.elems() rotations!";
        say "Time after getting count: {now - INIT now}";

        say "Fetching last one...";
        say "Last one's first 5 elements are: $rotations.tail.head(5)";
        say "Time after getting last elem: {now - INIT now}";
    }

    # OUTPUT:
    # Time after getting Bool: 0.0230339
    # We got 4999 rotations!
    # Time after getting count: 26.04481484
    # Fetching last one...
    # Last one's first 5 elements are: 4999 0 1 2 3
    # Time after getting last elem: 26.0466234

First things first, let's take a look at what we're doing in our `T`Iterator``.
We take an `T`Iterable`` (a `T`Range`` object with 5000 elements in this case),
shallow-clone it (using `[ ... ]` operator) and keep that clone in
`@!stuff` attribute of our `T`Iterator``. During object instantiation, we
also save how many items `@!stuff` has in it into `$!n` attribute, inside the
[`TWEAK` submethod](https://docs.perl6.org/language/objects#index-entry-TWEAK).

For each `R`.pull-one`` of the `T`Iterator``, we `R`.rotate`` our `@!stuff`
attribute, storing the rotated result back in it, as well as making a shallow
clone of it, which is what we return for the iteration.

We also already implemented the `R`.skip-one`` and `R`.skip-at-least``
optimization methods, where we use a private `$!steps` attribute to alter
how many steps the next `R`.pull-one`` will `R`.rotate`` our `@!stuff` by.
Whenever `R`.pull-one`` is called, we simply reset `$!steps` to its default
value of `1` using the [`LEAVE` phaser](https://docs.perl6.org/syntax/LEAVE).

Let's check out how this thing performs! We store
our precious `T`Seq`` in `$rotations` variable that we first check for
truthiness, to see if it has any elements in it at all; then we tell the
world how many rotations we can fish out of that `T`Seq``; lastly, we fetch
the *last* element of the `T`Seq`` and (for screen space reasons) print the
first 5 elements of the last rotation.

All three steps—check `R`.Bool``, check `R`.elems``, and fetch last item with
`R`.tail`` are timed, and the results aren't that pretty. While `R`.Bool`` took
relatively quick to complete, the `R`.elems`` call took ages (26s)! That's
actually not all of the damage. Recall from
[PART I of this series](https://perl6.party/post/Perl-6-Seqs-Drugs-and-Rock-n-Roll) that both `R`.Bool`` and `R`.elems`` cache the `T`Seq`` unless special
methods are implemented in the `T`Iterator``. This means that each of those
rotations we made are still there in memory, using up space for nothing! What
are we to do? Let's try implementing those special methods
`R`.Bool`` and `R`.elems`` are looking for!

This only thing we need changed is to add two extra methods to our iterator
that determinine how many elements we can generate (`R`.count-only``)
and whether we have any elements to generate (`R`.bool-only``):

        method count-only { $!n     }
        method bool-only  { $!n > 0 }

For completeness sake, here's our previous example, with these two methods
added to our `T`Iterator``:

    sub rotator (*@stuff) {
        Seq.new: class :: does Iterator {
            has int $!n;
            has int $!steps = 1;
            has     @.stuff is required;

            submethod TWEAK { $!n = @!stuff − 1 }

            method count-only { $!n     }
            method bool-only  { $!n > 0 }

            method pull-one {
                if $!n-- > 0 {
                    LEAVE $!steps = 1;
                    [@!stuff .= rotate: $!steps]
                }
                else {
                    IterationEnd
                }
            }
            method skip-one {
                $!n > 0 or return False;
                $!n--; $!steps++;
                True
            }
            method skip-at-least (\n) {
                if $!n > all 0, n {
                    $!steps += n;
                    $!n     −= n;
                    True
                }
                else {
                    $!n = 0;
                    False
                }
            }
        }.new: stuff => [@stuff]
    }

    my $rotations := rotator ^5000;

    if $rotations {
        say "Time after getting Bool: {now - INIT now}";

        say "We got $rotations.elems() rotations!";
        say "Time after getting count: {now - INIT now}";

        say "Fetching last one...";
        say "Last one's first 5 elements are: $rotations.tail.head(5)";
        say "Time after getting last elem: {now - INIT now}";
    }

    # OUTPUT:
    # Time after getting Bool: 0.0087576
    # We got 4999 rotations!
    # Time after getting count: 0.00993624
    # Fetching last one...
    # Last one's first 5 elements are: 4999 0 1 2 3
    # Time after getting last elem: 0.0149863

The code is nearly identical, but look at those sweet, sweet timings! Our
entire program runs about 1,733 *times* faster because our `T`Seq`` can figure
out *if* and *how many* elements it has *without* having to iterate anything.
The `.tail` call sees our optimization (side note: that's actually
[very recent](https://github.com/rakudo/rakudo/commit/9c04dfc4a427da11f5762534e4601fe697b9e127)) and it too
doesn't have to iterate over anything and can just use our `R`.skip-at-least``
optimization to skip to the end. And last but not least, our `T`Seq`` is
*no longer being cached*, so the only things kept in memory are the things
we care about. It's a huge win-win-win for very little extra code.

But wait... there's more!

## Push it real good...