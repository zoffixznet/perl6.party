%% title: Perl 6 Core Hacking: Grammatical Quibble
%% date: 2016-09-09
%% desc: Following along with fixing a grammar bug
%% draft: True

Feelin' like bugfixing? Here's a [great grammar
bugglet](https://rt.perl.org/Ticket/Display.html?id=128304): the `„”` quotes don't appear to work right when used in quoted white-space separated words
list constructor:

    say „hello world”;
    .say for qww<„hello world”>;
    .say for qww<"hello world">;

    # OUTPUT:
    # hello world
    # „hello
    # world”
    # hello world

The quotes should not be in the output and we should have just 3 lines in the
output; all `hello world`. Sounds like a fun bug to fix! Let's jump in.

## How do you spell that?

The fact that this piece of code doesn't parse right suggests this is a grammar
bug. Most of the grammar lives in [src/Perl6/Grammar.nqp](https://github.com/rakudo/rakudo/blob/83b8b1a/src/Perl6/Grammar.nqp), but before we get
out hands dirty, let's figure out what we should be looking for.

The `perl6` binary has a `--target` command line parameter that takes one of
the compilation stages and will cause the output for that stage to be
produced. What stages are there? They will differ, depending on which
backend you're using, but you can just run `perl6 --stagestats -e ''` to
print them all:

    zoffix@leliana:~$ perl6 --stagestats -e ''
    Stage start      :   0.000
    Stage parse      :   0.230
    Stage syntaxcheck:   0.000
    Stage ast        :   0.000
    Stage optimize   :   0.002
    Stage mast       :   0.013
    Stage mbc        :   0.000
    Stage moar       :   0.000

Grammars are about parsing, so we'll ask for the `parse` target. As for the
code to execute, we'll give it just the problematic bit; the `qww<>`:

    zoffix@leliana:~$ perl6 --target=parse -e 'qww<„hello world”>'
    - statementlist: qww<„hello world”>
      - statement: 1 matches
        - EXPR: qww<„hello world”>
          - value: qww<„hello world”>
            - quote: qww<„hello world”>
              - quibble: <„hello world”>
                - babble:
                  - B:
                - nibble: „hello world”
              - quote_mod: ww
                - sym: ww

That's great! Each of the lines is prefixed by the name of a token we can find in the grammar, so now we know where to look for the problem.

Now, we know that basic quotes work correctly, so let's dump
the parse stage for them as well to see if there is any difference between
the two outputs:

    zoffix@leliana:~$ perl6 --target=parse -e 'qww<"hello world">'
    - statementlist: qww<"hello world">
      - statement: 1 matches
        - EXPR: qww<"hello world">
          - value: qww<"hello world">
            - quote: qww<"hello world">
              - quibble: <"hello world">
                - babble:
                  - B:
                - nibble: "hello world"
              - quote_mod: ww
                - sym: ww

And... well, other than different quotes, the parse tree is the same. So it
looks like all the tokens involved are the same, but what is done by those
tokens differ.

We don't have to each of the tokens we see in the output. The `statementlist`
and `statement` are tokens matching general statements, the `EXPR` is the
precedence parser and `value` is one of the values it's operating on. We'll
ignore those, leaving us with this list of suspects:

    - quote: qww<„hello world”>
      - quibble: <„hello world”>
        - babble:
          - B:
        - nibble: „hello world”
      - quote_mod: ww
        - sym: ww

Let's start interrogating them.

## Down the rabbit hole we go...

Get yourself a local [Rakudo repo](https://github.com/rakudo/rakudo/) checkout,
if you don't already have one, pop open
[src/Perl6/Grammar.nqp](https://github.com/rakudo/rakudo/blob/83b8b1a/src/Perl6/Grammar.nqp), and get comfortable.

We'll follow our tokens from top of the tree down, so the first thing we need
to find is `token quote`, `rule quote`, or `regex quote`, or `method quote`;
search in that order, as the first items are more likely to be the right thing.

In this case, it's [a `token quote`](https://github.com/rakudo/rakudo/blob/83b8b1a/src/Perl6/Grammar.nqp#L3555) which is a
[proto regex](https://docs.perl6.org/language/grammars#Protoregexes). Our code
uses the `q` version of it and you can spot the `qq` and `Q` versions next to
it as well:

    token quote:sym<q> {
        :my $qm;
        'q'
        [
        | <quote_mod> {} <.qok($/)> { $qm := $<quote_mod>.Str }
            <quibble(%*LANG<Quote>, 'q', $qm)>
        | {} <.qok($/)> <quibble(%*LANG<Quote>, 'q')>
        ]
    }
    token quote:sym<qq> {
        :my $qm;
        'qq'
        [
        | <quote_mod> { $qm := $<quote_mod>.Str } <.qok($/)>
            <quibble(%*LANG<Quote>, 'qq', $qm)>
        | {} <.qok($/)> <quibble(%*LANG<Quote>, 'qq')>
        ]
    }
    token quote:sym<Q> {
        :my $qm;
        'Q'
        [
        | <quote_mod> { $qm := $<quote_mod>.Str } <.qok($/)>
            <quibble(%*LANG<Quote>, $qm)>
        | {} <.qok($/)> <quibble(%*LANG<Quote>)>
        ]
    }

Seeing that bodies of `qq` and `Q` look similar to `q`, let's see if they have
the bug as well:

    zoffix@leliana:~$ perl6 -e '.say for qqww<„hello world”>'
    „hello
    world”
    zoffix@leliana:~$ perl6 -e '.say for Qww<„hello world”>'
    „hello
    world”

Yup, it's there as well, so `token quote` is unlikely to be the problem.
Let's break down what the `token quote:sym<q>` is doing, to figure out how to proceed next; one of its alternations is not used by our current code, so I'll
omit it:

    token quote:sym<q> {
        :my $qm;
        'q'
        [
        | <quote_mod> {} <.qok($/)> { $qm := $<quote_mod>.Str }
            <quibble(%*LANG<Quote>, 'q', $qm)>
        | # (this branch omited)
        ]
    }

On line 2, we create a variable, then match literal `q` and then the
`quote_mod` token. That one was part of our `--target=parse` output and if you
do locate it the same way we located the `quote` token, you'll notice it's
a proto regex that in this case matches the `ww` bit of our code. The empty
`{}` block the follows we can ignore (it's a work around for a bug that may
have already been fixed when you read this). So far we've matched the `qww`
bit of our code.

Moving further, we encounter the call to `qok` token with the current
[`Match`](https://docs.perl6.org/type/Match) object as argument. The dot in
`<.qok` signifies this is a non-capturing token match, which is why it did
not show up in our `--target=parse` dump. Let's locate that token and see
what it's about:

    token qok($x) {
        » <![(]>
        [
            <?[:]> || <!{
                my $n := ~$x; $*W.is_name([$n]) || $*W.is_name(['&' ~ $n])
            }>
        ]
        [ \s* '#' <.panic: "# not allowed as delimiter"> ]?
        <.ws>
    }

Boy! Lots of symbols, but this shit's easy: `»` is a [right word
boundary](https://docs.perl6.org/language/regexes#%3C%3C_and_%3E%3E_,_left_and_right_word_boundary) that is *not* followed by an opening
parenthesis (`<![(]>`), followed by an alternation (`[]`), followed by a
check that we aren't trying to use `#` as delimiters (`[...]?`),
followed by [`<.ws>`
token](https://docs.perl6.org/language/grammars#ws) that gobbles up all kinds
of whitespace.

Inside the alternation, we use the first-token-match `||` alternation (as
opposed to longest-token-match `|` one), and the first token is a lookahead
for a colon `<?[:]>`. If that fails, we stringify the given argument (`~$x`)
and then call `is_name` method on [World
object](https://github.com/rakudo/rakudo/blob/83b8b1a/src/Perl6/World.nqp)
passing it the stringified argument as is and with `&` prepended. The passed
`~$x` is what our `token quote:sym<q>` token has matched so far (and that is
string `qww`). The `is_name` method simply checks if the given symbol is
declared and our token match will pass or fail based on that return
value. The `<!{ ... }>` construct we're using
will fail if the evaluated code returns a truthy value.

All said and done, all this token does is checks we're not using `#` as a
delimiter and aren't trying to call a method or a sub. No signs of the bug
in this corner of the room. Let's get back up to our `token quote:sym<q>`
and see what it's doing next:

    token quote:sym<q> {
        :my $qm;
        'q'
        [
        | <quote_mod> {} <.qok($/)> { $qm := $<quote_mod>.Str }
            <quibble(%*LANG<Quote>, 'q', $qm)>
        | # (this branch omited)
        ]
    }

We've just finished looking over the `<.qok()>`, so next up is
`{ $qm := $<quote_mod>.Str }` that merely assigns the string value of the
matched `<quote_mod>` token into the `$qm` variable. In our case, that value
is the string `ww`.

What follows is another token that showed up in our `--target=parse` output:

    <quibble(%*LANG<Quote>, 'q', $qm)>

Here, we're invoking that token with
three positional arguments: the Quote language braid, string `q`, and string
`ww` that we saved in the `$qm` variable. I wonder what it's doing with 'em.
Full speed ahead!

## Nibble Quibble Nimble Nibbler

