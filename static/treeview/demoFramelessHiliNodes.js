//
// Copyright (c) 2006 by Conor O'Mahony.
// For enquiries, please email GubuSoft@GubuSoft.com.
// Please keep all copyright notices below.
// Original author of TreeView script is Marcelino Martins.
//
// This document includes the TreeView script.
// The TreeView script can be found at http://www.TreeView.net.
// The script is Copyright (c) 2006 by Conor O'Mahony.
//
// You can find general instructions for this file at www.treeview.net.
//

USETEXTLINKS = 1
STARTALLOPEN = 1
USEFRAMES = 0
USEICONS = 0
WRAPTEXT = 1
PRESERVESTATE = 1
HIGHLIGHT = 1


//
// The following code constructs the tree.
//
foldersTree = gFld("<b>Tree Options</b>", "demoFramelessHili.html")
  aux2 = insFld(foldersTree, gFld("United States", "demoFramelessHili.html?pic=%22beenthere_unitedstates%2Egif%22"))
    insDoc(aux2, gLnk("S", "Boston", "demoFramelessHili.html?pic=%22beenthere_boston%2Ejpg%22"))
    insDoc(aux2, gLnk("S", "Tiny pic of New York City", "demoFramelessHili.html?pic=%22beenthere_newyork%2Ejpg%22"))
    insDoc(aux2, gLnk("S", "Washington", "demoFramelessHili.html?pic=%22beenthere_washington%2Ejpg%22"))
  aux2 = insFld(foldersTree, gFld("Europe", "javascript:undefined"))
    insDoc(aux2, gLnk("S", "London", "demoFramelessHili.html?pic=%22beenthere_london%2Ejpg%22"))
    insDoc(aux2, gLnk("S", "Lisbon", "demoFramelessHili.html?pic=%22beenthere_lisbon%2Ejpg%22"))

//
// Set this string if TreeView and other configuration files may also be loaded 
// in the same session.
//
foldersTree.treeID = "FramelessHili" 
 