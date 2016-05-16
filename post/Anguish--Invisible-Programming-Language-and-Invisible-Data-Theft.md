%% title: "Anguish": Invisible Programming Language and Invisible Data Theft
%% date: 2016-05-16
%% draft: True

# PART I: *Anguish*: The Invisible Programming Language

You may be familiar with funky isoteric languages like [Ook](http://esolangs.org/wiki/Ook!) or even [Whitespace](https://en.wikipedia.org/wiki/Whitespace_(programming_language)). Those are fun and neat, but I've decided to dial up the crazy a notch and make a completely invisible programming language!

I named it *Anguish* and, based on my quick googling, I may be a lone wolf at this depth of insanity. In this article, I'll describe the language, go over my implementation of its interpreter, and then talk about some security implications that come with invisible code.

## The Code

Here's an Anguish program that prints `Hello World`:


Here's another one that reads in a string and prints it back out:


Here's code for a full-featured web browser:


OK, the last one I lied about, but the first two *are* real programs and, if your Unicode support is decent, completely invisible to the human eye (as opposed to, say, spaces and tabs, which are "transparent").

*Anguish* is based on [Brainf#%k](https://en.wikipedia.org/wiki/Brainfuck) except instead of using visible characters, it uses invisible ones. This
also means we can easily convert any *Brainf#%k* program into an *Anguish* one.
Here's the character mapping I chose with Brainf#%k operators on the left
and Anguish versions of them on the right:

    >   [⁠] U+2060 WORD JOINER [Cf]
    <   [​] U+200B ZERO WIDTH SPACE [Cf]
    +   [⁡] U+2061 FUNCTION APPLICATION [Cf]
    -   [⁢] U+2062 INVISIBLE TIMES [Cf]
    .   [⁣] U+2063 INVISIBLE SEPARATOR [Cf]
    ,   [﻿] U+FEFF ZERO WIDTH NO-BREAK SPACE [Cf]
    [   [​] U+200B ZERO WIDTH SPACE [Cf]
    ]   [‌] U+200C ZERO WIDTH NON-JOINER [Cf]

These are—by far—not the only insible Unicode characters and my choice was
more or less arbitrary. However, most of the ones I chose can actually be
abused into Perl 6 terms and operators, which I'll show in Part II.

## The Interpreter

The interpreter is unspectacular. I merely copied over the guts of my
[Inline::Brainf#%k](http://modules.perl6.org/repo/Inline::Brainfuck) Perl 6
module and changed it to look for *Anguish* characters.
https://github.com/zoffixznet/perl6-Acme-Anguish/




