@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
global with sharing class PromoteAction extends PromoteActionService implements JobExecutionCallback {
    private static final String PROMOTED_USER_STORY = 'Promoted User Story: ';
    private static final String BACK_PROMOTED_USER_STORY = 'Back Promoted User Story: ';
    private static CreateExecutionRequestData requestData;

    global class Request {
        @InvocableVariable(
            label='Promotion Id'
            description='Id of the Promotion record. If it is not defined, Copado will create a new promotion with the parameter values provided.'
        )
        global Id promotionId;
        @InvocableVariable(label='User Story Ids' description='Ids of the user stories to be included in the promotion.')
        global List<Id> userStoryIds = new List<Id>();
        @InvocableVariable(label='Execute Promotion' description='Include this parameter if you want to run the promote job template.')
        global Boolean executePromotion = true;
        @InvocableVariable(
            label='Execute Deployment'
            description='Include this parameter if you want to run the deploy job template after the promote job template execution.'
        )
        global Boolean executeDeployment = false; // this is for promote+deplos US, validate US, and validate promotion
        @InvocableVariable(label='Deployment Dry Run' description='Include this parameter if you want to perform a validation-only deployment.')
        global Boolean deploymentDryRun = false; // NOTE: this is "validate only", but more generic for other technologies
        @InvocableVariable(label='Other Information' description='Additional information that can be passed for the job execution in JSON format')
        global String otherInformation; // "other information" in json, additional values associated with this commit
        @InvocableVariable(
            label='Source Environment Id'
            description='Id of the promotion’s source environment. Copado will use this parameter to populate the destination environment if no promotion Id is specified.'
        )
        global Id sourceEnvironmentId;
        @InvocableVariable(
            label='Project Id'
            description='Id of the Project record that will be used to define the pipeline details and pipeline connections.'
        )
        global Id projectId;
        @InvocableVariable(label='Back Promotion' description='Include this parameter if the promotion that will be executed is a back-promotion.')
        global Boolean isBackPromotion = false;
        @InvocableVariable(label='Action Callback' description='Apex Callback Class that implements JobExecutionCallback')
        global String actionCallback;
    }

    global class Response {
        @InvocableVariable
        global JobExecution__c jobExecution;
        @InvocableVariable
        global Promotion__c promotion;
    }

    // GLOBAL

    @InvocableMethod(label='Run a Copado promote' description='' category='Copado Multi-Cloud')
    global static List<Response> promote(List<Request> requests) {
        requestData = new CreateExecutionRequestData();
        // Note: No need of bulkification, so keep it simple
        Request request = requests[0];
        requestData.promotionId = request.promotionId != null ? request.promotionId : null;
        requestData.executePromotion = request.executePromotion != null ? request.executePromotion : false;
        requestData.executeDeployment = request.executeDeployment != null ? request.executeDeployment : false;
        requestData.deploymentDryRun = request.deploymentDryRun != null ? request.deploymentDryRun : false;
        requestData.otherInformation = request.otherInformation != null ? request.otherInformation : null;
        requestData.userStoryIds = request.userStoryIds;

        if (String.isEmpty(request.promotionId)) {
            Promotion__c promotion = createPromotionRecord(request);
            requestData.promotion = insertPromotions(new List<Promotion__c>{ promotion })[0];
            requestData.promotionId = requestData.promotion.Id;

            if (requestData.executePromotion && requestData.userStoryIds.isEmpty()) {
                throw new PromoteActionServiceException(Label.Please_add_at_least_one_user_story_to_your_promotion);
            }

            // Create the Promoted User Stories object with the data in the requestData
            List<Promoted_User_Story__c> promotedUserStories = new List<Promoted_User_Story__c>();
            for (User_Story__c userStory : userStories(requestData.userStoryIds)) {
                promotedUserStories.add(createPromotedUserStoryRecord(requestData.promotion, userStory));
            }
            insertPromotedUserStories(promotedUserStories);

            processPromotion();
            processJobExecution();
        } else {
            requestData.promotionId = request.promotionId;

            JobExecution__c jobExecution = new JobExecutionsSelector().byPromotionId(requestData.promotionId);
            processPromotion();
            if (jobExecution != null) {
                updateJobExecutionDataJson(jobExecution.Id, requestData);
                runOutstandingJobs(jobExecution.Id);
            } else {
                processJobExecution();
            }
        }

        Response responseRecord = new Response();
        responseRecord.jobExecution = new JobExecutionsSelector().byPromotionId(requestData.promotionId);
        responseRecord.promotion = requestData.promotion;
        return new List<Response>{ responseRecord };
    }

    // Callback after the job finishes
    global void execute(JobExecution__c job, String status) {
        requestData = (CreateExecutionRequestData) JSON.deserialize(job.DataJson__c, CreateExecutionRequestData.class);
        getPromotionDetails(requestData);
        Boolean jobIsSuccess = status == PromoteActionService.SUCCESSFUL;
        Boolean hasConflict = checkLatestResultForConflict(job.Id);

        if (jobIsSuccess && !hasConflict && requestData.executeDeployment) {
            createDeploymentAndJobExecution(true);
            updateLastDeploymentJobExecutionId();
        } else {
            PromotionTriggerHelper.resetUserStories = false;
            String promotionStatus = hasConflict
                ? PromoteActionService.MERGE_CONFLICT
                : jobIsSuccess ? PromoteActionService.COMPLETED : PromoteActionService.COMPLETED_WITH_ERRORS;
            updatePromotion(job.ParentId__c, promotionStatus, hasConflict);

            if (jobIsSuccess && !hasConflict && !isDeploymentJobExecutionCreated(job.ParentId__c)) {
                createDeploymentAndJobExecution(false);
                updateLastDeploymentJobExecutionId();
            }
        }

        PromoteActionService.runActionCallback(requestData.actionCallback, job, status);
    }

    // PUBLIC

    public static List<Promotion__c> insertPromotions(List<Promotion__c> promotions) {
        PromotionTriggerHelper.createJobExecution = false;
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, promotions);
        insert decision.getRecords();
        return (List<Promotion__c>) decision.getRecords();
    }

    public static Promotion__c createPromotionRecord(Request request) {
        // Create the Promotion object with the data in the request
        Promotion__c promotion = new Promotion__c();
        promotion.Project__c = request.projectId;
        promotion.Back_Promotion__c = request.isBackPromotion;

        // PromotionTriggerHelper.setDestinationOrgFromFlow will populate necessary fields
        // TODO: move the logic in a helper class
        if (request.isBackPromotion) {
            promotion.Destination_Environment__c = request.sourceEnvironmentId;
        } else {
            promotion.Source_Environment__c = request.sourceEnvironmentId;
        }
        return promotion;
    }

    public static Promoted_User_Story__c createPromotedUserStoryRecord(Promotion__c promotion, User_Story__c userStory) {
        Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c();
        promotedUserStory.Name = promotedUserStoryName(promotion, userStory.Name);
        promotedUserStory.Promotion__c = promotion.Id;
        promotedUserStory.User_Story__c = userStory.Id;
        return promotedUserStory;
    }

    public static void insertPromotedUserStories(List<Promoted_User_Story__c> promotedUserStories) {
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, promotedUserStories);
        insert decision.getRecords();
    }

    // PRIVATE

    private static List<User_Story__c> userStories(List<Id> userStoryIds) {
        return [SELECT Id, Name FROM User_Story__c WHERE Id IN :userStoryIds WITH SECURITY_ENFORCED];
    }

    private static String promotedUserStoryName(Promotion__c promotion, String userStoryName) {
        return promotion.Back_Promotion__c ? BACK_PROMOTED_USER_STORY + userStoryName : PROMOTED_USER_STORY + userStoryName;
    }

    private static void processPromotion() {
        getPromotionDetails(requestData);
        List<Promoted_User_Story__c> promotedUserStories = new PromotedUserStoriesSelector().byPromotionId(new Set<Id>{ requestData.promotionId });

        if (requestData.executePromotion && promotedUserStories.isEmpty()) {
            throw new PromoteActionServiceException(Label.Please_add_at_least_one_user_story_to_your_promotion);
        }

        requestData.isBackPromotion = !promotedUserStories.isEmpty() ? promotedUserStories[0].Promotion__r.Back_Promotion__c : false;
        requestData.sourceCredentialId = !promotedUserStories.isEmpty() ? promotedUserStories[0].Promotion__r.Source_Org_Credential__c : null;
        requestData.destinationCredentialId = !promotedUserStories.isEmpty()
            ? promotedUserStories[0].Promotion__r.Destination_Org_Credential__c
            : null;
        requestData.gitTag = !promotedUserStories.isEmpty() && promotedUserStories[0].Promotion__r.Release__c != null
            ? promotedUserStories[0].Promotion__r.Release__r.Version__c
            : null;

        requestData.promotionBranchName = 'promotion/' + requestData.promotion.Name;
        requestData.destinationBranchName = destinationBranchName(requestData.promotion);

        populateUserStoryParameters(requestData, promotedUserStories);
        populateChangeParameters(requestData);
        populateFileParameters(requestData, requestData.promotionId, 'Copado Promotion changes.json');
    }

    private static void executePromoteJobTemplate() {
        String templateName = promotionTemplateApiName(requestData.promotion);
        String parentId = requestData.promotionId;
        String callbackClass = Settings.ns.replace('__', '.') + 'PromoteAction';
        CreateExecution.execute(asRequests(requestData, templateName, parentId, callbackClass));
        // TODO: volume options
    }

    private static String promotionTemplateApiName(Promotion__c promotion) {
        String overridenTemplate = promotion.Destination_Environment__r.Promotion_Job_Template_Override__r?.ApiName__c;

        String templateApiName = '';
        if (promotion.Project__c != null) {
            templateApiName = promotion.Project__r.Deployment_Flow__r.Promotion_Job_Template__r.ApiName__c;
        } else if (promotion.Release__c != null) {
            templateApiName = promotion.Release__r.Project__r.Deployment_Flow__r.Promotion_Job_Template__r.ApiName__c;
        }
        return (overridenTemplate != null) ? overridenTemplate : templateApiName;
    }

    private static Boolean isDeploymentJobExecutionCreated(Id promotionId) {
        Deployment__c deployment = new DeploymentsSelector().byPromotionId(promotionId);
        if (deployment == null) {
            return false;
        }
        String jobExecutionId = new JobExecutionsSelector().byDeploymentId(deployment.Id)?.Id;
        return String.isNotBlank(jobExecutionId);
    }

    private static void createDeploymentAndJobExecution(Boolean excuteDeployment) {
        List<PromotionDeployAction.Request> requests = new List<PromotionDeployAction.Request>();
        PromotionDeployAction.Request request = new PromotionDeployAction.Request();
        request.promotionId = requestData.promotionId;
        request.executeDeployment = excuteDeployment;
        request.deploymentDryRun = requestData.deploymentDryRun;
        request.otherInformation = requestData.otherInformation;
        requests.add(request);

        PromotionDeployAction.deploy(requests);
    }

    private static void processJobExecution() {
        executePromoteJobTemplate();

        Id promotionJobExecutionId = new JobExecutionsSelector().byPromotionId(requestData.promotionId).Id;
        List<SObject> records = new List<SObject>{
            new Promotion__c(Id = requestData.promotionId, Last_Promotion_Execution_Id__c = promotionJobExecutionId)
        };

        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
    }

    private static void updateLastDeploymentJobExecutionId() {
        Deployment__c deployment = new DeploymentsSelector().byPromotionId(requestData.promotionId);
        Id deploymentJobExecutionId = new JobExecutionsSelector().byDeploymentId(deployment.Id).Id;

        List<SObject> records = new List<SObject>{
            new Promotion__c(Id = requestData.promotionId, Last_Deployment_Execution_Id__c = deploymentJobExecutionId)
        };

        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
    }

    private static Boolean checkLatestResultForConflict(Id jobExecutionId) {
        Result__c latestResult = new ResultsSelector().byJobExecutionId(jobExecutionId);
        String statusText = '';

        if (String.isNotBlank(latestResult.Result_Data__c)) {
            try {
                Map<String, Object> valuesByParamaters = (Map<String, Object>) JSON.deserializeUntyped(latestResult.Result_Data__c);
                statusText = (String) valuesByParamaters.get('status');
            } catch (Exception error) {
                // for internal troubleshooting purposes
                System.debug(LoggingLevel.ERROR, error.getMessage() + ': ' + error.getStackTraceString());
            }
        }

        return String.isNotBlank(statusText) && statusText == 'conflicts';
    }
}