/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout {

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */

	public static void getDummyJSONUserFromId(String dummyUserId) {
		try{
		// Create HTTP request to send.
		HttpRequest req = new HttpRequest();

		// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
		req.setEndpoint('callout:DummyJsonUser/' + dummyUserId);

		// Set the HTTP method to GET.
		req.setMethod('GET');

		// Send the HTTP request and get the response.
		Http http = new Http();
		HTTPResponse res = http.send(req);

		// If the HTTP response code is successful, parse the JSON response and update the contact.
		if (res.getStatusCode() == 200) {
			// Deserialize the JSON response and update Salesforce Contact
			String jsonResponse = res.getBody();
			Contact cont = createContactFromJson(jsonResponse);
			cont.DummyJSON_Id__c = dummyUserId;
			upsert cont DummyJSON_Id__c; //insert/update from the JSON response using the external id (dummyUserId)
		} else {
			//Handle the case where the response is not successful.
			System.debug('Failed to fetch User. Status Code: ' + res.getStatusCode() + ' ' + res.getStatus());
		}
	} catch (Exception e){
			System.debug('Callout error: ' + e.getMessage());
	}
}

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static Contact createContactFromJson(String jsonResponse) {
		// Deserialize the JSON string into map of primitive data types.
		Map<String, Object> userData = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);

		// Create a new contact from the JSON response.
		Contact cont = new Contact();

		// Set the contact fields from the JSON response.
		cont.Email = (String) userData.get('email');
		cont.Phone = (String) userData.get('phone');

		String birthdateString = (String) userData.get ('birthDate');
		if (birthdateString != null) {
		cont.Birthdate = Date.valueOf (birthdateString);
		}

		// Deserialize the address from the JSON response.
		Map<String, Object> address = (Map<String, Object>) userData.get('address');
		if (address != null) {
			cont.MailingStreet = (String) address.get('address');
			cont.MailingCity = (String) address.get('city');
			cont.MailingState = (String) address.get('state');
			cont.MailingCountry = (String) address.get('country');
			cont.MailingPostalCode = (String) address.get('postalCode');
		}


		return cont;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
	 public static void postCreateDummyJSONUser(String contactId) {
		try {
			// Query the Contact record
			Contact contact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId LIMIT 1];
	
			if (contact != null) {
				// Prepare the JSON payload
				String jsonPayload = generateDummyJsonUserPayload(contact);
	
				// Create HTTP request to send.
				HttpRequest req = new HttpRequest();
				req.setEndpoint('callout:DummyJsonUser/add'); // Set the endpoint URL
				req.setMethod('POST'); // Set the HTTP method to POST.
				req.setHeader('Content-Type', 'application/json');
				req.setBody(jsonPayload);
	
				// Send the HTTP request and get the response.
				Http http = new Http();
				HTTPResponse res = http.send(req);
	
				// If the HTTP response code is successful, update the contact.
				if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
					// Update the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
					contact.DummyJSON_Last_Updated__c = Datetime.now();
					update contact;
				} else {
					// Handle error response from the external system
					System.debug('Error response from DummyJSON API: ' + res.getStatusCode() + ' - ' + res.getBody());
				}
			} else {
				System.debug('No Contact found with ID: ' + contactId);
			}
		} catch (Exception e) {
			// Handle any unexpected errors
			System.debug('Error in postCreateDummyJSONUser: ' + e.getMessage());
		}
	}

// Helper method to generate JSON payload for the external system
public static String generateDummyJsonUserPayload(Contact contact) {
	Map<String, Object> payload = new Map<String, Object>();
	payload.put('id', contact.Id);
	payload.put('firstName', contact.FirstName);
	payload.put('lastName', contact.LastName);
	payload.put('email', contact.Email);
	payload.put('phone', contact.Phone);

	return JSON.serialize(payload);  // Convert map to JSON string
}


	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
private static String generateDummyJsonUserPayload(String contactId) {
    try {
        // Query the contact to get the field values to generate the JSON payload.
        Contact contact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId];

        // Create a map of the field values.
        Map<String, Object> contactPayload = new Map<String, Object>();
        // Make sure to check that required contacts fields have a value. Default the value to unknown if it does not exist.
        contactPayload.put('salesforceId', contact.Id);
        contactPayload.put('firstName', String.isNotBlank(contact.FirstName) ? contact.FirstName : 'Unknown');
        contactPayload.put('lastName', String.isNotBlank(contact.LastName) ? contact.LastName : 'Unknown');
        contactPayload.put('email', String.isNotBlank(contact.Email) ? contact.Email : 'Unknown');
        contactPayload.put('phone', String.isNotBlank(contact.Phone) ? contact.Phone : 'Unknown');

        // Serialize the map into a JSON string.
        String jsonPayload = JSON.serialize(contactPayload);

        return jsonPayload;

    } catch (Exception e) {
        System.debug('Error generating JSON payload: ' + e.getMessage());
        return null;
    }
}
}
