/* eslint-disable no-console */
import { LightningElement, track, api } from 'lwc';
import * as SLVHelper from 'c/simpliUIListViewsHelper';

//------------------------ LABELS ------------------------
import Close from '@salesforce/label/c.Close';

import createAction from '@salesforce/apex/ListViewAdminController.createAction';

export default class SimpliUIListViewsActionCreateWizardModal extends LightningElement {

    @api showModal;                       //indicates whether this modal dialog should be displayed or not.
    @track inRenderedCallback = false;    //indicates whether the rendered callback method is processing
    @track currentStep = '1';
    @track headerLabel = 'Basic Action Details';
    @track spinner = false;

    @track selectedActionRecordType = '';    //the record type selected by the user for the action
    @track selectedActionHasObject = '';     //whether the action is specific to an object
    @track selectedActionHasObjectDisabled = undefined;     //if the action is custom the object is required
    @track selectedActionType = '';          //the type of action the user selected.
    @track selectedActionSubType = '';       //the subtype of action the user selected.
    @track selectedActionIsActive = '';      //whether the action is active or not.
    @track selectedActionObjectType = '';    //if the action is specific to an object this holds the object type.
    @track selectedActionLabel = '';         //the action label.
    @track selectedActionRecordVisible = 'Always Displayed'; //how many records need to be selected for the action to be displayed
    @track selectedActionUserPermissions = '';
    @track selectedActionHasComponent = '';
    @track selectedActionComponentName = '';
    @track showSubType = false;              //indicates whether the action subtype combobox should be displayed
    @track hasActionType = false;            //indicates whether an action type has been selected
    @track actionHasObject = false;          //indicates whether the action is specific to an object
    @track actionHasComponent = false;       //indicates whether the action is specific to a component
    @track actionParams = new Map();         //holds the enhanced action parameters.
    @track calloutCount = 1;            //indicates the number of callouts made for this component

    get isSendEmailClassic() { return this.selectedActionType === "EmailClassic"; }
    get isSendEmailTemplate() { return this.selectedActionType === "EmailTemplate"; }
    get isHyperlink() { return this.selectedActionType === "Hyperlink"; }
    get isLaunchFlow() { return this.selectedActionType === "LaunchFlow"; }
    get isLightningComponent() { return this.selectedActionType === "LightningComponent"; }
    get isScreenFlow() { return this.selectedActionType === "ScreenFlow"; }
    get isManageData() { return this.selectedActionType === "ManageData"; }
    get isSaveToPDF() { return this.selectedActionType === "SaveToPDF"; }
    get isCustom() { return this.selectedActionType === "Custom"; }

    get isManageCreate() { return this.selectedActionSubType === "Create"; }
    get isManageEdit() { return this.selectedActionSubType === "Edit"; }
    get isManageEditAll() { return this.selectedActionSubType === "EditAll"; }
    get isManageClone() { return this.selectedActionSubType === "Clone"; }
    get isManageDelete() { return this.selectedActionSubType === "Delete"; }
    get isManageMassCreate() { return this.selectedActionSubType === "MassCreate"; }
    get isManageMassUpdate() { return this.selectedActionSubType === "MassUpdate"; }

    get isStepOne() { return this.currentStep === "1"; }
    get isStepTwo() { return this.currentStep === "2"; }
    get isStepThree() { return this.currentStep === "3"; }
    get isStepFour() { return this.currentStep === "4"; }
    get isEnableNext() { return this.currentStep !== "4"; }
    get isEnablePrev() { return this.currentStep !== "1"; }
    get isEnableSave() { return this.currentStep === "4"; }

    get strIsActive() { return this.booleanToYesNo(this.selectedActionIsActive); }
    get strActionHasObject() { return this.booleanToYesNo(this.selectedActionHasObject); }
    get strSpecificToLtn() { return this.booleanToYesNo(this.selectedActionHasComponent); }

    booleanToYesNo(value) {
        if (value === 'true') return 'Yes';
        return 'No';
    }

    get actionRecordTypes() {
        return [
            { label: 'Core', value: 'Core' },
            { label: 'Custom', value: 'Custom' },
        ];
    }

    get booleanList() {
        return [
            { label: 'Yes', value: 'true' },
            { label: 'No', value: 'false' },
        ];
    }

    get userPermissionsList() {
        return [
            { label: 'Read', value: 'Read' },
            { label: 'Create', value: 'Create' },
            { label: 'Edit', value: 'Edit' },
            { label: 'Delete', value: 'Delete' },
        ];
    }

    get recVisibleList() {
        return [
            { label: 'Always Displayed', value: 'Always Displayed' },
            { label: 'Displayed if multiple records are selected', value: 'Displayed if multiple records are selected' },
            { label: 'Displayed if no records are selected', value: 'Displayed if no records are selected' },
            { label: 'Displayed if one or more records are selected', value: 'Displayed if one or more records are selected' },
            { label: 'Displayed if one record is selected', value: 'Displayed if one record is selected' },
            { label: 'Displayed if zero or one record is selected', value: 'Displayed if zero or one record is selected' },
        ];
    }

    get actionTypes() {
        return [
            { label: 'Send Email', value: 'EmailClassic' },
            { label: 'Send Email From Template', value: 'EmailTemplate' },
            { label: 'Hyperlink', value: 'Hyperlink' },
            { label: 'Auto-Launch Flow', value: 'LaunchFlow' },
            { label: 'Screen Flow', value: 'ScreenFlow' },
            { label: 'Display Lightning Component', value: 'LightningComponent' },
            { label: 'Manage Data (create, edit, delete, clone)', value: 'ManageData' },
            { label: 'Save To PDF', value: 'SaveToPDF' },
            { label: 'Custom Action', value: 'Custom' },
        ];
    }

    get actionSubTypes() {
        return [
            { label: 'Create (create a new record)', value: 'Create' },
            { label: 'Edit (edit a single record)', value: 'Edit' },
            { label: 'Clone (clone a single record)', value: 'Clone' },
            { label: 'Mass Create (mass create multiple new records)', value: 'MassCreate' },
            { label: 'Mass Edit (edit all records using inline editing)', value: 'EditAll' },
            { label: 'Mass Update (update records using defined custom Apex class)', value: 'MassUpdate' },
            { label: 'Mass Delete (delete records)', value: 'Delete' },
        ];
    }

    get displayOrderList() {
        return [
            { label: '-1', value: '-1' },
            { label: '1 (Top)', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' },
            { label: '5', value: '5' },
            { label: '6', value: '6' },
            { label: '7', value: '7' },
            { label: '8', value: '8' },
            { label: '9', value: '9' },
            { label: '10', value: '10' },
        ];
    }

    get massUpdateRowIndexes() {
        return [2, 3, 4, 5, 6, 7, 8];
    }

    label = { Close };

    constructor() {
        super();
        this.showModal = false;
    }

    renderedCallback() {
        if (this.showModal === true && this.inRenderedCallback === false) {
            this.inRenderedCallback = true;
        }
    }

    //-----------------------------------------------------------------------------
    // HANDLERS FOR MOVEMENT TO EACH STAGE
    //-----------------------------------------------------------------------------

    handleNext() {
        if (this.currentStep === "1") {
            if (this.validateStepOne())
                this.handleGoToStepTwo();
        } else if (this.currentStep === "2") {
            if (this.validateStepTwo())
                this.handleGoToStepThree();
        } else if (this.currentStep === "3") {
            if (this.validateStepThree())
                this.handleGoToStepFour();
        }
        console.log('Moved current step to - ' + this.currentStep);
    }

    handlePrev() {
        if (this.currentStep === "4")
            this.handleGoToStepThree();
        else if (this.currentStep === "3")
            this.handleGoToStepTwo();
        else if (this.currentStep === "2")
            this.handleGoToStepOne();
    }

    handleGoToStepOne() {
        this.currentStep = "1";
        this.headerLabel = 'Basic Action Details';
    }

    validateStepOne() {
        if (this.selectedActionRecordType === ''
            || this.selectedActionType === ''
            || this.selectedActionLabel === ''
            || this.selectedActionIsActive === '') {
            this.dispatchEvent(SLVHelper.createToast('error', '', 'Required Field Missing', 'A required field is missing', false));
            return false;
        }

        if (this.selectedActionType === 'ManageData' && this.selectedActionSubType === '') {
            this.dispatchEvent(SLVHelper.createToast('error', '', 'Required Field Missing', 'A required field is missing', false));
            return false;
        }

        return true;
    }

    handleGoToStepTwo() {
        this.currentStep = "2";
        this.headerLabel = 'Enhanced Action Details';
        this.actionParams.set('actionRecordType', this.selectedActionRecordType);
        this.actionParams.set('actionType', this.selectedActionType);
        this.actionParams.set('actionSubType', this.selectedActionSubType);
        this.actionParams.set('actionLabel', this.selectedActionLabel);
        this.actionParams.set('actionIsActive', this.selectedActionIsActive);
    }

    validateStepTwo() {
        if ((this.selectedActionType === 'Hyperlink' && this.actionParams.get('hyperlinkURL') === undefined)
            || (this.selectedActionType === 'EmailTemplate' && this.actionParams.get('sendEmailTemplateFolderName') === undefined)
            || (this.selectedActionType === 'LaunchFlow' && this.actionParams.get('launchFlowAPIName') === undefined)
            || (this.selectedActionType === 'ScreenFlow' && this.actionParams.get('screenFlowAPIName') === undefined)
            || (this.selectedActionType === 'LightningComponent' && this.actionParams.get('lwcComponentAPIName') === undefined)
            || (this.selectedActionType === 'Custom' && this.actionParams.get('customApexClassName') === undefined)
        ) {
            this.dispatchEvent(SLVHelper.createToast('error', '', 'Required Field Missing', 'A required field is missing', false));
            return false;
        }

        return true;
    }

    handleGoToStepThree() {
        this.currentStep = "3";
        this.headerLabel = 'Accessibility';

        if (this.selectedActionRecordType === 'Custom') {
            this.selectedActionHasObject = 'true';
            this.actionHasObject = true;
            this.selectedActionHasObjectDisabled = true;
        } else {
            this.selectedActionHasObjectDisabled = undefined;
        }
    }

    validateStepThree() {
        if (this.selectedActionHasObject === ''
            || this.selectedActionHasComponent === ''
            || this.selectedActionRecordVisible === '') {
            this.dispatchEvent(SLVHelper.createToast('error', '', 'Required Field Missing', 'A required field is missing', false));
            return false;
        }

        if ((this.selectedActionHasObject === 'true' && this.selectedActionObjectType === '')
            || (this.selectedActionHasComponent === 'true' && this.selectedActionComponentName === '')) {
            this.dispatchEvent(SLVHelper.createToast('error', '', 'Required Field Missing', 'A required field is missing', false));
            return false;
        }

        return true;
    }

    handleGoToStepFour() {
        this.currentStep = "4";
        this.headerLabel = 'Review And Save';
        this.actionParams.set('actionHasObject', this.selectedActionHasObject);
        this.actionParams.set('actionObjectType', this.selectedActionObjectType);
        this.actionParams.set('actionHasComponent', this.selectedActionHasComponent);
        this.actionParams.set('actionComponentName', this.selectedActionComponentName);
        this.actionParams.set('actionRecordVisible', this.selectedActionRecordVisible);
        this.actionParams.set('actionUserPermissions', this.selectedActionUserPermissions);
    }

    handleSave() {
        let params = JSON.stringify(Array.from(this.actionParams));
        this.spinnerOn();
        console.log('All params - ' + params);
        console.log(this.pageName + ' CALLOUT - createAction - ' + this.calloutCount++);
        createAction({ actionFields: params })
            .then(result => {
                console.log('RESULT - ' + result);
                if (result === 'success') {
                    this.clearData();
                    this.dispatchEvent(new CustomEvent('finished'));
                    this.dispatchEvent(SLVHelper.createToast('success', '', 'Action Created', 'Action successfully created.', false));
                } else {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Action Create Error', 'There was a problem creating the action - ' + result, false));
                }
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Action Create Error', 'There was a problem creating the action.', true));
            }).finally(() => {
                this.spinnerOff();
            });
    }

    handleCancelClick() {
        this.clearData();
        this.dispatchEvent(new CustomEvent('cancelled'));
    }

    handleClose() {
        this.clearData();
        this.dispatchEvent(new CustomEvent('cancelled'));
    }

    //-----------------------------------------------------------------------------
    // HANDLERS FOR EACH FIELD UPDATE
    //-----------------------------------------------------------------------------

    handleActionRecordTypeSelected(event) {
        try {
            const { target } = event;
            this.selectedActionRecordType = target?.value ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionIsActiveSelected(event) {
        try {
            const { target } = event;
            this.selectedActionIsActive = target?.value ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionLabelSelected(event) {
        try {
            const { target } = event;
            this.selectedActionLabel = target?.value ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionTypeSelected(event) {
        try {
            const { target } = event;
            this.selectedActionType = target?.value ?? '';
            this.hasActionType = true;

            if (this.selectedActionType === 'ManageData')
                this.showSubType = true;
            else
                this.showSubType = false;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionSubTypeSelected(event) {
        try {
            const { target } = event;
            this.selectedActionSubType = target?.value ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionHasObjectSelected(event) {
        try {
            const { target } = event;
            this.selectedActionHasObject = target?.value ?? '';
            if (this.selectedActionHasObject === 'true')
                this.actionHasObject = true;
            else
                this.actionHasObject = false;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionObjectTypeSelected(event) {
        try {
            const { target } = event;
            this.selectedActionObjectType = target?.value ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionRecordVisibleSelected(event) {
        try {
            const { target } = event;
            this.selectedActionRecordVisible = target?.value ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionHasComponentSelected(event) {
        try {
            const { target } = event;
            this.selectedActionHasComponent = target?.value ?? '';
            if (this.selectedActionHasComponent === 'true')
                this.actionHasComponent = true;
            else
                this.actionHasComponent = false;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionComponentNameSelected(event) {
        try {
            const { target } = event;
            this.selectedActionComponentName = target?.value ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleActionUserPermissionsSelected(event) {
        try {
            const { target } = event;
            this.selectedActionUserPermissions = target?.value ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }


    handleActionParameterAdded(event) {
        try {
            const { currentTarget, detail, target } = event;
            if (currentTarget?.dataset?.paramName === undefined) {
                let fieldValue = detail?.selectedValue ?? '';
                let rowId = detail?.rowId ?? '';
                let paramName = detail?.field ?? '';
                if (paramName === 'simpli_lv__Type__c') //this field uses picklist widget so data comes in differently
                    paramName = 'manageDataMassUpdateType' + rowId;
                else
                    paramName = paramName + rowId;

                this.actionParams.set(paramName, fieldValue);
                console.log('Action param name/value - ' + paramName + '/' + fieldValue);

            } else {
                let paramName = currentTarget?.dataset?.paramName ?? '';
                let fieldValue = target?.value ?? '';
                if (paramName === 'manageDataCreateRedirectField') //this field is a boolean so is handled differently
                {
                    if (target?.checked === true)
                        fieldValue = 'true';
                    else
                        fieldValue = 'false';
                }
                if (currentTarget.dataset.paramRowIndex !== undefined)
                    paramName = paramName + currentTarget.dataset.paramRowIndex;
                this.actionParams.set(paramName, fieldValue);
                console.log('Action param name/value - ' + paramName + '/' + fieldValue);
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    //-----------------------------------------------------------------------------
    // HELPER METHODS
    //-----------------------------------------------------------------------------

    clearData() {
        this.currentStep = '1';
        this.headerLabel = 'Basic Action Details';

        this.selectedActionRecordType = '';
        this.selectedActionHasObject = '';
        this.selectedActionType = '';
        this.selectedActionSubType = '';
        this.selectedActionIsActive = '';
        this.selectedActionObjectType = '';
        this.selectedActionLabel = '';
        this.selectedActionRecordVisible = 'Always Displayed';
        this.selectedActionUserPermissions = '';
        this.selectedActionHasComponent = '';
        this.selectedActionComponentName = '';
        this.showSubType = false;
        this.hasActionType = false;
        this.actionHasObject = false;
        this.actionHasComponent = false;
        this.actionParams = new Map();
    }

    spinnerOn() {
        this.spinner = true;
        console.log('Spinner ON for SimpliUIListViewsActionCreateWizardModal');
    }

    spinnerOff() {
        this.spinner = false;
        console.log('Spinner OFF for SimpliUIListViewsActionCreateWizardModal');
    }
}