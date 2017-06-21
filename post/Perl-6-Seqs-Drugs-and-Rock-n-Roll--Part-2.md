%% title: Perl 6: Seqs, Drugs, And Rock'n'Roll, Part 2
%% date: 2017-06-20
%% desc: How to make your very own Iterator object
%% draft: true

This is the second part in the series! Be sure you
[read Part 1 first](Perl-6-Seqs-Drugs-and-Rock-n-Roll).

# PART II: That Iterated Quickly

The main piece that makes a `Seq` do its thang is
an object that does the [`Iterator`](https://docs.perl6.org/type/Iterator)
role. It's *this* object that knows how to generate the next value, whenever
we try to pull a value from a `Seq`, or push all of its values somewhere, or
simply discard all of the remaining values.

Keep in mind that you never need to use `Iterator`'s methods directly,
when making use of a `Seq` as a source of values. They're are called
indirectly under the hood in various Perl 6 constructs. The usecase for calling
those methods yourself is often when making an `Iterator` that's fed by another
`Iterator`, as we'll see.

## pull-one my finger

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
and is very likely good enough for all `Iterator`s. The method exists as a
convenience for `Iterator` *users* who call methods on `Iterators` and (at the
moment) it's not used by any methods that can be called on users' `Seq`s.