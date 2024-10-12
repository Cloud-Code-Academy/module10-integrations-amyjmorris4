public class ContactCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private String calloutType;
    private List<Contact> contactList;

    // Constructor to set the type of callout and contacts to process
    public ContactCalloutQueueable(String calloutType, List<Contact> contactList) {
        this.calloutType = calloutType;
        this.contactList = contactList;
    }

    // Execute method where the callout happens
    public void execute(QueueableContext context) {
        if (calloutType == 'GET') {
            for (Contact con : contactList) {
                DummyJSONCallout.getDummyJSONUserFromId(con.DummyJSON_Id__c);
            }
        } else if (calloutType == 'POST') {
            for (Contact con : contactList) {
                DummyJSONCallout.postCreateDummyJSONUser(con.Id);
            }
        }
    }
}
