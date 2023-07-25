use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> "RPC::Smart",
	VERSION_FROM	=> 'lib/RPC/Smart.pm',
	'dist'		=> {
			     COMPRESS	=> 'gzip -9f',
	      		     SUFFIX	=> 'gz',
	      		     DIST_DEFAULT => 'all tardist',
			   },
        PREREQ_FATAL    => 1,
        PREREQ_PRINT    => 1,
	MAN3PODS	=> {},
        PREREQ_PM => { 'IPC::Smart'  => '>= 0.10',
                       'Data::Dumper'=> 0,
                       'XML::Smart'  => '1.6.9' }
);
