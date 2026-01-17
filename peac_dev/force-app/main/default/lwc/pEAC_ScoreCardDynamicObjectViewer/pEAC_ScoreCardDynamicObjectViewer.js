import { LightningElement, api, wire } from 'lwc';
import fetchData from '@salesforce/apex/PEAC_GdsScoreCardViewController.fetchScorecrdData';

export default class PEAC_ScoreCardDynamicObjectViewer extends LightningElement {

@api recordId;

records = []; // Array of all fields from all objects combined
error;

// Wire Apex method
@wire(fetchData, { opportunityId: '$recordId' })
wiredData({ error, data }) {
if (data) {
this.records = [];

// Flatten fields from all objects into one array
for (let obj in data) {
for (let [key, value] of Object.entries(data[obj])) {
this.records.push({ key, value });

}
}
console.log( JSON.stringify(this.records));
this.error = undefined;
} else if (error) {
this.error = error.body.message;
this.records = [];
}
}
}