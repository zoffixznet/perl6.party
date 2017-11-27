
In the hands of a skilled musician, an instrument can bring the greatest joy to a person, move them to tears, or inspire... I, on the other hand, simply use them to make my living room look cool.

![](/assets/pic/instruments)

There *is* a tool I have, however, that I can take pride in: Perl 6. Thanks to the available audio modules, we can make a program, say, play drums. Sure, sure, I could use one of the thousands of different drum machines, but nothing quite beats coding your own from scratch.

To accomplish our goal, we'll use one of Perl 6's flagship features: Grammars. These are organized regexes with names, object oriented structure (along with inheritance and role composition), as well as ability to execute an "action" as soon as one of the parsed tokens matches.

We'll use the Grammars to parse a simple musical notation for how the program is meant to play and we'll have the audio modules provide the voice. So, how about it? Let's make Perl 6 Grammars sing!

## The Notation

Let's keep our notation simple, both to keep this article nice and short and to not distract those without much musical persuasion. The notation will be
this:

    e|x x x  x x x  x x x  x - x |
    B|- x -  - x x  - x -  x x - |
    G|x - -  x - -  x - -  x - x |
    D|x - x  x - x  x - -  x - x |

    e|x x x  x x x  x x x  x - x |
    B|- x -  - x x  - x -  x x - |
    G|x - -  x - -  x - -  x - x |
    D|x - x  x - x  x - -  x - x |

Each bar has several lines, each first indicating the type of drum the line
plays and the `x` and `-` indicate when to hit the drum.

There are several ways to approach this problem and I'm choosing to showcase
the features of the Grammars, while keeping it simple enough and still throwing
other awesome Perl 6 functionality into the pot. So the way we'll parse this
is we'll split the notation on empty lines that separate the bars, then we'll play all but one of the lines asynchronously in separate `Promise`s, while a single line will be played synchronously, to keep the time of the piece.