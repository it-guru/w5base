package open_flash_chart;

use strict;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
	my $class = shift;
        my $self  = {};

	$self->{data} = [];
	$self->{x_labels} = [];
	$self->{y_min} = 0;
	$self->{y_max} = 20;
	$self->{y_steps} = 5;
	$self->{title} = '';
	$self->{title_size} = 30;

	$self->{x_tick_size} = -1;

	# GRID styles:
	$self->{x_axis_colour} = '';
	$self->{x_grid_colour} = '';

	$self->{y_axis_colour} = '';
	$self->{y_grid_colour} = '';
	$self->{x_axis_steps} = 1;

	# AXIS LABEL styles:         
	$self->{x_label_style_size} = -1;
	$self->{x_label_style_colour} = '#000000';
	$self->{x_label_style_orientation} = 0;
	$self->{x_label_style_step} = 1;

	$self->{y_label_style_size} = -1;
	$self->{y_label_style_colour} = '#000000';

	# AXIS LEGEND styles:
	$self->{x_legend} = '';
	$self->{x_legend_size} = 20;
	$self->{x_legend_colour} = '#000000';

	$self->{y_legend} = '';
	$self->{y_legend_size} = 20;
	$self->{y_legend_colour} = '#000000';

	$self->{lines} = [];
	$self->{line_default} = '&line=3,#87421F'. "& \n";

	$self->{bg_colour} = '';
	$self->{bg_image} = '';

	$self->{inner_bg_colour} = '';
	$self->{inner_bg_colour_2} = '';
	$self->{inner_bg_angle} = '';

        bless($self, $class);
        return $self;
}




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_data {
	my $self = shift;
	my @a = @_;
	
	#print @a;
	
	if( scalar( @{$self->{data}} ) == 0 ) {
		push( @{$self->{data}}, '&values='.join(',',@a)."& \n");
	} else {
		my $t = scalar( @{$self->{data}} )+1;
		push (@{$self->{data}}, '&values_'. $t .'='.join(',',@a)."& \n");
	}
}
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_x_labels {
	my $self = shift;
	my @a = @_;

	push( @{$self->{x_labels}}, @a);
}
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_x_label_style {
	my $self = shift;

	my $size = shift;
	my $colour='';
	my $orientation=0;
	my $step=-1;
	
	if (@_) { $colour = shift }
	if (@_) { $orientation= shift }
	if (@_) { $step= shift }

	$self->{x_label_style_size} = $size;

	if( length( $colour ) > 0 ) { 
		$self->{x_label_style_colour} = $colour;
	}

	if( $orientation > 0 ) {
		$self->{x_label_style_orientation} = $orientation;
	}

	if( $step > 0 ) {
		$self->{x_label_style_step} = $step;
	}
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_bg_colour {
	my $self = shift;
	my $colour = shift;
	
	$self->{bg_colour} = $colour;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_bg_image {
	my $self = shift;
	my $url = shift;
	my $x='center'; #shift;
	my $y='center'; #shift;

	if (@_) { $x = shift }
	if (@_) { $y = shift }
	
	$self->{bg_image} = $url;
	$self->{bg_image_x} = $x;
	$self->{bg_image_y} = $y;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_inner_background {
	my $self = shift;
	my $col = shift;
	my $col2=''; #shift;
	my $angle=-1; #shift;

	if (@_) { $col2 = shift }
	if (@_) { $angle = shift }

	$self->{inner_bg_colour} = $col;


	if( length($col2) > 0 ) {
		$self->{inner_bg_colour_2} = $col2;
	}
	
	if( $angle ne -1 ) {
		$self->{inner_bg_angle} = $angle;
	}

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_y_label_style {
	my $self = shift;
	my $size = shift;
	my $colour=''; #shift;
	
	if (@_) { $colour = shift }

	$self->{y_label_style_size} = $size;

	if( length( $colour ) > 0 ) {
		$self->{y_label_style_colour} = $colour;
	}

}
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_y_max {
	my $self = shift;
	my $max = shift;
	$self->{y_max} = int( $max );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_y_min {
	my $self = shift;
	my $min = shift;
	$self->{y_min} = int( $min );
}
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub y_label_steps {
	my $self = shift;
	my $val = shift;
	$self->{y_steps} = int( $val );
}
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub title {
	my $self = shift;
	my $title = shift;
	my $size=-1; #shift;
	my $colour=''; #shift;
	
	if (@_) { $size = shift }
	if (@_) { $colour = shift }

	$self->{title} = $title;
	if( $size > 0 ) {
		$self->{title_size} = $size;
	}
	if( length( $colour ) > 0 ) {
		$self->{title_colour} = $colour;
	}
}
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_x_legend {
	my $self = shift;
	my $text = shift;
	my $size=-1; #shift;
	my $colour=''; #shift;
	
	if (@_) { $size = shift }
	if (@_) { $colour= shift }

	$self->{x_legend} = $text;
	if( $size > -1 ) {
		$self->{x_legend_size} = $size;
	}

	if( length( $colour )>0 ) {
		$self->{x_legend_colour} = $colour;
	}
}
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_x_tick_size {
	my $self = shift;
	my $size = shift;
	
	if( $size > 0 ) {
		$self->{x_tick_size} = $size;
	}
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_x_axis_steps {
	my $self = shift;
	my $steps = shift;
	
	if ( $steps > 0 ) {
		$self->{x_axis_steps} = $steps;
	}
}

    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_y_legend {
	my $self = shift;
	my $text = shift;
	my $size=-1; #shift;
	my $colour=''; #shift;
	
	if (@_) { $size = shift }
	if (@_) { $colour = shift }

	$self->{y_legend} = $text;
	if( $size > -1 ) {
		$self->{y_legend_size} = $size;
	}

	if( length( $colour )>0 ) {
		$self->{y_legend_colour} = $colour;
	}
}
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub line {
	my $self = shift;
	my $width = shift;
	my $colour=''; #shift;
	my $text=''; #shift;
	my $size=-1; #shift;
	my $circles=-1; #shift;
	
	if (@_) { $colour = shift }
	if (@_) { $text = shift }
	if (@_) { $size = shift }
	if (@_) { $circles = shift }

	
	my $tmp = '&line';

	if( scalar( @{$self->{lines}} ) > 0 ) {
		$tmp .= '_'. (scalar( @{$self->{lines}} )+1);
	}
		
	$tmp .= '=';

	if( $width > 0 ) {
		$tmp .= $width;
		$tmp .= ','. $colour;
	}
		
	if( length( $text ) > 0 ) {
		$tmp .= ','. $text;
		$tmp .= ','. $size;
	}

	if( $circles > 0 ) {
		$tmp .= ','. $circles;
	}

	$tmp .= "& \n";;

	push( @{$self->{lines}}, $tmp );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub line_dot {
	my $self = shift;
	my $width = shift;
	my $dot_size = shift;
	my $colour = shift;
	my $text=''; #shift;
	my $font_size=''; #shift;
	
	if (@_) { $text = shift }
	if (@_) { $font_size = shift }

	my $tmp = '&line_dot';

	if( scalar( @{$self->{lines}} ) > 0 ) {
		$tmp .= '_'. (scalar( @{$self->{lines}} )+1);
	}
		
	$tmp .= "=$width,$colour,$text";

	if( length( $font_size ) > 0 ) {
		$tmp .= ",$font_size,$dot_size";
	}

	$tmp .= "& \n";

	push( @{$self->{lines}}, $tmp );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub line_hollow {
	my $self = shift;
	my $width = shift; 
	my $dot_size = shift; 
	my $colour = shift;
	my $text=''; #shift;
	my $font_size=''; #shift;

	if (@_) { $text = shift }
	if (@_) { $font_size = shift }

	my $tmp = '&line_hollow';

	if( scalar( @{$self->{lines}} ) > 0 ) {
		$tmp .= '_'. (scalar( @{$self->{lines}} )+1);
	}
		
	$tmp .= "=$width,$colour,$text";

	if( length( $font_size ) > 0 ) {
	    $tmp .= ",$font_size,$dot_size";
	}

	$tmp .= "& \n";
	push( @{$self->{lines}}, $tmp );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub area_hollow {
	my $self = shift;
	my $width = shift; 
	my $dot_size = shift; 
	my $colour = shift;
	my $alpha = shift;
	my $text=''; #shift;
	my $font_size=''; #shift;
	
	if (@_) { $text = shift }
	if (@_) { $font_size = shift }

	my $tmp = '&area_hollow';

	if( scalar( @{$self->{lines}} ) > 0 ) {
		$tmp .= '_'. (scalar( @{$self->{lines}} )+1);
	}
		
	$tmp .= "=$width,$dot_size,$colour,$alpha";

	if( length( $text ) > 0 ) {
	    $tmp .= ",$text,$font_size";
	}
    
	$tmp .= "& \n";

	push( @{$self->{lines}}, $tmp );
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub bar {
	my $self = shift;
	my $alpha = shift;
	my $colour=''; #shift; 
	my $text=''; #shift;
	my $size=-1; #shift;
	
	if (@_) { $colour = shift }
	if (@_) { $text = shift }
	if (@_) { $size = shift }

	my $tmp = '&bar';

	if( scalar( @{$self->{lines}} ) > 0 ) {
		$tmp .= '_'. (scalar( @{$self->{lines}} )+1);
	}
		
	$tmp .= '=';
	$tmp .= $alpha .','. $colour .','. $text .','. $size;
	$tmp .= "& \n";
	
	push( @{$self->{lines}}, $tmp );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub bar_filled {
	my $self = shift;
	my $alpha = shift;
	my $colour = shift; 
	my $colour_outline = shift;
	my $text=''; #shift;
	my $size=-1; #shift;
	
	if (@_) { $text = shift }
	if (@_) { $size = shift }

	my $tmp = '&filled_bar';

	if( scalar( @{$self->{lines}} ) > 0 ) {
		$tmp .= '_'. (scalar( @{$self->{lines}} )+1);
	}
		
	$tmp .= "=$alpha,$colour,$colour_outline,$text,$size"."& \n";

	push( @{$self->{lines}}, $tmp );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub x_axis_colour {
	my $self = shift;
	my $axis = shift; 
	my $grid=''; #shift;
	
	if (@_) { $grid = shift }

	$self->{x_axis_colour} = $axis;
	$self->{x_grid_colour} = $grid;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub y_axis_colour {
	my $self = shift;
	my $axis = shift; 
	my $grid=''; #shift;

	if (@_) { $grid = shift }

	$self->{y_axis_colour} = $axis;
	$self->{y_grid_colour} = $grid;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub render {
	my $self = shift;

	my $tmp;
	#$tmp = "&padding=70,5,50,40& \0x0a";

	if( length( $self->{title} ) > 0 ) {
		$tmp .= '&title='. $self->{title} .',';
		$tmp .= $self->{title_size} .',';
		$tmp .= $self->{title_colour} ."& \n";
	}

	if( length( $self->{x_legend} ) > 0 ) {
		$tmp .= '&x_legend='. $self->{x_legend} .',';
		$tmp .= $self->{x_legend_size} .',';
		$tmp .= $self->{x_legend_colour} ."& \n";
	}

	if( $self->{x_label_style_size} > 0 ) {
		$tmp .= '&x_label_style='. $self->{x_label_style_size};
		$tmp .= ','.$self->{x_label_style_colour};
		$tmp .= ','.$self->{x_label_style_orientation};
		$tmp .= ','.$self->{x_label_style_step};
		$tmp .= "& \n";
	}

	if( $self->{x_tick_size} > 0 ) {
		$tmp .= "&x_ticks=". $self->{x_tick_size} ."& \n";
	}

	if( $self->{x_axis_steps} > 0 ) {
		$tmp .= "&x_axis_steps=". $self->{x_axis_steps} ."& \n";
	}

	if( length( $self->{y_legend} ) > 0 ) {
		$tmp .= '&y_legend='. $self->{y_legend} .',';
		$tmp .= $self->{y_legend_size} .',';
		$tmp .= $self->{y_legend_colour} ."& \n";
	}

	if( $self->{y_label_style_size} > 0 ) {
		$tmp .= "&y_label_style=";
		$tmp .= $self->{y_label_style_size} .',';
		$tmp .= $self->{y_label_style_colour};
		$tmp .= "& \n";
	}

	$tmp .= '&y_ticks=5,10,'. $self->{y_steps} ."& \n";

	if( scalar( @{$self->{lines}} ) == 0 ) {
		$tmp .= $self->{line_default};	
	} else {
		$tmp .= join "", @{$self->{lines}};
	}
	
	$tmp .= join "", @{$self->{data}};


	if( scalar( @{$self->{x_labels}} ) > 0 ) {
		$tmp .= '&x_labels='.join(',',@{$self->{x_labels}})."& \n";
	}

	$tmp .= '&y_min='. $self->{y_min} ."& \n";
	$tmp .= '&y_max='. $self->{y_max} ."& \n";

	if( length( $self->{bg_colour} ) > 0 ) {
		$tmp .= '&bg_colour='. $self->{bg_colour} ."& \n";
	}

	if( length( $self->{bg_image} ) > 0 ) {
		$tmp .= '&bg_image='. $self->{bg_image} ."& \n";
		$tmp .= '&bg_image_x='. $self->{bg_image_x} ."& \n";
		$tmp .= '&bg_image_y='. $self->{bg_image_y} ."& \n";
	}


	if( length( $self->{x_axis_colour} ) > 0 ) {
		$tmp .= '&x_axis_colour='. $self->{x_axis_colour} ."& \n";
		$tmp .= '&x_grid_colour='. $self->{x_grid_colour} ."& \n";
	}

	if( length( $self->{y_axis_colour} ) > 0 ) {
		$tmp .= '&y_axis_colour='. $self->{y_axis_colour} ."& \n";
		$tmp .= '&y_grid_colour='. $self->{y_grid_colour} ."& \n";
	}

	if( length( $self->{inner_bg_colour} ) > 0 ) {
		$tmp .= '&inner_background='.$self->{inner_bg_colour};
		if( length( $self->{inner_bg_colour_2} ) > 0 ) { 
			$tmp .= ','. $self->{inner_bg_colour_2};
			$tmp .= ','. $self->{inner_bg_angle};
		}
		$tmp .= "& \n";
	}
	
#	$tmp =~ s/ \n/\n/g;
 
	return "\r\n$tmp";
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub swf_object {
	my $width = shift;
	my $height = shift;
	my $url = shift;

  print '<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" width="400" height="300" id="graph-2" align="middle">';
  print '<param name="allowScriptAccess" value="sameDomain" />';
  print "<param name=\"movie\" value=\"/open-flash-chart.swf?width=$width &height=$height &data=$url  /><param name=\"quality\" value=\"high\" /><param name=\"bgcolor\" value=\"#FFFFFF\" />";
  print '<embed                src="/open-flash-chart.swf?width='. $width .'&height='. $height .'&data='. $url .'" quality="high" bgcolor="#FFFFFF" width="'. $width .'" height="'. $height .'" name="open-flash-chart" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />';
  print '</object>';

}



1;
