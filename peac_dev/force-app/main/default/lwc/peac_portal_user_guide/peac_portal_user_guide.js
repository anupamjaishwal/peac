import { LightningElement } from 'lwc';
import userGuide from '@salesforce/resourceUrl/Dealer_Portal_User_Guide'; // Static Resource import
import clickhere from '@salesforce/label/c.PEAC_Download_User_Guide';
import helptext from '@salesforce/label/c.PEAC_Portal_User_Help_Text';
import faqDocument from '@salesforce/resourceUrl/Dealer_Portal_FAQ_Document'; // Static Resource import
import clickhereForFaq from '@salesforce/label/c.PEAC_Dealer_Portal_FAQ_Document';

export default class Peac_portal_user_guide extends LightningElement {
    // Static resource URL
    staticResourceURL = userGuide;
    buttonLabel = clickhere;
    portalhelptext = helptext;
    // Static resource URL
    staticResourceURLFaq = faqDocument;
    buttonLabelForFaq = clickhereForFaq;

    
}