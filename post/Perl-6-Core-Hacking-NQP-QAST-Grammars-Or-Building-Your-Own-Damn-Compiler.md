%% title: Perl 6 Core Hacking: NQP, QAST, Grammars Or Building Your Own Damn Compiler
%% date: 2016-09-26
%% desc: Learn the basics of Perl 6 guts by inventing your own language
%% license: Attribution-NonCommercial-ShareAlike 3.0 Unported https://creativecommons.org/licenses/by-nc-sa/3.0/
%% draft: True

The Not Quite Perl (NQP) is a compiler toolchain and the language in which large
portions of the [Rakudo Perl 6 compiler](http://rakudo.org/) are written. Using
Grammars, you can parse some source code, generate the 'Q' Abstract Syntax
Tree (QAST) nodes, and then ship them off to the Virtual Machine for
execution.

Perl 6 is large and scary, so today, instead of looking at its guts, we'll
make some of our own, using the same building blocks Rakudo uses. Let's
build our own compiler for a language we invent! A fine damn compiler for a
fine gooddamm language... literally.

## The Goal

Here's what our language will have:

* strings and basic numerals
* basic math and string concatenation
* variables
* loop controls
* conditionals
* subroutines
* classes with methods you can call (implementing inheritance is left as an exercise)

And here's a bit of syntax. If you're following along, for fun, *change* this
syntax to make your own very unique language:

    # subroutine definition:
    damn sub hello
        # a built-in to print text to STDOUT:
        exasperatedly shout 'Hello, World!'
    goddammit

    # subroutine call (prints 'Hello, World!')
    just do hello dammit

    # class definition:
    damn class Foo
        damn method bar
            exasperatedly shout 'Hello, Classes!'
        goddammit

        damn method random
            4
        goddammit
    goddammit

    # class method call:
    Foo's dam bar

    # variables:
    a is goddamm 5                  # a number
    b is goddamm "meow"             # a string
    c is goddamm Foo but damn fine  # an instantiated object

    # print several variables, calling a method on variable c
    exasperatedly shout a, b, c's dam random

That's the big-picture stuff. We'll hammer out the few small details as
we move along.

## The Tools

We'll be using NQP with the [MoarVM](http://www.moarvm.org/) backend. Depending
on how (and if) you [installed Perl 6](https://github.com/tadzik/rakudobrew),
nqp might already be installed. Try running the `nqp` command, you should get
the [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop):

    $ nqp
    > say('Hello, World!')
    Hello, World!
    > ^C

If you don't have it, you can just build it from source:

    cd some-dir-where-you-want-to-keep-it
    git clone https://github.com/perl6/nqp .
    perl Configure.pl --gen-moar --backends=moar
    make
    make test
    make install

The above will build the executables in that same directory, so you'd
run `./nqp` to get the REPL.

We have the goal and the tools to accomplish it...  Let's dive in!

## The Stages

First, we need to get our bearings; where we are and what we're about to make.
If you pass `--stagestats` command line option to the `perl6` executable,
you'll get a print out of all the stages the code is going through:

    Stage start      :   0.000
    Stage parse      :   0.231
    Stage syntaxcheck:   0.000
    Stage ast        :   0.000
    Stage optimize   :   0.002
    Stage mast       :   0.012
    Stage mbc        :   0.000
    Stage moar       :   0.000

Our goal is the one in the middle—`AST`—that generates QAST, or 'Q' Abstract
Syntax Tree. Why 'Q'? Because it's after 'P', and 'P' stood for 'Parrot',
which was a previous attempt at implementing Perl 6.

Stuff below that stage relates to the backend. In this case it's the [MoarVM virtual machine](http://moarvm.org/), but can be
[JVM](https://en.wikipedia.org/wiki/Java_virtual_machine) if you built
NQP with it as the backend. We don't care about backend stages today.

So what we need to do is parse code and generate QASTs that we can then
hand off to the backend for execution. Sounds simple enough!

## The Boilerplate

Create a file for our compiler, call it, say, `compiler.nqp`, and add this
boilerplate code into it. Most of these things you already know from Perl 6
itself, such as grammars, actions, and `sub MAIN`:

```
    use NQPHLL;

    class   Damn::Compiler is HLL::Compiler { }
    grammar Damn::Grammar  is HLL::Grammar  { }
    class   Damn::Actions  is HLL::Actions  { }

    sub MAIN(*@ARGS) {
        my $comp := Damn::Compiler.new();

        $comp.language('damn');
        $comp.parsegrammar(Damn::Grammar);
        $comp.parseactions(Damn::Actions);
        $comp.command_line(@ARGS, :encoding<utf8>);
    }
```

We start off with empty Grammar, Compiler, and Action classes
that inherits `HLL::` counterparts (HLL stands for High Level Language). The
entry point to our compiler is `sub MAIN`, in which we bind an instance of our
Compiler class to `$comp`, tell it what our `.language` is called, and indicate
that our Grammar is to be used as the grammar for parsing and our Actions
are the actions for that grammar.

Lastly, we forward the arguments we received to the `.command_line` method
and our boilerplate compiler is good to go! Fire it up for a spin; we already
have the REPL!

```
    $ nqp compiler.nqp
    > exasperatedly shout 'Hello, World!'
    Cannot find method 'TOP' on object of type Damn::Grammar
    >
```

Of course, the REPL can't do anything yet, but we're ready for our journer. Our
feet are firmly planted at the starting line, and we're all set to begin!

## Hello, Damned World!

As is the tradition, the first steps in any language involve printing out
the string `Hello, World!`, so let's teach our compiler to be able to do that.
The `exasperatedly shout` is the statement for printing things to the screen,
so we need to parse that, as well as the argument given to it that needs
to be printed.

Our language's statements are separated by newlines. The default `<ws>` token
matches a whole bunch of different whitespaces, so let's make ours simpler
and make it match only horizontal space, or no space at all as long as we
aren't between two word-characters:

    token ws { <!ww> \h* || \h+ }

As our REPL error indicated, we don't have the `TOP` token for the grammar
to start at, so let's define one. A program is just a list of statements, and
our statements are separated by new lines, so parsing that is simple. Note
that we use `rule`, as opposed to `token` and add whitespace around atoms so
we'd get our `<.ws>` tokens inserted into those places automatically:

```
    token TOP { <statementlist> }
    rule statementlist { [ <statement> \n+ ]* }
```

Lastly, we'll define `statement` proto regex, as well as a statement token to
handle our `expasperatedly shout` statement:

```
    proto token statement {*}
    token statement:sym<exasperatedly shout> {
        <sym> <.ws> <?[']> <quote_EXPR: ':q'>
    }
```

The `<sym>` will match the name of our statement (in this case,
it's `expasperatedly shout`), then we match our whitespace handling token
(`<.ws>`; the dot means it's non-capturing). Then, we look-ahead for a quote
and then delegate the rest of the monkey business to the quoted expression
handler `HHL::Grammar` we inherit from gives us. The `:q` modifier we give it
as an argument indicates we want to use the same quoting semantics as the
`q//` quoter does in Perl 6.

Putting the pieces together, our grammar class becomes this:

```
    grammar Damn::Grammar is HLL::Grammar  {
        token ws { <!ww> \h* || \h+ }
        token TOP { <statementlist> }
        rule statementlist { [ <statement> \n+ ]* }

        proto token statement {*}
        token statement:sym<exasperatedly shout> {
            <sym> <.ws> <?[']> <quote_EXPR: ':q'>
        }
    }
```

If we run our REPL again, you'll notice we moved a step forward, but aren't
quite at the destination yet:

```
    $ nqp compiler.nqp
    > exasperatedly shout 'Hello, World!'
    Unable to obtain AST from NQPMatch
```

We need Actions! That is, we need to add methods to our `Damn::Action` class
that will be called during parsing by `Damn::Grammar`. An action for a token
gets executed as soon as that token finishes parsing, so lets work backwards
from our `exasperatedly shout` statement, since it's the first one to complete
parsing:

    method statement:sym<exasperatedly shout>($/) {
        make QAST::Op.new( :op<say>, $<quote_EXPR>.ast );
    }

[`make`](https://docs.perl6.org/routine/make) attaches a piece of data
to the current match object (`$/`) to be accessed elsewhere. In this case,
tell it to store a
[`QAST::Op`](https://github.com/perl6/nqp/blob/master/docs/qast.markdown#qastop)
that will call one of the [hundreds of
availble NQP ops](https://github.com/perl6/nqp/blob/master/docs/ops.markdown)
when the program is run.

The name of the op to run is passed via the `:op` named argument and the
arguments to the op are given as positionals. Here, we'll call the
[`say` op](https://github.com/perl6/nqp/blob/master/docs/ops.markdown#say) that
prints text to the screen. The quote EXPR parser took care of parsing the
quoted string for us, so we'll just use its results, from
`$<quote_EXPR>.ast`.

Next up is the `statementlist` action:

```
    method statementlist($/) {
        my $stmts := QAST::Stmts.new( :node($/) );
        $stmts.push($_.ast) for $<statement>;
        make $stmts;
    }
```

Again, we construct a QAST node. In this case, it's
[`QAST::Stmts`](https://github.com/perl6/nqp/blob/master/docs/qast.markdown#qaststmts-and-qaststmt) that simply contains a list of statements to execute, in
order. That list is populated via the `for` loop that loops over the
`$<statement>` capture—in our case, that is the `exasperatedly shout`
statement—and `.push`es the QASTs we attached with `make`, by calling `.ast`,
which in Perl 6 you more commonly see under the alternative alias `.made`.

The `:node` argument to `QAST::Stmts` takes our current
[`Match`](https://docs.perl6.org/type/Match) object, for the purposes of
knowing where we are in relation to the source code. This is used for awesome
error reporting, for example.

Once we collect all of the statements, we again `make` the QAST and that
lands us in the final action:

```
    method TOP($/) {
        make QAST::Block.new( $<statementlist>.ast );
    }
```

We've reached the top of the QAST we're building and the top can only be
a [`QAST::CompUnit`](https://github.com/perl6/nqp/blob/master/docs/qast.markdown#qastcompunit)
or a [`QAST::Block`](https://github.com/perl6/nqp/blob/master/docs/qast.markdown#qastblock).
We won't be dealing with CompUnits just yet, so we'll use the `QAST::Block`
which is both a unit of invocation and a unit of lexical scoping. In this case,
we're using it to define the outer scope for our program, but later will use
it for subroutines and other goodies too. For now, all we do is give the block
the `QAST::Stmts` we generated.

Putting the Actions pieces together, we get this:

```
    class Damn::Actions is HLL::Actions {
        method TOP($/) {
            make QAST::Block.new(
                QAST::Var.new( :decl<param>, :name<ARGS>, :scope<local>, :slurpy ),
                $<statementlist>.ast,
            );
        }
        method statementlist($/) {
            my $stmts := QAST::Stmts.new( :node($/) );
            $stmts.push($_.ast) for $<statement>;
            make $stmts;
        }
        method statement:sym<exasperatedly shout>($/) {
            make QAST::Op.new( :op<say>, $<quote_EXPR>.ast );
        }
    }
```

The ultimate moment has arrived! A new language is born! Run our REPL and
let that language greet the world:

```
    $ nqp compiler.nqp
    > exasperatedly shout 'Hello, World!'
    Hello, World!
    >
```

It works! Celebrate!

## Damn Files

The REPL is great and all, but it's a pain in the ass to always type code into
it. I'll leave it to others to add history and decent line editing to our REPL,
and instead will make our compiler accept a filename of the file with code to as
an argument.

If we try to do it right now, we'll get an error:

```
    $ nqp compiler.nqp code.damn
    Too many positionals passed; expected 0 arguments but got 1
       at code.damn:1  (<ephemeral file>:)
       ...
```

The error gives a hint: it seems our program receives an argument (the
filename), but we aren't asking for one. In fact, the NQP toolchain already
can handle reading code from files for us, the issue we're experiencing
is simply the toolchain trying to give the provided command line arguments
to our program when it isn't expecting any.

Think of our program having an
implicit `sub MAIN` that currently has an empty signature. For it to
accept the command line argument, we need to add a parameter, so we'll modify
the `QAST::Block` we generate in `method TOP` to include a
[`QAST::Var`
node](https://github.com/perl6/nqp/blob/master/docs/qast.markdown#qastvar):

```
    method TOP($/) {
        make QAST::Block.new(
            QAST::Var.new( :decl<param>, :name<ARGS>, :scope<local>, :slurpy ),
            $<statementlist>.ast,
        );
    }
```

The `:decl` argument says what sort of variable we are creating; in this case,
it's a parameter. The `:name` can be nearly anything and we're following the
convention by naming it `ARGS`. It is a `:slurpy` parameter, so we can
take any number of command line arguments. And we use a local `:scope` for it
(like lexical, but not visible to nested blocks), although we won't be using
this parameter for anything today.

Stick our `exasperatedly shout 'Hello, World!'` statement into some file
(e.g. `code.damn`) and run our compiler with that file as an argument:

```
    $ nqp compiler.nqp code.damn
    Hello, World!
```

Magic!

## Credits / See Also

This blog post is partly based on information from
the [Rakudo and NQP Internals
Course (Day 1)](https://github.com/edumentab/rakudo-and-nqp-internals-course)
offered by [Edument AB](http://edument.se/), under the [Creative Commons
Attribution-NonCommercial-ShareAlike 3.0 Unported
License](https://creativecommons.org/licenses/by-nc-sa/3.0/).

I recommend you take that full course, to learn more about NQP
and Rakudo internals.
