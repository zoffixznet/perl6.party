    sub rotator (*@stuff) {
        Seq.new: class :: does Iterator {
            has int $!n;
            has int $!steps = 1;
            has     @.stuff is required;

            submethod TWEAK { $!n = @!stuff − 1 }

            method pull-one {
                if $!n-- > 0 {
                    LEAVE $!steps = 1;
                    [@!stuff .= rotate: $!steps]
                }
                else {
                    IterationEnd
                }
            }
            method count-only { $!n     }
            method bool-only  { $!n > 0 }
            method skip-one {
                $!n > 0 or return False;
                $!n--; $!steps++;
                True
            }
            method skip-at-least (\n) {
                if $!n > all 0, n {
                    $!steps += n;
                    $!n     −= n;
                    True
                }
                else {
                    $!n = 0;
                    False
                }
            }
        }.new: stuff => [@stuff]
    }

    my $rotations := rotator ^5000;

    if $rotations {
        say "Time after getting Bool: {now - INIT now}";

        say "We got $rotations.elems() rotations!";
        say "Time after getting count: {now - INIT now}";

        say "Fetching last one...";
        say "Last one's first 5 elements are: $rotations.tail.head(5)";
        say "Time after getting last elem: {now - INIT now}";
    }

    # OUTPUT:
    # Time after getting Bool: 0.0087576
    # We got 4999 rotations!
    # Time after getting count: 0.00993624
    # Fetching last one...
    # Last one's first 5 elements are: 4999 0 1 2 3
    # Time after getting last elem: 0.0149863
