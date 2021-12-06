import { LightningElement, wire, track, api   } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getOrgWideConfigParam from '@salesforce/apex/ListViewAdminController.getOrgWideConfigParam';
import saveOrgWideConfig from '@salesforce/apex/ListViewAdminController.saveOrgWideConfig';
import scheduleRefreshJob from '@salesforce/apex/ListViewAdminController.scheduleRefreshJob';

import List_View_Refresh_Scheduled from '@salesforce/label/c.List_View_Refresh_Scheduled';
import Select_Time_Period from '@salesforce/label/c.Select_Time_Period';
import Select_X_Minute from '@salesforce/label/c.Select_X_Minute';
import Select_Minute from '@salesforce/label/c.Select_Minute';
import Select_Hour from '@salesforce/label/c.Select_Hour';
import Select_Day from '@salesforce/label/c.Select_Day';
import Select_Month from '@salesforce/label/c.Select_Month';
import Monday from '@salesforce/label/c.Monday';
import Tuesday from '@salesforce/label/c.Tuesday';
import Wednesday from '@salesforce/label/c.Wednesday';
import Thursday from '@salesforce/label/c.Thursday';
import Friday from '@salesforce/label/c.Friday';
import Saturday from '@salesforce/label/c.Saturday';
import Sunday from '@salesforce/label/c.Sunday';
import Schedule from '@salesforce/label/c.Schedule';
import Scheduled from '@salesforce/label/c.Scheduled';
import Unschedule from '@salesforce/label/c.Unschedule';
import Schedule_Core_List_View_Refreshes from '@salesforce/label/c.Schedule_Core_List_View_Refreshes';
import Schedule_Core_List_View_Refreshes_Verbage from '@salesforce/label/c.Schedule_Core_List_View_Refreshes_Verbage';

export default class SimpliUIListViewsScheduleJob extends LightningElement {

    @api isTurnedOn = undefined;
    @api apexClassName = 'Simpli_lv.ListViewPreProcessBatch';
    @api set timePeriod(value) {
        if (value !== undefined)
            this.timePeriodChanged(value);
    }
    get timePeriod() { 
        return this.selectedTimePeriod; 
    }

    @track isInitialized = false;
    @track selectedXMinutes = '5';
    @track selectedMinute = '00';
    @track selectedHour = '00';
    @track selectedDay = Monday;
    @track selectedMonth = '1';
    @track selectedTimePeriod = 'hourly';
    @track displayXMinutes = false;
    @track displayMinutes = false;
    @track displayHours = false;
    @track displayDays = false;
    @track displayMonths = false;
    @track scheduleText = 'Click to schedule automatic core list view refreshes';

    @track spinner = false;             //identifies if the PAGE spinner should be displayed or not.

    @track timePeriodsList = [
        { label: 'Minutely', value: 'minutely' },
        { label: 'Hourly', value: 'hourly' },
        { label: 'Daily', value: 'daily' },
        { label: 'Weekly', value: 'weekly' },
        { label: 'Monthly', value: 'monthly' }
    ];

    @track xMinutePeriodsList = [
        { label: '5', value: '5' }, { label: '10', value: '10' }, { label: '15', value: '15' }, 
        { label: '20', value: '20' }, { label: '30', value: '30' },
    ];

    @track minutePeriodsList = [
        { label: '00', value: '0' }, { label: '05', value: '5' }, { label: '10', value: '10' },
        { label: '15', value: '15' }, { label: '20', value: '20' }, { label: '25', value: '25' },
        { label: '30', value: '30' }, { label: '35', value: '35' }, { label: '40', value: '40' },
        { label: '45', value: '45' }, { label: '50', value: '50' }, { label: '55', value: '55' },
    ];   

    @track hourPeriodsList = [
        { label: '00', value: '0' }, { label: '01', value: '1' }, { label: '02', value: '2' },
        { label: '03', value: '3' }, { label: '04', value: '4' }, { label: '05', value: '5' },
        { label: '06', value: '6' }, { label: '07', value: '7' }, { label: '08', value: '8' },
        { label: '09', value: '9' }, { label: '10', value: '10' }, { label: '11', value: '11' },
        { label: '12', value: '12' }, { label: '13', value: '13' }, { label: '14', value: '14' },
        { label: '15', value: '15' }, { label: '16', value: '16' }, { label: '17', value: '17' },
        { label: '18', value: '18' }, { label: '19', value: '19' }, { label: '20', value: '20' },
        { label: '21', value: '21' }, { label: '22', value: '22' }, { label: '23', value: '23' },
    ];   

    @track dayPeriodsList = [
        { label: Monday, value: 'MON' }, { label: Tuesday, value: 'TUE' },
        { label: Wednesday, value: 'WED' }, { label: Thursday, value: 'THU' },
        { label: Friday, value: 'FRI' }, { label: Saturday, value: 'SAT' },
        { label: Sunday, value: 'SUN' },
    ];   

    @track monthPeriodsList = [
        { label: 'First Day Of Month', value: '1' }, 
        { label: '15th Of Month', value: '15' },
        { label: 'Last Day Of Month', value: 'L' },
    ];   

    label = { List_View_Refresh_Scheduled, Select_Time_Period, Select_Minute, Select_Hour, Select_Day, Select_Month, Monday, Tuesday, Wednesday, Thursday, 
              Friday, Saturday, Sunday, Schedule_Core_List_View_Refreshes, Schedule_Core_List_View_Refreshes_Verbage, Schedule, Scheduled, Unschedule,
              Select_X_Minute };

    
    renderedCallback() {
        if (this.isInitialized === false)
        {
            this.isInitialized = true;
            this.spinnerOn();
            getOrgWideConfigParam({ paramName: 'RefreshJob' })
            .then(result => {

                let refreshJobData = result.value.split(':'); //example - weekly:00:00:Tuesday

                if (refreshJobData[0] !== 'Not Scheduled')
                {                
                    this.isTurnedOn = true;
                    this.selectedTimePeriod = refreshJobData[0]; 

                    if (this.selectedTimePeriod === 'minutely')
                        this.selectedXMinutes = refreshJobData[1];
                    else if (this.selectedTimePeriod === 'hourly')
                        this.selectedMinute = refreshJobData[1];
                    else if (this.selectedTimePeriod === 'daily') {
                        this.selectedMinute = refreshJobData[1];
                        this.selectedHour = refreshJobData[2];
                    } else if (this.selectedTimePeriod === 'weekly') {
                        this.selectedMinute = refreshJobData[1];
                        this.selectedHour = refreshJobData[2];
                        this.selectedDay = refreshJobData[3];
                    } else if (this.selectedTimePeriod === 'monthly') {
                        this.selectedMinute = refreshJobData[1];
                        this.selectedHour = refreshJobData[2];
                        this.selectedMonth = refreshJobData[3];
                    }                
                    this.timePeriodChanged(this.selectedTimePeriod);    
                }

                this.spinnerOff();
            })
            .catch(error => {
                let errorStr = '';
                if (error.body !== undefined)
                {
                    errorStr = error.body.message;
                    console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
                } else {
                    errorStr = error.message;
                    console.log('Error Detected - ' + error.message + ' | ' + error.stack);
                }

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error loading the refresh job config. Please see an administrator - ' + errorStr,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.spinnerOff();
                return;
            });

        }
    }

    handleIsTurnedOnChange(event) {
        this.spinnerOn();

        if (this.isTurnedOn === undefined)
            this.isTurnedOn = true;
        else
            this.isTurnedOn = undefined;

        //turning OFF
        if (this.isTurnedOn === undefined) {
            this.scheduleText = 'Click to schedule automatic core list view refreshes';
            this.saveScheduledJobConfig('Not Scheduled');

        //turning ON
        } else {
            this.scheduleText = 'Click to unschedule refreshes';

            let jobDataStr = this.selectedTimePeriod + ':';

            if (this.selectedTimePeriod === 'minutely')
                jobDataStr += this.selectedXMinutes;
            else if (this.selectedTimePeriod === 'hourly')
                jobDataStr += this.selectedMinute;
            else if (this.selectedTimePeriod === 'daily')
                jobDataStr += this.selectedMinute + ':' + this.selectedHour;
            else if (this.selectedTimePeriod === 'weekly')
                jobDataStr += this.selectedMinute + ':' + this.selectedHour + ':' + this.selectedDay;
            else if (this.selectedTimePeriod === 'monthly')
                jobDataStr += this.selectedMinute + ':' + this.selectedHour + ':' + this.selectedMonth;

            this.saveScheduledJobConfig(jobDataStr);
        }

    }

    saveScheduledJobConfig(jobDataStr) {

        let parameters = new Map();
        parameters.set('RefreshJob', jobDataStr);
        let strParamMap = JSON.stringify( Array.from(parameters) );
        console.log('Field/Value  - ' + strParamMap);

        saveOrgWideConfig({ paramStr: strParamMap})
        .then(result => {

            //get the status
            let status = result.substring(0, result.indexOf(':'));
            
            //get any associated message
            let message = result.substring(result.indexOf(':')+1);
            if (message === '' && status === 'Ok') {
                message = 'Refresh job configuration has been saved successfully.';
            } else if (message === '' && status != 'Ok') {
                message = 'There was an error saving the refresh job configuration.';
                this.isTurnedOn = undefined;
            }

            if (status === 'Ok') {

                scheduleRefreshJob()
                .then(result => {    

                    if (result == 'success')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Save Successful!',
                            message: message,
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.dispatchEvent(new CustomEvent('updated', { status: 'Ok' }));
                        this.spinnerOff();
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error!',
                            message: 'There was a problem scheduling the job',
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        this.spinnerOff();
                        this.isTurnedOn = undefined;
                        return;
                    }
                })
                .catch(error => {
                    this.spinnerOff();
                    return;
                });

            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error!',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.spinnerOff();
                return;
            }
        })
        .catch(error => {
            let errorStr = '';
            if (error.body !== undefined)
            {
                errorStr = error.body.message;
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            } else {
                errorStr = error.message;
                console.log('Error Detected - ' + error.message + ' | ' + error.stack);
            }

            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error saving the refresh job config. Please see an administrator - ' + errorStr,
                variant: 'error',
                mode: 'sticky'
            }));
            this.spinnerOff();
            return;
        });

    }

    handleTimePeriodChange(event) {
        this.timePeriodChanged(event.target.value);
    }

    periodValueChange(event) {
        console.log('Selected time period - ' + this.selectedTimePeriod);
        console.log('Selected value name  - ' + event.target.name);
        console.log('Period value changed - ' + event.target.value);


        if (event.target.name === 'X Minute List') {
            this.selectedXMinutes = event.target.value;
        } else if (event.target.name === 'Minute List') {
            this.selectedMinute = event.target.value;
        } else if (event.target.name === 'Hour List') {
            this.selectedHour = event.target.value;
        } else if (event.target.name === 'Day List') {
            this.selectedDay = event.target.value;
        } else if (event.target.name === 'Month List') {
            this.selectedMonth = event.target.value;
        }
    }

    timePeriodChanged(value) {
        this.selectedTimePeriod = value;
        this.displayMinutes = false;
        this.displayHours = false;
        this.displayDays = false;
        this.displayMonths = false;
        this.displayXMinutes = false;
        
        if (this.selectedTimePeriod === 'minutely')
        {
            this.displayXMinutes = true;
            this.displayMinutes = false;
            this.displayHours = false;
            this.displayDays = false;
            this.displayMonths = false;
        } else if (this.selectedTimePeriod === 'hourly')
        {
            this.displayXMinutes = false;
            this.displayMinutes = true;
            this.displayHours = false;
            this.displayDays = false;
            this.displayMonths = false;
        } else if (this.selectedTimePeriod === 'daily')
        {
            this.displayXMinutes = false;
            this.displayMinutes = true;
            this.displayHours = true;
            this.displayDays = false;
            this.displayMonths = false;
        } else if (this.selectedTimePeriod === 'weekly')
        {
            this.displayXMinutes = false;
            this.displayMinutes = true;
            this.displayHours = true;
            this.displayDays = true;
            this.displayMonths = false;
        } else if (this.selectedTimePeriod === 'monthly')
        {
            this.displayXMinutes = false;
            this.displayMinutes = true;
            this.displayHours = true;
            this.displayDays = false;
            this.displayMonths = true;
        }
    }

    spinnerOn() {
        this.spinner = true;
        console.log('Spinner ON for ' + this.pageName);
    }

    spinnerOff() {
        this.spinner = false;
        console.log('Spinner OFF for ' + this.pageName);
    }

}