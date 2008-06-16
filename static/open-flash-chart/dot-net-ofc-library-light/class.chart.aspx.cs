using System;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
public  partial class graph : System.Web.UI.Page{

  
   	public ArrayList data=new ArrayList();
   	public ArrayList x_labels=new ArrayList();
   	public int y_min=0;
   	public int y_max=20;
   	public int y_steps=5;
   	public string title="";
   	public string title_style="";
   	public int x_tick_size=-1;
   	
   	// GRID styles:
   	public string x_axis_colour = "";
    public string x_grid_colour = "";
    public string y_axis_colour = "";
    public string y_grid_colour = "";
    public int x_axis_steps = 1;
   
     // AXIS LABEL styles:         
    public  string x_label_style = "";
    public  string y_label_style = "";
	
     
     // AXIS LEGEND styles:
    public  string x_legend = "";
    public  int x_legend_size = 20;
    public  string x_legend_colour = "#000000";

    public  string y_legend = "";
    public  int y_legend_size = 20;
    public  string y_legend_colour = "#000000";
     
    public  ArrayList lines = new ArrayList();
    public  string line_default = "&line=3,#87421F&"+ "\r\n";
     
    public  string bg_colour = "";
    public  string bg_image = "";
	public  string bg_image_x = "";
	public  string bg_image_y = "";

    public  string inner_bg_colour = "";
    public  string inner_bg_colour_2 = "";
    public  string inner_bg_angle = "";
     
     
     // PIE chart ------------
    public  string pie = "";
    public  string pie_values = "";
    public  string pie_colours = "";
    public  string pie_labels = "";

    public  string tool_tip = "";
   	
       

   public void  set_data(ArrayList a )
    {
   	if(data.Count==0){
   		
		string s="";
		for(int j=0;j<a.Count;j++)
			
			if(j!=0){
				s=s+","+a[j];
			}else{
				s=a[j].ToString();
			}
   		data.Add("&values="+s+"&"+"\r\n");
   	}else{
   		string s="";
		for(int j=0;j<a.Count;j++)
			
			if(j!=0){
				s=s+","+a[j];
			}else{
				s=a[j].ToString();
			}
   		data.Add("&values_"+(a.Count+1)+"="+s+"&"+"\r\n");
   	}
   }

   public void set_tool_tip(string tip )
    {
        tool_tip = tip;
    }
    
    public void set_x_labels(ArrayList a )
    {
        x_labels = a;
    }
    
    public void set_x_label_style(int size, string colour,int orientation,int step, string grid_colour)
    {
        
        x_label_style = "&x_label_style="+ size;
        
        if( colour.Length > 0 )
            x_label_style+= ","+colour;

        if( orientation > -1 )
            x_label_style += ","+orientation;

        if( step > 0 )
            x_label_style += ","+ step;
        
        if( grid_colour.Length > 0 )
            x_label_style+= ","+ grid_colour;
            
        x_label_style += "&\r\n";
    }

    public void set_bg_colour( string colour )
    {
        bg_colour = colour;
    }

   public void set_bg_image( string url, string x, string y)
    {
        bg_image = url;
        bg_image_x = x;
        bg_image_y = y;
    }


    public void set_inner_background(string col, string col2, int angle )
    {

         inner_bg_colour = col;


         if( col2.Length > 0 )
             inner_bg_colour_2 = col2;

         if( angle != -1 )
             inner_bg_angle = angle.ToString();

    }

     public void set_y_label_style( int size, string colour )
    {
        y_label_style = "&y_label_style="+ size;


        if( colour.Length > 0 )
                y_label_style += ","+ colour;

        y_label_style += "&\r\n";

    }
    
    public void  set_y_max(int max)
    {

        y_max =  max ;
    }

    public void   set_y_min(int min )
    {

        y_min = min;
    }
    
    public void y_label_steps( int val )
    {
         y_steps = val ;
    }
    
    public void ftitle(string ctitle, string style)
    {
        title = ctitle;
        if( style.Length > 0 ){
                title_style = style;
		}
    }

   
    public void set_x_legend( string text, int size, string colour)
		
    {
         x_legend = text;
         if( size > -1 )
                x_legend_size = size;
                
         if( colour.Length>0 )
                x_legend_colour = colour;
    }
    
    public void  set_x_tick_size( int size )
    {
        if( size > 0 )
                x_tick_size = size;
    }

    public void  set_x_axis_steps( int steps )
    {
        if ( steps > 0 )
           x_axis_steps = steps;
    }

    
    public void set_y_legend( string text, int size, string colour)
    {
         y_legend = text;
         if( size > -1 )
                y_legend_size = size;

         if( colour.Length>0 )
                y_legend_colour = colour;
    }
    
     public void line( int width,string colour, string text, int size, int circles)
    {
    	string tmp = "&line";
    	
    	if( lines.Count > 0 )
        	tmp+= "_"+ (lines.Count+1);
        	
    	tmp+= "=";
    	
        if( width > 0 )
        {
                tmp+= width;
                tmp+= ","+colour;
        }
                
        if( text.Length > 0 )
        {
                tmp+= ","+ text;
                tmp+= ","+ size;
        }
        
        if( circles > 0 )
                tmp+= ","+ circles;
        
        tmp+= "&\r\n";;
        
        lines.Add(tmp);
    }
	 

    public void line_dot(int width,int dot_size, string colour, string text, string font_size )
    {
    	string tmp = "&line_dot";
    	
    	if( lines.Count > 0 )
        	tmp+= "_"+ (lines.Count+1);
        	
    	tmp+= "="+width+","+colour+","+text;

        if( font_size.Length > 0 )
            tmp+= ","+font_size+","+dot_size;
        
        tmp+= "&\r\n";
        lines.Add(tmp);
    }

    public void line_hollow( int width, int dot_size, string colour, string text, string font_size )
    {
    	string tmp = "&line_hollow";
    	
    	if(lines.Count > 0 )
        	tmp+= "_"+ (lines.Count+1);
        	
    	tmp+= "="+width+","+colour+","+text;

        if( font_size.Length > 0 )
            tmp+= ","+font_size+","+dot_size;
        
        tmp+= "&\r\n";
        lines.Add(tmp);
    }

    public void  area_hollow( int width, int dot_size, int alpha,string colour ,string text, string font_size )
    {
    	string tmp = "&area_hollow";
    	
    	if( lines.Count > 0 )
        	tmp+= "_"+ (lines.Count+1);
        	
    	tmp+= "="+width+","+dot_size+","+alpha+","+colour;

        if( text.Length  > 0 ){
            tmp+= ","+text+","+font_size;
		}

        tmp+= "&\r\n";
        
        lines.Add(tmp);
    }


    public void bar( int alpha, string colour, string text, int size)
    {
    	string tmp = "&bar";
    	
    	if( lines.Count > 0 )
        	tmp+= "_"+ (lines.Count+1);
        	
    	tmp+= "=";
        tmp+= alpha + ","+colour +","+ text +"," +size;
        tmp+= "&\r\n";;
        
        lines.Add(tmp);
    }

    public void bar_filled( int alpha,string colour, string colour_outline, string text, int size )
    {
    	string tmp = "&filled_bar";
    	
    	if( lines.Count > 0 )
        	tmp+= "_"+ (lines.Count+1);
        	
    	tmp+= "="+alpha+","+colour+","+colour_outline+","+text+","+size+"&\r\n";
        
        lines.Add(tmp);
    }

    public void fx_axis_colour(string axis, string grid )
    {
         x_axis_colour = axis;
         x_grid_colour = grid;
    }

    public void  fy_axis_colour(string axis, string grid)
    {
         y_axis_colour = axis;
         y_grid_colour = grid;
    }

    public void fpie( int alpha, string line_colour, string label_colour )
    {
         pie = alpha+","+line_colour+","+label_colour;

    }

    public void fpie_values( ArrayList values, ArrayList labels )
    {
		string s="";
		for(int j=0;j<values.Count;j++){
			
			if(j!=0){
				s=s+","+values[j];
			}else{
				s=values[j].ToString();
			}
		}
         pie_values = s;
		 s="";
		 for(int j=0;j<labels.Count;j++){
			
			if(j!=0){
				s=s+","+labels[j];
			}else{
				s=labels[j].ToString();
			}
		}
         pie_labels = s;
    }


    public void fpie_slice_colours( ArrayList colours )
    {
        string s="";
		for(int j=0;j<colours.Count;j++){
			
			if(j!=0){
				s=s+","+colours[j];
			}else{
				s=colours[j].ToString();
			}
		}
         pie_colours = s;
    }

  

    public string render()
    {
        string tmp = "";
        
        if( title.Length > 0 )
        {
                tmp += "&title="+ title+ ",";
                tmp += title_style +"&";
                tmp += "\r\n";
        }
        
        if( x_legend.Length > 0 )
        {
                tmp+= "&x_legend="+x_legend +",";
                tmp+= x_legend_size+",";
                tmp+= x_legend_colour +"&\r\n";
        }

        if( x_label_style.Length > 0 )
            tmp+= x_label_style;
            
        if( x_tick_size > 0 )
                tmp+= "&x_ticks="+ x_tick_size +"&\r\n";

        if( x_axis_steps > 0 )
                tmp+= "&x_axis_steps="+ x_axis_steps +"&\r\n";


        
        if( y_legend.Length > 0 )
        {
                tmp+= "&y_legend="+y_legend +",";
                tmp+= y_legend_size+",";
                tmp+= y_legend_colour +"&\r\n";
        }

        if( y_label_style.Length > 0 )
        {
            tmp+= y_label_style;
        }

        tmp+= "&y_ticks=5,10,"+y_steps +"&"+"\r\n";
        
        if( lines.Count == 0 )
        {
			tmp+=line_default;	
        }
        else
        {
			//foreach( lines in ArrayList line )
			for(int k=0;k<lines.Count;k++)
				tmp+= lines[k];
        }

        //foreach( this.data as data )
		for(int k=0;k<data.Count;k++)
				tmp+= data[k];
        
        if( x_labels.Count > 0 ){
        	string s="";
		for(int j=0;j<x_labels.Count;j++)
			
			if(j!=0){
				s=s+","+x_labels[j];
			}else{
				s=x_labels[j].ToString();
			}
                tmp+= "&x_labels="+s+"&"+"\r\n";
        }
                
        tmp+= "&y_min="+y_min +"&"+"\r\n";
        tmp+= "&y_max="+ y_max +"&"+"\r\n";
        
        if( bg_colour.Length > 0 )
        	tmp+= "&bg_colour="+ bg_colour +"&"+"\r\n";

        if( bg_image.Length > 0 )
        {
                tmp+= "&bg_image="+ bg_image +"&"+"\r\n";
                tmp+= "&bg_image_x="+ bg_image_x +"&"+"\r\n";
                tmp+= "&bg_image_y="+ bg_image_y +"&"+"\r\n";
        }


        if( x_axis_colour.Length > 0 )
        {
            tmp+= "&x_axis_colour="+x_axis_colour +"&"+"\r\n";
            tmp+= "&x_grid_colour="+x_grid_colour +"&"+"\r\n";
        }

        if( y_axis_colour.Length > 0 )
        {
            tmp+= "&y_axis_colour="+y_axis_colour +"&"+"\r\n";
            tmp+= "&y_grid_colour="+y_grid_colour +"&"+"\r\n";
        }

        if( inner_bg_colour.Length > 0 )
        {
            tmp+= "&inner_background="+inner_bg_colour;
            if( inner_bg_colour_2.Length > 0 )
            {
             
                tmp+= ","+inner_bg_colour_2;
                tmp+= ","+inner_bg_angle;
            }
            tmp+= "&"+"\r\n";
        }

        if( pie.Length > 0 )
        {

             tmp+= "&pie="+pie +"&"+"\r\n";
             tmp+= "&values="+pie_values +"&"+"\r\n";
             tmp+= "&pie_labels="+pie_labels +"&"+"\r\n";
             tmp+= "&colours="+pie_colours +"&"+"\r\n";
        }

        if( tool_tip.Length > 0 )
        {
             tmp+= "&tool_tip="+tool_tip +"&"+"\r\n";
        }

        return tmp;
    }


}
