#!/usr/bin/perl
use POSIX;
# I've seen a few versions of this algorithm 
# online, I don't know who to credit. I assume 
# this code to by GPL unless proven otherwise. 
# Comments provided by William Porquet, February 2004. 
# You may need to change the line above to # reflect the location of your Perl binary 
# (e.g. "#!/usr/local/bin/perl"). 
# Also change this file's name to '2038.pl'. 
# Don't forget to make this file +x with "chmod". 
# On Linux, you can run this from a command line like this: 
# ./2038.pl use POSIX; 
# Use POSIX (Portable Operating System Interface), 
# a set of standard operating system interfaces.

$ENV{'TZ'} = "GMT";

# Set the Time Zone to GMT (Greenwich Mean Time) for date 
# calculations.

for ($clock = 2147483641; $clock < 2147483651; $clock++) {
       print ctime($clock); }

# Count up in seconds of Epoch time just before and after the 
# critical event. 
# Print out the corresponding date in Gregorian calendar 
# for each result. 
# Are the date and time outputs correct after the critical 
# event second?

