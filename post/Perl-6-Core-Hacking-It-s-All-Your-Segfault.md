%% title: Perl 6 Core Hacking: It's All Your Segfault!
%% date: 2016-09-12
%% desc: Following along with debugging a segfault

Narrow down the crash:

Large numbers crash all the time:

zoffix@VirtualBox:~/CPANPRC/rakudo$ ./perl6 -e '7 ~ "\x[308]" x 110_000'
Segmentation fault
zoffix@VirtualBox:~/CPANPRC/rakudo$ ./perl6 -e '7 ~ "\x[308]" x 110_000'
Segmentation fault


Small number crashes some times:

zoffix@VirtualBox:~/CPANPRC/rakudo$ ./perl6 -e '7 ~ "\x[308]" x 104_805'
WARNINGS for -e:
Useless use of "~" in expression "7 ~ \"\\x[308]\" x" in sink context (line 1)
zoffix@VirtualBox:~/CPANPRC/rakudo$ ./perl6 -e '7 ~ "\x[308]" x 104_805'
Segmentation fault

=========================

cd nqp/MoarVM
perl Configure.pl --debug=3 --optimize=1
make
make install
cd ../../

=========================

No symbol table info available.
#104790 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104791 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104792 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104793 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104794 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104795 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104796 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104797 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104798 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so


But then:


No symbol table info available.
#104828 0x00007ffff79667fa in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104829 0x00007ffff79665b4 in twiddle_trie_node () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104830 0x00007ffff7966c9d in lookup_or_add_synthetic () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104831 0x00007ffff797b102 in grapheme_composition () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104832 0x00007ffff797be1c in MVM_unicode_normalizer_eof () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104833 0x00007ffff7967ae6 in re_nfg () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104834 0x00007ffff79690b9 in MVM_string_concatenate () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104835 0x00007ffff78c10fa in MVM_interp_run () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104836 0x00007ffff798bca9 in MVM_vm_run_file () from //home/zoffix/CPANPRC/rakudo/install/lib/libmoar.so
No symbol table info available.
#104837 0x0000000000401047 in main ()
No symbol table info available.
(gdb)
