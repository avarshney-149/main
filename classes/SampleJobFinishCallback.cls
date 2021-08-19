global with sharing class SampleJobFinishCallback implements JobExecutionCallback {
       global void execute(JobExecution__c job, String status) {
           // Start execution of next job template
           // The callback context is Automated process user
       }
   }