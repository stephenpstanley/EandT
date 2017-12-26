<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_Email_Valuie</fullName>
        <field>Email_Copy__c</field>
        <formula>PersonEmail</formula>
        <name>Copy Email Valuie</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Copy email from person account</fullName>
        <actions>
            <name>Copy_Email_Valuie</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.PersonEmail</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Because we are using Person Accounts, there are two emails Account and Contact. Standard UI edits the Account email, not contact email, so you need to copy the email address from Account to Contact to allow it to be referenced by some code sections</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Tsk renew CCard</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Account.Upd__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Create task to remind account record owner to get a student to renew their CCard</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
