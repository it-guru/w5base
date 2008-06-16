#!/usr/bin/python
#=========================================================================
#                		   Open Flash Chart Demo
#
# Author: Eugene Kin Chee Yip
# Maintainer: Eugene Kin Chee Yip
# Date: 13 Jan 2008


# Import required python modules
import	cherrypy		# Webserving
import	os				# Going through the filesystem


# Import custom functions and classes
from	openFlashChart import *		# Flash based charting application


class ofc_Demo:
	
	#########################################################
	#                    Main webpages
	#########################################################
	
	#====== Homepage of http://localhost:80/ =========
	def index(self):
		"""This is the Homepage."""
		g = graph_object()
		
		graphs = []
		graphs.append(g.render('80%', '100%', "/line_demo"))
		graphs.append(g.render('80%', '100%', "/bar2_demo"))
		graphs.append(g.render('80%', '100%', "/bar3d_demo"))
		graphs.append(g.render('80%', '100%', "/barGlass_demo"))
		graphs.append(g.render('80%', '100%', "/barFade_demo"))
		graphs.append(g.render('80%', '100%', "/sketch_demo"))
		graphs.append(g.render('80%', '100%', "/area2_demo"))
		graphs.append(g.render('80%', '100%', "/barsLines_demo"))
		graphs.append(g.render('80%', '100%', "/pieLinks_demo"))
		graphs.append(g.render('80%', '100%', "/scatter_demo"))
		graphs.append(g.render('80%', '100%', "/hlc_demo"))
		graphs.append(g.render('80%', '100%', "/candle_demo"))
			
		graphs.append(g.render('80%', '100%', "/y2_demo"))
		graphs.append(g.render('80%', '100%', "/y3_demo"))

		return "<br/><br/><br/>".join(graphs)
		
	index.exposed = True


	#============= Open Flash Charts =================
	def line_demo(self):
		g = graph()
	
		data_1 = [19,17,19,19,17,19,17,17,14,14,17,16]
		data_2 = [12,10,8,10,13,9,8,10,8,10,10,8]
		data_3 = [7,6,2,6,6,4,3,2,5,4,2,5]

		g.title( 'Many data lines', '{font-size: 20px; color: #736AFF}' )

		g.set_data( data_1 )
		g.set_data( data_2 )
		g.set_data( data_3 )

		g.line( 2, '0x9933CC', 'Page views', 10 )
		g.line_dot( 3, 5, '0xCC3399', 'Downloads', 10)
		g.line_hollow( 2, 4, '0x80a033', 'Bounces', 10 )

		g.set_x_labels( ['January,February,March,April,May,June,July,August,Spetember,October,November,December'] )
		g.set_x_label_style( 10, '0x000000', 0, 2 )

		g.set_y_max( 20 )
		g.y_label_steps( 4 )
		g.set_y_legend( 'Open Flash Chart', 12, '#736AFF' )
		
		return g.render()
	
	
	line_demo.exposed = True
	
	
	def bar2_demo(self):
		g = graph()
		
		g.bar_outline( 50, '#0066CC', '#0c0c0c', 'Me', 20 )
		g.bar( 50, '#9933CC', 'You', 20 )
		g.bar( 50, '#639F45', 'Them', 20 )

		g.set_data([4,3,5,5,4,4,4,4,3])
		g.set_data([7,9,6,7,7,8,8,5,8])
		g.set_data([9,2,4,9,4,6,3,4,2])

		g.title( 'Multiple Bar Charts', '{font-size: 26px;}' );

		g.set_x_labels( ['January,February,March,April,May,June,July,August,September'] );
		g.set_x_label_style( 10, '#9933CC', 0, 2 )
		g.set_x_axis_steps( 2 )

		g.set_y_max( 10 )
		g.y_label_steps( 2 )
		g.set_y_legend( 'Open Flash Chart', 12, '0x736AFF' )
		return g.render();
		
	bar2_demo.exposed = True
	
	
	def bar3d_demo(self):
		g = graph()
		
		g.bar_3d( 75, '#D54C78', '2006', 10 )
		g.set_data([4,2,2,4,2,3,5,5,4,5])

		g.bar_3d( 75, '#3334AD', '2007', 10 )
		g.set_data([5,6,8,8,7,9,9,9,6,8])

		g.title( '3D Bar Chart', '{font-size:20px; color: #FFFFFF; margin: 5px; background-color: #505050; padding:5px; padding-left: 20px; padding-right: 20px;}' )

		g.set_x_axis_3d( 12 )
		g.x_axis_colour = '#909090'
		g.x_grid_colour = '#ADB5C7'
		g.y_axis_colour = '#909090'
		g.y_grid_colour = '#ADB5C7'

		g.set_x_labels( ['January,February,March,April,May,June,July,August,September,October'] )
		g.set_y_max( 10 )
		g.y_label_steps( 5 )
		g.set_y_legend( 'Open Flash Chart', 12, '#736AFF' )
	
		return g.render()
	
	bar3d_demo.exposed = True
	
	
	def barGlass_demo(self):
		g = graph()
		
		g.bar_glass( 55, '#D54C78', '#C31812', '2006', 10 )
		g.bar_glass( 55, '#5E83BF', '#424581', '2007', 10 )

		g.title( 'Glass Bars', '{font-size:20px; color: #bcd6ff; margin:10px; background-color: #5E83BF; padding: 5px 15px 5px 15px;}' )

		g.set_data([3,3,4,3,3,2,2,2,3,5])
		g.set_data([4,8,1,1,1,-2,9,5,1,-3])

		g.set_x_labels( ['January,February,March,April,May,June,July,August,September,October'] )

		g.x_axis_colour = '#909090'
		g.x_grid_colour = '#D2D2FB'
		g.y_axis_colour = '#909090'
		g.y_grid_colour = '#D2D2FB'

		g.set_y_min( -5 )
		g.set_y_max( 10 )
		g.y_label_steps( 6 )
		g.set_y_legend( 'Open Flash Chart', 12, '#736AFF' )
		
		return g.render()
	
	barGlass_demo.exposed = True
	
	
	def barFade_demo(self):
		g = graph()
	
		g.bar_fade( 55, '#C31812', '2006', 10 )
		g.bar_fade( 55, '#424581', '2007', 10 )

		g.title( 'Fade Bars', '{font-size:20px; color: #bcd6ff; margin:10px; background-color: #5E83BF; padding: 5px 15px 5px 15px;}' )
		g.bg_colour = '#FDFDFD'

		g.set_data([3,3,5,3,4,4,2,4,2,5])
		g.set_data([6,7,8,6,7,9,5,6,8,9])

		g.x_axis_colour = '#909090'
		g.x_grid_colour = '#D2D2FB'
		g.y_axis_colour = '#909090'
		g.y_grid_colour = '#D2D2FB'

		g.set_x_labels( ['January,February,March,April,May,June,July,August,September,October'] )
		g.set_x_label_style( 11, '#000000', 2 )

		g.set_y_max( 10 )
		g.y_label_steps( 5 )
		g.set_y_legend( 'Open Flash Chart', 12, '#736AFF' )

		return g.render()
	
	barFade_demo.exposed = True
	
	
	def sketch_demo(self):
		g = graph()
		
		g.bar_sketch( 55, 6, '#d070ac', '#000000', '2006', 10 )

		g.title( 'Sketch', '{font-size:20px; color: #ffffff; margin:10px; background-color: #d070ac; padding: 5px 15px 5px 15px;}' )
		g.bg_colour = '#FDFDFD'

		g.set_data([7,7,7,8,5,2,9,7,9,2])

		g.x_axis_colour = '#e0e0e0'
		g.x_grid_colour = '#e0e0e0'
		g.set_x_tick_size( 9 );
		g.y_axis_colour = '#e0e0e0'
		g.y_grid_colour = '#e0e0e0'

		g.set_x_labels( ['January,February,March,April,May,June,July,August,September,October'] )
		g.set_x_label_style( 11, '#303030', 2 )
		g.set_y_label_style( 11, '#303030')

		g.set_y_max( 10 )
		g.y_label_steps( 5 )
		
		return g.render()
		
	sketch_demo.exposed = True
	
	
	def area2_demo(self):
		g = graph()

		g.title( 'Area Chart 2', '{font-size: 26px;}' )

		g.set_data([0,0.37747172851062,0.73989485038644,1.0728206994506,1.3629765727091,1.598794871135,1.7708742633377, 1.8723544869781,1.8991898457789,1.8503104986686,1.7276651109688,1.5361431672572,1.2833800430472,0.97945260646078, 0.63647748529622,0.26812801531375,-0.1109108725124,-0.48552809385098,-0.84078884226022,-1.1625299927912,-1.4379247410851, -1.6559939675858,-1.8080439403901,-1.8880129069036,-1.8927127567881,-1.82195612186,-1.6785638458683,-1.4682525263564, -1.1994066119574,-0.88274414088613,-0.53088944657795])

		g.area_hollow( 2, 3, 25, '#C11B01', 'Squared', 12, '#0c0c0c' )

		g.set_x_labels([0.00,0.38,0.74,1.07,1.36,1.60,1.77,1.87,1.90,1.85,1.73,1.54,1.28,0.98,0.64,0.27,-0.11,-0.49,-0.84,-1.16,-1.44, -1.66,-1.81,-1.89,-1.89,-1.82,-1.68,-1.47,-1.20,-0.88,-0.53])
		g.set_x_label_style( 10, '#000000', 0, 2 )
		g.set_x_axis_steps( 2 )
		g.set_x_legend( 'X squared', 12, '#C11B01' )

		g.set_y_min( -2 )
		g.set_y_max( 2 )

		g.y_label_steps( 15 )
		g.set_y_legend( 'Value', 12, '#C11B01' )
		
		
		return g.render()
		
	area2_demo.exposed = True
	
	
	def barsLines_demo(self):
		g = graph()
		
		g.set_data([3,3,2,3,3,2,4,2,3])
		g.bar( 50, '#9933CC', 'Purple Bar', 10 )

		g.set_data([4,5,6,7,7,6,6,5,6])
		g.bar( 50, '#339966', 'Green Bar', 10 )
		
		g.set_data([8,6,5,5,9,8,9,8,5])
		g.line_dot( 3, 5, '#CC3399', 'Line', 10 )

		g.title( 'Mixed Line and Bar Charts', '{font-size: 35px; color: #800000}' )

		g.set_x_labels( ['Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep'] )
		g.set_y_max( 10 )
		g.y_label_steps( 2 )
		g.set_y_legend( 'Your legend here!', 12, '#736AFF' )
	
		return g.render()
		
	barsLines_demo.exposed = True
	
	
	def pieLinks_demo(self):
		g = graph()

		values = [14,11,11,13,8]
		links = ["javascript:alert('%s')" %value for value in values]

		g.bg = '#E4F0DB'
		g.pie_chart(60,'#ffffff','#000000',True,1)
		g.pie_data( values, ['IE','Firefox','Opera','Wii','Other','Slashdot'], links )

		g.pie_slice_colours( ['#d01f3c','#356aa0','#C79810'] )
		g.set_tool_tip( '#val#%' )

		g.title( 'Pie Chart Links', '{font-size:18px; color: #d01f3c}' )

		return g.render()
		
	pieLinks_demo.exposed = True
	
	
	def scatter_demo(self):
		g = graph()
		
		points = [[-5,-5,10],[0,0,5],[0,1,15],[0,-1,15],[1,1,15],[2,2,4],[5,5,12],[5,-5,9],[-5,5,5],[0.5,1,15]]

		g.title( 'Scatter Chart', '{font-size: 26px;}' )
		g.scatter( points, 3, '#736AFF', 'My Dots', 12 )

		g.set_tool_tip( 'x:#x_label#<br>y:#val#' )

		g.set_x_offset( False )

		g.set_y_label_style( 10, '#9933CC' )
		g.y_label_steps(10)

		g.set_x_label_style( 10, '#9933CC' )

		g.set_x_legend( 'Measurements' )

		g.set_y_min( -5 )
		g.set_y_max( 5 )
		g.set_x_min( -5 )
		g.set_x_max( 5 )
	
		return g.render()
		
	scatter_demo.exposed = True
	
	
	def hlc_demo(self):
		g = graph()
		
		g.hlc([[48,40,42],[30,28,28],[20,10,15],[50,30,35],[58,30,50],[62,33,45],[30,20,25]],60, 2, '#F50505', 'My Company', 12)
		g.title( 'High Low Close', '{font-size: 26px;}' )
		g.set_tool_tip( '#x_label#<br>Close: #close#<br>High: #high#<br>Low: #low#' )

		g.set_x_labels(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'])
		g.set_x_label_style( 10, '#000000', 0, 1 )
		g.set_x_legend( 'Week 1', 12, '#C11B01' )

		g.set_y_min( 0 )
		g.set_y_max( 70 )

		g.y_label_steps( 10 )
		g.set_y_legend( 'Value', 12, '#C11B01' )
	
		cherrypy.response.headers['Cache-Control'] = 'no-cache'
		return g.render()
	
	hlc_demo.exposed = True


	def candle_demo(self):
		g = graph()
		
		hlc_1 = [[10,8,6,4],[20,15,10,5],[20,15,10,5],[20,10,15,5],[30,5,27,2]]
		hlc_2 = [[10,8,6,4],[20,10,15,5],[28,24,18,16],[10,6,9,4],[5,4,2,1]]

		g.title( 'Candle', '{font-size: 26px;}' )

		g.candle( hlc_1, 60, 2, '#C11B01', 'My Company', 12 )
		g.candle( hlc_2, 60, 2, '#B0C101', 'Your Company', 12 )

		g.set_tool_tip( '#x_legend#<br>High: #high#<br>Open: #open#<br>Close: #close#<br>Low: #low#' )

		g.set_x_labels(['Mon','Tue','Wed','Thu','Fri'])
		g.set_x_label_style( 10, '#000000', 0, 1 )
		g.set_x_legend( 'Week 1', 12, '#C11B01' )

		g.set_y_min( 0 )
		g.set_y_max( 30 )

		g.y_label_steps( 10 )
		g.set_y_legend( 'Value', 12, '#C11B01' )

		return g.render()
		
	candle_demo.exposed = True


	def y2_demo(self):
		g = graph()

		g.title( 'Users vs. Ram - 24h statistics', '{color: #7E97A6; font-size: 20; text-align: center}' )
		g.bg_colour = '#FFFFFF'

		g.set_data([289,198,143,126,98,96,124,164,213,238,256,263,265,294,291,289,306,341,353,353,402,419,404,366,309])
		g.line_dot( 2, 4, '#818D9D', 'Max Users', 10 )

		g.set_data([698,1101,1324,1396,1568,1571,1496,1349,1140,1045,966,926,906,754,766,757,672,510,431,436,227,533,566,744,1004])
		g.line_hollow( 2, 4, '#164166', 'Free Ram', 10 )

		g.attach_to_y_right_axis(2)

		g.set_y_max( 600 )
		g.set_y_right_max( 1700 )

		g.x_axis_colour = '#818D9D'
		g.x_grid_colour = '#F0F0F0'
		g.y_axis_colour = '#818D9D'
		g.y_grid_colour = '#ADB5C7'
		g.y2_axis_colour = '#164166'
		
		g.set_x_legend( 'My IRC Server', 12, '#164166' )
		g.set_y_legend( 'Max Users', 12, '#164166' )
		g.set_y_right_legend( 'Free Ram (MB)' ,12 , '#164166' )

		g.set_x_labels(['00:00','01:00','02:00','03:00','04:00','05:00','06:00','07:00','08:00','09:00', '10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00','19:00','20:00','21:00','22:00','23:00','24:00'])
		g.set_x_label_style( 10, '#164166', 0, 3 )

		g.set_tool_tip( '#key#<br>#val# (#x_label#)' )

		g.y_label_steps( 5 )


		cherrypy.response.headers['Cache-Control'] = 'no-cache'
		return g.render()
	
	y2_demo.exposed = True



	def y3_demo(self):
		graphTip = graph_object()
		
	
		g = graph()

		g.title( 'Users vs. Ram - 24h statistics', '{color: #7E97A6; font-size: 20; text-align: center}' )
		g.bg_colour = '#FFFFFF'

		g.set_data([289,198,143,126,98,96,124,164,213,238,256,263,265,294,291,289,306,341,353,353,402,419,404,366,309])
		g.line_dot( 2, 4, '#818D9D', 'Max Users', 10 )

		g.set_data([300,111,124,136,156,151,196,149,110,105,96,96,90,74,66,77,67,10,31,43,22,53,56,74,104])
		g.line_hollow( 2, 4, '#164166', 'Used Ram', 10 )

		g.set_data([698,1101,1324,1396,1568,1571,1496,1349,1140,1045,966,926,906,754,766,757,672,510,431,436,227,533,566,744,1004])
		g.line_hollow( 2, 4, '#164166', 'Free Ram', 10 )

		g.attach_to_y_right_axis(3)

		g.set_y_max( 600 )
		g.set_y_right_max( 1700 )

		g.x_axis_colour = '#818D9D'
		g.x_grid_colour = '#F0F0F0'
		g.y_axis_colour = '#818D9D'
		g.y_grid_colour = '#ADB5C7'
		g.y2_axis_colour = '#164166'
		
		g.set_x_legend( 'My IRC Server', 12, '#164166' )
		g.set_y_legend( 'Max Users', 12, '#164166' )
		g.set_y_right_legend( 'Free Ram (MB)' ,12 , '#164166' )
		g.set_y_label_style( 'none' )

		g.set_x_labels(['00:00','01:00','02:00','03:00','04:00','05:00','06:00','07:00','08:00','09:00', '10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00','19:00','20:00','21:00','22:00','23:00','24:00'])
		g.set_x_label_style( 10, '#164166', 0, 3 )

		g.set_tool_tip( '#key#<br>#val# (#x_label#)' )

		g.y_label_steps( 5 )


		cherrypy.response.headers['Cache-Control'] = 'no-cache'
		return g.render()
	
	y3_demo.exposed = True


	#============= Returns flash files ===============
	def flashes(self, filename, data = None):
		"""Take a filename and return the corresponding adobe flash object."""
		cherrypy.response.headers['Content-Type'] = "application/x-shockwave-flash"
		cherrypy.response.headers['Expires'] = 'Mon, 1 Jul 2009 01:00:00 GMT'
		cherrypy.response.headers['Cache-Control'] = 'Public'
		return open(filename)
	
	flashes.exposed = True


#====                           ======                              ====#
#                           Server session                              #
#========================================================================

cherrypy.server.socket_host = "localhost"
cherrypy.server.socket_port = 8080
cherrypy.quickstart(ofc_Demo())

#=================

print
print "*Done with server*"
print
