%% title: Perl6.Fail, Release Robots, and Other Goodies
%% date: 2016-09-17
%% desc: Description of work done to automate Perl 6 releases
%% draft: True

If you follow [what I write](http://perl6.party), you know that last month
I messed up a Perl 6 release and vowed to [improve the
process](/post/I-Botched-A-Perl-6-Release-And-Now-A-Robot-Is-Taking-My-Job),
by making a release robot. Well, I didn't lie!

```irc
* Zoffix dissapears for a couple of weeks
<Zoffix> Can be reached via twitter if needed
```

I popped in [some relaxing
music](https://youtu.be/5i7qZxICwgQ?list=RD5i7qZxICwgQ) and
got cracking. Today, I'll talk about the goodies I've made, which touch
a much broader scope than just releasing Perl 6.

Let the gift unwrapping begin!

## Perl6.Fail: R6 Is The New RT

First thing I needed was a web app where a release manager could view new
bug tickets since last release and mark them as release-blockers, if needed.
The app needs to keep track of what tickets were already reviewed, so the
release manager can spend just a couple of minutes of their time every few
days, instead of cramming everything into a single sitting on release date.

I named that app **R6**.
The six fits the Perl 6 theme, and `6` is above `T`
on the keyboard, which I found apropos, since my app is better than
[stock RT](https://bestpractical.com/request-tracker) we currently use 😜.
With the name for the bug app in place, I went to hunt for neat domain names to
host it on and nearly immediately found the perfectest one:
**[perl6.fail](https://perl6.fail)**.

Helping release managers is the smaller side of the utility of the app and
it aims to address some of the major pain points with RT (or rather with our
particular instance of RT that we also have to share with Perl 5).

### Viewing Tags

The RT version has [overly complicated
interface](/post/A-Date-With-The-Bug-Queue-or-Let-Me-Help-You-Help-Me-Help-You--Part-2#lesson4:tagyourticketsandmakethemeasytofind) when it comes to trying
to find a ticket tagged with a particular tag. Worse still, some tags
are just special codes in ticket subject lines, while others use the actual
tag interface. Annoying!

This is one of the first things I solved in R6. The home page lists all
available tags, along with ticket counts for each tag. Simply clicking the
tag will show the tickets just for that tag.

![](Image of tags interface)

Simple. Just the way it's supposed to be.

### Searching

* describe search *

### Decent Editor

* describe MultiMarkdown ticket commenting *

### Release Managers

If you log in as a release manager, you get extra bells and whistles in the
interface that let you mark tickets as was the original plan, as well as
update changelog and mark commits as reviewed.

### API

The release robot has to fetch info from this app to know whether all tickets
and commits have been reviewed. As such,
[adding `.json` to the URL](https://perl6.fail/t/BUG.json)
of most pages will cause the app provide output in JSON format, rather than
plain ol' HTML.

Speaking of robots...

## Buggable

Some of you have already seen my prototype fembot `buggable`. She
was... well, let's just say the name suits her.

```irc
<buggable> ☠ [travis build above] One job failed but NOT due to the timeout.
<lizmat> "No output has been received in the last 10m0s, this potentially
    indicates a stalled build or something wrong with the build itself."
<lizmat> sounds like timeout to me
```

&nbsp;

```irc
<buggable> geekosaur, Found 2 tickets tagged with STAR.
    Details: http://bug.perl6.party/1470861574.html
<geekosaur> o.O
<geekosaur> buggable appears to have a math problem
```

First, I fixed the Travis bogus-failure watcher and taught it to handle
missing build logs and GitHub connectivity issues:

```irc
<buggable> [travis build above] ✓ All failures are due to timeout (0),
    missing build log (1), or GitHub connectivity (0)
```

As for tags and tickets, I completely threw away the old backend that used
RT API and its own database. Instead, the bot now uses the API of the R6
app I made.

```irc
<Zoffix> buggable, tags
<buggable> Zoffix, **Total: 439;** **BUG:** 189; **UNTAGGED:** 58; **LTA:** 54; **RFC:** 40;
    **CONC:** 20; **SEGV:** 18; **JVM:** 14; **UNI:** 13; **PERF:** 12; **TESTNEEDED:** 12; **POD:** 9;
    **PRECOMP:** 9; **@LARRY:** 7; **NATIVECALL:** 7; **NYI:** 6; **IO:** 5; **REGEX:** 5; **BUILD:** 3;
    **MATH:** 3; **REPL:** 3; **GLR:** 2; **OSX:** 2; **WEIRD:** 2; **BOOTSTRAP:** 1; **CONFIGURE:** 1;
    **OO:** 1; **RT:** 1; **SITE:** 1; **SPEC:** 1; **STAR:** 1; **TESTCOMMITTED:** 1;
    See [https://perl6.fail/](https://perl6.fail/) for details
<Zoffix> buggable, tag bug,rfc
<buggable> Zoffix, There are **2 tickets** tagged with **BUG, RFC**;
    See [http://perl6.fail/t/BUG,RFC](http://perl6.fail/t/BUG,RFC) for details
```

Not only all the issues are gone, it now picks up the proper RT tags too and
not just the ones in the subject line. You can specify multiple tags with a
comma, to find tickets with a combination of tags.

Most importantly, `buggable` can now search for tickets, which can be
handy in-chat when trying to decide whether something was or needs to be
rakudobugged.

* Insert info on search interface *

## NeuralAnomaly

Finally, I'm proud to present the star of the hour, the newest member of the
release team, and Perl 6's first gender-fluid bot: `NeuralAnomaly`. They
graciously made the release of the Rakudo Perl 6 Compiler this month,
successfully replacing me at the job:

```irc
<Zoffix> NeuralAnomaly, release
<NeuralAnomaly> Zoffix, testing mode not enabled. This is the REAL DEAL.
    Guess the number I'm thinking of to proceed.
<Zoffix> NeuralAnomaly, 17
<NeuralAnomaly> Zoffix, Woooho! All 117 stil-open tickets since last release
    reviewed (no blockers). Latest MoarVM release found. Starting testing
    and will ping you for final confirmation to ship the deliverables. Tell
    me to `abort` to stop the processes at any time.
<NeuralAnomaly> Zoffix, if you're feeling particularly naughty, you can watch
    me at http://perl6.fail/release-progress or go look
    at some cats http://www.lolcats.com/
```

&nbsp;

```irc
<NeuralAnomaly> Zoffix, all tests passed, all things tagged, all files packaged
    and signed. I'm ready to upload the archives and to email
    the announcement, just say go.
<Zoffix> NeuralAnomaly, go
<NeuralAnomaly> 🎺🎺🎺📯📯📯📯📯📯🌈🌈🌈📦📦📦
<NeuralAnomaly> The release of **Rakudo #103 2016.09** has now been completed
<NeuralAnomaly> 🎺🎺🎺📯📯📯📯📯📯🌈🌈🌈📦📦📦
* NeuralAnomaly celebrates with an appropriate amount of fun
<Zoffix> NeuralAnomaly, thanks for doing the release!
<NeuralAnomaly> Zoffix, any time, buddy!
```

## The Tech

The code for all of the deliverables is [available on
GitHub](https://github.com/zoffixznet), in [R6
repo](https://github.com/zoffixznet/r6), [Buggable
repo](https://github.com/zoffixznet/perl6-buggable), and [NeuralAnomaly
repo](https://github.com/zoffixznet/na).

### R6

The R6 app uses [RT's REST API](https://rt-wiki.bestpractical.com/wiki/REST)
to ask the running RT instance for updated tickets every 10 minutes.

I chose Perl 5 as the weapon of choice, utilizing the talents of
the [Mojolicious web framework](http://mojolicious.org/) and
[`DBIx::Class` ORM](https://metacpan.org/pod/DBIx::Class).

I attempted to
use [`RT::Client::REST`](https://metacpan.org/pod/RT::Client::REST) for API
interfacing, but found the module oddly designed and requiring too many
requests to obtain information I needed. So I implemented the
relevant portions of the RT's REST API interface myself.

For user accounts, I <s>stole</s> borrowed,

### Buggable

The bot uses my very own ``P6:`IRC::Client` Perl 6 module``IRC::Client``
and is pretty thin
and isn't much to look at. Using ``P6:JSON::Fast`` and ``P6:HTTP::UserAgent``
modules it accesses R6 using its JSON endpoints to fetch the tag info
and perform ticket searches.

Travis features use [Travis API](https://docs.travis-ci.com/api). Since the
stuff I use does not require authentication, this is nothing more than
fetching data from an endpoint, decoding JSON, and finding the right data.
I found [JSONViewer.Stack.Hu](http://jsonviewer.stack.hu/) helpful when
figuring out what bits of data I wanted to keep.

### NeuralAnomaly

When I planned this bot, I suspected developing it would be somewhat difficult,
with lots of thinking... In reality, *writing code for it*
turned out to be super easy.
Popping `ssh` into [`Proc::Async`](https://docs.perl6.org/type/Proc::Async)
was child's play, and the Proc bailed out on non-zero exit codes, which made
it super easy for me to abort failing stages of the process. I basically
ended up with Perl-6-super-charged bash script.

However, when it came to giving `gpg` and `git tag` the passphrase for the
key that... is worth its own section

#### *Won't You Take My Passphrase Please*


 it's the supporting infrastructure that proved a bit annoying, but
was a great learning opportunity. The major roadblock was trying to pass
the GPG passphrase to the `gpg` (which was easy) and to the `git` when signing
the tag (which got annoying quick).

Avoiding [idiotic solutions that tell you to write your passphrase
into world-readable files](http://stackoverflow.com/a/11270814), I went
to enable the `gpg-agent` by installing `gnupg-agent`, uncommenting
`use-agent` in `~/.gnupg/gpg.conf`,
and running `eval $(gpg-agent --daemon --sh)`

That did the trick with starting the agent, *but* `git tag` was now outright
choking when attempting to sign, telling 'gpg: cancelled by user', even though
I did naught. I had to
