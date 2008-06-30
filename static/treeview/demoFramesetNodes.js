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

// Configures whether the names of the nodes are links (or whether only the icons
// are links).
USETEXTLINKS = 1

// Configures whether the tree is fully open upon loading of the page, or whether
// only the root node is visible.
STARTALLOPEN = 0

// Specify if the images are in a subdirectory;
ICONPATH = ''


foldersTree = gFld("<i>Treeview Demo</i>", "demoFramesetRightFrame.html")
  foldersTree.treeID = "Frameset"

  aux1 = insFld(foldersTree, gFld("Photos example", "demoFramesetRightFrame.html"))

    aux2 = insFld(aux1, gFld("United States", "http://www.treeview.net/treemenu/demopics/beenthere_america.gif"))
      insDoc(aux2, gLnk("R", "Boston", "http://www.treeview.net/treemenu/demopics/beenthere_boston.jpg"))
      insDoc(aux2, gLnk("R", "New York", "http://www.treeview.net/treemenu/demopics/beenthere_newyork.jpg"))
      insDoc(aux2, gLnk("R", "Washington", "http://www.treeview.net/treemenu/demopics/beenthere_washington.jpg"))

    aux2 = insFld(aux1, gFld("Europe", "http://www.treeview.net/treemenu/demopics/beenthere_europe.gif"))
      insDoc(aux2, gLnk("R", "Edinburgh", "http://www.treeview.net/treemenu/demopics/beenthere_edinburgh.gif"))
      insDoc(aux2, gLnk("R", "London", "http://www.treeview.net/treemenu/demopics/beenthere_london.jpg"))
      insDoc(aux2, gLnk("R", "Munich", "http://www.treeview.net/treemenu/demopics/beenthere_munich.jpg"))
      insDoc(aux2, gLnk("R", "Athens", "http://www.treeview.net/treemenu/demopics/beenthere_athens.jpg"))
      insDoc(aux2, gLnk("R", "Florence", "http://www.treeview.net/treemenu/demopics/beenthere_florence.jpg"))
      //
      // The next three links have their http protocol appended by the script
      //
      insDoc(aux2, gLnk("Rh", "Pisa", "www.treeview.net/treemenu/demopics/beenthere_pisa.jpg"))
      insDoc(aux2, gLnk("Rh", "Rome", "www.treeview.net/treemenu/demopics/beenthere_rome.jpg"))
      insDoc(aux2, gLnk("Rh", "Lisboa", "www.treeview.net/treemenu/demopics/beenthere_lisbon.jpg"))

  aux1 = insFld(foldersTree, gFld("3 Types of folders", "javascript:parent.op()"))

    aux2 = insFld(aux1, gFld("Linked", "http://www.treeview.net/treemenu/demopics/beenthere_unitedstates.gif"))
      insDoc(aux2, gLnk("R", "New York", "http://www.treeview.net/treemenu/demopics/beenthere_newyork.jpg"))

    aux2 = insFld(aux1, gFld("Empty, linked", "http://www.treeview.net/treemenu/demopics/beenthere_europe.gif"))

    //
    // Netscape 4.x needs the HREF to be non-empty to process other events such as open folder,
    // hence the need for the op function
    //
    aux2 = insFld(aux1, gFld("Not linked", "javascript:parent.op()"))
      insDoc(aux2, gLnk("R", "New York", "http://www.treeview.net/treemenu/demopics/beenthere_newyork.jpg"))

  aux1 = insFld(foldersTree, gFld("Targets", "javascript:parent.op()"))
      insDoc(aux1, gLnk("R", "Right frame", "http://www.treeview.net/treemenu/demopics/beenthere_edinburgh.gif"))
      insDoc(aux1, gLnk("B", "New window", "http://www.treeview.net/treemenu/demopics/beenthere_london.jpg"))
      insDoc(aux1, gLnk("T", "Whole window", "http://www.treeview.net/treemenu/demopics/beenthere_munich.jpg"))
      insDoc(aux1, gLnk("S", "This frame", "http://www.treeview.net/treemenu/demopics/beenthere_athens.jpg"))
      //
      // The S target is required.
      // The \\\ is needed to escape the ' character for string arguments.
      // Also, note that if you define your function in the parent frame, use javascript:parent.myfunc
      insDoc(aux1, gLnk("S", "JavaScript link", "javascript:alert(\\\'This JavaScript link simply calls the built-in alert function,\\\\nbut you can define your own function.\\\')"))

  aux1 = insFld(foldersTree, gFld("Other icons", "javascript:parent.op()"))
  aux1.iconSrc = ICONPATH + "diffFolder.gif"
  aux1.iconSrcClosed = ICONPATH + "diffFolder.gif"
    docAux = insDoc(aux1, gLnk("B", "D/L Treeview", "http://www.treeview.net/treemenu/download.asp"))
    docAux.iconSrc = ICONPATH + "diffDoc.gif"

  aux1 = insFld(foldersTree, gFld("<font color=red>F</font><font color=blue>o</font><font color=pink>r</font><font color=green>m</font><font color=red>a</font><font color=blue>t</font><font color=brown>s</font>", "javascript:parent.op()"))
    docAux = insDoc(aux1, gLnk("R", "<div class=specialClass>CSS Class</div>", "http://www.treeview.net/treemenu/demopics/beenthere_newyork.jpg"))

