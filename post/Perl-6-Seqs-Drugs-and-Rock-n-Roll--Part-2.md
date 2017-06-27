%% title: Perl 6: Seqs, Drugs, And Rock'n'Roll (Part 2)
%% date: 2017-06-27
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

### A so, so count...

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
We take an `T`Iterable`` (a `T`Range`` object out of which we can milk 5000
elements in this case),
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

```
    method count-only { $!n     }
    method bool-only  { $!n > 0 }
```

For the sake of completeness, here is our previous example, with these two
methods added to our `T`Iterator``:

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
out *if* and *how many* elements it has *without* having to iterate or
rotate anything.
The `.tail` call sees our optimization (side note: that's actually
[very recent](https://github.com/rakudo/rakudo/commit/9c04dfc4a427da11f5762534e4601fe697b9e127)) and it too
doesn't have to iterate over anything and can just use our `R`.skip-at-least``
optimization to skip to the end. And last but not least, our `T`Seq`` is
*no longer being cached*, so the only things kept around in memory are the
things we care about. It's a huge win-win-win for very little extra code.

But wait... there's more!

### Push it real good...

The ``Seq|s`` we looked at so far did heavy work: each generated value took
a relatively long time to generate. However, ``Seq|s`` are quite versatile
and at times you'll find that generating a value might be even cheaper than
calling ``.pull-one`` and storing that value somewhere. For cases like that,
there're a few more methods we can implement to make our ``Seq`` perform
better.

For our example, we'll stick with the basics. Our ``Iterator`` will generate
an sequence of positive
[even numbers](https://en.wikipedia.org/wiki/Parity_%28mathematics%29) up to
the wanted limit. Here's what the call to the sub that makes our ``Seq`` looks
like:

    say evens-up-to 20; # OUTPUT: (2 4 6 8 10 12 14 16 18)

And here's the all of the code for it. The particular operation we'll be
doing is storing all the values in an ``Array``:

    sub evens-up-to {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            has int $.limit is required;
            method pull-one { ($!n += 2) < $!limit ?? $!n !! IterationEnd }
        }.new: :$^limit
    }

    my @a = evens-up-to 500_000;

    say now - INIT now; # OUTPUT: 1.2895676

For a limit of half a million, the code takes a bit over a second to run.
However, all we do in our ``Iterator`` is add some numbers together, so a lot
of the time is actually lost in pulling the values and adding them to the
``Array``.

In cases like these, implementing a custom ``.push-all`` method on our
``Iterator`` can help. The method receives one argument that is a
[reification](https://docs.perl6.org/language/glossary#index-entry-Reify)
target. We're closer to the "metal" now, so we can't do anything fancy with
the reification target object other than call `.push` method on it with a
single value to add to the target. The ``.push-all`` always returns
[`IterationEnd`](https://docs.perl6.org/type/Iterator#IterationEnd), since it
exhausts the ``Iterator``, so we'll just pop that value right into the
return value of the method's ``Signature``:

    sub evens-up-to {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            has int $.limit is required;
            method pull-one {
                ($!n += 2) < $!limit ?? $!n !! IterationEnd
            }
            method push-all (\target --> IterationEnd) {
                target.push: $!n while ($!n += 2) < $!limit;
            }
        }.new: :$^limit
    }

    my @a = evens-up-to 500_000;
    say now - INIT now; # OUTPUT: 0.9662275

Our program is now 30% faster! However, since we're doing all the work in
``.push-all`` now, we no longer need to carry state around, so we can shave
off a bit of time by using lexical variables instead of accessing object's
attributes all the time. Also, (at least currently), the `+=` meta operator
is more expensive than a simple assignment and a regular `+`; since we're
trying to squeeze every last bit of juice here, let's get take advantage of
that as well. So what we have now is this:

    sub evens-up-to {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            has int $.limit is required;
            method pull-one {
                ($!n += 2) < $!limit ?? $!n !! IterationEnd
            }
            method push-all (\target --> IterationEnd) {
                my int $limit = $!limit;
                my int $n     = $!n;
                target.push: $n while ($n = $n + 2) < $limit;
                $!n = $n;
            }
        }.new: :$^limit
    }

    my @a = evens-up-to 500_000;
    say now - INIT now; # OUTPUT: 0.5515191

There we go. Now our program is 2.3 times faster than the original, thanks to
``.push-all|!`` There are
[a few more `.push-*` methods](https://docs.perl6.org/type/Iterator) you can
implement to, for example, do something special in code like...

    for $some-seq -> $a, $b, $c { ... }

...where the ``Iterator`` would be asked to ``.push-exactly`` three items.
The idea behind them is similar to ``.push-all`` and their utility is ever
smaller, useful only in particular situations, so I won't be covering them.

It's worth noting the ``.push-all`` can be used only with ``Iterators`` that
are not lazy, since... well... it expects you to push **all** the items. And
what exactly are lazy ``Iterator|s``? I'm so glad you asked!

### Lazy Boy

Let's pare down our previous ``Seq`` that generates even numbers down to the
basics. Let's make it generate an **infinite** list of even numbers:

    sub evens {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            method pull-one { $!n += 2 }
        }.new
    }

    put evens

Since the list is infinite, it'd take us an infinite time to fetch them all.
So what exactly happens when we run the code above? It... quite predictably
hangs when the ``put`` routine is called; it sits and patiently waits for
our infinite ``Seq`` to complete. The same issue occurs when trying to
assign our seq to a
[`@`-sigiled](https://docs.perl6.org/language/glossary#index-entry-Sigil) variable:

    my @evens = evens # hangs

Or even when trying to pass our ``Seq`` to a sub with a
[slurpy parameter](https://docs.perl6.org/type/Signature#Slurpy_(A.K.A._Variadic)_Parameters):

    sub meows (*@evens) { say 'Got some evens!' }
    meows evens # hangs

That's quite an annoying problem. Fortunately, there's a very easy solution
for it! But first, a minor detour to the land of naming clarification!

#### A rose by any other name would laze as sweet

In Perl 6 some things are or can be made "``lazy``". While it evokes the
concept of on-demand or "lazy" evaluation, things that are ``lazy`` in Perl 6
aren't *just* about that. If something ``is-lazy``, it means it always
wants to be evaluated lazily; fetching only as many items as needed.

For example, a sequence of lines read from a file would want to be ``lazy``,
as reading them all in at once has the potential to use up all the RAM.
An infinite sequence would also want to be ``is-lazy`` because
an ``eager`` evaluation would cause it to hang, as the sequence never
completes.

So a thing that ``is-lazy`` in Perl 6 can be thought of as being infinite, or
if not actually infinite, having similar consequences if used eagerly (too
much CPU time used, too much RAM, etc).

----

Now back to our infinite list of even numbers. It sounds like all we have to
do is make it lazy and we do that by implementing ``.is-lazy`` method that
simply returns `True`:

    sub evens {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            method pull-one { $!n += 2 }
            method is-lazy (--> True) {}
        }.new
    }

    sub meows (*@evens) { say 'Got some evens!' }

    put         evens; # OUTPUT: ...
    my @evens = evens; # doesn't hang
    meows       evens; # OUTPUT: Got some evens!

The ``put`` routine now detects its dealing with something terribly long and
just outputs some dots. Assignment to ``Array`` no longer hangs (and will
instead [reify](https://docs.perl6.org/language/glossary#index-entry-Reify) on
demand). And the call to a slurpy doesn't hang either and will
[reify](https://docs.perl6.org/language/glossary#index-entry-Reify) on
demand.

There's one more ``Iterator`` optimization method left that we should
discuss...

### A Sinking Ship

Perl 6 has [sink context](https://github.com/perl6/doc/issues/1309), similar
to "void" context in other language, which means a value is being discarded:

    42;

    # OUTPUT:
    # WARNINGS for ...:
    # Useless use of constant integer 42 in sink context (line 1)

The constant `42` in the above program is in sink context—its value isn't
used anywhere—and since it's nearly pointless to have it like that, the
compiler warns about it.

Not all sinkage is bad however and sometimes you may find that gorgeous
``Seq`` you worked so hard on is ruthlessly being sunk by the user! Let's take
a look at what happens when we sink one of our previous examples, the ``Seq``
that makes up to `limit` even numbers:

    sub evens-up-to {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            has int $.limit is required;
            method pull-one {
                ($!n += 2) < $!limit ?? $!n !! IterationEnd
            }
        }.new: :$^limit
    }

    evens-up-to 5_000_000; # sink our Seq

    say now - INIT now; # OUTPUT: 5.87409072

Ouch! Iterating our ``Seq`` has no side-effects outside of the ``Iterator``
that it uses, which means it took the program almost six seconds to do
absolute nothing.

We can remedy the situation by implementing our own ``.sink-all`` method.
Its default implementation ``.pull-one|s`` until the end of the ``Seq``
(since ``Seq|s`` may have useful side effects), which is not what we want
for *our* ``Seq``. So let's implement a ``.sink-all`` that does nothing!

    sub evens-up-to {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            has int $.limit is required;
            method pull-one {
                ($!n += 2) < $!limit ?? $!n !! IterationEnd
            }
            method sink-all(--> IterationEnd) {}
        }.new: :$^limit
    }

    evens-up-to 5_000_000; # sink our Seq

    say now - INIT now; # OUTPUT: 0.0038638

We made our program 1,520 times faster—the perfect speed up for a program
that does nothing!

However, doing nothing is not the only thing ``.sink-all`` is good for. Use
it for clean up that would usually be done at the end of iteration (e.g.
closing a file handle the ``Iterator`` was using). Or simply set the state
of the system to what it would be at the end of the iteration (e.g. ``.seek``
a file handle to the end, for sunk ``Seq`` that produces ``lines`` from it).
Or, as an alternative idea, how about warning the user their code might
contain an error:

    sub evens-up-to {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            has int $.limit is required;
            method pull-one {
                ($!n += 2) < $!limit ?? $!n !! IterationEnd
            }
            method sink-all(--> IterationEnd) {
                warn "Oh noes! Looks like you sunk all the evens!\n"
                    ~ 'Why did you make them in the first place?'
            }
        }.new: :$^limit
    }

    evens-up-to 5_000_000; # sink our Seq

    # OUTPUT:
    # Oh noes! Looks like you sunk all the evens!
    # Why did you make them in the first place?
    # ...

That concludes our discussion on optimizing your ``Iterator|s``. Now, let's
talk about using ``Iterator|s`` others have made.

## It's a marathon, not a sprint

With all the juicy knowledge about ``Iterator|s`` and ``Seq|s`` we now
possess, we can probably see how this piece of code manages to work without
hanging, despite being given an infinite ``Range`` of numbers:

    .say for ^∞ .grep(*.is-prime).map(* ~ ' is a prime number').head: 5;

    # OUTPUT:
    # 2 is a prime number
    # 3 is a prime number
    # 5 is a prime number
    # 7 is a prime number
    # 11 is a prime number

The infinite ``Range`` probably ``is-lazy``. That ``.grep``
probably ``.pull-one|s`` until it finds a prime number. The ``.map``
``.pull-one|s`` each of the ``.grep|'s`` values and modifies them, and
``.head`` allows at most 5 values to be ``.pull-one|d`` from it.

In short what we have here is a pipe line of ``Seq|s`` and ``Iterator|s`` where
the ``Iterator`` of the next ``Seq`` is based on the ``Iterator`` of the
previous one. Let's cook up a ``Seq`` of our own that combines all of the
steps above:

    sub first-five-primes (*@numbers) {
        Seq.new: class :: does Iterator {
            has     $.iter;
            has int $!produced = 0;
            method pull-one {
                $!produced++ == 5 and return IterationEnd;
                loop {
                    my $value := $!iter.pull-one;
                    return IterationEnd if $value =:= IterationEnd;
                    return "$value is a prime number" if $value.is-prime;
                }
            }
        }.new: iter => @numbers.iterator
    }

    .say for first-five-primes ^∞;

    # OUTPUT:
    # 2 is a prime number
    # 3 is a prime number
    # 5 is a prime number
    # 7 is a prime number
    # 11 is a prime number

Our sub [slurps up](https://docs.perl6.org/type/Signature#Slurpy_(A.K.A._Variadic)_Parameters) its positional argument and then calls
``.iterator| method`` on the `@numbers` ``Iterable``. This method is available
on all Perl 6 objects and will let us interface with the object using
``Iterator`` methods directly.

We save the `@numbers`'s ``Iterator`` in one of the attributes of our
``Iterator`` as well as create another attribute to keep track of how many
items we produced. In the ``.pull-one`` method, we first check whether
we already produced the 5 items we need to produce, and if not, we drop into
a loop that calls ``.pull-one`` on the *other* ``Iterator``, the one we
got from `@numbers` ``Array|!``

Now, we already know if the ``Iterator`` does not have any more values for us
it will return the [`IterationEnd` constant](https://docs.perl6.org/type/Iterator#IterationEnd). A constant whose job is to signal end of
iteration in across the entire language is finicky to deal with, as you can
imagine.

To detect it, we need to ensure we use the [binding (`:=`)](https://docs.perl6.org/language/operators#index-entry-Binding_operator), not
the [assignment (`=`)](https://docs.perl6.org/language/operators#Assignment_Operators) operator. The reason for that is
pretty much only the [container identity (`=:=`) operator](https://docs.perl6.org/routine/=:=) will accept such a monstrocity, so we can't stuff the value
we ``.pull-one`` into just any container we please.

If we did find that we received [`IterationEnd`](https://docs.perl6.org/type/Iterator#IterationEnd) from the source ``Iterator``, we simply return
it to indicate we're done. If not, we repeat the process until we find a prime
number, which we then put into our desired string and that's what we return
from our ``.pull-one``.

All the rest of the ``Iterator`` methods we've learned about can be called
on the source ``Iterator`` in the similar fashion as we've called ``.pull-one``
in our example.

## Conclusion

Today, we've learned a whole ton of stuff! We now know that ``Seq|s`` are
powered by ``Iterator`` objects and we can make custom iterators that generate
any variety of values we can dream about.

The most basic ``Iterator`` has only ``.pull-one`` method that generates
a single value, or returns [`IterationEnd`](https://docs.perl6.org/type/Iterator#IterationEnd) when it has no values to produce. It's not
permitted to call ``.pull-one`` again, once it generated
[`IterationEnd`](https://docs.perl6.org/type/Iterator#IterationEnd) and we
can write our ``.pull-one`` methods with the expectation that will never
happen.

There are plenty of optimization opportunities a custom ``Iterator`` can
take advantage of. If it can cheaply skip through items, it can implement
``.skip-one`` or ``.skip-at-least`` methods. If it can know how many items
it'll produce, it can implement ``.bool-only`` and ``.count-only`` methods
that can avoid a ton of work and memory use when only certain values of a
``Seq`` are needed. And for squeezing the very last bit of performance, you
can take advantage of ``.push-all`` and other `.push-*` methods that let you
push values onto the target directly.

When your ``Iterator`` ``.is-lazy``, things will treat it with extra care and
not try to fetch all of the items at once. And we can use the ``.sink-all``
method to avoid work when our ``Seq`` is being sunk, or warn the user of
potential mistakes in their code.

Lastly, since we now know how to make ``Iterator|s`` and what their methods do,
we can make use of ``Iterator|s`` coming from other sources and call methods
on them directly, manipulating them just how we want to.

We've now have all the tools to work with ``Seq`` objects in Perl 6. In the
PART III of this series, we'll learn how to compactify all that knowledge and
skillfully build ``Seq|s`` with just a line or two of code, using the sequence
operator.

Stay tuned!

-Ofun

