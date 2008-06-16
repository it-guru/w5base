<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<%@ page import="org.openflashchart.Graph" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>Insert title here</title>
</head>
<body>
<%
	int max = 50;
java.util.List<String> data = new java.util.ArrayList<String>();
for( int i=0; i<12; i++ )
{
  data.add(Double.toString(Math.random() * max));
}

org.openflashchart.Graph g = new org.openflashchart.Graph();

// Spoon sales, March 2007
g.title( "Spoon sales "+java.util.GregorianCalendar.getInstance().get(java.util.Calendar.YEAR),
		"{font-size: 26px;}" );

g.set_data( data );
// label each point with its value
java.util.List<String> labels = new java.util.ArrayList<String>();
labels.add("Jan");
labels.add("Feb");
labels.add("Mar");
labels.add("Apr");
labels.add("May");
labels.add("Jun");
labels.add("Jul");
labels.add("Aug");
labels.add("Sep");
labels.add("Oct");
labels.add("Nov");
labels.add("Dec");
g.set_x_labels(labels);

// set the Y max
g.set_y_max( 60 );
// label every 20 (0,20,40,60)
g.y_label_steps( 6 );
%>
<%= g.render()  %>
</body>
</html>