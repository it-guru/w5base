<%@ Language=VBScript %>
<% 
option explicit 
Response.Expires=-1
%>
<!--------------------------------------------------------------->
<!-- Copyright (c) 2006 by Conor O'Mahony.                     -->
<!-- For enquiries, please email GubuSoft@GubuSoft.com.        -->
<!-- Please keep all copyright notices below.                  -->
<!-- Original author of TreeView script is Marcelino Martins.  -->
<!--------------------------------------------------------------->
<!-- This document includes the TreeView script.  The TreeView -->
<!-- script can be found at http://www.TreeView.net.  The      -->
<!-- script is Copyright (c) 2006 by Conor O'Mahony.           -->
<!--------------------------------------------------------------->
<!-- The Response.Expires=-1 will make sure the page is not    -->
<!-- cached.  If the page is cached and the database changes,  -->
<!-- the new tree will not be shown.                           -->
<!--------------------------------------------------------------->
<%
Dim databaseDir, Conn

'Change this to a path (c:\...) if the database is not in the same dir of the 
'current file
databaseDir = Server.MapPath("demoDynamic.mdb")
Set Conn = Server.CreateObject("ADODB.Connection")
Conn.Open("DRIVER={Microsoft Access Driver (*.mdb)}; DBQ=" & databaseDir)


' This is a recursive function; it will find the children directly under 
' a node and then call itself for each of those children in order to find 
' the grand-children.  For each entry in the DB that this function finds, 
' it sends a snippet of JavaScript to the browser with the Treeview 
' commands necessary for the construction of a node (either a folder or 
' a doc).
' 
' conn:          is an ADODB.Connection opened on a database with a table 
'                called NodesTable
' parentId:      is the value of the ParentID field for a record in the 
'                database
' parentObject:  is the name of the JavaScript variable used to define 
'                the parent
sub outputJavascriptForRoot(Conn)
    dim rsHits, queryString
    queryString = "SELECT NodeID, NodeName, IsFolder, ParentID, Link FROM NodesTable WHERE (ParentID=-1)"
    Set rsHits = Server.CreateObject("ADODB.Recordset")

    rsHits.Open queryString, Conn 

    outputJavascriptForSubFolder Conn, rsHits("NodeID"), rsHits("NodeName"), "fSub1"
    
    response.write "foldersTree = fSub1"
end sub


sub outputJavascriptForSubFolder(Conn, folderId, nodeName, fName)
    dim rsHits, queryString, gFldStr, gLnkStr, fi, subFolders, di

    queryString = "SELECT NodeID, NodeName, IsFolder, ParentID, Link FROM NodesTable WHERE ((ParentID=" & folderId & ") AND (IsFolder=True)) ORDER BY NodeName"

    Set rsHits = Server.CreateObject("ADODB.Recordset")
    rsHits.Open queryString, Conn

    fi=1
    do while not rsHits.EOF
        outputJavascriptForSubFolder Conn, rsHits("NodeID"), rsHits("NodeName"), fName & "Sub" & fi
        rsHits.MoveNext
        fi=fi+1
    loop

    response.write fName & " = " & "gFld('" & nodeName & "', 'javascript:parent.op();')" & VbCrLf
    response.write fName & ".xID = " & folderId & VbCrLf

    ' Call the addChildren function
    response.write fName & ".addChildren(["

    ' member of the list argument to addChildren
    if not rsHits.BOF then rsHits.MoveFirst()
    fi=1
    do while not rsHits.EOF
        if fi>1 then response.write ", "
        response.write fName & "Sub" & fi
        rsHits.MoveNext
        fi=fi+1
    loop
    rsHits.close
    subFolders = fi-1 'Count how many

    queryString = "SELECT NodeID, NodeName, Link FROM NodesTable WHERE ((ParentID=" & folderId & ") AND (IsFolder=False)) ORDER BY NodeName"
    rsHits.Open queryString, Conn
    di = 1
    do while not rsHits.EOF
        if di>1 or subFolders > 0 then response.write ", "
        response.write "['" & rsHits("NodeName") & "', '" & rsHits("Link") &"']"
        rsHits.MoveNext
        di = di + 1
    loop

    response.write "])" & VbCrLf 'Close addChildren function

    ' xID's for docs
    if not rsHits.BOF then rsHits.MoveFirst()
    di = subFolders
    do while not rsHits.EOF
        response.write fName & ".children[" & di & "].xID = " & rsHits("NodeID") & VbCrLf
        rsHits.MoveNext
        di = di+1
    loop

    rsHits.close

end sub
%>

<HTML>

 <HEAD>
  <TITLE>TreeView Demo: Dynamic Script that Reads from a Database</TITLE>

  <STYLE>
   BODY {
     background-color: white;}
   TD {
     font-size: 10pt; 
     font-family: verdana,helvetica; 
     text-decoration: none;
     white-space:nowrap;}
   A {
     text-decoration: none;
     color: black}
  </STYLE>

  <!-- As in a client-side tree, all the tree infrastructure   -->
  <!-- is put in place within the <HEAD> block, but the actual -->
  <!-- tree rendering is trigered within the <BODY>.           -->

  <!-- Code for browser detection. DO NOT REMOVE.              -->
  <SCRIPT src="ua.js"></SCRIPT>

  <!-- Infrastructure code for the TreeView. DO NOT REMOVE.    -->
  <SCRIPT src="ftiens4.js"></SCRIPT>

  <SCRIPT>
   USETEXTLINKS = 1
   STARTALLOPEN = 0
   PRESERVESTATE = 1
   ICONPATH = '' 
   HIGHLIGHT = 1

   <!-- Execution of the code that actually builds the specific -->
   <!-- tree.  The variable foldersTree is created with calls   -->
   <!-- to gFld, insFld, and insDoc.                            -->
   <% 
   outputJavascriptForRoot Conn
   %>

   // Load a page as if a node on the tree was clicked (to
   // synchronize the frames).  Also highlights selection if 
   // highlighting is chosen.
   function loadSynchPage(xID) 
   {
     var folderObj;
     docObj = parent.treeframe.findObj(xID);
     docObj.forceOpeningOfAncestorFolders();
     parent.treeframe.clickOnLink(xID,docObj.link,'basefrm'); 
 
     // Scroll the tree window to show the selected node.
     // Note that the code in this function might need to be 
     // chnaged to work with frameless pages.  Also note that
     // the scrolling does not work with NS4 browsers.
     if (typeof parent.treeframe.document.body != "undefined")
       parent.treeframe.document.body.scrollTop=docObj.navObj.offsetTop
   } 
  </SCRIPT>

 </HEAD>

 <BODY topmargin="16" marginheight="16">

 <!------------------------------------------------------------->
 <!-- IMPORTANT NOTICE:                                       -->
 <!-- Removing the following link will prevent this script    -->
 <!-- from working.  Unless you purchase the registered       -->
 <!-- version of TreeView, you must include this link.        -->
 <!-- If you make any unauthorized changes to the following   -->
 <!-- code, you will violate the user agreement.  If you want -->
 <!-- to remove the link, see the online FAQ for instructions -->
 <!-- on how to obtain a version without the link.            -->
 <!------------------------------------------------------------->
 <DIV style="position:absolute; top:0; left:0;"><TABLE border=0><TR><TD><FONT size=-2><A style="font-size:7pt;text-decoration:none;color:silver" href="http://www.treemenu.net/" target=_blank>Javascript Tree Menu</A></FONT></TD></TR></TABLE></DIV>

  <!-- Build the browser's objects and display default view  -->
  <!-- of the tree.                                          -->
  <SCRIPT>
   initializeDocument()
   // Click the Parakeet link
   loadSynchPage(506027036)
  </SCRIPT>
  <NOSCRIPT>
   A tree for site navigation will open here if you enable JavaScript in your browser.
  </NOSCRIPT>

 </BODY>

</HTML>