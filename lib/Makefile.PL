#!/usr/bin/perl
use ExtUtils::MakeMaker;

# Write the makefile
WriteMakefile(
    'NAME'      => 'W5Base-API',
    'VERSION_FROM' => 'W5Base/API.pm', # finds $VERSION
    'MAN1PODS'     =>{'W5Base/API.pm'=>'blib/man1/W5Base::API.1'},
    'PMLIBDIRS'    =>['./W5Base/'],
    'PM'     => {'W5Base/API.pm' =>'$(INST_LIBDIR)/W5Base/API.pm',
                 'W5Kernel.pm' => '$(INST_LIBDIR)/W5Kernel.pm',
                 'W5FastConfig.pm' => '$(INST_LIBDIR)/W5FastConfig.pm'},
    'PREREQ_PM' => { 
         XML::DOM   => undef,
         HTTP::Response => undef,
         HTTP::Request::Common => undef,
         LWP::UserAgent => undef,
       },
    'dist'      => { COMPRESS => "gzip -9f" },
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'W5Base/API.pm',
         AUTHOR     => 'Hartmut Vogler <it@guru.de>') : ()),
);
