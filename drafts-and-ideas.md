### Drafts

* 10-Easy-Steps-To-Burn-Yourself-Out-With-An-Open-Source-Project.md
* Perl-6-Core-Hacking-NQP-QAST-Grammars-Or-Building-Your-Own-Damn-Compiler.md
* Perl-6-Awesome-Multi-Threading-Herding-A-Hoard-Of-Socks.md
* Perl-6-Slip-and-Fall--All-About-Listy-Things.md
* Perl-6-There-Are-Traitors-In-Our-Midst--Part-2.md

### Ideas

* "Abusing Perl 6 for Fun, Profit, and Utility: Custom Operators" a post about molding the
language to what your problem domain may need; do custom ops primarily.
Show how to regular ops to work on custom objects (like the Color.pm6 stuff). 
This is most likely enough to fill one post, but if not, maybe mention a small
slang (if the Slangs post now exists, link to it)
* Post about Junctions
* *Perl 6 ♥ Mojolicious: A Great Web Framework Meets a Great Language*:
    examples of using Mojolicious via Inline::Perl5. Build a sample web socket
    app that uses Proc::Async to interface with the shell. Use
    Mojolicious::Plugin::AssetPack as an example of plugin usage.
* *Perl 6 Is My Drummer: Making Grammars Sing*
* *Perl 6: Released By A Robot*
* *Perl 6 Slangs: Molding The Language To Suit Your Needs*: talk about
    implementation of `//=` signature defaults, since we gotta make that
    anyway.
* *Perl 6 Core Hacking: Gut Map*: an "orientation" sort of post that will
    outline where to find all the repos, bug tickets, and communicate with
    core members. Give a big picture view of how NQP, MoarVM, Rakudo,
    and Rakudo Star fit in and interoperate.
* *Perl 6: These Aren't The Sigils You're Looking For*: primarily to learn
    and explain what the `@`, `%` really are about in Perl 6, as compared
    to Perl 5. If too short, also expound the `\\` "sigil" and maybe twigils
    too.
* *Perl 6 MOP: From Clean Floors to Spiffy Metamodel Hacking*: start by
    showing some introspection features and end by implementing a useful
    custom metaobject.
* *Perl 6 ♥ Unicode: It Doesn't Hurt And I'm Loving It*: showcase
    Perl 6 Unicode awesomeness, including texas vs unicode operators. Then,
    talk about .NFG and all the other crap that lets you work on individual
    characters. (make title more awesome; something with emojis. if there's
    space, make a slang for finger-air-quotes emoji to be used to quote
    strings).
* *Perl 6 Is Sooo Meta: Making Operators More Useful*: detailed explanation
    of Perl 6 meta operators
* *Perl 6's Awesome Multi-Threading or How To Keep A Promise*: detailed
    explanation of Promises. Include using Promises as an async signaler,
    where you .keep or .break a promise yourself.
* *Perl 6's Awesome Multi-Threading: It's Time To React!*: detailed explanation
    of react/whenever construct. Be sure to learn whether a whenever on
    a Supply is an .act or a .tap. See if we can `whenever` in a sub that
    gets called somewhere from an another whenever in a react block.
* *Multi-Threading in Perl 6: Tapping Supplies of Awesomeness*: detailed
    explanation of supplies and taps
* *Multi-Threading in Perl 6: Channel The Awesome*: detailed explanation
    of channels
* *Perl 6: What Ye take So Ye Shall gather*: (shit title?) explanation of
    gather/take. Be sure to include examples of `take`ing from called
    subroutines and so on.
* *Perl 6 Core Hacking: Gramatically Incorrect*: find a grammar bug and
    explain how to trace and debug these.
* *Perl 6 Core Hacking: A Yummy Roast*: explanation of how to add stuff
    to roast: finding `tests needed` tickets, finding the right place
    to add the test in in roast, testing your changes, fudging mechanism.


**Need a lot more Core Hacking posts!!**
