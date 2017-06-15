%% title: Perl 6 Release Quality Assurance: Full Ecosystem Toaster
%% date: 2017-06-14
%% desc: How devs are ensuring quality of Rakudo compiler releases

As some recall, [Rakudo's 2017.04 release was somewhat of a
trainwreck](https://perl6.party/post/The-Failure-Point-of-a-Release). It was
clear the quality assurance of releases needed to be kicked up a notch. So
today, I'll talk about what progress we've made in that area.

## Define The Problem

A particular problem that plagued the 2017.04 release were big changes and
refactors made in the compiler that passed all the stresstests, however still
caused fall out in some ecosystem modules and users' code.

The upcoming 2017.06 has many, many more big changes:

- IO::ArgFiles were entirely replaced with the new IO::CatHandle implementation
- IO::Socket got a refactor and sync sockets no longer use libuv
- IO::Handle got a refactor with encoding and sync IO no longer uses libuv
- Sets/Bags/Mixes got optimization polish and op semantics finalizations
- Proc was refactored to be in terms of Proc::Async

The IO and Proc stuff is especially impactful, as it affects precomp and
module loading as well. Merely passing stresstests just wouldn't give me enough
of peace of mind of a solid release. It was time to extend the testing.

While there's a [budding effort to get CPANTesters to smoke
Perl 6 dists](http://ugexe.com/perl-toolchain-summit-2017-cpan-and-perl6/),
it's not quite the data I need. I need to smoke a whole ton of modules on
a particular commit, while also smoking them on a previous release on the
same box, eliminating setup issues that might contribute to failures.

So where can I get that data?

## Going All In

The good news is I didn't actually have to *write* any new tests. With
[836 modules in the Perl 6 ecosystem](http://modules.perl6.org/), the tests
were already there for the taking. Best of all, they were mostly written
without bias due to implementation knowledge of core code, as well as have
personal style variations from hundreds of different coders. This is all
perfect for testing for any regressions of core code. The only problem is
running all that.

My first crude attempt involved firing up a [32-core Google Compute Engine VM](https://console.cloud.google.com/compute) and writing
[a 60-line script](https://github.com/zoffixznet/zefyr/blob/master/bin/zefyr.p6) that fired up 836 [Proc::Asyncs](https://docs.perl6.org/type/Proc::Async)—one for each module.

Other than [chewing through 125 GB of RAM with a single Perl 6 program](https://twitter.com/zoffix/status/870108245502853120), the experiment didn't
yield any useful data. Each module had to wait for locks, before being
installed, and all the Procs were asking [`zef`](https://modules.perl6.org/repo/zef) to install to the same location, to dep handling was iffy. I
needed a more refined solution...


## Procs, Kernels, and Murder

So, I started to polish my code. First, I wrote [`Proc::Q` module](https://modules.perl6.org/dist/Proc::Q) that let me queue up a bunch of Procs, and scale the number of them running at the same time, based on the number of cores on box. [`Supply.throttle`](https://docs.perl6.org/type/Supply.html#method_throttle) core feature made the job a piece of cake.

However, some modules are naughty or broken and I needed a way to kill Procs that take a too much time to run. Alas, I discovered that
[`Proc::Async.kill`](https://docs.perl6.org/type/Proc::Async#method_kill) had a bug in it, where trying to kill when you have more than one Proc was failing. After some digging I found out the cause was [`$*KERNEL.signal`](https://docs.perl6.org/language/variables#index-entry-%24*KERNEL) method the `.kill` was
using isn't actually thread safe and the bug was due to a data race in initialization of the signal table.

After [refactoring Kernel.signal](https://github.com/rakudo/rakudo/commit/79b8ab9d3f9a5499e8a7859f34b4499fb352ac13), and [fixing Proc::Async.kill](https://github.com/rakudo/rakudo/commit/99421d4caa05ae952020a6d918f94fc7b68f2305), I released [`Proc::Q` module](https://modules.perl6.org/dist/Proc::Q)—my first module
[to require](https://modules.perl6.org/repo/RakudoPrereq) the bleedest of bleeding edges: a HEAD commit.

## Going Atomic

After cooking up [boilerplate DB and Proc::Q](https://github.com/zoffixznet/perl6-Toaster) code, I was ready to toast the ecosystem.
However, it appeared [`zef`](https://modules.perl6.org/repo/zef) wasn't
designed, or at least well-tested, in scenarious where up to 40 instances were running module installations simultaneously. I was getting JSON errors from
reading ecosystem JSON, broken cache files (due to lack of file locking),
and false positives in installations because modules claimed they were already installed.

I initially attempted to solve the JSON errors by [fixing an Issue](https://github.com/perl6/ecosystem/issues/345) in the ecosystem repo due to the updater script not writing atomically. However, even after
[fixing the updater script](https://github.com/perl6/ecosystem/commit/ffe71f7583e5ec8ca8ee38f438d00ff78ade6444), I was still getting invalid JSON errors from `zef`.

It might be due to something in zef, but instead of investigating it further, I followed ugexe++'s advice and told zef not to fetch ecosystem in each Proc.
The broken cache issues were similarly elimited by disabling caching support.
And the false positives were eliminated telling each zef instance to install
the tested module into a separate location.

The final solution involved [programatically editing zef's config file](https://github.com/zoffixznet/perl6-Toaster/blob/3d8d217a925be3272f6633c18f4ec22c59c87b32/lib/Toaster.pm6#L104-L116) before a toast run, and then in individual Procs using zef command:

    «zef --/cached --debug install "$module" "--install-to=inst#$where"»

Where `$where` is a per-module, per-rakudo-commit location. The final issue
was floppy test runs, which I resolved by re-testing failed modules one more time, to see if the new run succeeds.

## Time is Everything

The toasting of the entire ecosystem on HEAD and 2017.05 releases took about three hours on a 24-core VM, while being unattended. While watching over it and
killing the few hanging modules at the end without waiting for them to time out I think makes a single-commit run take about 65 minutes.

I also did a toast run on a 64-core VM...

![](/assets/pics/toaster/htop.png)

Overall, the run took me 50 minutes, and I had to manually kill some modules'
tests. However, looking at CPU utilization charts, it seems the run sat idle
for dozens of minutes before I came along to kill stuff:

![](/assets/pics/toaster/cpu-utilization.png)

So I think after some polish of blocking hanging modules and figuring out why (apparently) Proc::Async.kill still doesn't kill everything, the runs can be entirely automated and a single run can be completed in about 20-30 minutes.

This means that even with last-minute big changes pushed to Rakudo, I can still toast the entire ecosystem reasonably fast and detect any potential regressions. Fix them. And re-test again.

## First Catches

The toasting runs I did weren't just a chance to play with powerful hardware.
The [very first catch](https://rt.perl.org/Ticket/Display.html?id=131561) was
detected to be in [`Clifford` module](http://modules.perl6.org/dist/Clifford).
It took me about an hour to dig through
a regression in how [`Lists`](https://docs.perl6.org/type/List) of [`Pairs`](https://docs.perl6.org/type/Pair) were coerced into
a [`MixHash`](https://docs.perl6.org/type/MixHash)