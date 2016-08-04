%% title: Perl 6 Core Hacking: Where's Da Sauce, Boss?
%% date: 2016-08-03
%% desc: Locating the source code for specific core methods and subs
%% draft: True

Imagine you were playing with Perl 6 and you came across a bugglet
or you were having some fun with [the Perl 6 bug
queue](http://rakudo.org/rt/open-all)—you'd like to debug a particular core
subroutine or method, so where's the source for it at?

Asked such a question, you might be told it's in [Rakudo compiler's
GitHub repository](rakudo.org/downloads/rakudo/). Depending on how deep
down the rabit hole you wish to go, you may also stop by [NQP's
repo](https://github.com/perl6/nqp), which is a subset of Perl 6 that's used
in Rakudo, or the [MoarVM's repo](https://github.com/MoarVM/MoarVM), which
is the leading virtual machine Perl 6 runs on.

The answer is fine, but we can do better. We'd like to know *exactly* where
da sauce is.

## Stick to The Basics

The most obvious way is to just use `grep` command in the source repository.
The code is likely in `src/` directory, or `src/core` more specifically.

We'll use a regex that catches `sub`, `method`, and `multi` keywords. For
example, here's our search for `path` sub or method:

    $ grep -ER '^\s*(multi|sub|method|multi sub|multi method)\s+path' src/core

    src/core/Cool.pm:    method path() { self.Stringy.IO }
    src/core/CompUnit/Repository/Locally.pm:    method path-spec(CompUnit::Repository::Locally:D:) {
    src/core/CompUnit/Repository/AbsolutePath.pm:    method path-spec() {
    src/core/CompUnit/Repository/NQP.pm:    method path-spec() {
    src/core/CompUnit/Repository/Perl5.pm:    method path-spec() {
    src/core/CompUnit/PrecompilationStore/File.pm:    method path(CompUnit::PrecompilationId $compiler-id,
    src/core/CompUnit/PrecompilationUnit.pm:    method path(--> IO::Path) { ... }
    src/core/IO/Spec/Win32.pm:    method path {
    src/core/IO/Spec/Unix.pm:    method path {
    src/core/IO/Handle.pm:    method path(IO::Handle:D:)            { $!path.IO }

It's not too terrible, but it's a rather blunt tool. We have these problems:

* There are no line numbers, so we'd have to search the individual files for
the methods
* There are false positives; we have several `path-spec` methods found
* It doesn't tell us which of the results is for the actual method we have in
our code. There's `Cool`, `IO::Spec::Unix`, and `IO::Handle` all with
`method path` in them. If I call `"foo".IO.path`, which of those get called?

The last one is particularly irksome, but luckily Perl 6 can tell us where
the source is from. Let's ask it!

## But here's line number... So code me maybe

The `Code` class from which all subs and methods inherit provides
`.file` and `.line` methods that tell which file that particular `Code` is
defined in, including the line number:

    say "The code is in {.file} on line {.line}" given &foo;

    sub foo {
        say 'Hello world!';
    }

    # OUTPUT:
    # The code is in test.p6 on line 3

That looks nice and simple, but it gets more awkward with methods:

    class Kitty {
        method meow {
            say 'Meow world!';
        }
    }

    say "The code is in {.file} on line {.line}" given Kitty.^can('meow')[0];

    # OUTPUT:
    # The code is in test.p6 on line 2

We got extra cruft of the `.^can` metamodel call, which returns a list of
`Method` objects. Above we use the first one to get the `.file` and
`.line` number from, but is it really the method we were looking for?
Take a look at this example:

    class Cudly {
        method meow ('meow', 'meow') {
            say 'Meow meow meow!';
        }
    }

    class Kitty is Cudly {
        multi method meow ('world') {
            say 'Meow world!';
        }

        multi method meow ('meow') {
            say 'Meow meow';
        }
    }

We have a method `meow` in one class, in another class we have two
`multi method`s `meow` as well as an attribute `meow`. How can we print the
location of the last method, the one that takes a single `'meow'` as an
argument?

First, let's take a gander at all the items `.^can` returns:

    say Kitty.^can('meow');
    # OUTPUT:
    # (meow meow)

Wait a minute, we have four entities in our code, so how come we only have
two meows in the output? Let's see which

for 0, 1 {
    say "The code is in {.file} on line {.line}"
        given Kitty.^can('meow')[$_];
}



class Cudly {
    method meow ('meow', 'meow') {
        say 'Meow meow meow!';
    }
}

class Kitty is Cudly {
    multi method meow ('world') {
        say 'Meow world!';
    }

    multi method meow ('meow') {
        say 'Meow meow';
    }
}

for 0, 1 {
    say "The code is in {.file} on line {.line}"
        given Kitty.^can('meow')[$_];
}



# .new.^can('meow')[0].($_) given Cudly;

#say "The code is in {.file} on line {.line}" given Kitty.^can('meow')[0];

