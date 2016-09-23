use NQPHLL;

class   Damn::Compiler is HLL::Compiler { }
grammar Damn::Grammar  is HLL::Grammar  { }
class   Damn::Actions  is HLL::Actions  {
    method TOP($/) {
        make QAST::Block.new(
            QAST::Var.new(
                :decl('param'), :name('ARGS'), :scope('local'), :slurpy(1)
            ),
        );
    }
}

sub MAIN(*@ARGS) {
    my $comp := Damn::Compiler.new();

    $comp.language('damn');
    $comp.parsegrammar(Damn::Grammar);
    $comp.parseactions(Damn::Actions);
    $comp.command_line(@ARGS, :encoding('utf8'));
}
