sub evens {
    Seq.new: class :: does Iterator {
        method pull-one { $ += 2 }
    }.new
}

put evens.head: 20;