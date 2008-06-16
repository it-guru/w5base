package org.openflashchart;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;


public class Graph {
	List<data_set> data_sets = new ArrayList<data_set>();
	
	List<String> data = new ArrayList<String>();
	List<String> links = new ArrayList<String>();
	int width = 250;
	int height = 200;
	String base = "js/";
	List<String> x_labels = new ArrayList<String>();
	String y_min = "";
	String y_max = "";
	String x_min = "";
	String x_max = "";
	String y_steps = "";
	String title = "";
	String title_style = "";
	int occurence = 0;
	
	String x_offset = "";

	int x_tick_size = -1;

	String y2_max = "";
	String y2_min = "";

	// GRID styles:
	String x_axis_colour = "";
	String x_axis_3d = "";
	String x_grid_colour = "";
	int x_axis_steps = 1;
	String y_axis_colour = "";
	String y_grid_colour = "";
	String y2_axis_colour = "";
	
	// AXIS LABEL styles:         
	String x_label_style = "";
	String y_label_style = "";
	String y_label_style_right = "";


	// AXIS LEGEND styles:
	String x_legend = "";
	int x_legend_size = 20;
	String x_legend_colour = "#000000";

	String y_legend = "";
	String y_legend_right = "";
	//this.y_legend_size = 20;
	//this.y_legend_colour = '#000000';

	List<Line> lines = new ArrayList<Line>();
	// this.line_default['type'] = 'line';
	// this.line_default['values'] = '3,#87421F';
	// this.js_line_default = 'so.addVariable("line","3,#87421F");';
	
	String bg_colour = "";
	String bg_image = "";

	String inner_bg_colour = "";
	String inner_bg_colour_2 = "";
	String inner_bg_angle = "";
	
	// PIE chart ------------
	String pie = "";
	String pie_values = "";
	String pie_colours = "";
	String pie_labels = "";
	String pie_links = "";
	
	String tool_tip = "";
	
	// which data lines are attached to the
	// right Y axis?
	List<String> y2_lines = new ArrayList<String>();
	
	// Number formatting:
	String y_format="";
	String num_decimals="";
	String is_fixed_num_decimals_forced="";
	String is_decimal_separator_comma="";
	String is_thousand_separator_disabled="";

	
	/**
	* Constructor for the open_flash_chart_api
	* Sets our default variables
	*/
	public Graph()
	{
		
		//
		// set some default value incase the user forgets
		// to set them, so at least they see *something*
		// even is it is only the axis and some ticks
		//
		this.set_y_min( 0 );
		this.set_y_max( 20 );
		this.set_x_axis_steps( 1 );
		this.y_label_steps( 5 );
	}

//	String unique_id;
//	/**
//	* Set the unique_id to use for the flash object id.
//	*/
//	private void set_unique_id()
//	{
//		this.unique_id = uniqid();
//	}
//	
//	/**
//	 * The uniqid() function generates a unique ID based on the microtime (current time in microseconds).
//	 * @return 4415297e3af8c
//	 */
//	String uniqid() {
//		// TODO
//		return "";
//	}
//	/**
//	* Get the flash object ID for the last rendered object.
//	*/
//	public String get_unique_id()
//	{
//		return (this.unique_id);
//	}
	
	String js_path;
	/**
	* Set the base path for the swfobject.js
	*
	* @param base_path a string argument.
	*   The path to the swfobject.js file
	*/
	public void set_js_path(String path)
	{
		this.js_path = path;
	}
	
	String swf_path;
	/**
	* Set the base path for the open-flash-chart.swf
	*
	* @param path a string argument.
	*   The path to the open-flash-chart.swf file
	*/
	public void set_swf_path(String path)
	{
		this.swf_path = path;
	}

	String output_type;
	/**
	* Set the type of output data.
	*
	* @param type a string argument.
	*   The type of data.  Currently only type is js, or nothing.
	*/
	public void set_output_type(String type)
	{
		this.output_type = type;
	}
	
	// is this needed now?
	public void increment_occurence()
	{
		this.occurence++;
	}

	/**
	* returns the next line label for multiple lines.
	*/
	public String next_line()
	{
		String line_num = "";
		if( this.lines.size()  > 0 )
			line_num = "_"+(this.lines.size()+1);

		return line_num;
	}
	
	// escape commas (,)
	public String esc( String text )
	{
		// we replace the comma so it is not URL escaped
		// if it is, flash just thinks it is a comma
		// which is no good if we are splitting the
		// string on commas.
		String tmp = text.replace( ",", "#comma#");
		// now we urlescape all dodgy characters (like & % $ etc..)
		try {
			return URLEncoder.encode( tmp, "UTF-8" );
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			return text;
		}
	}

	/**
	* Format the text to the type of output.
	*/
	public String format_output(String output_type,String function, int value) {
		return format_output(output_type, function, Integer.toString(value));
	}
	public String format_output(String output_type,String function, String values)
	{
		String tmp = null;
		if(output_type.equals("js"))
		{
			tmp = "so.addVariable(\""+function+"\",\""+values+"\");";
		}
		else
		{
			tmp = "&"+function+"="+values+"&";
		}

		return tmp;
	}

	/**
	* Set the text and style of the title.
	*
	* @param title a string argument.
	*   The text of the title.
	* @param style a string.
	*   CSS styling of the title.
	*/
	public void set_title( String title) {
		set_title(title, "");
	}
	public void set_title( String title, String style )
	{
		this.title = title;
		if( style.length() > 0 )
			this.title_style = style;
	}

	/**
	 * Set the width of the chart.
	 *
	 * @param width an int argument.
	 *   The width of the chart frame.
	 */
	public void set_width( int width )
	{
		this.width = width;
	}
	
	/**
	 * Set the height of the chart.
	 *
	 * @param height an int argument.
	 *   The height of the chart frame.
	 */
	public void set_height( int height )
	{
		this.height = height;
	}

	/**
	 * Set the base path of the swfobject.
	 *
	 * @param base a string argument.
	 *   The base path of the swfobject.
	 */
	public void set_base( String base/*='js/'*/ )
	{
		this.base = base;
	}
	
	// Number formatting:
	public void set_y_format( String val )
	{
		this.y_format = val;	
	}
	
	public void set_num_decimals( int val )
	{
		this.num_decimals = Integer.toString(val);
	}
	
	public void set_is_fixed_num_decimals_forced( boolean val )
	{
		this.is_fixed_num_decimals_forced = val?"true":"false";
	}
	
	public void set_is_decimal_separator_comma( boolean val )
	{
		this.is_decimal_separator_comma = val?"true":"false";
	}
	
	public void set_is_thousand_separator_disabled( boolean val )
	{
		this.is_thousand_separator_disabled = val?"true":"false";
	}

	/**
	 * Set the data for the chart
	 * @param a an array argument.
	 *   An array of the data to add to the chart.
	 */
	public void set_data( List<String> a )
	{
		this.data.add(implode(",", a));
	}
	
	// UGH, these evil public voids are making me fell ill
	public void set_links( List<String> a )
	{
		this.links.add(implode(",", a));
	}
	
	// $val is a boolean
	public void set_x_offset( boolean val )
	{
		this.x_offset = val?"true":"false";
	}

	/**
	 * Set the tooltip to be displayed on each chart item.\n
	 * \n
	 * Replaceable tokens that can be used in the string include: \n
	 * #val# - The actual value of whatever the mouse is over. \n
	 * #key# - The key string. \n
	 * \<br>  - New line. \n
	 * #x_label# - The X label string. \n
	 * #x_legend# - The X axis legend text. \n
	 * Default string is: "#x_label#<br>#val#" \n
	 * 
	 * @param tip a string argument.
	 *   A formatted string to show as the tooltip.
	 */
	public void set_tool_tip( String tip )
	{
		this.tool_tip = this.esc( tip );
	}

	/**
	 * Set the x axis labels
	 *
	 * @param a an array argument.
	 *   An array of the x axis labels.
	 */
	public void set_x_labels( List<String> a )
	{
		this.x_labels = a;
	}

	/**
	 * Set the look and feel of the x axis labels
	 *
	 * @param font_size an int argument.
	 *   The font size.
	 * @param colour a string argument.
	 *   The hex colour value.
	 * @param orientation an int argument.
	 *   The orientation of the x-axis text.
	 *   0 - Horizontal
	 *   1 - Vertical
	 *   2 - 45 degrees
	 * @param step an int argument.
	 *   Show the label on every $step label.
	 * @param grid_colour a string argument.
	 */
	public void set_x_label_style( String size )
	{
		set_x_label_style( size, "", 0, -1, "" );
	}
	public void set_x_label_style( String size, String colour, int orientation, int step, String grid_colour )
	{
		this.x_label_style = size;
		
		if( colour.length() > 0 )
			this.x_label_style += ","+colour;

		if( orientation > -1 )
			this.x_label_style += ","+orientation;

		if( step > 0 )
			this.x_label_style += ","+step;

		if( grid_colour.length() > 0 )
			this.x_label_style += ","+grid_colour;
	}

	/**
	 * Set the background colour.
	 * @param colour a string argument.
	 *   The hex colour value.
	 */
	public void set_bg_colour( String colour )
	{
		this.bg_colour = colour;
	}

	String bg_image_x;
	String bg_image_y;
	/**
	 * Set a background image.
	 * @param url a string argument.
	 *   The location of the image.
	 * @param x a string argument.
	 *   The x location of the image. 'Right', 'Left', 'Center'
	 * @param y a string argument.
	 *   The y location of the image. 'Top', 'Bottom', 'Middle'
	 */
	public void set_bg_image( String url ) {
		set_bg_image( url, "center", "center" );
	}
	public void set_bg_image( String url, String x, String y )
	{
		this.bg_image = url;
		this.bg_image_x = x;
		this.bg_image_y = y;
	}

	/**
	 * Attach a set of data (a line, area or bar chart) to the right Y axis.
	 * @param data_number an int argument.
	 *   The numbered order the data was attached using set_data.
	 */
	public void attach_to_y_right_axis( List<String> data_number )
	{
		this.y2_lines = data_number;
	}

	/**
 	 * Set the background colour of the grid portion of the chart.
	 * @param col a string argument.
	 *   The hex colour value of the background.
	 * @param col2 a string argument.
	 *   The hex colour value of the second colour if you want a gradient.
	 * @param angle an int argument.
	 *   The angle in degrees to make the gradient.
	 */
	public void set_inner_background( String col) {
		set_inner_background( col, "", -1 );
	}
	public void set_inner_background( String col, String col2, int angle )
	{
		this.inner_bg_colour = col;
		
		if( col2.length() > 0 )
			this.inner_bg_colour_2 = col2;
		
		if( angle != -1 )
			this.inner_bg_angle = Integer.toString(angle);
	}

	/**
	 * Internal public void to build the y label style for y and y2
	 */
	public String _set_y_label_style( String size, String colour )
	{
		String tmp = size;
		
		if( colour.length() > 0 )
			tmp += ","+colour;
		return tmp;
	}

	/**
	 * Set the look and feel of the y axis labels
	 *
	 * @param font_size an int argument.
	 *   The font size.
	 * @param colour a string argument.
	 *   The hex colour value.
	 */
	public void set_y_label_style( String size ) {
		set_y_label_style( size, "" );
	}

	public void set_y_label_style( String size, String colour )
	{
		this.y_label_style = this._set_y_label_style( size, colour );
	}

	/**
	 * Set the look and feel of the right y axis labels
	 *
	 * @param font_size an int argument.
	 *   The font size.
	 * @param colour a string argument.
	 *   The hex colour value.
	 */
	public void set_y_right_label_style( String size ) {
		set_y_right_label_style( size, "" );
	}

	public void set_y_right_label_style( String size, String colour )
	{
		this.y_label_style_right = this._set_y_label_style( size, colour );
	}

	public void set_x_max( int max )
	{
		this.x_max = Integer.toString( max );
	}

	public void set_x_min( int min )
	{
		this.x_min = Integer.toString( min );
	}

	/**
	 * Set the maximum value of the y axis.
	 *
	 * @param max an int argument.
	 *   The maximum value.
	 */
	public void set_y_max( int max )
	{
		this.y_max = Integer.toString( max );
	}

	/**
	 * Set the minimum value of the y axis.
	 *
	 * @param min an int argument.
	 *   The minimum value.
	 */
	public void set_y_min( int min )
	{
		this.y_min = Integer.toString(min);
	}

	/**
	 * Set the maximum value of the right y axis.
	 *
	 * @param max an int argument.
	 *   The maximum value.
	 */  
	public void set_y_right_max( int max )
	{
		this.y2_max = Integer.toString(max);
	}

	/**
	 * Set the minimum value of the right y axis.
	 *
	 * @param min an int argument.
	 *   The minimum value.
	 */
	public void set_y_right_min( int min )
	{
		this.y2_min = Integer.toString(min);
	}

	/**
	 * Show the y label on every $step label.
	 *
	 * @param val an int argument.
	 *   Show the label on every $step label.
	 */
	public void y_label_steps( int val )
	{
		 this.y_steps = Integer.toString( val );
	}
	
	public void title( String title) {
		title(title, "");
	}
	public void title( String title, String style )
	{
		 this.title = this.esc( title );
		 if( style.length() > 0 )
				 this.title_style = style;
	}

	/**
	 * Set the parameters of the x legend.
	 *
	 * @param text a string argument.
	 *   The text of the x legend.
	 * @param font_size an int argument.
	 *   The font size of the x legend text.
	 * @param colour a string argument
	 *   The hex value of the font colour. 
	 */
	public void set_x_legend( String text ) {
		set_x_legend( text, -1, "" );
	}
	public void set_x_legend( String text, int size, String colour )
	{
		this.x_legend = this.esc( text );
		if( size > -1 )
			this.x_legend_size = size;
		
		if( colour.length() >0 )
			this.x_legend_colour = colour;
	}

	/**
	 * Set the size of the x label ticks.
	 *
	 * @param size an int argument.
	 *   The size of the ticks in pixels.
	 */
	public void set_x_tick_size( int size )
	{
		if( size > 0 )
				this.x_tick_size = size;
	}

	/**
	 * Set how often you would like to show a tick on the x axis.
	 *
	 * @param steps an int argument.
	 *   Show a tick ever $steps.
	 */
	public void set_x_axis_steps( int steps )
	{
		if ( steps > 0 )
			this.x_axis_steps = steps;
	}

	/**
	 * Set the depth in pixels of the 3D X axis slab.
	 *
	 * @param size an int argument.
	 *   The depth in pixels of the 3D X axis.
	 */
	public void set_x_axis_3d( int size )
	{
		if( size > 0 )
			this.x_axis_3d = Integer.toString(size);
	}
	
	/**
	 * The private method of building the y legend output.
	 */
	public String _set_y_legend( String text, int size, String colour )
	{
		String tmp = text;
	
		if( size > -1 )
			tmp += ","+size;

		if( colour.length()	>0 )
			tmp += ","+colour;

		return tmp;
	}

	/**
	 * Set the parameters of the y legend.
	 *
	 * @param text a string argument.
	 *   The text of the y legend.
	 * @param font_size an int argument.
	 *   The font size of the y legend text.
	 * @param colour a string argument
	 *   The hex colour value of the font colour. 
	 */
	public void set_y_legend( String text ) {
		set_y_legend( text, -1, "" );
	}
	public void set_y_legend( String text, int size, String colour)
	{
		this.y_legend = this._set_y_legend( text, size, colour );
	}

	/**
	 * Set the parameters of the right y legend.
	 *
	 * @param text a string argument.
	 *   The text of the right y legend.
	 * @param font_size an int argument.
	 *   The font size of the right y legend text.
	 * @param colour a string argument
	 *   The hex value of the font colour. 
	 */
	public void set_y_right_legend( String text) {
		set_y_right_legend( text, -1, "");
	}
	public void set_y_right_legend( String text, int size, String colour )
	{
		this.y_legend_right = this._set_y_legend( text, size, colour );
	}
	
	/**
	 * Set the colour of the x axis line and grid.
	 *
	 * @param axis a string argument.
	 *   The hex colour value of the x axis line.
	 * @param grid a string argument.
	 *   The hex colour value of the x axis grid. 
	 */
	public void x_axis_colour( String axis ) {
		x_axis_colour( axis, "" );
	}
	public void x_axis_colour( String axis, String grid )
	{
		this.x_axis_colour = axis;
		this.x_grid_colour = grid;
	}

	/**
	 * Set the colour of the y axis line and grid.
	 *
	 * @param axis a string argument.
	 *   The hex colour value of the y axis line.
	 * @param grid a string argument.
	 *   The hex colour value of the y axis grid. 
	 */
	public void y_axis_colour( String axis ) {
		y_axis_colour( axis, "" );
	}
	public void y_axis_colour( String axis, String grid )
	{
		this.y_axis_colour = axis;

		if( grid.length() > 0 )
			this.y_grid_colour = grid;
	}

	/**
	 * Set the colour of the right y axis line.
	 *
	 * @param colour a string argument.
	 *   The hex colour value of the right y axis line.
	 */
	public void y_right_axis_colour( String colour )
	{
		 this.y2_axis_colour = colour;
	}

	/**
	 * Draw a line without markers on values.
	 *
	 * @param width an int argument.
	 *   The width of the line in pixels.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label
	 * @param circles an int argument
	 *   Need to find out.
	 */
	public void line( int width ) {
		line( width, "", "", -1, -1 );
	}
	public void line( int width, String colour, String text, int size, int circles )
	{
		String type = "line"+this.next_line();
		String description = "";

		if( width > 0 )
		{
			description += width;
			description += ","+colour;
		}

		if( text.length() > 0 )
		{
			description += ","+text;
			description += ","+size;
		}

		if( circles > 0 ) 
			description += ","+circles;

		this.lines.add(new Line(type, description));
	}

	/**
	 * Draw a line with solid dot markers on values.
	 *
	 * @param width an int argument.
	 *   The width of the line in pixels.
	 * @param dot_size an int argument.
	 *   Size in pixels of the dot.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label.
	 */
	public void line_dot( String width, String dot_size, String colour ) {
		line_dot( width, dot_size, colour, "", "" );
	}

	public void line_dot( String width, String dot_size, String colour, String text, String font_size )
	{
		String type = "line_dot"+this.next_line();

		String description = width+colour+text;

		if( font_size.length() > 0 )
			description += ","+font_size+dot_size;

		this.lines.add(new Line(type, description));
	}

	/**
	 * Draw a line with hollow dot markers on values.
	 *
	 * @param width an int argument.
	 *   The width of the line in pixels.
	 * @param dot_size an int argument.
	 *   Size in pixels of the dot.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label.
	 */
	public void line_hollow( String width, String dot_size, String colour) {
		line_hollow( width, dot_size, colour, "", "");
	}
	public void line_hollow( String width, String dot_size, String colour, String text, String font_size )
	{
		String type = "line_hollow"+this.next_line();

		String description = width+","+colour+","+text;

		if( font_size.length() > 0 )
			description += ","+font_size+","+dot_size;

		this.lines.add(new Line(type, description));
	}

	/**
	 * Draw an area chart.
	 *
	 * @param width an int argument.
	 *   The width of the line in pixels.
	 * @param dot_size an int argument.
	 *   Size in pixels of the dot.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param alpha an int argument.
	 *   The percentage of transparency of the fill colour.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label.
	 * @param fill_colour a string argument.
	 *   The hex colour value of the fill colour.
	 */
	public void area_hollow( String width, String dot_size, String colour, String alpha) {
		area_hollow( width, dot_size, colour, alpha, "", "", "" );
	}
	public void area_hollow( String width, String dot_size, String colour, String alpha, String text,
			String font_size, String fill_colour )
	{
		String type = "area_hollow"+this.next_line();

		String description = width+","+dot_size+","+colour+","+alpha;

		if( text.length() > 0 )
			description += ","+text+","+font_size;
	
		if( fill_colour.length() > 0 )
			description += ","+fill_colour;

		this.lines.add(new Line(type, description));
	}

	/**
	 * Draw a bar chart.
	 *
	 * @param alpha an int argument.
	 *   The percentage of transparency of the bar colour.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label.
	 */
	public void bar( String alpha ) {
		bar( alpha, "", "", -1 );
	}
	public void bar( String alpha, String colour, String text, int size )
	{
		String type = "bar"+this.next_line();

		String description = alpha +","+ colour +","+ text +","+ size;

		this.lines.add(new Line(type, description));
	}

	/**
	 * Draw a bar chart with an outline.
	 *
	 * @param alpha an int argument.
	 *   The percentage of transparency of the bar colour.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param colour_outline a strng argument.
	 *   The hex colour value of the outline.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label.
	 */
	public void bar_filled( String alpha, String colour, String colour_outline ) {
		bar_filled( alpha, colour, colour_outline, "", -1 );
	}
	public void bar_filled( String alpha, String colour, String colour_outline, String text, int size)
	{
		String type = "filled_bar"+this.next_line();

		String description = alpha+","+colour+","+colour_outline+","+text+","+size;

		this.lines.add(new Line(type, description));
	}

	public void bar_sketch( String alpha, String offset, String colour, String colour_outline ) {
		bar_sketch( alpha, offset, colour, colour_outline, "", -1 );
	}
	public void bar_sketch( String alpha, String offset, String colour, String colour_outline, String text, int size )
	{
		String type = "bar_sketch"+this.next_line();

		String description = alpha+","+offset+","+colour+","+colour_outline+","+text+","+size;

		this.lines.add(new Line(type, description));
	}

	/**
	 * Draw a 3D bar chart.
	 *
	 * @param alpha an int argument.
	 *   The percentage of transparency of the bar colour.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label.
	 */
	public void bar_3D( String alpha ) {
		bar_3D( alpha, "", "", -1 );
	}
	public void bar_3D( String alpha, String colour, String text, int size )
	{
		String type = "bar_3d"+this.next_line();

		String description = alpha +","+ colour +","+ text +","+ size;

		this.lines.add(new Line(type, description));
	}

	/**
	 * Draw a 3D bar chart that looks like glass.
	 *
	 * @param alpha an int argument.
	 *   The percentage of transparency of the bar colour.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param outline_colour a string argument.
	 *   The hex colour value of the outline.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label.
	 */
	public void bar_glass( String alpha, String colour, String outline_colour ) {
		bar_glass( alpha, colour, outline_colour, "", -1 );
	}
	public void bar_glass( String alpha, String colour, String outline_colour, String text, int size )
	{
		String type = "bar_glass"+this.next_line();

		String description = alpha +","+ colour +","+ outline_colour +","+ text +","+ size;

		this.lines.add(new Line(type, description));
	}

	/**
	 * Draw a faded bar chart.
	 *
	 * @param alpha an int argument.
	 *   The percentage of transparency of the bar colour.
	 * @param colour a string argument.
	 *   The hex colour value of the line.
	 * @param text a string argument.
	 *   The label of the line.
	 * @param font_size an int argument.
	 *   Font size of the label.
	 */
	public void bar_fade( String alpha ) {
		bar_fade( alpha, "", "", -1 );
	}
	public void bar_fade( String alpha, String colour, String text, int size )
	{
		String type = "bar_fade"+this.next_line();

		String description = alpha +","+colour +","+ text +","+ size;

		this.lines.add(new Line(type, description));
	}
	
	public void candle( List<bar> data, String alpha, String line_width, String colour ) {
		candle( data, alpha, line_width, colour, "", -1 );
	}
	public void candle( List<bar> data, String alpha, String line_width, String colour, String text, int size )
	{
		String type = "candle"+this.next_line();

		String description = alpha +","+ line_width +","+ colour +","+ text +","+ size;

		this.lines.add(new Line(type, description));
		
		List<String> a = new ArrayList<String>();
		for (bar b : data) {
			a.add(b.toString("", ""));
		}	
		this.data.add(implode(",",a));
	}
	
	public void hlc( List<hlc> data, String alpha, String line_width, String colour ) {
		hlc( data, alpha, line_width, colour, "", -1 );
	}
	public void hlc( List<hlc> data, String alpha, String line_width, String colour, String text, int size )
	{
		String type = "hlc"+this.next_line();

		String description = alpha +","+ line_width +","+ colour +","+ text +","+ size;

		this.lines.add(new Line(type, description));

		List<String> a = new ArrayList<String>();
		for (hlc anHlc : data) {
			a.add(anHlc.toString(null, null));
		}	
		this.data.add(implode(",",a));
	}

	public void scatter( List<point> data, String line_width, String colour ) {
		scatter( data, line_width, colour, "", -1 );
	}
	public void scatter( List<point> data, String line_width, String colour, String text, int size )
	{
		String type = "scatter"+this.next_line();

		String description = line_width +","+ colour +","+ text +","+ size;

		this.lines.add(new Line(type, description));

		List<String> a = new ArrayList<String>();
		for (point p : data) {
			a.add(p.toString("", ""));
		}	
		this.data.add(implode(",",a));
	}


	//
	// Patch by, Jeremy Miller (14th Nov, 2007)
	//
	/**
	 * Draw a pie chart.
	 *
	 * @param alpha an int argument.
	 *   The percentage of transparency of the pie colour.
	 * @param line_colour a string argument.
	 *   The hex colour value of the outline.
	 * @param label_colour a string argument.
	 *   The hex colour value of the label.
	 * @param gradient a boolean argument.
	 *   Use a gradient true or false.
	 * @param border_size an int argument.
	 *   Size of the border in pixels.
	 */
	public void pie( int alpha, String line_colour, String label_colour ) {
		pie( alpha, line_colour, label_colour, true, false );
	}
	public void pie( int alpha, String line_colour, String label_colour, boolean gradient, boolean border_size )
	{
		this.pie = ""+alpha+","+line_colour+","+label_colour;
		if( !gradient )
		{
			this.pie += ","+!gradient;
		}
		if (border_size)
		{
			if (!gradient )
			{
				this.pie += ",";
			}
			this.pie += ","+border_size;
		}
	}

	/**
	 * Set the values of the pie chart.
	 *
	 * @param values an array argument.
	 *   An array of the values for the pie chart.
	 * @param labels an array argument.
	 *   An array of the labels for the pie pieces.
	 * @param links an array argument.
	 *   An array of the links to the pie pieces.
	 */
	public void pie_values( List<String> values ) {
		pie_values( values, null, null );
	}
	public void pie_values( List<String> values, List<String> labels, List<String> links )
	{
		this.pie_values = implode(",",values);
		this.pie_labels = implode(",",labels);
		this.pie_links  = implode(",",links);
	}

	/**
	 * Set the pie slice colours.
	 *
	 * @param colours an array argument.
	 *   The hex colour values of the pie pieces.
	 */
	public void pie_slice_colours( List<String> colours )
	{
		this.pie_colours = implode(",", colours);
	}
	

	/**
	 * Render the output.
	 */
	public String render() {
		return render("");
	}
	public String render(String output_type)
	{
		List<String> tmp = new ArrayList<String>();

		if(output_type.equals("js"))
		{
			this.increment_occurence();
		
			tmp.add("<div id=\"my_chart"+this.occurence+"\"></div>");
			tmp.add("<script type=\"text/javascript\" src=\""+this.base+"swfobject.js\"></script>");
			tmp.add("<script type=\"text/javascript\">");
			tmp.add("var so = new SWFObject(\"open-flash-chart.swf\", \"ofc\", \""+this.width+"\", \""+
					this.height+"\", \"9\", \"#FFFFFF\");");
			tmp.add("so.addVariable(\"variables\",\"true\");");
		}

		if( this.title.length() > 0 )
		{
			StringBuffer values = new StringBuffer(this.title);
			values.append(',').append(this.title_style);
			tmp.add(this.format_output(output_type, "title", values.toString()));
		}

		if( this.x_legend.length() > 0 )
		{
			StringBuffer values = new StringBuffer(this.x_legend);
			values.append(',').append(this.x_legend_size);
			values.append(',').append(this.x_legend_colour);
			tmp.add(this.format_output(output_type, "x_legend", values.toString()));
		}
	
		if( this.x_label_style.length() > 0 )
			tmp.add( this.format_output(output_type, "x_label_style", this.x_label_style));
	
		if( this.x_tick_size > 0 )
			tmp.add(this.format_output(output_type, "x_ticks", this.x_tick_size));

		if( this.x_axis_steps > 0 )
			tmp.add(this.format_output(output_type, "x_axis_steps", this.x_axis_steps));

		if( this.x_axis_3d.length() > 0 )
			tmp.add(this.format_output(output_type, "x_axis_3d", this.x_axis_3d));
		
		if( this.y_legend.length() > 0 )
			tmp.add(this.format_output(output_type,"y_legend", this.y_legend));
		
		if( this.y_legend_right.length() > 0 )
			tmp.add(this.format_output(output_type, "y2_legend", this.y_legend_right));

		if( this.y_label_style.length() > 0 )
			tmp.add(this.format_output(output_type, "y_label_style", this.y_label_style));

		tmp.add(this.format_output(output_type, "y_ticks", "5,10,"+this.y_steps));

		if( this.lines.size() == 0 )
		{
			tmp.add(this.format_output(output_type, 
					// this.line_default['type'] = 'line';
					// this.line_default['values'] = '3,#87421F';
					// this.js_line_default = 'so.addVariable("line","3,#87421F");';
					"line", //this.line_default["type"],
					"3,#87421F" //this.line_default["values"]
					));	
		}
		else
		{
			for( Line line: this.lines) {
				tmp.add(this.format_output(output_type, line.type, line.description));	
			}
		}
	
		int num = 1;
		for( String data : this.data )
		{
			if( num==1 )
			{
				tmp.add(this.format_output(output_type, "values", data));
			}
			else
			{
				tmp.add(this.format_output(output_type, "values_"+num, data));
			}
		
			num++;
		}
		
		num = 1;
		for (String link : this.links)
		{
			if( num==1 )
			{
				tmp.add(this.format_output(output_type, "links", link));
			}
			else
			{
				tmp.add(this.format_output( output_type, "links_"+num, link));
			}
		
			num++;
		}

		if( this.y2_lines.size() > 0 )
		{
			tmp.add(this.format_output(output_type, "y2_lines", implode( ",", this.y2_lines )));
			//
			// Should this be an option? I think so...
			//
			tmp.add(this.format_output(output_type, "show_y2", "true"));
		}

		if( this.x_labels.size() > 0 )
			tmp.add(this.format_output(output_type, "x_labels", implode(",", this.x_labels)));
		else
		{
			if( this.x_min.length() > 0 )
				tmp.add(this.format_output(output_type, "x_min", this.x_min));
				
			if( this.x_max.length() > 0 )
				tmp.add(this.format_output(output_type, "x_max", this.x_max));			
		}
		
		tmp.add(this.format_output(output_type, "y_min", this.y_min));
		tmp.add(this.format_output(output_type, "y_max", this.y_max));

		if( this.y2_min.length() > 0 )
			tmp.add(this.format_output(output_type, "y2_min", this.y2_min));
			
		if( this.y2_max.length() > 0 )
			tmp.add(this.format_output(output_type, "y2_max", this.y2_max));
		
		if( this.bg_colour.length() > 0 )
			tmp.add(this.format_output(output_type, "bg_colour", this.bg_colour));

		if( this.bg_image.length() > 0 )
		{
			tmp.add(this.format_output(output_type, "bg_image", this.bg_image));
			tmp.add(this.format_output(output_type, "bg_image_x", this.bg_image_x));
			tmp.add(this.format_output(output_type, "bg_image_y", this.bg_image_y));
		}

		if( this.x_axis_colour.length() > 0 )
		{
			tmp.add(this.format_output(output_type, "x_axis_colour", this.x_axis_colour));
			tmp.add(this.format_output(output_type, "x_grid_colour", this.x_grid_colour));
		}

		if( this.y_axis_colour.length() > 0 )
			tmp.add(this.format_output(output_type, "y_axis_colour", this.y_axis_colour));

		if( this.y_grid_colour.length() > 0 )
			tmp.add(this.format_output(output_type, "y_grid_colour", this.y_grid_colour));
  
		if( this.y2_axis_colour.length() > 0 )
			tmp.add(this.format_output(output_type, "y2_axis_colour", this.y2_axis_colour));
		
		if( this.x_offset.length() > 0 )
			tmp.add(this.format_output(output_type, "x_offset", this.x_offset));

		if( this.inner_bg_colour.length() > 0 )
		{
			StringBuilder values = new StringBuilder(this.inner_bg_colour);
			if( this.inner_bg_colour_2.length() > 0 )
			{
				values.append(',').append(this.inner_bg_colour_2);
				values.append(',').append(this.inner_bg_angle);
			}
			tmp.add(this.format_output(output_type, "inner_background", values.toString()));
		}
	
		if( this.pie.length() > 0 )
		{
			tmp.add(this.format_output(output_type,"pie", this.pie));
			tmp.add(this.format_output(output_type,"values", this.pie_values));
			tmp.add(this.format_output(output_type,"pie_labels", this.pie_labels));
			tmp.add(this.format_output(output_type,"colours", this.pie_colours));
			tmp.add(this.format_output(output_type,"links", this.pie_links));
		}

		if( this.tool_tip.length() > 0 )
			tmp.add(this.format_output(output_type, "tool_tip", this.tool_tip));
		
		if( this.y_format.length() > 0 )
			tmp.add(this.format_output(output_type, "y_format", this.y_format));
			
		if( this.num_decimals.length() > 0 )
			tmp.add(this.format_output(output_type, "num_decimals", this.num_decimals));
			
		if( this.is_fixed_num_decimals_forced.length() > 0 )
			tmp.add(this.format_output(output_type, "is_fixed_num_decimals_forced", 
					this.is_fixed_num_decimals_forced));
			
		if( this.is_decimal_separator_comma.length() > 0 )
			tmp.add(this.format_output(output_type, "is_decimal_separator_comma", this.is_decimal_separator_comma));
			
		if( this.is_thousand_separator_disabled.length() > 0 )
			tmp.add(this.format_output(output_type, "is_thousand_separator_disabled", this.is_thousand_separator_disabled));
			

		if(output_type.equals("js"))
		{
			tmp.add("so.write(\"my_chart"+this.occurence+"\");");
			tmp.add("</script>");
		}


		int count = 1;
		for( data_set set : this.data_sets )
		{
			tmp.add(set.toString( output_type, (count>1)?("_"+count):"" ));
			count++;
		}
		
		return implode("\r\n", tmp);
	}

	String implode(String glue, List<String> array) {
		StringBuilder sb = new StringBuilder();
		for (String element : array) {
			if (sb.length()>0) sb.append(glue);
			sb.append(element);
		}
		return sb.toString();
	}

	abstract class data_set {
		abstract String toString(String outputType, String number);
	}
	class bar extends data_set
	{
		String colour;
		String alpha;
		List<String> data;
		List<String> links;
		boolean _key;
		String key;
		int key_size;
		String var;
		
		public bar( String alpha, String colour )
		{
			this.var = "bar";
			
			this.alpha = alpha;
			this.colour = colour;
			this.data = new ArrayList<String>();
			this.links = new ArrayList<String>();
			this._key = false;
		}
	
		public void key( String key, int size )
		{
			this._key = true;
			this.key = key;
			this.key_size = size;
		}
		
		public void add( String data, String link )
		{
			this.data.add(data);
			this.links.add(link);
		}
		
		public String toString( String output_type, String set_num )
		{
			String values = this.alpha +","+ this.colour;
			
			if( this._key )
			{
				values += ","+this.key +","+ this.key_size;
			}
			String tmp = null;
			if( output_type.equals("js") )
			{
				tmp = "so.addVariable(\""+this.var+"\",\""+values+"\");";
			}
			else
			{
				tmp  = "&"+this.var+set_num+"="+values+"&";
				tmp += "\r\n";
				tmp += "&values"+set_num+"="+implode( ",", this.data )+"&";
				if( this.links.size() > 0 )
				{
					tmp += "\r\n";
					tmp += "&links"+set_num+"="+implode( ",", this.links )+"&";	
				}
			}
	
			return tmp;
		}
		
	}
	
	class candle extends data_set
	{
		final int high;
		final int low; 
		final int close;
		final int open;
		
		public candle( int high, int open, int close, int low )
		{
			this.high = high;
			this.low = low;
			this.close = close;
			this.open = open;
		}
		
		public String toString(String arg0, String arg1)
		{
			return "["+high+","+open+","+low+","+close+"]";
		}
	}
	
	class hlc extends data_set
	{
		final int high;
		final int low; 
		final int close;	
		public hlc( int high, int low, int close )
		{
			this.high = high;
			this.low = low;
			this.close = close;
		}
		
		public String toString(String arg0, String arg1)
		{
			return "["+high+","+low+","+close+"]";
		}
	}
	
	class point extends data_set
	{
		final int x;
		final int y; 
		final int size_px;
		
		public point( int x, int y, int size_px )
		{
			this.x = x;
			this.y = y;
			this.size_px = size_px;
		}
		
		public String toString(String arg0, String arg1)
		{
			return "["+x+","+y+","+size_px+"]";
		}
	}
	class Line {
		String type;
		String description;
		public Line(String t, String d) {
			type = t;
			description = d;
		}
	}
}