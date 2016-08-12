%% title: Perl 6 Core Hacking: NQP, QAST, Grammars Or Building Your Own Damn Compiler
%% date: 2016-08-13
%% desc: Learn the basics of Perl 6 guts by inventing your own language
%% draft: True

The Not Quite Perl (NQP) is the language large portions of
the [Rakudo Perl 6 compiler](http://rakudo.org/) are written in. Using
Grammars, you can parse some source code, generate the 'Q' Abstract Syntax
Tree (QAST) nodes, and then ship them off to the Virtual Machine for
execution.

Perl 6 is large and scary, so today, instead of looking at its guts, we'll
make some of our own, using the same building blocks Rakudo uses. Let's
build our own compiler for a language we invent! A gooddamm compiler for a
gooddamm language... literally.

## The Goal

Here's what our language will have:

* strings and basic numerals
* basic math and string concatenation
* variables
* subroutines
* classes with methods you can call

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

## The Boilerplate

