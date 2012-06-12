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


chrome.extension.sendRequest({ action: 'options' }, function (response) {

    var contentExp='([\+][0-9]{1,2}[0-9, ]{5,20}|'+
        '[\+]{1}[0-9]{1,2}[ ]{0,1}[\(]{1}[0-9, ]{2,5}[\)]{1}[0-9, ]{5,20})';
    var contentExp = RegExp(contentExp, 'gm');

    var intlReplacement="<span class='uniWebDial'>$&</span>";

    var found = false;

//    // Test the text of the body element against our international regular expression.
//    var directhr_softphone_meta = $('meta[name=directhr_telephone_plugin]').attr("content");
//    if (directhr_softphone_meta != undefined && directhr_softphone_meta.toLowerCase().indexOf("[disabled]") >= 0) {
//        console.log('directhr meta was found, disabled value was found, plugin on this page was disabled');
//        return;
//    }



    if (contentExp.test(document.body.innerText)) {
        $(document).find(':not(textarea)').replaceText(
                         contentExp,intlReplacement);
        $(".uniWebDial").css({cursor:'pointer',
                              color:'blue'});
        var tURL=response.options.tURL;
        $(".uniWebDial").click(function() {
          var num=$(this).text();
          var callURL=mergeURL(tURL,num);
          var win=window.open(callURL,'_blank',
                   'height=480,width=640,toolbar=no,status=no,'+
                   'location=no,resizable=yes,scrollbars=no,'+
                   'menubar=no');
        });
        found = true;
    }
    if (found) {
        chrome.extension.sendRequest({action:'showPageAction' },function(){});
    }
});


