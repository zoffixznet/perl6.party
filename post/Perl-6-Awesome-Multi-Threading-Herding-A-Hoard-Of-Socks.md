%% title: Perl 6's Awesome Multi-Threading: Herding A Hoard of Socks
%% date: 2016-08-18
%% desc: How to maintain connection to multiple sockets
%% draft: True

The [`IRC::Client` Perl 6 module](https://modules.perl6.org/dist/IRC::Client)
presented me with an interesting challenge: multi-server
support is a feature. Not only had I to connect to multiple servers and respond
to their data, but I had to handle disconnects. If a connection drops,
the socket has to be connected again, that is, unless the user of the
module explicitly requested the connection to that particular socket
to be closed. We have to keep the program running, while at least one
socket connection is maintained, and once that is closed by the user,
we need to exit. Sounds like a fantastic job for Perl 6's awesome concurrency
primitives! Let's jump in and solve this!

## You're One and Only

Let's start simple. We'll pop open a single socket and send stuff to it.
The [`IO::Socket::Async`](https://docs.perl6.org/type/IO::Socket::Async)
core type can handle this.

    react {
        whenever IO::Socket::Async.connect('localhost', 6667) -> $conn {
            say "Connected!";
            $conn.print: "NICK Zoffix\n";
            $conn.print: "USER Z Z Z Z\n";

            whenever $conn.Supply -> $buf {
                say "Got $buf";
            }
        }
    }

    # OUTPUT:
    # Connected!
    # Got :irc.local NOTICE Auth :*** Looking up your hostname...
    #
    # Got :irc.local NOTICE Auth :*** Could not resolve your hostname: Request
    #  timed out; using your IP address (127.0.0.1) instead.
    # :irc.local NOTICE Auth :Welcome to Localnet!
    # ...

We start off with a [`react` block](https://docs.perl6.org/language/concurrency#index-entry-react)
that's essentially an event loop. As far as those events are concerned, we
look for two types: socket gets connected and socket receives data.

`Whenever` the sock gets connected, we send `NICK` and `USER` data into
it (we're connecting to an IRC server), then, we start to listen to its
data: we declare that `whenever` we receive that data, we want to print
`Got $that-data`.

From the output we can see our stuff works. The server responds to our
connecting to it as well as sending our data to it. Let's kick it up
a notch: we want to connect to multiple servers, with all the addresses of
all the servers to connect to given to us in an Array.

## Polysockagamy

    my @servers = <localhost  irc.freenode.net>;

    react {
        for @servers -> $server {
            whenever IO::Socket::Async.connect($server, 6667) -> $conn {
                say "Connected to $server!";
                $conn.print: "NICK Zoffix42\n";
                $conn.print: "USER Z Z Z Z\n";

                whenever $conn.Supply -> $buf {
                    say "Got [$server]: $buf";
                }
            }
        }
    }

    # OUTPUT:
    # Connected to localhost!
    # Got [localhost]: :irc.local NOTICE Auth :*** Looking up your hostname...
    # Connected to irc.freenode.net!
    # ...
    # Got [irc.freenode.net]: :morgan.freenode.net NOTICE * :*** Looking up your hostname...
    # ...
