package Text::Diff::myHtml;

use 5.006;
use strict;
use warnings;
use kernel;
use Carp;

our $VERSION   = '1.44';
our @ISA       = qw( Text::Diff::Base Exporter );
our @EXPORT_OK = qw( expand_tabs );



sub new {
    my $proto = shift;
    return bless { @_ }, $proto
}

sub file_header {
    my $self = shift;
    my @seqs = (shift,shift);
    return("<table width=\"100%\">".
           "<tr><th align=left width=\"50%\">old:</th>".
           "<th align=left width=\"50%\">new:</th></tr>");
}
my $missing_elt = [ "", "" ];

sub hunk {
    my $self    = shift;
    my @seqs    = ( shift, shift );
    my $ops     = shift;  ## Leave sequences in @_[0,1]
    my $options = shift;

    my ( @A, @B );
    for ( @$ops ) {
        my $opcode = $_->[Text::Diff::OPCODE()];
        if ( $opcode eq " " ) {
            push @A, $missing_elt while @A < @B;
            push @B, $missing_elt while @B < @A;
        }
        push @A, [ $_->[0] + ( $options->{OFFSET_A} || 0), $seqs[0][$_->[0]] ]
            if $opcode eq " " || $opcode eq "-";
        push @B, [ $_->[1] + ( $options->{OFFSET_B} || 0), $seqs[1][$_->[1]] ]
            if $opcode eq " " || $opcode eq "+";
    }

    push @A, $missing_elt while @A < @B;
    push @B, $missing_elt while @B < @A;
    my @elts;
    for ( 0..$#A ) {
        my ( $A, $B ) = (shift @A, shift @B );
        
        ## Do minimal cleaning on identical elts so these look "normal":
        ## tabs are expanded, trailing newelts removed, etc.  For differing
        ## elts, make invisible characters visible if the invisible characters
        ## differ.
        my $elt_type =  $B == $missing_elt ? "A" :
                        $A == $missing_elt ? "B" :
                        $A->[1] eq $B->[1]  ? "="
                                            : "*";
        push @elts, [ @$A, @$B, $elt_type ];
    }
    my $d="";
    foreach my $e (@elts){
          $d.="<tr>";
          my $c1="<font color=gray>";
          my $c2="<font color=gray>";
          if ($e->[4] eq "A"){
             $c1="<font color=darkred>";
          }
          if ($e->[4] eq "*"){
             $c1="<font color=darkred>";
             $c2="<font color=darkgreen>";
          }
          if ($e->[4] eq "B"){
             $c2="<font color=darkgreen>";
          }

          $d.="<td>$c1".quoteHtml($e->[1])."</font></td>";
          $d.="<td>$c2".quoteHtml($e->[3])."</font></td>";
          $d.="</tr>";
    }
    return($d);

    push @{$self->{ELTS}}, @elts, ["bar"];
    return "";
}


sub file_footer {
    my $self = shift;
    my @seqs = (shift,shift);
    my $options = pop;

    return("</table>");
}

1;
