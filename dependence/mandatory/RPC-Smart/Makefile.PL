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
        PREREQ_PM => { 'Data::Dumper'=> 0,
                       'IPC::SharedMem'  => '2.0' }
);
