/*
   Copyright (C) 2012  Hartmut Vogler (it@guru.de)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/

function getDirectDial() {
   return function (info, tab) {
      var tURL=localStorage['tURL'] || defaults['tURL'];
      var url = 'http://127.0.0.1:7069/Dial/' + info.selectionText;
      var num=info.selectionText;
      var callURL=tURL;
      var callURL=mergeURL(tURL,num);
     
      // Create a new window to the info page.
      chrome.windows.create({ url: callURL, width: 520, height: 660 });
   };
};



/**
* Create a context menu which will only show up for images.
*/
chrome.contextMenus.create({
    "title": "directDial %s",
    "type": "normal",
    "contexts": ["selection"],
    "onclick": getDirectDial()
});



var defaults = {
    //intlRegex: '([\+]{0,1}86[0-9. -]{10,18})|([0-9]{2,4}[. -]{0,1}[0-9]{7,8})|(400|800)([2-9][0-9]{6,11})|(1[3-9][0-9]{9})|([0-9]{7,8})',
    intlRegex: '([\+][0-9]{1,2}[0-9, ]{5,20})',
    intlReplacement: '$1$2$3$4$5$6',
    tURL: 'https://meintelefon2.telekom.de/webdialer/Webdialer?destination=0%phonenumber%'
}


function loadOptions() {
   var tURL = localStorage['tURL'] || defaults['tURL'];
   document.getElementById('tURL').value=tURL.toString();
}


function saveOptions() {
   try {
      localStorage['tURL']=document.getElementById('tURL').value;
      setStatus('Options Saved.');
   } catch (error) {
      alert(error);
   }
}


function setStatus(message) {
  var status = document.getElementById('status');
  status.innerHTML = message;
  setTimeout(function() {
    status.innerHTML = '';
  }, 4000);
}


function clearData() {
  if (confirm('Clear data in extension? (includes extension settings)')) {
    localStorage.clear();
    alert('Extension data cleared.');
  }
}

