<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_Location_picklist_value_to_text</fullName>
        <field>Location_Copy__c</field>
        <formula>TEXT( Location__c )</formula>
        <name>Copy Location picklist value to text</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Copy Location picklist value to text</fullName>
        <actions>
            <name>Copy_Location_picklist_value_to_text</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Copies the picklist value to a read only text field so you can reference the value from a child record formlula field</description>
        <formula>TRUE</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
