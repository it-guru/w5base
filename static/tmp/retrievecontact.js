/*
 * Retrieve all contacts
 */ 

// Create the contacts service object
var contactsService =
    new google.gdata.contacts.ContactsService('GoogleInc-jsguide-1.0');

// The feed URI that is used for retrieving contacts
var feedUri = 'http://www.google.com/m8/feeds/contacts/default/full';
var query = new google.gdata.contacts.ContactQuery(feedUri);

// Set the maximum of the result set to be 50
query.setMaxResults(50);

// callback method to be invoked when getContactFeed() returns data
var callback = function(result) {
  
  // An array of contact entries
  var entries = result.feed.entry;
  
  // Iterate through the array of contact entries
  for (var i = 0; i < entries.length; i++) {
    var contactEntry = entries[i];

    var emailAddresses = contactEntry.getEmailAddresses();
    
    // Iterate through the array of emails belonging to a single contact entry
    for (var j = 0; j < emailAddresses.length; j++) {
      var emailAddress = emailAddresses[j].getAddress();
      PRINT('email = ' + emailAddress);
    }    
  }
}

// Error handler
var handleError = function(error) {
  PRINT(error);
}

// Submit the request using the contacts service object
contactsService.getContactFeed(query, callback, handleError);