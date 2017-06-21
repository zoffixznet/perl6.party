%% title: Perl 6: Seqs, Drugs, And Rock'n'Roll
%% date: 2017-06-20
%% desc: Seq type and its caching mechanism
%% draft: true

I vividly recall my first steps in Perl 6 were just a couple of months before
the first stable release of the language in December 2015. Around that time,
Larry Wall was presenting and showed a neat feature—the sequence operator—and
it got me amazed about just how powerful the language is:

    # First 12 even numbers:
    say (2, 4 … ∞)[^12];      # OUTPUT: (2 4 6 8 10 12 14 16 18 20 22 24)

    # First 10 powers of 2:
    say (2, 2², 2³ … ∞)[^10]; # OUTPUT: (2 4 8 16 32 64 128 256 512 1024)

    # First 13 Fibonacci numbers:
    say (1, 1, *+* … ∞)[^13]; # OUTPUT: (1 1 2 3 5 8 13 21 34 55 89 144 233)

The ellipsis (`…`) is the sequence operator and the stuff it makes is the `Seq`
object. And today, a year and a half later, I hope to pass on my amazement to a
new batch of future Perl 6 programmers.

This is a 3-part series. In PART I of this article we'll talk about what `Seq`
s are and how to make them without the sequence operator. In PART II, we'll
look at the thing-behind-the-curtain of `Seq`'s: the `Iterator` type and how
to make `Seq`s from our own `Iterator`s. Lastly, in PART III, we'll examine
the sequence operator in all of its glory.

Note: I will be using all sorts of fancy Unicode operators and symbols in this
article. If you don't like them, consult with the
[Texas Equivalents page](https://docs.perl6.org/language/unicode_texas)
for the equivalent ASCII-only way to type those elements.

# PART I: What the Seq is all this about?

The `Seq` stands for *Sequence* and the `Seq` object provides a one-shot way
to iterate over a sequence of stuff. New values can be generated on
demand only—and in fact, it's perfectly possible to create infinite sequences—and already-generated values are discarded, never to be seen again,
although, there's a way to cache them, as we'll see.

Sequences are driven by `Iterator` objects that are responsible for generating
values. However, in many cases you don't have to create `Iterator`s directly
or use their methods while iterating a `Seq`. One way to generate a `Seq` is
using the sequence operator, which we'll examine in PART III. In this section,
we'll talk about `gather`/`take` and in PART II, we'll talk about contructing
`Seqs` from our very own `Iterator` objects.

## I gather you'll take us to...

The `gather` statement and `take` routine are similar to "generators" and "yield" statement in some other languages:

    my $seq-full-of-sunshine := gather {
        say  'And nobody cries';
        say  'there’s only butterflies';

        take 'me away';
        say  'A secret place';
        say  'A sweet escape';

        take 'meee awaaay';
        say  'To better days'    ;

        take 'MEEE AWAAAAYYYY';
        say  'A hiding place';
    }

Above, we have a code block with lines of [song lyrics](https://www.youtube.com/watch?v=0btXhLdAuAc), some of which we
[`say`](https://docs.perl6.org/routine/say) (print to the screen) and others we
[`take`](https://docs.perl6.org/routine/take) (to be `gather`ed). Just like,
`.say` can be used as either a method or a subroutine, so you can use `.take`
as a method or subroutine, there's no real difference.

Now, let's iterate over `$seq-full-of-sunshine` and watch the output:

    for $seq-full-of-sunshine {
        ENTER say '▬▬▶ Entering';
        LEAVE say '◀▬▬ Leaving';

        say "❚❚ $_";
    }

    # OUTPUT:
    # And nobody cries
    # there’s only butterflies
    # ▬▬▶ Entering
    # ❚❚ me away
    # ◀▬▬ Leaving
    # A secret place
    # A sweet escape
    # ▬▬▶ Entering
    # ❚❚ meee awaaay
    # ◀▬▬ Leaving
    # To better days
    # ▬▬▶ Entering
    # ❚❚ MEEE AWAAAAYYYY
    # ◀▬▬ Leaving
    # A hiding place

Notice how the `say` statements we had inside the `gather` statement didn't
actualy get executed until we needed to iterate over a value that
`take` routines took after those particular `say` lines. The block got stopped
and then continued only when more values from the `Seq` were requested. The
last `say` call didn't have any more `take`s after it, and it got executed
when the iterator was asked for more values after the last `take`.

## That's exceptional!

The `take` routine works by throwing a `CX::Take`
[control exception](https://docs.perl6.org/syntax/CONTROL) that will
percolate up the call stack until something takes care of it. This means you
can feed a `gather` not just from an immediate block, but from a bunch of different sources, such as routine calls:

    multi what's-that (42)                     { take 'The Answer'            }
    multi what's-that (Int $ where *.is-prime) { take 'Tis a prime!'          }
    multi what's-that (Numeric)                { take 'Some kind of a number' }

    multi what's-that { how-good-is $^it                   }
    sub how-good-is   { take rand ≥ ½ ?? 'Tis OK' !! 'Eww' }

    my $seq := gather map &what's-that, 1, 31337, 42, 'meows';

Once again, we can iterate over our `Seq` with a `for` loop, and you can see
that `take` called from different multies and even nested sub calls still
delivered the value to our `Seq` successfully:

    .say for $seq;

    # OUTPUT:
    # Some kind of a number
    # Tis a prime!
    # The Answer
    # Eww

## Stash into the cache

I mentioned earlier that `Seq`s are one-shot [`Iterables`](https://docs.perl6.org/type/Iterable) that can be iterated only once. So what exactly happens
when we try it the second time?

    my $seq := gather take 42;
    .say for $seq;
    .say for $seq;

    # OUTPUT:
    # 42
    # This Seq has already been iterated, and its values consumed
    # (you might solve this by adding .cache on usages of the Seq, or
    # by assigning the Seq into an array)

A `X::Seq::Consumed` [exception](https://docs.perl6.org/type/Exception) gets
thrown. In fact, `Seqs` do not even
[do](https://docs.perl6.org/routine/does.html)
the [`Positional`](https://docs.perl6.org/type/Positional) role, which is why
you didn't see me use the `@` [sigil](https://docs.perl6.org/language/glossary#index-entry-Sigil) that type-checks for `Positional`.

As you can imagine, having `Seqs` *always* be one-shot would be somewhat of
a pain in the butt. A lot of times you can afford to keep the entire sequence
around, as the price for being able to access its values more than once, and
that's precisely what the [`Seq.cache`method](https://docs.perl6.org/type/Seq#(PositionalBindFailover)_method_cache) does:

    my $seq := gather { take 42; take 70 };
    $seq.cache;

    .say for $seq;
    .say for $seq;

    # OUTPUT:
    # 42
    # 70
    # 42
    # 70

As long as you call `.cache` before you fetch the first item of the `Seq`,
you're good to go iterating over it until the heat death of the Universe.
However, often you do not even need to call `.cache` yourself.

Many methods will automatically `.cache` the `Seq` for you:

- `.Str`, `.Stringy`, `.fmt`, `.gist`, `.perl` methods always `.cache`
- `.AT-POS` and `.EXIST-POS` methods, or in other words, [`Positional`](https://docs.perl6.org/type/Positional) indexing like `$seq[^10]`, always `.cache`
- `.elems`, `.Numeric`, and `.Int` will `.cache` the `Seq`, unless the underlying `Iterator` provides a `.count-only` method (we'll get to those soon)
- `.Bool' will `.cache` unless the underlying `Iterator` provides `.bool-only` or `.count-only`

There's one more nicety with `Seq`s losing their one-shotness that you may
see refered to as
[`PositionalBindFailover`](https://docs.perl6.org/type/PositionalBindFailover).
It's a [role](https://docs.perl6.org/syntax/role) that indicates to the
parameter binder that the type can still be converted into a [`Positional`](https://docs.perl6.org/type/Positional), even when it doesn't do
[`Positional`](https://docs.perl6.org/type/Positional). In plain English, it
means you can do this:

    sub foo (@pos) { say @pos[1, 3, 5] }

    my $seq := 2, 4 … ∞;
    foo $seq; # OUTPUT: (4 8 12)

We have a `sub` that expects a [`Positional`](https://docs.perl6.org/type/Positional) argument and we give it a [`Seq`](https://docs.perl6.org/type/Seq) which isn't [`Positional`](https://docs.perl6.org/type/Positional), yet it all works out, because the binder `.cache`s our `Seq`, thanks to
it doing the [`PositionalBindFailover`](https://docs.perl6.org/type/PositionalBindFailover) role.


## Conclusion


-OFun