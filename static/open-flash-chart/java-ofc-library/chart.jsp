<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>A Flash Chart</title>
</head>
<body>
<%
String base = "";
int width = 500;
int height = 250;
String dataurl = request.getRequestURL().toString();
//
// escape the & and stuff:
//
String url = java.net.URLEncoder.encode(dataurl.replace("/chart.jsp", "/chart-data.jsp"), "UTF-8");

//
// if there are more than one charts on the
// page, give each a different ID
//
//int open_flash_chart_seqno;
String obj_id = "chart";
//String div_name = "flashcontent";
// These values are for when there is >1 chart per page
//    $open_flash_chart_seqno++;
//    $obj_id .= '_<%=open_flash_chart_seqno;
//    $div_name .= '_<%=open_flash_chart_seqno;
// Not using swfobject: <script type="text/javascript" src="< % = base % >js/swfobject.js"></script>
%>
<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" 
	codebase="<%= request.getProtocol() %>://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0"
	width="<%=width %>" height="<%=height %>" id="ie_<%=obj_id %>" align="middle">
  <param name="allowScriptAccess" value="sameDomain" />
  <param name="movie" value="<%=base%>open-flash-chart.swf?width=<%=width%>&height=<%=height%>&data=<%=url%>" />
  <param name="quality" value="high" />
  <param name="bgcolor" value="#FFFFFF" />
  <embed src="<%=base%>open-flash-chart.swf?data=<%=url%>" 
    quality="high" bgcolor="#FFFFFF" 
  	width="<%=width%>" height="<%=height%>" name="<%=obj_id%>" align="middle" allowScriptAccess="sameDomain"
	type="application/x-shockwave-flash" 
	pluginspage="<%=request.getProtocol()%>://www.macromedia.com/go/getflashplayer" 
	id="<%=obj_id%>"
	/>
</object>
</body>
</html>