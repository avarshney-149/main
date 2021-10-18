import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import { reduceErrors } from 'c/copadocoreUtils';
import COPADO_ALERT_CHANNEL from '@salesforce/messageChannel/CopadoAlert__c';

import PULL_REQUEST_BASE_URL from '@salesforce/schema/Promotion__c.Project__r.Deployment_Flow__r.Git_Repository__r.Pull_Request_Base_URL__c';
import PROMOTION_NAME from '@salesforce/schema/Promotion__c.Name';

export default class PromotePullRequest extends LightningElement {
    @api recordId;
    pullRequestBase= '';
    promotionN = '';
    communicationId = 'promotionRecordPageAlerts';
    modalCommunicationId = 'modalAlerts';

    @wire(getRecord, { recordId: '$recordId', fields: PULL_REQUEST_BASE_URL, optionalFields : PROMOTION_NAME})
    promotion;

    get baseURL(){
        this.pullRequestBase = getFieldValue(this.promotion.data, PULL_REQUEST_BASE_URL);
        console.log('pullRequestBase', this.pullRequestBase);
        return getFieldValue(this.promotion.data, PULL_REQUEST_BASE_URL);
    }

    get promotionName(){
        this.promotionN = getFieldValue(this.promotion.data, PROMOTION_NAME);
        return getFieldValue(this.promotion.data, PROMOTION_NAME);
    }

    
    openPullRequest() {
        if (this.pullRequestBase && this.pullRequestBase != '') {
            try {
                var promotionURL = this.pullRequestBase + 'promotion/'+this.promotionN;
                window.open(promotionURL);
            } catch (e) {
                console.log('openPullRequest::error', e);
            }
        } else {
           console.log('pull request empty');
           this.messageAlert('The Git Repository pull request base url is empty', 'error', true, this.communicationId);
        }
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
      }

    messageAlert(message, variant, dismissible, communicationId) {
        const payload = {
            variant,
            message,
            dismissible,
            communicationId
        };
        publish(this.messageContext, COPADO_ALERT_CHANNEL, payload);
    }
}