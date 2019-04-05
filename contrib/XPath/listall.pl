#!/usr/bin/perl
use strict;
use XML::LibXML;
use Data::Dumper;

my @xml;

while(my $l=<>){
   push(@xml,$l);
}

my @l;
my $root = XML::LibXML->load_xml(string => join("",@xml));

sub process_node {
    my $node = shift;

    my $p=$node->nodePath;
    $p=~s/\[[0-9]+\]/[]/g;
    if (!($p=~m/[)\]]$/)){
       my $qp=quotemeta($p);
       if (!grep(/^$qp$/,@l)){
          push(@l,$p);
       }
    }
    for my $child ($node->childNodes) {
        process_node($child);
    }
}

process_node($root->documentElement);

foreach my $p (sort(@l)){
   printf("%s\n",$p);
}


