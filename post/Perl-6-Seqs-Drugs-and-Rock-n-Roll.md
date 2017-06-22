%% title: Perl 6: Seqs, Drugs, And Rock'n'Roll
%% date: 2017-06-20
%% desc: Seq type and its caching mechanism

I vividly recall my first steps in Perl&nbsp;6 were just a couple of months
before
the first stable release of the language in December 2015. Around that time,
Larry Wall was making a presentation and showed a neat feature—the sequence
operator—and it got me amazed about just how powerful the language is:

    # First 12 even numbers:
    say (2, 4 … ∞)[^12];      # OUTPUT: (2 4 6 8 10 12 14 16 18 20 22 24)

    # First 10 powers of 2:
    say (2, 2², 2³ … ∞)[^10]; # OUTPUT: (2 4 8 16 32 64 128 256 512 1024)

    # First 13 Fibonacci numbers:
    say (1, 1, *+* … ∞)[^13]; # OUTPUT: (1 1 2 3 5 8 13 21 34 55 89 144 233)

The ellipsis (`…`) is the sequence operator and the stuff it makes is the
`T`Seq``
object. And now, a year and a half after Perl&nbsp;6's first release, I hope to
pass on my amazement to a new batch of future Perl&nbsp;6 programmers.

This is a 3-part series. In PART I of this article we'll talk about what
`T`Seq``
s are and how to make them without the sequence operator. In PART II, we'll
look at the thing-behind-the-curtain of `T`Seq``'s: the `T`Iterator`` type and
how to make `T`Seq``s from our own `T`Iterator``s. Lastly, in PART III, we'll
examine the sequence operator in all of its glory.

Note: I will be using all sorts of fancy Unicode operators and symbols in this
article. If you don't like them, consult with the
[Texas Equivalents page](https://docs.perl6.org/language/unicode_texas)
for the equivalent ASCII-only way to type those elements.

# PART I: What the `Seq` is all this about?

The `T`Seq`` stands for *Sequence* and the `T`Seq`` object provides a one-shot
way to iterate over a sequence of stuff. New values can be generated on
demand—in fact, it's perfectly possible to create infinite sequences—and already-generated values are discarded, never to be seen again,
although, there's a way to cache them, as we'll see.

Sequences are driven by `T`Iterator`` objects that are responsible for
generating
values. However, in many cases you don't have to create `T`Iterator``s directly
or use their methods while iterating a `T`Seq``. There are several ways to
make a `T`Seq`` and in this section,
we'll talk about [`gather`](https://docs.perl6.org/syntax/gather%20take)/`R`take`` construct.

## I `gather` you'll `take` us to...

The [`gather`](https://docs.perl6.org/syntax/gather%20take) statement and `R`take`` routine are similar to "generators" and "yield" statement in some other languages:

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
[`take`](https://docs.perl6.org/routine/take) (to be [`gather`](https://docs.perl6.org/syntax/gather%20take)ed). Just like,
`R`.say`` can be used as either a method or a subroutine, so you can use
`R`.take`` as a method or subroutine, there's no real difference; merely
convenience.

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

Notice how the `R`say`` statements we had inside the [`gather`](https://docs.perl6.org/syntax/gather%20take) statement didn't
actualy get executed until we needed to iterate over a value that
`R`take`` routines took after those particular `R`say`` lines. The block got stopped
and then continued only when more values from the `T`Seq`` were requested. The
last `R`say`` call didn't have any more `R`take``s after it, and it got executed
when the iterator was asked for more values after the last `R`take``.

## That's exceptional!

The `R`take`` routine works by throwing a `CX::Take`
[control exception](https://docs.perl6.org/syntax/CONTROL) that will
percolate up the call stack until something takes care of it. This means you
can feed a [`gather`](https://docs.perl6.org/syntax/gather%20take) not just from an immediate block, but from a bunch of different sources, such as routine calls:

    multi what's-that (42)                     { take 'The Answer'            }
    multi what's-that (Int $ where *.is-prime) { take 'Tis a prime!'          }
    multi what's-that (Numeric)                { take 'Some kind of a number' }

    multi what's-that   { how-good-is $^it                   }
    sub how-good-is ($) { take rand > ½ ?? 'Tis OK' !! 'Eww' }

    my $seq := gather map &what's-that, 1, 31337, 42, 'meows';

    .say for $seq;

    # OUTPUT:
    # Some kind of a number
    # Tis a prime!
    # The Answer
    # Eww

Once again, we iterated over our new `R`Seq`` with a [`for` loop](https://docs.perl6.org/syntax/for), and you can see
that `R`take`` called from different multies and even nested sub calls still
delivered the value to our [`gather`](https://docs.perl6.org/syntax/gather%20take) successfully:

The only limitation is you can't [`gather`](https://docs.perl6.org/syntax/gather%20take) `R`take``s done in another `T`Promise``
or in code manually [cued](https://docs.perl6.org/routine/cue) in the scheduler:

    gather await start take 42;
    # OUTPUT:
    # Tried to get the result of a broken Promise
    #   in block <unit> at test.p6 line 2
    #
    # Original exception:
    #     take without gather

    gather $*SCHEDULER.cue: { take 42 }
    await Promise.in: 2;
    # OUTPUT: Unhandled exception: take without gather

However, nothing's stopping you from using a `T`Channel`` to proxy your data
to be `R`take``n in a [`react` block](https://docs.perl6.org/language/concurrency#index-entry-react).

    my Channel $chan .= new;
    my $promise = start gather react whenever $chan { .take }

    say "Sending stuff to Channel to gather...";
    await start {
        $chan.send: $_ for <a b c>;
        $chan.close;
    }
    dd await $promise;

    # OUTPUT:
    # Sending stuff to Channel to gather...
    # ("a", "b", "c").Seq

Or gathering `R`take``s from within a `R`Supply``:

    my $supply = supply { emit take 42 }

    my $x := gather react whenever $supply { say "Took $_" }
    say $x;

    # OUTPUT: Took 42
    # (42)

## Stash into the `cache`

I mentioned earlier that `T`Seq``s are one-shot [`Iterables`](https://docs.perl6.org/type/Iterable) that can be iterated only once. So what exactly happens
when we try to iterate them the second time?

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
the `T`Positional`` role, which is why
we didn't use the `@`
[sigil](https://docs.perl6.org/language/glossary#index-entry-Sigil) that type-
checks for `T`Positional`` on the variables we stored `T`Seq``s in.

The `T`Seq`` is deemed consumed whenever something asks it for its
`T`Iterator``, like the `for` loop would. So even if we iterated over
just 1 item from the `T`Seq``, it would be deemed entirely consumed, and we wouldn't be able to resume taking more items using, say, another `for` loop.

As you can imagine, having `T`Seqs`` *always* be one-shot would be somewhat of
a pain in the butt. A lot of times you can afford to keep the entire sequence
around, which is the price for being able to access its values more than once,
and that's precisely what the [`Seq.cache`method](https://docs.perl6.org/type/Seq#(PositionalBindFailover)_method_cache) does:

    my $seq := gather { take 42; take 70 };
    $seq.cache;

    .say for $seq;
    .say for $seq;

    # OUTPUT:
    # 42
    # 70
    # 42
    # 70

As long as you call `R`.cache`` before you fetch the first item of the
`T`Seq``, you're good to go iterating over it until the heat death of the
Universe (or until its cache noms all of your RAM). However, often you do not
even need to call `R`.cache`` yourself.

Many methods will automatically `R`.cache`` the `T`Seq`` for you:

- `R`.Str``, `R`.Stringy``, `R`.fmt``, `R`.gist``, `R`.perl`` methods always
`R`.cache``
- `R`.AT-POS`` and `R`.EXISTS-POS`` methods, or in other words, `T`Positional``
indexing like `$seq[^10]`, always `R`.cache``
- `R`.elems``, `R`.Numeric``, and `R`.Int`` will `R`.cache`` the `T`Seq``, unless the underlying `T`Iterator`` provides a `R`.count-only`` method (we'll
get to those in PART II)
- `R`.Bool`` will `R`.cache`` unless the underlying `T`Iterator`` provides
    `R`.bool-only`` or `R`.count-only`` methods

There's one more nicety with `T`Seq``s losing their one-shotness that you may
see refered to as
`T`PositionalBindFailover``.
It's a [role](https://docs.perl6.org/syntax/role) that indicates to the
parameter binder that the type can still be converted into a `T`Positional``,
even when it doesn't do `T`Positional`` role. In plain English, it
means you can do this:

    sub foo (@pos) { say @pos[1, 3, 5] }

    my $seq := 2, 4 … ∞;
    foo $seq; # OUTPUT: (4 8 12)

We have a `sub` that expects a `T`Positional`` argument and we give it a
`T`Seq`` which isn't `T`Positional``, yet it all works out, because the binder
`R`.cache``s our `T`Seq``, thanks to it doing the `T`PositionalBindFailover`` role.

Last, but not least, if you don't care about *all* of your `Seq`'s values
being generated and cached right there and then, you can simply assign it
to a `@` [sigiled](https://docs.perl6.org/language/glossary#index-entry-Sigil)
variable, which will [reify](https://docs.perl6.org/language/glossary#index-entry-Reify)
the `T`Seq`` and store it as an `T`Array``:

    my @stuff = gather {
        take 42;
        say "meow";
        take 70;
    }

    say "Starting to iterate:";
    .say for @stuff;

    # OUTPUT:
    # meow
    # Starting to iterate:
    # 42
    # 70

From the output, we can see `say "meow"` was executed on assignment to `@stuff`
and not when we actually iterated over the value in the `for` loop.

## Conclusion

In Perl&nbsp;6, `T`Seq``s are one-shot `T`Iterables`` that don't keep their
values around, which makes them very useful for iterating over huge, or even
infinite, sequences. However, it's perfectly possible to cache `T`Seq`` values
and re-use them, if that is needed. In fact, many of the `T`Seq``'s methods
will automatically cache the `T`Seq`` for you.

There are several ways to create `T`Seq``s, one of which is to use the
[`gather`](https://docs.perl6.org/syntax/gather%20take) and `R`take`` where
a [`gather`](https://docs.perl6.org/syntax/gather%20take) block will stop
its execution and continue it only when more values are needed.

In parts II and III, we'll look at other, more exciting, ways of
creating `T`Seq``s. Stay tuned!

-OFun