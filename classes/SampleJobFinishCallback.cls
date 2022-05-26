global with sharing class SampleJobFinishCallback {
       global void execute(Account job, String status) {
           String test;
           System.debug('tetst');
           // Start execution of next job template
           // The callback context is Automated process user
       }
   }