public with sharing class AccExt {
	
	private Account acct;
	public Account getacct(){
		if(acct==null){
			string accId = [select SFDC_Account_Id__c from User where Id =:Userinfo.getUserId()].SFDC_Account_Id__c;
        	this.acct =[select IsPersonAccount,Id,Name,PersonBirthdate,PersonEmail,Sex__pc,PersonMobilePhone,PersonHomePhone,Work_Phone__pc,Fax,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry from Account where Id = :accId];
		}
		return acct;
	}
    
    // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    /*public AccExt(ApexPages.StandardController stdController) {
    	string accId = [select SFDC_Account_Id__c from User where Id =:Userinfo.getUserId()].SFDC_Account_Id__c;
        this.acct =[select Id,Name,PersonBirthdate,PersonEmail,Sex__pc,PersonMobilePhone,PersonHomePhone,Work_Phone__pc,Fax,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry from Account where Id = :accId];
    }*/

    public String getGreeting() {
        return 'Hello ' + getacct().name + ' (' + getacct().id + ')';
    }

}