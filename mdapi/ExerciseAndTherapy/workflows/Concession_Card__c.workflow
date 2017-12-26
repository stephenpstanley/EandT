<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_email_to_Concession_card_holder_to_get_them_to_renew_it</fullName>
        <description>Send email to Concession card holder to get them to renew it</description>
        <protected>false</protected>
        <recipients>
            <field>Owner_email__c</field>
            <type>email</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Exercise_Therapy_Email_Templates/Concession_Card_Expiry</template>
    </alerts>
    <fieldUpdates>
        <fullName>Copy_EMail_to_CCard</fullName>
        <field>Owner_email__c</field>
        <formula>Customer__r.Email_Copy__c</formula>
        <name>Copy EMail to CCard</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Nullify_Email_sent_date</fullName>
        <field>Expiry_Reminder_Sent__c</field>
        <name>Nullify Email sent date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Reminder_Sent_Date</fullName>
        <description>Set the date that the email reminder was sent to the owner</description>
        <field>Expiry_Reminder_Sent__c</field>
        <formula>Today()</formula>
        <name>Populate Reminder Sent Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Reminder_Sent_Date2</fullName>
        <field>Expiry_Reminder_Sent__c</field>
        <formula>today()</formula>
        <name>Populate Reminder Sent Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_CCard_Expiry_Date</fullName>
        <description>Set Expiry date to 4 months beyond Issue Date</description>
        <field>Expiry_Date__c</field>
        <formula>IF( ISBLANK( Expiry_Date__c ) , 
DATE ( 
YEAR ( Issue_Date__c ) + FLOOR ( (MONTH ( Issue_Date__c ) -1 + 4)/12), 
CASE ( MOD ( MONTH ( Issue_Date__c )+4, 12 ),0,12,MOD ( MONTH ( Issue_Date__c )+4, 12 )), 
MIN ( DAY ( Issue_Date__c ), 
CASE ( MOD ( MONTH ( Issue_Date__c )+4,12 ) ,9,30,4,30,6,30,11,30,2,28,31 ) ) 
), 

Expiry_Date__c )</formula>
        <name>Set C-Card Expiry Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Exp_Date</fullName>
        <description>IF blank set exp date to start date plus 4 months</description>
        <field>Expiry_Date__c</field>
        <formula>IF( ISBLANK(  Expiry_Date__c  ) ,  
DATE (
  YEAR ( Issue_Date__c ) + FLOOR ( (MONTH ( Issue_Date__c ) -1 + 4)/12),
  CASE ( MOD ( MONTH ( Issue_Date__c )+4, 12 ),0,12,MOD ( MONTH ( Issue_Date__c )+4, 12 )),
MIN ( DAY ( Issue_Date__c ),
  CASE ( MOD ( MONTH ( Issue_Date__c )+4,12 ) ,9,30,4,30,6,30,11,30,2,28,31 ) )
),  

Expiry_Date__c )</formula>
        <name>Set Exp Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Upd_false</fullName>
        <field>Upd__c</field>
        <literalValue>0</literalValue>
        <name>Upd false</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Customer__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_true</fullName>
        <field>Upd__c</field>
        <literalValue>1</literalValue>
        <name>Update true</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Customer__c</targetObject>
    </fieldUpdates>
    <rules>
        <fullName>Card close to expiring</fullName>
        <actions>
            <name>Send_email_to_Concession_card_holder_to_get_them_to_renew_it</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Populate_Reminder_Sent_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Concession_Card_expires_shortly</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <description>If there are 20% of the original value or sessions left after a card has been used, then send email to card holder  to remind them to renew and update email sent date. Don&apos;t send a reminder email has already been sent</description>
        <formula>(Sessions_Balance__c/Sessions__c  &lt;= 0.2  || 
 Value_Balance__c /  Value__c  &lt;= 0.2 )  &amp;&amp; 
 isblank(Expiry_Reminder_Sent__c)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Copy owners email into local field</fullName>
        <actions>
            <name>Copy_EMail_to_CCard</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.PersonEmail</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>To allow a workflow rule to send an expiry reminder email to the card holder, copy the email field from the holder record into the concession card object if it is blank</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Reset Email reminder</fullName>
        <actions>
            <name>Nullify_Email_sent_date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>If the expiry date is extended to 14 days beyond the email reminder sent date then blank out the email reminder sent date</description>
        <formula>Expiry_Date__c -  Expiry_Reminder_Sent__c &gt; 14</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Send expiry reminder email</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Concession_Card__c.Expiry_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Concession_Card__c.Expiry_Reminder_Sent__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Schedules reminder to send an email if Email sent date is blank</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Send_email_to_Concession_card_holder_to_get_them_to_renew_it</name>
                <type>Alert</type>
            </actions>
            <actions>
                <name>Populate_Reminder_Sent_Date2</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Upd_false</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Update_true</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Concession_Card_expires_shortly</name>
                <type>Task</type>
            </actions>
            <offsetFromField>Concession_Card__c.Expiry_Date__c</offsetFromField>
            <timeLength>-14</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Set C-Card Expiry Date if Blank</fullName>
        <actions>
            <name>Set_CCard_Expiry_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Concession_Card__c.Expiry_Date__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>If blank, sets card expiry date to 4 months after purchase date.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <tasks>
        <fullName>Concession_Card_expires_shortly</fullName>
        <assignedToType>owner</assignedToType>
        <description>The concession card expires soon. Please contact the customer to renew it.

This task was created for one or more of these three reasons:
1 The card&apos;s expiry date is in the next two weeks
2 The card has &lt;20% of the initial value or session count left</description>
        <dueDateOffset>14</dueDateOffset>
        <notifyAssignee>true</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>Concession Card expires shortly</subject>
    </tasks>
</Workflow>
