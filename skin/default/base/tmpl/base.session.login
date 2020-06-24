<html>
<style>
div.loginhead{
   background-color:gray;
   padding:2px;
   color:white;
   border-width:0px;
   margin:0px;
   font-weight:bold;
}
div.loginframe{
   border-style:solid;
   border-color:black;
   border-width:1px;
   height:150px;
   width:250px;
   margin:4px;
}

</style>
<body><table width="100%" height="100%"><tr><td align=center valign=center>
<table border=0>
<tr>
<td width=250 height=140 align=left valign=top>
<div class=loginframe>
<div class=loginhead>Classic HTTP Basic Login</div>
Use this login process, to auth by
NT-Domain or W5Base Service accounts (f.e. interface access). 
If you have special chars in your loginname (f.e. &auml;) this
kind of login will fail!<br>
<br>
<center>
<input type=button value=" Select Basic-Auth Login process ">


</div>
</td>
<td width=250 height=140 align=left valign=top>
<div class=loginframe>
<div class=loginhead>WebSSO Login</div>
This kind of login process uses IBM Web-Seal technologie. 
<br>
<center>
<input type=button value=" Select WebSSO Login process ">


</div>
</td>
</tr>
<tr>
<td colspan=2 height=140 align=center valign=top>
<div class=loginframe style="width:400px">
<div class=loginhead>OpenID Login</div>
<br>
<input type=button style="width:100px" value=" Google ">
<input type=button style="width:100px" value=" Yahoo ">
<input type=button style="width:100px" value=" openid.net ">
<br><br><br>
<form method=POST>
Login URL: &nbsp;<input type=text name=openid style="width:70%"
xvalue="http://openid.org/voglerh"
value="https://www.google.com/accounts/o8/id"
><br><br>
<input type=submit value=" OpenID Login ">
<input type=hidden name=LoginType value="openid">
</form>


</div>
</td>
</tr>


</table><br><br><br>
</td></tr></table></body></html>
