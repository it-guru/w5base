/*******************************************************************************
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ******************************************************************************/

/* 
    This JavaScript creates a simple slide presentation in a web browser using
    div tags.  It supports key presses for changing slides.
 */ 

var slideCount = 0;
var slideArray = [];
var currentSlide = 1;


/**
 * Positions the slide deck to the specified slide
 * 
 * @param slide  the index of the slide to use
 */
function positionSlide(/*int*/ slide) {
    if (slide > 0 && slide <= slideCount) {
        slideArray[currentSlide].hide();
        currentSlide = slide;
        slideArray[currentSlide].show();
        setXofYLabel();
    }
    enableButtons();
}

function setXofYLabel() {
    $("#slideIndex").val("" + currentSlide);
    $("#xofy").html("of " + slideCount);
}

/**
 * Positions the slide deck to the next slide
 */
function nextSlide() {
    positionSlide(currentSlide + 1);
}

/**
 * Positions the slide deck to the previous slide
 */
function prevSlide() {
    positionSlide(currentSlide - 1);
}

/**
 * A helper function to enable and disable the navigation buttons based
 * on the current slide index.
 */
function enableButtons() {
    if (currentSlide === 1) {
        $(".first").addClass("firstdisabled").removeClass("firstenabled");
        $(".previous").addClass("previousdisabled").removeClass("previousenabled");
        $(".next").removeClass("nextdisabled").addClass("nextenabled");;
        $(".last").removeClass("lastdisabled").addClass("lastenabled");;
    } else if (currentSlide === slideCount) {
        $(".first").removeClass("firstdisabled").addClass("firstenabled");;
        $(".previous").removeClass("previousdisabled").addClass("previousenabled");;
        $(".next").addClass("nextdisabled").removeClass("nextenabled");
        $(".last").addClass("lastdisabled").removeClass("lastenabled");
    } else {
        $(".first").removeClass("firstdisabled").addClass("firstenabled");
        $(".previous").removeClass("previousdisabled").addClass("previousenabled");;
        $(".next").removeClass("nextdisabled").addClass("nextenabled");;
        $(".last").removeClass("lastdisabled").addClass("lastenabled");;
    }
}

/**
 * Checks every key event for a key ID that we want to respond to
 */
var KeyCheck = function(e) {
    var KeyID = (window.event) ? event.keyCode : e.keyCode;
    switch(KeyID) {
        case 37:    //the left arrow key
            prevSlide();
            e.returnValue = false;
            return false;
        case 39:    // the right arrow key
        case 32:    //the space key
            nextSlide();
            e.returnValue = false;
            return false;
        case 35:    // the end key
            positionSlide(slideCount);
            e.returnValue = false;
            return false;
        case 36:    // the home key
            positionSlide(1);
            e.returnValue = false;
            return false;
    }
};

/* 
 * Adds the KeyCheck listener for keyboard based grid navigation
 */
var addListener = function(element, type, expression, bubbling)
{
    bubbling = bubbling || false;
 
    if(window.addEventListener) { // Standard
        element.addEventListener(type, expression, bubbling);
        return true;
    } else if(window.attachEvent) { // IE
        element.attachEvent('on' + type, expression);
        return true;
    } else {
        return false;
    }
};

var footerVisible = true;

/**
 * This is a helper function to hide and show the footer 
 * when the grippie is clicked.
 */
function toggleFooter() {
    if (footerVisible) {
        $("#footercontent").hide();
        $("#footer").css({
            height: "0em",
            marginTop: "3em",
            borderTop: "transparent"
        });
    } else {
        $("#footercontent").show();
        $("#footer").css({
            height: "4em",
            marginTop: "-0.5em",
            borderTop: "thin solid lightgray"
        });
    }

    footerVisible = !footerVisible;
}

/**
 * This is a JQuery API method that gets called once the document 
 * is parsed and loaded
 * 
 * @param document
 */
$(document).ready(function () {
  $(".slide").each(function () {
      slideCount++;
      $(this).css("display", "none");
      slideArray[slideCount] = $(this);
  });
  
  addListener(document, 'keyup', KeyCheck);
  
  slideArray[currentSlide].css("display", "block");
  setXofYLabel();
  
  /* 
   * Add the listeners for the arrow buttons
   */
  $(".first").click(function () {
      positionSlide(1);
  });
  
  $(".previous").click(function () {
      prevSlide();
  });
  
  $(".next").click(function () {
      nextSlide();
  });
  
  $(".last").click(function () {
      positionSlide(slideCount);
  });
  
  enableButtons();
  
  /* 
   * Click handler for the grippie
   */
  $("#grip").click(function () {
      toggleFooter();
  });
  
  /* 
   * Add the listener for the navigation key toggle.
   */
  $("#keysmall").click(function () {
      toggleKey();
  });

  /*
   * The handler for enter on the slide index number
   */
  $("#slideIndex").keyup( function(e) {
      if(e.keyCode == 13) {
          positionSlide(parseInt($("#slideIndex").val()));
      }
  });
      
});

var keyVisible = true;

/* 
 * This function handles toggling the navigation key.  The key slides up 
 * and to the right.  It leaves a little edge you can click to get it back
 */ 
function toggleKey() {
    if(keyVisible) {
        $("#keydiv").animate({ 
            right: "-450px",
            top: "-400px"
            }, 500, "swing", function () {
                 $("#keydiv").hide();
                 $("#keysmall").fadeIn();
            });
        keyVisible = false;
    } else {
        $("#keysmall").fadeOut(function () {
            $("#keydiv").show();
            $("#keydiv").animate({ 
            right: "20px",
            top: "20px"
            }, 500, "swing");
        });
        keyVisible = true;
    }
}
