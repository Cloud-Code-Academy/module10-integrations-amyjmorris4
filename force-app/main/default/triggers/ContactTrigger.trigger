/**
 * ContactTrigger Trigger Description:
 * 
 * The ContactTrigger is designed to handle various logic upon the insertion and update of Contact records in Salesforce. 
 * 
 * Key Behaviors:
 * 1. When a new Contact is inserted and doesn't have a value for the DummyJSON_Id__c field, the trigger generates a random number between 0 and 100 for it.
 * 2. Upon insertion, if the generated or provided DummyJSON_Id__c value is less than or equal to 100, the trigger initiates the getDummyJSONUserFromId API call.
 * 3. If a Contact record is updated and the DummyJSON_Id__c value is greater than 100, the trigger initiates the postCreateDummyJSONUser API call.
 * 
 * Best Practices for Callouts in Triggers:
 * 
 * 1. Avoid Direct Callouts: Triggers do not support direct HTTP callouts. Instead, use asynchronous methods like @future or Queueable to make the callout.
 * 2. Bulkify Logic: Ensure that the trigger logic is bulkified so that it can handle multiple records efficiently without hitting governor limits.
 * 3. Avoid Recursive Triggers: Ensure that the callout logic doesn't result in changes that re-invoke the same trigger, causing a recursive loop.
 * 
 * Optional Challenge: Use a trigger handler class to implement the trigger logic.
 */
trigger ContactTrigger on Contact(before insert, before update) {
	//List of Contacts to process for API callouts
	List<Contact> contactsForGetCallout = new List<Contact>();
	List<Contact> contactsForPostCallout = new List<Contact>();

	//Loop through all inserted/updated contacts
	for (contact con : Trigger.new) {
		//Check if the Contact is being inserted and DummyJSON_Id__c is null
		if (Trigger.isInsert) {
			if (con.DummyJSON_Id__c == null) {
				//Generate a random number between 0 and 100
				con.DummyJSON_Id__c = String.valueOf(Math.floor(Math.random() * 101));
			}
			//If DummyJSON_Id__c is less than or equal to 100, prepare for a Get callout
			if (Trigger.isInsert && Integer.valueOf(con.DummyJSON_Id__c) <= 100) {
				contactsForGetCallout.add(con);
			}
			//If the contact is updated and DummyJSON_Id__c is greater than 100, prepare for a POST callout
			if (Trigger.isUpdate && Integer.valueOf(con.DummyJSON_Id__c) > 100) {
				contactsForPostCallout.add(con);
			}

		}
		//Make the GET callout via a Queueable class if needed
		if (!contactsForGetCalout.isEmpty()){
			System.enqueueJob(new ContactCalloutQueueable('GET', contactsForGetCallout));
		}
		//Make the POST callout via a Queueable class if needed
		if (!contactsForPostCallout.isEmpty()){
			System.enqueueJob(new ContactCalloutQueueable('POST', contactsForPostCallout));
		}
}