<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Updated_User_Account_with_Account_Id</fullName>
        <description>This field udpdate will copy the Account Id to the User Accounf SFDC Account Id Field</description>
        <field>SFDC_Account_Id__c</field>
        <formula>Contact.AccountId</formula>
        <name>Updated User Account with Account Id</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Updated User Account with Account Id</fullName>
        <actions>
            <name>Updated_User_Account_with_Account_Id</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.IsPortalEnabled</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>This workflow is used to copy the Account Id field to the User SFDC account field</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
