use NQPHLL;

class   Damn::Compiler is HLL::Compiler { }
grammar Damn::Grammar is HLL::Grammar  {
    token ws { <!ww> \h* || \h+ }
    token TOP { <statementlist> }
    rule statementlist { [ <statement> \n+ ]* }

    proto token statement {*}
    token statement:sym<exasperatedly shout> {
        <sym> <.ws> <?[']> <quote_EXPR: ':q'>
    }
}
class Damn::Actions is HLL::Actions {
    method TOP($/) {
        make QAST::Block.new(
            QAST::Var.new( :decl<param>, :name<ARGS>, :scope<local>, :slurpy ),
            $<statementlist>.ast,
        );
    }
    method statementlist($/) {
        my $stmts := QAST::Stmts.new( :node($/) );
        $stmts.push($_.ast) for $<statement>;
        make $stmts;
    }
    method statement:sym<exasperatedly shout>($/) {
        make QAST::Op.new( :op<say>, $<quote_EXPR>.ast );
    }
}

sub MAIN(*@ARGS) {
    my $comp := Damn::Compiler.new();

    $comp.language('damn');
    $comp.parsegrammar(Damn::Grammar);
    $comp.parseactions(Damn::Actions);
    $comp.command_line(@ARGS, :encoding<utf8>);
}
