    sub evens-up-to {
        Seq.new: class :: does Iterator {
            has int $!n = 0;
            has int $.limit is required;
            method pull-one {
                ($!n += 2) < $!limit ?? $!n !! IterationEnd
            }
            method push-all (\target --> IterationEnd) {
                my int $limit = $!limit;
                my int $n     = $!n;
                my int $step  = 2;
                target.push: $n while ($n = $n + $step) < $limit;
                $!n = $n;
            }
        }.new: :$^limit
    }

    my @a = evens-up-to 1_700_000;
    say now - INIT now; # OUTPUT: 0.6688109