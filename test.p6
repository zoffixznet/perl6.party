
    sub first-five-primes (*@numbers) {
        Seq.new: class :: does Iterator {
            has     $.iter;
            has int $!produced = 0;
            method pull-one {
                $!produced++ == 5 and return IterationEnd;
                loop {
                    my $value := $!iter.pull-one;
                    return IterationEnd if $value =:= IterationEnd;
                    return "$value is a prime number" if $value.is-prime;
                }
            }
        }.new: iter => @numbers.iterator
    }

    .say for first-five-primes ^∞;

    # OUTPUT:
    # 2 is a prime number
    # 3 is a prime number
    # 5 is a prime number
    # 7 is a prime number
    # 11 is a prime number