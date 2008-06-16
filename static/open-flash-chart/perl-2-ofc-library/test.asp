<%@ Language="PerlScript"%>
<html><head><title>Test Chart</title></head><body><h1>Test Chart</h1>
<% 

# For this test you must have an iis webserver with the perlscript dll installed as a language.
# Also you'll need the open-flash-chart.swf file and the open_flash_chart.pm files together with this one
#

use strict; 
our ($Server, $Request, $Response);
use lib $Server->mappath('.');
use open_flash_chart;

if ( $Request->QueryString("data")->Item == 1 ) {
	#
	# NOTE: how we are filling 3 arrays full of data,
	#       one for each bar on the graph
	#
	my @data_1;
	my @data_2;
	my @data_3;

	for( my $i=0; $i<12; $i++ ) {
		push ( @data_1, rand(10) );
		push ( @data_2, rand(20) );
		push ( @data_3, rand(2000) );
	}

  my $g = graph->new();

	$g->title( 'Open Flash Chart - Bar Test', '{font-size: 15px; color: #800000}' );
	$g->set_x_legend( 'By Hours Wasted', 12, '#000000' );

	$g->set_data( \@data_1 );
	$g->bar( 50, '0x0066CC', 'Me', 10 );

	$g->set_data( \@data_2 );
	$g->bar( 50, '0x9933CC', 'You', 10 );

	$g->set_data( \@data_3 );
	$g->bar( 50, '0x639F45', 'Them', 10 );


	$g->set_x_labels( ['Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'] );
	#$g->set_y_max( 10 ); #not need with new auto y_max
	$g->set_y_min( 0 );

	$g->y_label_steps( 1 );
	$g->set_y_legend( 'Open Flash Chart', 12, '0x736AFF' );

	$Response->write($g->render());
} elsif ( $Request->QueryString("data")->Item == 2 ) {
	#
	my @pie_data;

	for( my $i=0; $i<5; $i++ ) {
		push ( @pie_data, rand(5) );
	}

  my $g = graph->new();
  $g->pie(60,'#505050','#000000');
	$g->title( 'Open Flash Chart - Pie Test', '{font-size: 15px; color: #800000}' );

	$g->pie_values( \@pie_data, ['777', 'MD-11', '737', '747-400', 'Airbus'], [] );
  $g->pie_slice_colours( ['#ff0000','#ff6600','#ff9900','#ffcc00','#ffff00']);
	$Response->write($g->render());
} else {
  my $width = '100%';
  my $height = 600;
 	$Response->write('<div style="border: 1px solid #784016;">');
  $Response->write( graph::swf_object( $width, $height, "test.asp?data=1" ));
  $Response->write("</div>");

 	$Response->write('<div style="margin-top: 20px; border: 1px solid #784016;">');
  $Response->write( graph::swf_object( $width, $height, "test.asp?data=2" ));
  $Response->write("</div>");
  
}

%>
</body>
</html>