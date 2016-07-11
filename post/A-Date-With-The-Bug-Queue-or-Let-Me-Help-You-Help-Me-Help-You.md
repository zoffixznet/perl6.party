%% title: A Date With The Bug Queue or Let Me Help You Help Me Help You
%% date: 2016-07-10
%% desc: Lessons learned from going through 1,300+ bug reports
%% draft: True

Recently, I decided to undertake a quick little journey down to the
[Perl 6's Bug Queue](https://rt.perl.org/). A quest for fame and profit—some
easy game to hunt for sport. There's plenty of tickets, so how hard can
it be? The quick little journey turned out to be long and big, but I've
learned some good lessons in the process.

![](/assets/pics/date-with-bug-queue/found-tickets.png)

Right away, I hit a snag. Some tickets looked hard. On some, it wasn't clear
what the correct goal was. And some looked easy, but I wasn't sure whether
I wanted to work on them just yet. While the ticket queue has the tag system,
I needed some personal tags. Something special just for me....

## The Ticket Trakr

So I wrote a [nice little helper app—Ticket
Trakr](https://github.com/zoffixznet/perl6-Ticket-Trakr). It fetches all the
tickets from the bug queue onto one page and lets me tag each of them
with any combination of:

* Try to fix
* Easy
* Tests needed
* Needs core member decision
* Needs spec decision
* Check ticket later
* Needs checking if it's still broken
* Too hard
* Not interested

![](/assets/pics/date-with-bug-queue/trakr.png)

The app worked great! I quickly started going through the queue, looking over
the tickets, testing if the bugs were still there, and estimating whether
I could and wanted to fix them. And after a full weekend of clicking, tagging,
testing, closing, taking an occasional break to
[hunt bears with a mortar](https://www.youtube.com/watch?v=VEsP7XR4EDA),
more closing, testing, tagging, and clicking, I... was through just 200
tickets, which is only 15% of the queue:

![](/assets/pics/date-with-bug-queue/number-done.png)

And so I've learned the first lesson.

## LESSON 1: Going Through Bug Reports is a Full Time Job