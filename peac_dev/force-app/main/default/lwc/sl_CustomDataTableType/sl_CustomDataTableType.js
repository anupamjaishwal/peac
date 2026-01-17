import LightningDatatable from 'lightning/datatable';
import picklistColumn from './picklistColumn.html';
import pickliststatic from './pickliststatic.html';
import requiredColumn from './requiredColumn.html';

export default class Sl_CustomDataTableType extends LightningDatatable {
  static customTypes = {
    picklistColumn: {
      template: pickliststatic,
      editTemplate: picklistColumn,
      standardCellLayout: true,
      typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant','name']
    },
    requiredColumn: {
      template: pickliststatic,
      editTemplate: requiredColumn,
      standardCellLayout: true,
      typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant','name']
    }
  };
}