#!/usr/bin/perl
use strict;
use warnings;

use JavaScript::Packer;



foreach my $file (glob("*.COMPRESSED.js")){
   my $source=$file;
   $source=~s/\.COMPRESSED//;
   printf("Prozessing %-20s -> %s\n",$source,$file);

   my $packer = JavaScript::Packer->init();

   open( UNCOMPRESSED, '<',$source );
   open( COMPRESSED, '>', $file );

   my $js = join( '', <UNCOMPRESSED> );

   $packer->minify( \$js, { compress => 'clean' } );

   print COMPRESSED $js."\n";
   close(UNCOMPRESSED);
   close(COMPRESSED);
}

