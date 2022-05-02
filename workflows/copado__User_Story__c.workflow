<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Exclude_from_CBM</fullName>
        <field>copado__Exclude_From_CBM__c</field>
        <literalValue>1</literalValue>
        <name>Exclude from CBM</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Stop_Index</fullName>
        <field>copado__Stop_Indexing_Metadata__c</field>
        <literalValue>1</literalValue>
        <name>Stop Index</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>US Finished</fullName>
        <actions>
            <name>Exclude_from_CBM</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Stop_Index</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>copado__User_Story__c.copado__Status__c</field>
            <operation>equals</operation>
            <value>Completed</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
