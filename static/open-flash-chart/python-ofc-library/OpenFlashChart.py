#class graph_object:
#	def render( self, width, height, url, ofc_base_url="/flashes/", ofc_swf="openFlashChart.swf" ):
#		return """<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/#swflash.cab#version=8,0,0,0" width="%(width)d" height="%(height)d" id="graph-2" align="middle">
#<param name="allowScriptAccess" value="sameDomain" />
#<param name="movie" value="%(ofc_base_url)s%(ofc_swf)s?width=%(width)d&height=%(height)d&data=%(url)s" />
#<param name="quality" value="high" /><param name="bgcolor" value="#FFFFFF" />
#<embed src="%(ofc_base_url)s%(ofc_swf)s?width=%(width)d&height=%(height)d&data=%(url)s" quality="high" bgcolor="#000000" width=%(width)d height=%(height)d name="open-flash-chart" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
#</object>""" % locals()


class graph_object:
	def render( self, width, height, data_url, swf_url_root=''):
		width = str(width)
		height = str(height)
		return """<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" width="400" height="300" id="graph-2" align="middle">
<param name="allowScriptAccess" value="sameDomain" />
<param name="movie" value="%sopen-flash-chart.swf?width=%s&height=%s&data=%s" />
<param name="quality" value="high" /><param name="bgcolor" value="#FFFFFF" />
<embed src="%sopen-flash-chart.swf?width=%s&height=%s&data=%s" quality="high" bgcolor="#FFFFFF" width="%s" height="%s" name="open-flash-chart" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
</object>"""%(swf_url_root,
				width,
				height,
				data_url,
				swf_url_root,
				width,
				height,
				data_url,
				width,
				height,
				)

class graph:
	def __init__(self):
		self.data = []
		self.x_labels = []
		self.y_min = 0
		self.y_max = 20
		self.y_steps = 5
		self.x_min = 0
		self.x_max = 0
		self.title_text = ''
		self.title_size = 30
		self.x_tick_size = -1
		
		self.y2_max = 0
		self.y2_min = 0

		# GRID styles:
		self.x_offset = ''
		self.x_axis_colour = ''
		self.x_grid_colour = ''
		self.x_axis_3d = 0
		self.x_axis_steps = 1
		
		self.y_axis_colour = ''
		self.y2_axis_colour = ''
		self.y_grid_colour = ''
		self.y2_grid_colour = ''
		self.x_axis_steps = 1


		# AXIS LABEL styles:         
		self.x_label_style_size = -1
		self.x_label_style_colour = '#000000'
		self.x_label_style_orientation = 0
		self.x_label_style_step = 1

		self.y_label_style_size = -1
		self.y_label_style_colour = '#000000'
		self.y_label_style_right_size = -1
		self.y_label_style_right_colour = '#000000'
		

		# AXIS LEGEND styles:
		self.x_legend = ''
		self.x_legend_size = 20
		self.x_legend_colour = '#000000'

		self.y_legend = ''
		self.y_legend_right = ''
		self.y_legend_size = 20
		self.y_legend_colour = '#000000'
		
		self.lines = []
		self.line_default = '&line=3,#87421F&' + "\r\n"
		
		self.bg_colour = ''
		self.bg_image = ''

		self.inner_bg_colour = ''
		self.inner_bg_colour_2 = ''
		self.inner_bg_angle = ''


		# PIE chart:
		self.pie = ''
		self.pie_values = ''
		self.pie_colours = ''
		self.pie_labels = ''
		self.pie_links = ''


		# Which data lines are attached to the right Y axis?
		self.y2_lines = []
	

		# Number formatting:
		self.y_format = ''
		self.num_decimals = 0
		self.is_fixed_num_decimals_forced = ''
		self.is_decimal_separator_comma = ''
		self.is_thousand_separator_disabled = ''

		
		# Tool tip:
		self.tool_tip = ''
		

	#========= Number formatting ==========
	def set_y_format( self, val ):
		self.y_format = val	
	
	def set_num_decimals( self, val ):
		self.num_decimals = int( val )
	
	def set_is_fixed_num_decimals_forced( self, val ):
		self.is_fixed_num_decimals_forced = "true" if (val) else "false"
	
	def set_is_decimal_separator_comma( self, val ):
		self.is_decimal_separator_comma = "true" if (val) else "false"

	def set_is_thousand_separator_disabled( self, val ):
		self.is_thousand_separator_disabled = "true" if (val) else "false"



	#============ Look ===============
	def set_data( self, a ):
		if( len( self.data ) == 0 ):
			self.data.append( '&values=%s&\r\n' % ','.join([str(v) for v in a]) )
		else:
			self.data.append( '&values_%s=%s&\r\n' % (len(self.data)+1, ','.join([str(v) for v in a])) )

	def pie_data( self, values, labels, links="" ):
		self.pie_values = '&values=%s&\r\n' % ','.join([str(value) for value in values])
		self.pie_labels = '&pie_labels=%s&\r\n' % ','.join(labels)
		self.pie_links  = '&links=%s&\r\n' % ','.join(links)

	def scatter_data( self, values):
		tmp = ','.join([str(point) for point in values])
		self.data.append( '&values=%s&\r\n' % (tmp) )

	def hlc_data( self, values):
		tmp = ','.join([str(point) for point in values])
		self.data.append( '&values=%s&\r\n' % (tmp) )

	def candle_data( self, values):
		tmp = ','.join([str(point) for point in values])
		if( len( self.data ) == 0 ):
			self.data.append( '&values=%s&\r\n' % (tmp) )
		else:
			self.data.append( '&values_%s=%s&\r\n' % (len(self.data)+1,tmp) )

	def clear_data( self ):
		self.data = []
		
	def clear_pie_data( self ):
		self.pie_values = ""
		self.pie_labels = ""
		self.pie_links = ""
		
	def clear_scatter_data( self ):
		self.scatter_values = ""

	def set_x_offset( self, val ):
		if ( val ):
			self.x_offset = "true"
		else:
			self.x_offset = "false"

	def set_tool_tip( self, tip ):
		self.tool_tip = tip

	def set_x_labels( self, a ):
		self.x_labels = a
    
	def set_x_label_style( self, size, colour='', orientation=0, step=-1 ):
		self.x_label_style_size = size

		if( len( colour ) > 0 ):
			self.x_label_style_colour = colour

		if( orientation > 0 ):
			self.x_label_style_orientation = orientation

		if( step > 0 ):
			self.x_label_style_step = step

	def set_bg_colour( self, colour ):
		self.bg_colour = colour

	def set_bg_image( self, url, x='center', y='center' ):
		self.bg_image = url
		self.bg_image_x = x
		self.bg_image_y = y

	def attach_to_y_right_axis( self, data_number ):
		self.y2_lines.append(data_number)

	def set_inner_background( self, col, col2='', angle=-1 ):
		self.inner_bg_colour = col

		if( len(col2) > 0 ):
			self.inner_bg_colour_2 = col2

		if( angle != -1 ):
			self.inner_bg_angle = angle

	def set_y_label_style( self, size, colour='' ):
		self.y_label_style_size = size

		if( len( colour ) > 0 ):
			self.y_label_style_colour = colour

	def set_y_max( self, max ):
 		self.y_max = int( max )

	def set_y_min( self, min ):
		self.y_min = int( min )
    
	def y_label_steps( self, val ):
		self.y_steps = int( val )
  
	def set_y_right_max( self, max ):
		self.y2_max =int( max )

	def set_y_right_min( self, min ):
		self.y2_min = int( min )
  
	def set_x_max( self, max ):
		self.x_max = int( max )

	def set_x_min( self, min ):
		self.x_min = int( min )
   
	def title( self, title, size=-1, colour='#000000' ):
		self.title_text = title
		if( size > 0 ):
			self.title_size = size
		if( len( colour ) > 0 ):
			self.title_colour = colour

	def set_x_legend( self, text, size=-1, colour='' ):
		self.x_legend = text
		if( size > -1 ):
			self.x_legend_size = size
                
		if( len( colour )>0 ):
			self.x_legend_colour = colour
    
	def set_x_tick_size( self, size ):
		if( size > 0 ):
			self.x_tick_size = size

	def set_x_axis_steps( self, steps ):
		if ( steps > 0 ):
			self.x_axis_steps = steps

	def set_x_axis_3d( self, size ):
		if( size > 0 ):
			self.x_axis_3d = size;

	def set_y_legend( self, text, size=-1, colour='' ):
		self.y_legend = text
		if( size > -1 ):
			self.y_legend_size = size

		if( len( colour )>0 ):
			self.y_legend_colour = colour
    
	def set_y_right_legend( self, text, size=-1, colour='' ):
		self.y_legend_right = text
		if( size > -1 ):
			self.y_legend_right_size = size

		if( len( colour ) > 0 ):
			self.y_legend_right_colour = colour
    
	def pie_slice_colours( self, colours ):
		self.pie_colours = '&colours=%s&\r\n' % ','.join(colours)

    
    #========== Chart types ==============
	def line( self, width, colour='', text='', size=-1, circles=-1 ):
		tmp = '&line'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)
				
		tmp += '='
		
		if( width > 0 ):
			tmp += "%s,%s" % (width, colour)
							
		if( len( text ) > 0 ):
			tmp += ',%s,%s' % (text,size)
			
		if( circles > 0 ):
			tmp += ',%s' % circles
			
		tmp += "&\r\n"
		self.lines.append( tmp )

	def line_dot( self, width, dot_size, colour, text='', font_size=0 ):
		tmp = '&line_dot'
		
		if( len( self.lines ) > 0 ):
				tmp += '_%s' % (len( self.lines )+1)
				
		tmp += "=%s,%s,%s" % (width,colour,text)

		if( font_size > 0 ):
			tmp += ",%s,%s" % (font_size,dot_size)
			
		tmp += "&\r\n"
			
		self.lines.append( tmp )

	def line_hollow( self, width, dot_size, colour, text='', font_size=0 ):
		tmp = '&line_hollow'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)
				
		tmp += "=%s,%s,%s" % (width,colour,text)

		if( font_size > 0 ):
			tmp += ",%s,%s" % (font_size,dot_size)
			
		tmp += "&\r\n"
		self.lines.append( tmp )

	def area_hollow( self, width, dot_size, colour, alpha, text='', font_size=0, fill_color='' ):
		tmp = '&area_hollow'
		
		if( len( self.lines ) > 0 ):
				tmp += '_%s' % (len( self.lines )+1)
				
		tmp += "=%s,%s,%s,%s" % (width,dot_size,colour,alpha)

		if( len( text ) > 0 ):
			tmp += ",%s,%s" % (text,font_size)

		if( len( fill_color ) > 0 ):
			tmp += ",%s" % (fill_color)
				
		tmp += "&\r\n"
		self.lines.append( tmp )

	def bar( self, alpha, colour='', text='', size=-1 ):
		tmp = '&bar'
		
		if( len( self.lines ) > 0 ):
				tmp += '_%s' % (len( self.lines )+1)
				
		tmp += '='
		tmp += "%s,%s,%s,%s" % (alpha,colour,text,size)
		tmp += "&\r\n"
			
		self.lines.append( tmp )

	def bar_outline( self, alpha, colour, colour_outline, text='', size=-1 ):
		tmp = '&filled_bar'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)
				
		tmp += '='
		tmp += "%s,%s,%s,%s,%s" % (alpha,colour,outline_colour,text,size)
		tmp += "&"
			
		self.lines.append( tmp )

	def bar_3d( self, alpha, colour='', text='', size=-1 ):
		tmp = '&bar_3d'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)
			
		tmp += "=%s,%s,%s,%s&\r\n" % (alpha,colour,text,size)
			
		self.lines.append( tmp )
		
	def bar_glass( self, alpha, colour, colour_outline, text='', size=-1 ):
		tmp = '&bar_glass'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)

		tmp += "=%s,%s,%s,%s,%s&\r\n" % (alpha,colour,colour_outline,text,size)

		self.lines.append( tmp )

	def bar_fade( self, alpha, colour, text='', size=-1 ):
		tmp = '&bar_fade'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)
			
		tmp += "=%s,%s,%s,%s&\r\n" % (alpha,colour,text,size)

		self.lines.append( tmp )

	def bar_sketch( self, alpha, offset, colour, colour_outline, text='', size=-1 ):
		tmp = '&bar_sketch'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)
			
		tmp += "=%s,%s,%s,%s,%s,%s&\r\n" % (alpha,offset,colour,colour_outline,text,size)

		self.lines.append( tmp )

	def pie_chart( self, alpha, line_colour, label_colour, gradient=True, border_size=-1 ):
		
		self.pie = "%s,%s,%s" % (alpha,line_colour,label_colour)
		
		if( gradient ):
			self.pie += ",%s" %("true")

		if ( border_size > 0 ):
			if ( gradient ):
				self.pie += ","
			self.pie += ",%s" %(border_size)

	def scatter( self, data, line_width, colour, text='', size=-1 ):
		tmp = '&scatter'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)

		tmp += "=%s,%s,%s,%s&\r\n" % (line_width,colour,text,size)

		self.lines.append( tmp )
		self.scatter_data( data )

	def hlc( self, data, alpha, line_width, colour, text='', size=-1 ):
		tmp = '&hlc'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)

		tmp += "=%s,%s,%s,%s,%s&\r\n" % (alpha,line_width,colour,text,size)

		self.lines.append( tmp )
		self.hlc_data( data )

	def candle( self, data, alpha, line_width, colour, text='', size=-1 ):
		tmp = '&candle'
		
		if( len( self.lines ) > 0 ):
			tmp += '_%s' % (len( self.lines )+1)

		tmp += "=%s,%s,%s,%s,%s&\r\n" % (alpha,line_width,colour,text,size)

		self.lines.append( tmp )
		self.candle_data( data )


	#============ Axis colour ============
	def set_x_axis_colour( self, axis, grid='' ):
		self.x_axis_colour = axis
		self.x_grid_colour = grid

	def y_axis_colour( self, axis, grid='' ):
		self.y_axis_colour = axis
		self.y_grid_colour = grid

	def pie(self, alpha, line_colour, label_colour ):
		self.pie = str(alpha) + ',' + line_colour + ',' + label_colour

	def pie_values(self, values, labels):
		self.pie_values = ','.join([str(v) for v in values]) 
		self.pie_labels = ','.join([str(v) for v in labels])		

	def pie_slice_colours(self, colours):
		self.pie_colours = ','.join([str(v) for v in colours])

	def set_tool_tip(self, tip):
		self.tool_tip = tip

	#========== Render data string ========
	def render( self,):
		#tmp = "&padding=70,5,50,40&\r\n"
		tmp = ''
		
		if( len( self.title_text ) > 0 ):
			tmp += '&title=%s,%s,%s&\r\n' % (self.title_text,self.title_size,self.title_colour)
		
		if( len( self.x_legend ) > 0 ):
			tmp += '&x_legend=%s,%s,%s\r\n' % (self.x_legend,self.x_legend_size,self.x_legend_colour)
		
		if( self.x_label_style_size > 0 ):
			tmp += '&x_label_style=%s,%s,%s,%s&\r\n' % (self.x_label_style_size,self.x_label_style_colour,self.x_label_style_orientation,self.x_label_style_step)
		
		if( self.x_tick_size > 0 ):
			tmp += "&x_ticks=%s&\r\n" % self.x_tick_size

		if( self.x_axis_steps > 0 ):
			tmp += "&x_axis_steps=%s&\r\n" % self.x_axis_steps

		if( self.x_axis_3d > 0 ):
			tmp += "&x_axis_3d=%s&\r\n" % self.x_axis_3d

		if( len( self.y_legend ) > 0 ):
			tmp += '&y_legend=%s,%s,%s&\r\n' % (self.y_legend,self.y_legend_size,self.y_legend_colour)

		if( len( self.y_legend_right) > 0 ):
			tmp += '&y2_legend=%s,%s,%s&\r\n' % (self.y_legend_right, self.y_legend_right_size, self.y_legend_right_colour)

		if( self.y_label_style_size > 0 ):
			tmp += "&y_label_style=%s" % (self.y_label_style_size)
			if( len( self.y_label_style_colour ) > 0):
				tmp += ",%s&\r\n" % (self.y_label_style_colour)

		tmp += '&y_ticks=5,10,%s&\r\n' % self.y_steps
		
		if( len( self.lines ) == 0 ):
			tmp += self.line_default
		else:
			tmp += "".join(self.lines)

		tmp += "".join(self.data)
		
		if( len( self.y2_lines ) > 0 ):
			tmp += '&y2_lines=%s&\r\n' % ",".join([str(value) for value in self.y2_lines])
			tmp += '&show_y2=true&\r\n'
		
		if( len( self.x_labels ) > 0 ):
			tmp += '&x_labels=%s&\r\n' % ",".join(str(label) for label in self.x_labels)
		else:
			if( self.x_min ):
				tmp += '&x_min=%s&\r\n' % self.x_min
			if( self.x_max ):
				tmp += '&x_max=%s&\r\n' % self.x_max		
		
		tmp += '&y_min=%s&\r\n' % self.y_min
		tmp += '&y_max=%s&\r\n' % self.y_max
		if( self.y2_min > 0 ):
			tmp += '&y2_min=%s&\r\n' % self.y2_min
			
		if( self.y2_max > 0 ):
			tmp += '&y2_max=%s&\r\n' % self.y2_max

		if( len( self.bg_colour ) > 0 ):
			tmp += '&bg_colour=%s&\r\n' % self.bg_colour

		if( len( self.bg_image ) > 0 ):
			tmp += '&bg_image=%s&\r\n' % self.bg_image
			tmp += '&bg_image_x=%s&\r\n' % self.bg_image_x
			tmp += '&bg_image_y=%s&\r\n' % self.bg_image_y

		if( len( self.x_axis_colour ) > 0 ):
			tmp += '&x_axis_colour=%s&\r\n' % self.x_axis_colour
			tmp += '&x_grid_colour=%s&\r\n' % self.x_grid_colour

		if( len( self.y_axis_colour ) > 0 ):
			tmp += '&y_axis_colour=%s&\r\n' % self.y_axis_colour
			tmp += '&y_grid_colour=%s&\r\n' % self.y_grid_colour

		if( len( self.y2_axis_colour ) > 0 ):
			tmp += '&y2_axis_colour=%s&\r\n' % self.y2_axis_colour
			tmp += '&y2_grid_colour=%s&\r\n' % self.y2_grid_colour

		if( len( self.x_offset ) > 0 ):
			tmp += '&x_offset=%s&\r\n' % self.x_offset

		if( len( self.inner_bg_colour ) > 0 ):
			tmp += '&inner_background=%s' % self.inner_bg_colour
			if( len( self.inner_bg_colour_2 ) > 0 ):
				tmp += ',%s,%s' % ( self.inner_bg_colour_2, self.inner_bg_angle )
			tmp += "&\r\n"

		if( len( self.pie ) > 0 ):
			tmp += '&pie=%s&\r\n' % self.pie
			tmp += self.pie_values
			tmp += self.pie_labels
			tmp += self.pie_colours
			tmp += self.pie_links

		if( len( self.tool_tip) > 0 ):
			tmp += '&tool_tip=%s&\r\n' % self.tool_tip

		if( len( self.y_format) > 0 ):
			tmp += '&y_format=%s&\r\n' % self.y_format
			
		if( self.num_decimals > 0 ):
			tmp += '&num_decimals=%s&\r\n' % self.num_decimals
			
		if( len( self.is_fixed_num_decimals_forced) > 0 ):
			tmp += '&is_fixed_num_decimals_forced=%s&\r\n' % self.is_fixed_num_decimals_forced
			
		if( len( self.is_decimal_separator_comma) > 0 ):
			tmp += '&is_decimal_separator_comma=%s&\r\n' % self.is_decimal_separator_comma
			
		if( len( self.is_thousand_separator_disabled) > 0 ):
			tmp += '&is_thousand_separator_disabled=%s&\r\n' % self.is_thousand_separator_disabled
			

		return tmp



