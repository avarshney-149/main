<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>MDVIP_FU_1</fullName>
        <field>MDVIP_Test_Control__c</field>
        <literalValue>Controller One</literalValue>
        <name>MDVIP FU 1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>MDVIP_FU_2</fullName>
        <field>MDVIP_WFU_1__c</field>
        <literalValue>1</literalValue>
        <name>MDVIP FU 2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>MDVIP_FU_3</fullName>
        <field>MDVIP_WFU_2__c</field>
        <literalValue>1</literalValue>
        <name>MDVIP FU 3</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>MDVIP_FU_4</fullName>
        <field>MDVIP_WFU_4__c</field>
        <literalValue>1</literalValue>
        <name>MDVIP FU 4</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>MDVIP_FU_5</fullName>
        <field>MDVIP_WFU_4__c</field>
        <literalValue>1</literalValue>
        <name>MDVIP FU 5</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>MDVIP WF Test</fullName>
        <actions>
            <name>MDVIP_FU_1</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>MDVIP_FU_2</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>MDVIP_FU_3</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>MDVIP_FU_4</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>MDVIP_FU_5</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>User.IsActive</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
