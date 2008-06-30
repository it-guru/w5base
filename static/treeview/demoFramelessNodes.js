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
STARTALLOPEN = 0
USEFRAMES = 0
USEICONS = 0
WRAPTEXT = 1
PRESERVESTATE = 1

//
// The following code constructs the tree.  This code produces a tree that looks like:
// 
// Tree Options
//  - Expand for example with pics and flags
//    - United States
//      - Boston
//      - Tiny pic of New York City
//      - Washington
//    - Europe
//      - London
//      - Lisbon
//  - Types of node
//    - Expandable with link
//      - London
//    - Expandable without link
//      - NYC
//    - Opens in new window
//

foldersTree = gFld("<b>Tree Options</b>", "demoFrameless.html")
  foldersTree.treeID = "Frameless"
  aux1 = insFld(foldersTree, gFld("Expand for example with pics and flags", "javascript:undefined"))
    aux2 = insFld(aux1, gFld("United States", "demoFrameless.html?pic=%22beenthere_unitedstates%2Egif%22"))
      insDoc(aux2, gLnk("S", "Boston", "demoFrameless.html?pic=%22beenthere_boston%2Ejpg%22"))
      insDoc(aux2, gLnk("S", "Tiny pic of New York City", "demoFrameless.html?pic=%22beenthere_newyork%2Ejpg%22"))
      insDoc(aux2, gLnk("S", "Washington", "demoFrameless.html?pic=%22beenthere_washington%2Ejpg%22"))
    aux2 = insFld(aux1, gFld("Europe", "demoFrameless.html?pic=%22beenthere_europe%2Egif%22"))
      insDoc(aux2, gLnk("S", "London", "demoFrameless.html?pic=%22beenthere_london%2Ejpg%22"))
      insDoc(aux2, gLnk("S", "Lisbon", "demoFrameless.html?pic=%22beenthere_lisbon%2Ejpg%22"))
  aux1 = insFld(foldersTree, gFld("Types of node", "javascript:undefined"))
    aux2 = insFld(aux1, gFld("Expandable with link", "demoFrameless.html?pic=%22beenthere_europe%2Egif%22"))
      insDoc(aux2, gLnk("S", "London", "demoFrameless.html?pic=%22beenthere_london%2Ejpg%22"))
    aux2 = insFld(aux1, gFld("Expandable without link", "javascript:undefined"))
      insDoc(aux2, gLnk("S", "NYC", "demoFrameless.html?pic=%22beenthere_newyork%2Ejpg%22"))
    insDoc(aux1, gLnk("B", "Opens in new window", "http://www.treeview.net/treemenu/demopics/beenthere_pisa.jpg"))
