import { LightningElement, api } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class Sl_CustomInputToogle extends LightningElement {
  @api label = 'Toggle Label';
  @api toogleState = false;

  handleToggle(evt){
    this.toogleState  = evt.target.checked;
    this.dispatchEvent(new FlowAttributeChangeEvent('toogleState', this.toogleState));
  }
}