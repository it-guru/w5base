use ExtUtils::MakeMaker;

system('./Configure');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IPC::Smart',
    'VERSION_FROM' => 'Smart.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => 'smart.o Smart.o',
    'dist'      => {
        COMPRESS => 'gzip', SUFFIX => 'gz',
    },          
);
