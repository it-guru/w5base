#!/usr/bin/perl

use lib "/opt/perllib";
use open_flash_chart;
use CGI qw/:standard/;
use strict;

if( !param() ) {

	print header, start_html( -title   => "Open Flash Demo"  );
	&open_flash_chart::swf_object( 600, 250, 'http://localhost/cgi-bin/my.cgi?data' );
	print "</body></html>\n";

} else {

	#
	# NOTE: how we are filling 3 arrays full of data,
	#       one for each bar on the graph
	#
	my @data_1;
	my @data_2;
	my @data_3;

	#srand(1000000);

	for( my $i=0; $i<12; $i++ ) {
		push ( @data_1, rand(10) );
		push ( @data_2, rand(10) );
		push ( @data_3, rand(10) );
	}

	my $g = new open_flash_chart();

	$g->title( 'Bar Chart' );

	$g->set_data( @data_1 );
	$g->bar( 50, '0x0066CC', 'Me', 10 );

	$g->set_data( @data_2 );
	$g->bar( 50, '0x9933CC', 'You', 10 );

	$g->set_data( @data_3 );
	$g->bar( 50, '0x639F45', 'Them', 10 );


	$g->set_x_labels( ( 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec' ) );
	$g->set_y_max( 10 );
	$g->set_y_min( -1 );

	$g->y_label_steps( 1 );
	$g->set_y_legend( 'Open Flash Chart', 12, '0x736AFF' );

	print $g->render();

}
