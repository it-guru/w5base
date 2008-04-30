//<![CDATA[
/* The author of this code is Geir K. Engdahl, and can be reached
 * at geir.engdahl (at) gmail.com
 * 
 * If you intend to use the code or derive code from it, please
 * consult with the author.
 */ 
// Create a directions object and register a map and DIV to hold the 
// resulting computed directions

var gebMap;           // The map DOM object
var directionsPanel;  // The driving directions DOM object
var gebDirections;    // The driving directions returned from GMAP API
var gebGeocoder;      // The geocoder for addresses
var maxTspSize = 20;  // A limit on the size of the problem, mostly to save Google servers from undue load.
var maxTspBF = 9;     // Max size for brute force, may seem conservative, but many browsers have limitations on run-time.
var maxSize = 24;     // Max number of waypoints in one Google driving directions request.
var exportOrder = false; // Save lat/lng for text export.
var maxTripSentry = 2000000000; // Approx. 63 years., this long a route should not be reached...
var distIndex;      
var reasons = new Array();
reasons[G_GEO_SUCCESS]            = "Success";
reasons[G_GEO_MISSING_ADDRESS]    = "Missing Address: The address was either missing or had no value.";
reasons[G_GEO_UNKNOWN_ADDRESS]    = "Unknown Address:  No corresponding geographic location could be found for the specified address.";
reasons[G_GEO_UNAVAILABLE_ADDRESS]= "Unavailable Address:  The geocode for the given address cannot be returned due to legal or contractual reasons.";
reasons[G_GEO_BAD_KEY]            = "Bad Key: The API key is either invalid or does not match the domain for which it was given";
reasons[G_GEO_TOO_MANY_QUERIES]   = "Too Many Queries: The daily geocoding quota for this site has been exceeded.";
reasons[G_GEO_SERVER_ERROR]       = "Server error: The geocoding request could not be successfully processed.";
var gebMarkers = new Array();
var waypoints = new Array();
var addresses = new Array();
var addr = new Array();
var wpActive = new Array();
var wayStr;
var distances;
var durations;
var dist;
var dur;
var visited;
var currPath;
var bestPath;
var bestTrip;
var numActive;
var chunkNode;
var addressRequests;

/* Returns a textual representation of time in the format 
 * "N days M hrs P min Q sec". Does not include days if
 * 0 days etc. Does not include seconds if time is more than
 * 1 hour.
 */
function formatTime(seconds) {
  var days;
  var hours;
  var minutes;
  days = parseInt(seconds / (24*3600));
  seconds -= days * 24 * 3600;
  hours = parseInt(seconds / 3600);
  seconds -= hours * 3600;
  minutes = parseInt(seconds / 60);
  seconds -= minutes * 60;
  var ret = "";
  if (days > 0) 
    ret += days + " days ";
  if (days > 0 || hours > 0) 
    ret += hours + " hrs ";
  if (days > 0 || hours > 0 || minutes > 0) 
    ret += minutes + " min ";
  if (days == 0 && hours == 0)
    ret += seconds + " sec";
  return(ret);
}

/* Returns textual representation of distance in the format
 * "N km M m". Does not include km if less than 1 km. Does not
 * include meters if km >= 10.
 */
function formatLength(meters) {
  var km = parseInt(meters / 1000);
  meters -= km * 1000;
  var ret = "";
  if (km > 0) 
    ret += km + " km ";
  if (km < 10)
    ret += meters + " m";
  return(ret);
}

/* Returns an HTML string representing the driving directions.
 * Icons match the ones shown in the map. Addresses are used
 * as headers where available.
 */
function formatDirections(gdir) {
  var retStr = "<table class='gebddir' border=0 cell-spacing=0>\n";
  for (var i = 0; i < gdir.getNumRoutes(); ++i) {
    var route = gdir.getRoute(i);
    var colour = "g";
    var number = i+1;
    if (number == 1)
      colour = "r";
    retStr += "\t<tr class='heading'><td class='heading' width=40>"
      + "<div class='centered-directions'><img src='../../icon" + colour 
      + number + ".png'></div></td>"
      + "<td class='heading'><div class='centered-directions'>";
    var headerStr;
    if (addr[bestPath[i]] == null) {
      var prevI = (i == 0) ? gdir.getNumRoutes() - 1 : i-1;
      var latLng = gdir.getRoute(prevI).getEndLatLng();
      headerStr = "(" + latLng.lat() + ", " + latLng.lng() + ")";
    } else {
      headerStr = addr[bestPath[i]];
    }
    retStr += headerStr + "</div></td></tr>\n";
    for (var j = 0; j < route.getNumSteps(); ++j) {
      var classStr = "odd";
      if (j % 2 == 0) classStr = "even";
      retStr += "\t<tr class='text'><td class='" + classStr + "'></td>"
	+ "<td class='" + classStr + "'>"
	+ route.getStep(j).getDescriptionHtml() + "<div class='left-shift'>"
	+ route.getStep(j).getDistance().html + "</div></td></tr>\n";
    }
  }
  var headerStr;
  if (addr[0] == null) {
    var prevI = gdir.getNumRoutes() - 1;
    var latLng = gdir.getRoute(prevI).getEndLatLng();
    headerStr = "(" + latLng.lat() + ", " + latLng.lng() + ")";
  } else {
    headerStr = addr[0];
  }
    
  retStr += "\t<tr class='heading'><td class='heading'>"
    + "<div class='centered-directions'><img src='icons/iconr1.png'></div></td>"
    + "<td class='heading'>"
    + "<div class='centered-directions'>" 
    + headerStr + "</div></td></tr>\n";
  retStr += "</table>";
  return(retStr);
}

/* Computes a near-optimal solution to the TSP problem, 
 * using Ant Colony Optimization and local optimization
 * in the form of k2-opting each candidate route.
 * Run time is O(numWaves * numAnts * numActive ^ 2) for ACO
 * and O(numWaves * numAnts * numActive ^ 3) for rewiring?
 */
function tspAntColonyK2() {
  var alfa = 1.0; // The importance of the previous trails
  var beta = 1.0; // The importance of the durations
  var rho = 0.1;  // The decay rate of the pheromone trails
  var asymptoteFactor = 0.9; // The sharpness of the reward as the solutions approach the best solution
  var pher = new Array();
  var nextPher = new Array();
  var prob = new Array();
  var numAnts = 10;
  var numWaves = 10;
  for (var i = 0; i < numActive; ++i) {
    pher[i] = new Array();
    nextPher[i] = new Array();
  }
  for (var i = 0; i < numActive; ++i) {
    for (var j = 0; j < numActive; ++j) {
      pher[i][j] = 1;
      nextPher[i][j] = 0.0;
    }
  }

  for (var wave = 0; wave < numWaves; ++wave) {
    for (var ant = 0; ant < numAnts; ++ant) {
      // var startNode = Math.floor(Math.random() * numActive);
      var startNode = 0;
      var curr = startNode;
      var currDist = 0;
      for (var i = 0; i < numActive; ++i) {
	visited[i] = false;
      }
      currPath[0] = curr;
      for (var step = 0; step < numActive-1; ++step) {
	visited[curr] = true;
	var cumProb = 0.0;
	for (var next = 0; next < numActive; ++next) {
	  if (!visited[next]) {
	    prob[next] = Math.pow(pher[curr][next], alfa) * 
	      Math.pow(dur[curr][next], 0.0-beta);
	    //prob[next] = pow(pher[curr][next],alfa) 
	    //  * pow(dur[curr][next],-beta);
	    cumProb += prob[next];
	  }
	}
	var guess = Math.random() * cumProb;
	//double guess = rand() / (double)(RAND_MAX) * cumProb;
	var nextI = -1;
	for (var next = 0; next < numActive; ++next) {
	  if (!visited[next]) {
	    nextI = next;
	    guess -= prob[next];
	    if (guess < 0) {
	      nextI = next;
	      break;
	    }
	  }
	}
	currDist += dur[curr][nextI];
	currPath[step+1] = nextI;
	curr = nextI;
      }
      currPath[numActive] = startNode;
      currDist += dur[curr][startNode];
      
      // k2-rewire:
      // cerr << "Before rewire, soln with duration = " << currDist << endl;
      var changed = true;
      while (changed) {
	changed = false;
	for (var i = 0; i < numActive-2 && !changed; ++i) {
	  var cost = dur[currPath[i+1]][currPath[i+2]];
	  var revCost = dur[currPath[i+2]][currPath[i+1]];
	  for (var j = i+2; j < numActive && !changed; ++j) {
	    if (cost + dur[currPath[i]][currPath[i+1]] 
		+ dur[currPath[j]][currPath[j+1]] > revCost 
		+ dur[currPath[i]][currPath[j]] 
		+ dur[currPath[i+1]][currPath[j+1]]) {
	      currDist += revCost + dur[currPath[i]][currPath[j]] 
		+ dur[currPath[i+1]][currPath[j+1]] - cost
		- dur[currPath[i]][currPath[i+1]] 
		- dur[currPath[j]][currPath[j+1]];
	      var tmp;
      	      for (var k = 0; k < Math.floor((j-i)/2); ++k) {
		//for (int k = 0; k < (j-i)/2; ++k) {
		tmp = currPath[i+1+k];
		currPath[i+1+k] = currPath[j-k];
		currPath[j-k] = tmp;
	      }
	      changed = true;
	    }
	    cost += dur[currPath[j]][currPath[j+1]];
	    revCost += dur[currPath[j+1]][currPath[j]];
	  }
	}
      }
      if (currDist < bestTrip) {
	bestPath = currPath;
	bestTrip = currDist;
      }
      for (var i = 0; i < numActive; ++i) {
	nextPher[currPath[i]][currPath[i+1]] += (bestTrip - asymptoteFactor * bestTrip) / (numAnts * (currDist-asymptoteFactor*bestTrip));
      }
    }
    for (var i = 0; i < numActive; ++i) {
      for (var j = 0; j < numActive; ++j) {
	pher[i][j] = pher[i][j] * (1.0 - rho) + rho * nextPher[i][j];
	nextPher[i][j] = 0.0;
      }
    }
  }
}

/* Returns the optimal solution to the TSP problem.
 * Run-time is O((numActive-1)!).
 * Prerequisites: 
 * - numActive contains the number of locations
 * - dur[i, j] contains weight of edge from node i to node j
 * - visited[i] should be false for all nodes
 * - bestTrip is set to a very high number
 */
function tspBruteForce(currNode, currLen, currStep) {

  // If this route is promising:
  if (currLen + dur[currNode][0] < bestTrip) {

    // If this is the last node:
    if (currStep == numActive) {
      currLen += dur[currNode][0];
      currPath[currStep] = 0;
      bestTrip = currLen;
      for (var i = 0; i <= numActive; ++i) {
        bestPath[i] = currPath[i];
      }
    } else {

      // Try all possible routes:
      for (var i = 0; i < numActive; ++i) {
        if (!visited[i]) {
          visited[i] = true;
          currPath[currStep] = i;
          tspBruteForce(i, currLen+dur[currNode][i], currStep+1);
          visited[i] = false;
        }
      }
    }
  }
}

/* Returns the optimal solution to the CPP problem.
 * The carpooling problem (CPP) is:
 *   Given a starting location, an ending location (fixed),
 *   and several passenger locations, find the shortest / fastest
 *   route from the starting location to the ending location
 *   which visits all the passenger locations.
 * Run-time is O((numActive-2)!) 
 * Prerequisites: 
 * - numActive contains the number of locations (including start and end)
 * - dur[i, j] contains weight of edge from node i to node j
 * - visited[i] should be false for all nodes
 * - bestTrip is set to a very high number
 * - node 0 is the starting location
 * - node numActive-1 is the final destination
 */
function cppBruteForce(currNode, currLen, currStep) {

  // If this route is promising:
  if (currLen + dur[currNode][numActive-1] < bestTrip) {

    // If this is the last node:
    if (currStep == numActive - 1) {
      currLen += dur[currNode][numActive - 1];
      currPath[currStep] = numActive - 1;
      bestTrip = currLen;
      for (var i = 0; i <= numActive - 1; ++i) {
        bestPath[i] = currPath[i];
      }
    } else {

      // Try all possible routes:
      for (var i = 0; i < numActive - 1; ++i) {
        if (!visited[i]) {
          visited[i] = true;
          currPath[currStep] = i;
          cppBruteForce(i, currLen+dur[currNode][i], currStep+1);
          visited[i] = false;
        }
      }
    }
  }
}
  
function makeLatLng(latLng) {
  return(latLng.toString().substr(1,latLng.toString().length-2));
}

function getWayStr(curr) {
  //  alert("getWayStr(" + curr + ")");
  var nextAbove = -1;
  for (var i = curr + 1; i < waypoints.length; ++i) {
    if (wpActive[i]) {
      if (nextAbove == -1) {
        nextAbove = i;
      } else {
        wayStr.push(makeLatLng(waypoints[i]));
        wayStr.push(makeLatLng(waypoints[curr]));
      }
    }
  }
  if (nextAbove != -1) {
    wayStr.push(makeLatLng(waypoints[nextAbove]));
    getWayStr(nextAbove);
    wayStr.push(makeLatLng(waypoints[curr]));
  }
}

function getDistTable(curr, currInd) {
  var nextAbove = -1;
  var index = currInd;
  for (var i = curr + 1; i < waypoints.length; ++i) {
    if (wpActive[i]) {
      index++;
      if (nextAbove == -1) {
        nextAbove = i;
      } else {
        dist[currInd][index] = distances[distIndex];
        dur[currInd][index] = durations[distIndex++];
        dist[index][currInd] = distances[distIndex];
        dur[index][currInd] = durations[distIndex++];
      }
    }
  }
  if (nextAbove != -1) {
    dist[currInd][currInd+1] = distances[distIndex];
    dur[currInd][currInd+1] = durations[distIndex++];
    getDistTable(nextAbove, currInd+1);
    dist[currInd+1][currInd] = distances[distIndex];
    dur[currInd+1][currInd] = durations[distIndex++];
  }
}

function directions() {
  //  alert("directions()");
  // Disable further calls:
  document.getElementById("clickme").innerHTML = "<input id='button1' type='button' value='Start over again' onClick='startOver()'>";
  //  alert("Disabled reclick");
  
  wayStr = new Array();
  numActive = 0;
  for (var i = 0; i < waypoints.length; ++i) {
    if (wpActive[i]) ++numActive;
  }
  //  alert("Found numActive = " + numActive);

  for (var i = 0; i < waypoints.length; ++i) {
    if (wpActive[i]) {
      wayStr.push(makeLatLng(waypoints[i]));
      getWayStr(i);
      break;
//      var tmpStr = waypoints[i].toString().substr(1,waypoints[i].toString().length-2);
    }
  }
  //  alert("Got wayStr = " + wayStr);

  if (numActive > maxTspSize) {
    alert("Too many locations! You have " + numActive + ", but max limit is " + maxTspSize);
  } else {
    /*
      for (var i = 0; i < wayStr.length; ++i) {
      log("wayStr[" + i + "] = " + wayStr[i]);
      }
    */
  
    distances = new Array();
    durations = new Array();
    chunkNode = 0;
    nextChunk();
  }
}

function nextChunk() {
  //alert("nextChunk() chunkNode = " + chunkNode);

  if (chunkNode < wayStr.length) {
    var wayStrChunk = new Array();
    for (var i = 0; i < maxSize && i + chunkNode < wayStr.length; ++i) {
      wayStrChunk.push(wayStr[chunkNode+i]);
    }
    chunkNode += maxSize;
    if (chunkNode < wayStr.length-1) {
      chunkNode--;
    }

    //alert("Got wayStrChunk = " + wayStrChunk);

    gebDirections = new GDirections();
    //    alert("Created new GDirections object");
    GEvent.addListener(gebDirections, "error", function() {
	alert("Request failed: " + reasons[gebDirections.getStatus().code]);
      });
    
    GEvent.addListener(gebDirections, "load", function() {
	// Save distances and durations
	//	alert("Directions request succesfull (load fired)!");
	for (var i = 0; i < gebDirections.getNumRoutes(); ++i) {
	  durations.push(gebDirections.getRoute(i).getDuration().seconds);
	  distances.push(gebDirections.getRoute(i).getDistance().meters);
	}
	nextChunk();
      });
    //for (var i = 0; i < wayStrChunk.length; ++i) 
    //      log("wayStrChunk[" + i + "] = " + wayStrChunk[i]);

    //    alert("Sending directions request");
    gebDirections.loadFromWaypoints(wayStrChunk, { getSteps:false, getPolyline:false, preserveViewport:true });
  } else {
    readyTsp();
  }
}

function readyTsp() {

  // Get distances and durations into 2-d arrays:
  distIndex = 0;
  dist = new Array();
  dur = new Array();
  numActive = 0;
  for (var i = 0; i < waypoints.length; ++i) {
    if (wpActive[i]) {
      dist.push(new Array());
      dur.push(new Array());
      addr[numActive] = addresses[i];
      numActive++;
    }
  }
  for (var i = 0; i < numActive; ++i) {
    dist[i][i] = 0;
    dur[i][i] = 0;
  }
  for (var i = 0; i < waypoints.length; ++i) {
    if (wpActive[i]) {
      getDistTable(i, 0);
      break;
    }
  }

  // Show the acquired info as a table:
/*
  var stateStr = "<b>Distance matrix:</b><br><table border=1>";
  for (var i = 0; i < numActive; ++i) {
    stateStr += "<tr>";
    for (var j = 0; j < numActive; ++j) {
      stateStr += "<td>" + dur[i][j] + "</td>";
    }
    stateStr += "</tr>";
  }
  stateStr += "</table>";
  document.getElementById("message").innerHTML = stateStr;
*/
  // Calculate shortest roundtrip:
  visited = new Array();
  for (var i = 0; i < numActive; ++i) {
    visited[i] = false;
  }
  currPath = new Array();
  bestPath = new Array();
  bestTrip = maxTripSentry;
  visited[0] = true;
  currPath[0] = 0;
  if (numActive <= maxTspBF) {
    tspBruteForce(0, 0, 1);
  } else {
    alert("More than " + maxTspBF + " locations, will find near-optimal solution.");
    tspAntColonyK2();
  }

  // Print shortest roundtrip data:
  var pathStr = "<p>Roundtrip duration: " + formatTime(bestTrip) + "<br>";
  var pathLength = 0;
  for (var i = 0; i < bestPath.length-1; ++i) {
    pathLength += dist[bestPath[i]][bestPath[i+1]];
  }
  pathStr += "Roundtrip length: " + formatLength(pathLength) + "</p>";
  document.getElementById("path").innerHTML = pathStr;

  // Print directions for shortest roundtrip:
  gebDirections = new GDirections(gebMap, directionsPanel);
  GEvent.addListener(gebDirections, "error", function() {
      alert("Request failed: " + reasons[gebDirections.getStatus().code]);
    });
  GEvent.addListener(gebDirections, "load", function() {
      //      alert("Final path directions request succeeded (load fired)");
      for (var i = 0; i < waypoints.length; ++i) {
	if (wpActive[i]) {
	  gebMap.removeOverlay(gebMarkers[i]);
	  wpActive[i] = false;
	}
      }
      //alert("Removed old marker overlays");
    });
  GEvent.addListener(gebDirections, "addoverlay", function() {      
      // Remove the standard google maps icons:
      for (var i = 0; i < gebDirections.getNumGeocodes(); ++i) {
	gebMap.removeOverlay(gebDirections.getMarker(i));
      }

      // Add nice, numbered icons instead:
      for (var i = 0; i < gebDirections.getNumRoutes(); ++i) {
	var route = gebDirections.getRoute(i);
	var myPt1 = route.getEndLatLng();
	var myIcn1;
	if (i == gebDirections.getNumRoutes()-1) {
	  myIcn1 = new GIcon(G_DEFAULT_ICON,"../../base/load/iconr1.png");
	  myIcn1.printImage = "../../base/load/iconr1.png";
	  myIcn1.mozPrintImage = "../../base/load/iconr1.gif";
	} else {
	  myIcn1 = new GIcon(G_DEFAULT_ICON,"../../base/load/icong" + (i+2) + ".png");
	  myIcn1.printImage = "../../base/load/icong" + (i+2) + ".png";
	  myIcn1.mozPrintImage = "../../base/load/icong" + (i+2) + ".gif";
	}
	gebMap.addOverlay(new GMarker(myPt1,myIcn1));
      }

      // Replace driving directions with custom made design:
      document.getElementById("my_textual_div").innerHTML 
	= formatDirections(gebDirections); 
    });
    
  wayStrChunk = new Array();
  var wpIndices = new Array();
  for (var i = 0; i < waypoints.length; ++i) {
    if (wpActive[i]) {
      wpIndices.push(i);
    }
  }
  var bestPathLatLngStr = "";
  for (var i = 0; i < bestPath.length; ++i) {
    wayStrChunk.push(makeLatLng(waypoints[wpIndices[bestPath[i]]]));
    bestPathLatLngStr += makeLatLng(waypoints[wpIndices[bestPath[i]]]) + "\n";
  }
//	alert(wayStrChunk);
  gebDirections.loadFromWaypoints(wayStrChunk);
  if (exportOrder) {
    document.getElementById("exportData").innerHTML = 
      "<textarea name='outputList' rows='10' cols='40'>" 
      + bestPathLatLngStr + "</textarea><br>";
  }
}

function addWaypoint(latLng) {
  var freeInd = -1;
  for (var i = 0; i < waypoints.length; ++i) {
    if (!wpActive[i]) {
      freeInd = i;
      break;
    }
  }
  if (freeInd == -1) {
    if (waypoints.length < 20) {
      waypoints.push(latLng);
      wpActive.push(true);
      freeInd = waypoints.length-1;
    } else {
      return(-1);
    }
  } else {
    waypoints[freeInd] = latLng;
    wpActive[freeInd] = true;
  }
  var myIcn1;
  if (freeInd == 0) {
    myIcn1 = new GIcon(G_DEFAULT_ICON,"../../base/load/iconr" + (freeInd+1) + ".png");
    myIcn1.printImage = "../../base/load/iconr" + (freeInd+1) + ".png";
    myIcn1.mozPrintImage = "../../base/load/iconr" + (freeInd+1) + ".gif";
  } else {
    myIcn1 = new GIcon(G_DEFAULT_ICON,"../../base/load/iconb" + (freeInd+1) + ".png");
    myIcn1.printImage = "../../base/load/iconb" + (freeInd+1) + ".png";
    myIcn1.mozPrintImage = "../../base/load/iconb" + (freeInd+1) + ".gif";
  }
  gebMarkers[freeInd] = new GMarker(latLng,myIcn1);
  gebMap.addOverlay(gebMarkers[freeInd]);
  return(freeInd);
} 

function loadAtStart(lat, lng, zoom, exprt) {
  if (exprt != null) exportOrder = exprt;
  //  alert("loadAtStart()");
  //ip2location("12.215.42.19");
  if (GBrowserIsCompatible()) {
    addressRequests = 0;
    gebMap = new GMap2(document.getElementById("map"));
    directionsPanel = document.getElementById("my_textual_div");
    gebGeocoder = new GClientGeocoder();
  
    //    map.setCenter(new GLatLng(37.4419, -122.1419), 13);
    gebMap.setCenter(new GLatLng(lat, lng), zoom);
    gebMap.addControl(new GLargeMapControl());
    gebMap.addControl(new GMapTypeControl());
    GEvent.addListener(gebMap, "click", function(marker, latLng) {
      if (marker == null) {
	addWaypoint(latLng);
      } else {
        latLng = marker.getPoint();
        for (var i = 0; i < waypoints.length; ++i) {
          if (wpActive[i] && waypoints[i].equals(latLng)) {
            wpActive[i] = false;
            break;
          }
        }
        gebMap.removeOverlay(marker);
      }

      // Debug:
      /*
      var stateStr = "";
      for (var i = 0; i < waypoints.length; ++i) {
        if (wpActive[i]) {
          stateStr += waypoints[i].toString();
        } else {
          stateStr += "INACTIVE";
        }
        stateStr += "<br>";
      }
      document.getElementById("message").innerHTML = stateStr;
      */
    });
    
    //directions();
  }
}

function clickedAddAddress() {
  addAddress(document.address.addressStr.value);
}

function clickedAddList() {
  addList(document.forms['listOfLocations'].elements['inputList'].value);
}

function addList(listStr) {
  var listArray = listStr.split("\n");
  for (var i = 0; i < listArray.length; ++i) {
    var listLine = listArray[i];
    var listLineArray = listArray[i].split(",");
    if (listLineArray.length == 2) {
      var lat = parseFloat(listLineArray[0]);
      var lng = parseFloat(listLineArray[1]);
      var latLng = new GLatLng(lat, lng);
      addWaypoint(latLng);
    }
  }
}

function addAddress(address) {
  addressRequests++;
  gebGeocoder.getLatLng(address, function(latLng) {
      addressRequests--;
      if (!latLng) {
	alert("Address " + address + " not found.");
      } else {
	gebMap.setCenter(latLng, 13);
	var freeInd = addWaypoint(latLng);
	addresses[freeInd] = address;
      }
    });	
}

function startOver() {
  document.getElementById("clickme").innerHTML = "<input id='button1' type='button' value='Calculate Fastest Roundtrip' onClick='directions()'>";
  document.getElementById("my_textual_div").innerHTML = ""
  document.getElementById("path").innerHTML = ""
  gebMap.clearOverlays();
  gebMarkers = new Array();
  waypoints = new Array();
  addresses = new Array();
  addr = new Array();
  wpActive = new Array();
  wayStr = "";
  distances = new Array();
  durations = new Array();
  dist = new Array();
  dur = new Array();
  visited = new Array();
  currPath = new Array();
  bestPath = new Array();
  bestTrip = new Array();
  numActive = 0;
  chunkNode = 0;
  addressRequests = 0;
}
//]]>
    
