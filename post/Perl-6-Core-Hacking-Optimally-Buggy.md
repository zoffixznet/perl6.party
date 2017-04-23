%% title: Perl 6 Core Hacking: Optimally Buggy
%% date: 2016-10-08
%% desc: Following along with fixing an optimizer bug
%% draft: true

The code you write by hand isn't the most optimal for performance, which is
why the Perl 6 compiler comes with an [optimizer](https://github.com/rakudo/rakudo/blob/6977b8741386aeb789907d77c0df111d46ded612/src/Perl6/Optimizer.nqp)
that figures out a better way to run your handywork.

As any code, the optimizer can have bugs in it, and today, we'll fix one of
them! So grab a bucket of coffee, pop in some [decent
music](https://www.youtube.com/watch?v=jIC0tNh686k), warm up your editors,
and let's get cracking!

## The Bug

The bug involves invocation of a native type multi candidate, despite the
argument being of a Perl 6 type. You can read [the full bug
report](https://rt.perl.org/Ticket/Display.html?id=128655), if you like; I'll
jump straight to the golfed demonstration:

    multi bug(Int) { ‘right’ }
    multi bug(int) { ‘wrong’ }
    say bug 2;

    # OUTPUT:
    # wrong

The literal numeral `2` is not a native `int`, but the native `int` candidate
gets called. And if instead of a literal, we put it into a variable, the bug
vanishes:

    multi bug(Int) { ‘right’ }
    multi bug(int) { ‘wrong’ }
    my $v = 2;
    say bug $v;

    # OUTPUT:
    # right

It doesn't have to be an `int`. The issue is present with `num`s as well:

    multi bug(Num) { ‘right’ }
    multi bug(num) { ‘wrong’ }
    say bug 2e0;

    # OUTPUT:
    # wrong

However, once we turn the optimizer off, we *do* get the right result:

    $ perl6 -e 'multi bug(Int) { ‘right’ }; multi bug(int) { ‘wrong’ }; say bug 2;'
    wrong

    $ perl6 --optimize=off -e 'multi bug(Int) { ‘right’ }; multi bug(int) { ‘wrong’ }; say bug 2;'
    right

So the problem is somewhere within the 2,258 lines of the optimizer that's located in the [`src/Perl6/Optimizer.nqp`](https://github.com/rakudo/rakudo/blob/6977b8741386aeb789907d77c0df111d46ded612/src/Perl6/Optimizer.nqp) file. Let's
pop it open and see what it's doing.

## Preparing for the Journey

Since I don't know a single thing about the optimizer, the symptops of the
bug don't tell me anything. So I'll "brute force" this bug, by following along
the code and learning what each line of the path it follows does.

Our trip starts in [`src/Perl6/Compiler.nqp`](https://github.com/rakudo/rakudo/blob/6977b8741386aeb789907d77c0df111d46ded612/src/Perl6/Compiler.nqp#L34) at
the line that instantiates the optimizer object and uses it to optimize our
code. It's this line of code that bypassed when we turn the optimizer off,
causing the bug to vanish:

    Perl6::Optimizer.new.optimize($past, |%adverbs);

After instantiation, we call the `.optimize` method on the optimizer, passing
it the QAST tree the compiler generated, along with any command line arguments.
The `$past` is the QAST tree... why is it called `$past` and not `$qast`?
For historical reasons, back when QAST was PAST, as in *Parrot Abstract Syntax
Tree,* with Parrot being one of the previous attempts at building a Perl 6
compiler. The 'Q' in QAST stands for... 'Q', which is a letter after 'P'.
<abbr title="Current model is a successor to Parrot; QAST is a successor to PAST; Q is a 'successor' to P, being the next letter of the alphabet">Get it?</abbr>

Before we start going through possibly hundreds of lines of code, let's get
the lay of the land, to see what lies ahead. What the *People Who Know* would
likely do first is dump the buggy and proper ASTs and compare them. Let's
do just that. We can't use `--target=ast` for the dump, since the optimizer
comes after that target, as we can see by displaying all stages:

    $ ./perl6 --stagestats -e ''
    Stage start      :   0.000
    Stage parse      :   0.077
    Stage syntaxcheck:   0.000
    Stage ast        :   0.000
    Stage optimize   :   0.001
    Stage mast       :   0.004
    Stage mbc        :   0.000
    Stage moar       :   0.000

So we'll use `--target=optimize` for the dump:

    ./perl6                --target=optimize bug.p6 > buggy-ast
    ./perl6 --optimize=off --target=optimize bug.p6 > non-buggy-ast

And the diff the two versions:

    diff -Naur non-buggy-ast buggy-ast > diff-ast

The dumps and the diff are pretty big and perhaps they hold the key to the bug,
but since I'm barely familiar with ASTs, they may as well be gibberish. The
curious can look [at the gist of the data](https://gist.github.com/zoffixznet/9873466e79ee860f38be9d66d0996174), but I'll try going in with a
blunter tool for the job. The AST dumps aren't entirely useless and we'll
refer to them as we go along the optimizer code.

We know the bug is somewhere in
[`src/Perl6/Optimizer.nqp`](https://github.com/rakudo/rakudo/blob/6977b8741386aeb789907d77c0df111d46ded612/src/Perl6/Optimizer.nqp), which is a file full
of routines. We can cheetsy-doodle and search-replace that file, inserting
a print statement on entry to each routine, telling us which routine is being
called. Simple! The `.nqp` extension of the file signifies we're in the
[nqp](https://github.com/perl6/nqp) land, so we can use
`nqp::say("");` routine for printing. We need to catch multies, methods, and
subs (any submethods in the crowd?), so our search-replace command looks
something like this:

    perl -pi -e 's/^(\s* ((?:multi\s+)? (?:submethod|multi|method|sub)) \s+
        ([-\w]+) [^{]+ \{ )/$1 nqp::say("in $2 $3 [line $.]");/mx' src/Perl6/Optimizer.nqp

Let's hope the compiler still builds:

    perl Configure.pl --gen-moar --gen-nqp --backends=moar
    make
    make install

It does! Producing lots of new output as it uses the optimizer to optimize
itself, showing our sweet little hack works like a charm. Let's see what our
buggy program produces:

    ./perl6 -e 'multi bug(Int) { ‘right’ }; multi bug(int) { ‘wrong’ }; say bug 2;' > optimizer-path

Along with the `wrong` in the output, we get a wall of method calls too
large to reproduce in this post. The brave can look at [the full list of
called routines](https://gist.github.com/zoffixznet/4631e13ca8eb6e850a5f7c1e1ece70c4).
For the rest, here's a trimmed down run that shows just the names of the 45
routines we'd have to examine and understand in the *worst case* scenario:

    $ ./perl6 -e 'multi bug(Int) { ‘right’ }; multi bug(int) { ‘wrong’ }; say bug 2;' | sort | uniq
    in method add_decl [line 440]
    in method add_usage [line 447]
    in method analyze_args_for_ct_call [line 1851]
    in method BUILD [line 298]
    in method BUILD [line 47]
    in method BUILD [line 701]
    in method delete_unused_autoslurpy [line 593]
    in method delete_unused_magicals [line 533]
    in method faking_top_routine [line 89]
    in method find_lexical [line 169]
    in method force_value [line 209]
    in method get_calls [line 488]
    in method get_decls [line 482]
    in method get_usages_flat [line 484]
    in method get_usages_inner [line 486]
    in method incorporate_inner [line 502]
    in method inline_call [line 2119]
    in method is_outer_foldable [line 707]
    in method lexical_vars_to_locals [line 617]
    in method Mu [line 99]
    in method new [line 293]
    in method new [line 42]
    in method new [line 696]
    in method optimize_call [line 1357]
    in method optimize [line 767]
    in method optimize [line 881]
    in method optimize_p6typecheckrv [line 1344]
    in method pop_block [line 71]
    in method PseudoStash [line 102]
    in method push_block [line 68]
    in method register_call [line 460]
    in method register_takedispatcher [line 474]
    in method report [line 376]
    in method scopes_in [line 224]
    in method simplify_takedispatcher [line 608]
    in method top_routine [line 77]
    in method UNIT [line 98]
    in method visit_block [line 916]
    in method visit_children [line 1957]
    in method visit_op_children [line 1337]
    in method visit_op [line 1052]
    in method visit_var [line 1798]
    in method visit_want [line 1751]
    in sub add_to_set [line 517]
    in sub get_last_stmt [line 993]
    wrong

We can do one better here, and set `RAKUDO_OPTIMIZER_DEBUG` variable
to a true value:

    RAKUDO_OPTIMIZER_DEBUG=1 ./perl6 -e 'multi bug(Int) { ‘right’ };
        multi bug(int) { ‘wrong’ }; say bug 2;' 2> optimizer-debug

Theoretically, it should be possible to combine our called-method output
with the debug output, but when I tried to use `note()` instead of
`nqp::say()` for called-method output, the compiler's compilation hung on
core lib install, and when using `nqp::say()`, the race conditions between
STDERR and STDOUT output prevent proper alignment of called methods and
debug info in the file. So we'll have to do with the info in separate files.

The [extra debugging info](https://gist.github.com/zoffixznet/4631e13ca8eb6e850a5f7c1e1ece70c4)
looks like a lot of fun! Let's brew another bucket of coffee, strap up,
and jump in!

## Whereever The Code Path Takes Me

As we already discussed and as can be seen from the [list of called
methods](https://gist.github.com/zoffixznet/4631e13ca8eb6e850a5f7c1e1ece70c4),
our first stop in the optimizer is the `.optimize` method:




BUGGY:

m: use nqp; multi bug(Int) { ‘right’ }; multi bug(int) { ‘wrong’ }; my $types := nqp::list; nqp::push($types, Int); my $flags := nqp::list; nqp::push($flags, 33); say &bug.analyze_dispatch($types, $flags)[1]


Copy paste analyze dispatch into our file for easy tweaking. Run:

perl -pi -e 's/my int/my/g' foo.p6
perl -pi -e 's/NQPMu/Mu/g' foo.p6

Then use in code:

my $types := nqp::list; nqp::push($types, Int);
my $flags := nqp::list; nqp::push($flags, 33);
say &bug.analyze_dispatch($types, $flags)[1]

-----

Dump sigs in analyze_dispatch:

    if nqp::getenvhash<FUCKYOU> {
        for @candidates {
            next unless $_.HOW.name($_) eq 'BOOTHash';
            nqp::say("\tsig: " ~ $_<signature>.gist);
        }
    }

## Crux of The Issue

Native `int` is an unboxed type, `Int` is a boxed one, and a literal number
that isn't too big can fit either. Moreover, an `Int` that isn't too big
can fit into a native type, if no `Int` candidates are available, and the
native type can fit into an `Int` if it has to. So the crux of our issue is
that our literal is used as a native type simply because it shows up first in
the list of available candidates, not because there aren't any suitable `Int`
candidates.

Let's write out the rules for how we figure out the candidates for all the
edge cases and then, hopefully, translate them into code.

Here are variations of different multies and how they are meant to be chosen:

    my int $i = 2; # used in all examples to indicate native int

    multi foo (int $x) {say "native" };
    foo 2; # native

    multi foo (Int $x) {say "other Int" };
    foo 2; # other Int

    multi foo (int $x) {say "native" };
    foo $i; # native

    multi foo (Int $x) {say "other Int" };
    foo $i; # other Int

    multi foo (int $x) {say "native"    };
    multi foo (Int $x) {say "other Int" };
    foo  2; # other Int
    foo $i; # native

    multi foo (int $x) {say "native"    };
    multi foo (Str $x) {say "other Str" };
    foo  2; # native
    foo $i; # native

    multi foo (Int $x) {say "other Int" };
    multi foo (Str $x) {say "other Str" };
    foo  2; # other Int
    foo $i; # other Int

    multi foo (int $x) {say "native"    };
    multi foo (Int $x) {say "other Int" };
    foo 2;      # other Int
    foo 2**100; # other Int

    multi foo (int $x) {say "native" };
    foo 2;      # native
    foo 2**100; # X::Multi::NoMatch (no Int candidate)

    multi foo (int $x, int $y) {say "native"       };
    multi foo (Int $x, Int $y) {say "other Int"    };
    foo  2, $i; # other Int
    foo  2, 2;  # other Int
    foo $i, $i; # native

    multi foo (int $x, int $y) {say "native"       };
    multi foo (Int $x, int $y) {say "Int + native" };
    multi foo (Int $x, Int $y) {say "other Int"    };
    foo  2, $i; # Int + native
    foo  2, 2;  # other Int
    foo $i, $i; # native

The multies' rules then are (I describe `int`/`Int`, but same applies for
other natives that have a boxed Perl 6 equivalent):

    0) Literal: treat as Int
    1) Int:
        1.1) Use as Int, if have candidate
        1.2) Use as native, if:
            1.2.1) have native candidate
            1.2.2) size fits
    2) Native:
        2.1) Use as native, if have candidate
        2.2) Use as Int, if have candidate


And this is how the rules are applied to all of our examples:

    my int $i = 2; # used in all examples to indicate native int

    multi foo (int $x) {say "native" };
    foo 2; # native; 0 => 1 => 1.2

    multi foo (Int $x) {say "other Int" };
    foo 2; # other Int; 0 => 1 => 1.1

    multi foo (int $x) {say "native" };
    foo $i; # native; 2 => 2.1

    multi foo (Int $x) {say "other Int" };
    foo $i; # other Int; 2 => 2.2

    multi foo (int $x) {say "native"    };
    multi foo (Int $x) {say "other Int" };
    foo  2; # other Int; 0 => 1 => 1.1
    foo $i; # native; 2 => 2.1

    multi foo (int $x) {say "native"    };
    multi foo (Str $x) {say "other Str" };
    foo  2; # native; 0 => 1 => 1.2
    foo $i; # native; 2 => 2.1

    multi foo (Int $x) {say "other Int" };
    multi foo (Str $x) {say "other Str" };
    foo  2; # other Int; 0 => 1 => 1.1
    foo $i; # other Int; 2 => 2.2

    multi foo (int $x) {say "native"    };
    multi foo (Int $x) {say "other Int" };
    foo 2;      # other Int; 0 => 1 => 1.1
    foo 2**100; # other Int; 0 => 1 => 1.1

    multi foo (int $x) {say "native" };
    foo 2;      # native; 0 => 1.2
    foo 2**100; # X::Multi::NoMatch (no Int candidate);
    # 0 => 1 => 1.2 => 1.2.2 (fails to match at this point)

    multi foo (int $x, int $y) {say "native"       };
    multi foo (Int $x, Int $y) {say "other Int"    };
    foo  2, $i; # other Int; (0 => 1 => 1.1), (2 => 2.1)
    foo  2, 2;  # other Int; (0 => 1 => 1.1), (0 => 1 => 1.1)
    foo $i, $i; # native; (2 => 2.1), (2 => 2.1)

    multi foo (int $x, int $y) {say "native"       };
    multi foo (Int $x, int $y) {say "Int + native" };
    multi foo (Int $x, Int $y) {say "other Int"    };
    foo  2, $i; # Int + native; (0 => 1 => 1.1), (2 => 2.1)
    foo  2, 2;  # other Int; (0 => 1 => 1.1), (0 => 1 => 1.1)
    foo $i, $i; # native; (2 => 2.1), (2 => 2.1)

Writing out these rules and actually trying out the code examples has revealed
another bug:

```irc
<Zoffix> m: sub foo (int) { say "OK!" }; foo 2
<camelia> rakudo-moar d03459: OUTPUT«OK!␤»
<Zoffix> m: multi foo (int) { say "OK!" }; foo 2
<camelia> rakudo-moar d03459: OUTPUT«Cannot resolve caller foo(Int); none of these signatures match:␤    (int)␤  in block <unit> at <tmp> line 1␤␤»
```

The literal gets used as a native if the sub is the only one we have, but if
it's a multi, we fail to use it as such. It looks like our bug is not affected
by that bug, so we'll
[file it on RT](https://rt.perl.org/Ticket/Display.html?id=129844) and leave
that battle for another day.

Since `Routine.analyze_dispatch` gets both of our candidates, but ends up
selecting the wrong one, we'll need to mend it to do the right thing. The
change doesn't look to be abjectly trivial, so we should understand in entirety
what `.analyze_dispatch` is doing.

Exciting!

## Analyzing Analysis
