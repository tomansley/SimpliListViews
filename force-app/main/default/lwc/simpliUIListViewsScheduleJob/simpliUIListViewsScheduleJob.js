import { LightningElement, wire, track, api   } from 'lwc';

import List_View_Refresh_Scheduled from '@salesforce/label/c.List_View_Refresh_Scheduled';
import Select_Time_Period from '@salesforce/label/c.Select_Time_Period';
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

    @track selectedMinute = '00';
    @track selectedHour = '00';
    @track selectedDay = Monday;
    @track selectedMonth = 'First Day Of Month';
    @track selectedTimePeriod = 'daily';
    @track displayMinutes = false;
    @track displayHours = false;
    @track displayDays = false;
    @track displayMonths = false;

    @track timePeriodsList = [
        { label: 'Hourly', value: 'hourly' },
        { label: 'Daily', value: 'daily' },
        { label: 'Weekly', value: 'weekly' },
        { label: 'Monthly', value: 'monthly' }
    ];   

    @track minutePeriodsList = [
        { label: '00', value: '00' }, { label: '05', value: '05' }, { label: '10', value: '10' },
        { label: '15', value: '15' }, { label: '20', value: '20' }, { label: '25', value: '25' },
        { label: '30', value: '30' }, { label: '35', value: '35' }, { label: '40', value: '40' },
        { label: '45', value: '45' }, { label: '50', value: '50' }, { label: '55', value: '55' },
    ];   

    @track hourPeriodsList = [
        { label: '00', value: '00' }, { label: '01', value: '01' }, { label: '02', value: '02' },
        { label: '03', value: '03' }, { label: '04', value: '04' }, { label: '05', value: '05' },
        { label: '06', value: '06' }, { label: '07', value: '07' }, { label: '08', value: '08' },
        { label: '09', value: '09' }, { label: '10', value: '10' }, { label: '11', value: '11' },
        { label: '12', value: '12' }, { label: '13', value: '13' }, { label: '14', value: '14' },
        { label: '15', value: '15' }, { label: '16', value: '16' }, { label: '17', value: '17' },
        { label: '18', value: '18' }, { label: '19', value: '19' }, { label: '20', value: '20' },
        { label: '21', value: '21' }, { label: '22', value: '22' }, { label: '23', value: '23' },
    ];   

    @track dayPeriodsList = [
        { label: Monday, value: Monday }, { label: Tuesday, value: Tuesday },
        { label: Wednesday, value: Wednesday }, { label: Thursday, value: Thursday },
        { label: Friday, value: Friday }, { label: Saturday, value: Saturday },
        { label: Sunday, value: Sunday },
    ];   

    @track monthPeriodsList = [
        { label: 'First Day Of Month', value: 'First Day Of Month' }, 
        { label: '15th Of Month', value: '15th Of Month' },
        { label: 'Last Day Of Month', value: 'Last Day Of Month' },
    ];   

    label = { List_View_Refresh_Scheduled, Select_Time_Period, Select_Minute, Select_Hour, Select_Day, 
              Select_Month, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday };

    handleIsTurnedOnChange(event) {
        if (event.target.checked === true) {
            this.isTurnedOn = true;
        } else {
            this.isTurnedOn = undefined;
        }
    }

    handleTimePeriodChange(event) {
        this.timePeriodChanged(event.target.value);
    }

    timePeriodChanged(value) {
        this.selectedTimePeriod = value;
        this.displayMinutes = false;
        this.displayHours = false;
        this.displayDays = false;
        this.displayMonths = false;
        
        if (this.selectedTimePeriod === 'hourly')
        {
            this.displayMinutes = true;
            this.displayHours = false;
            this.displayDays = false;
            this.displayMonths = false;
        } else if (this.selectedTimePeriod === 'daily')
        {
            this.displayMinutes = true;
            this.displayHours = true;
            this.displayDays = false;
            this.displayMonths = false;
        } else if (this.selectedTimePeriod === 'weekly')
        {
            this.displayMinutes = true;
            this.displayHours = true;
            this.displayDays = true;
            this.displayMonths = false;
        } else if (this.selectedTimePeriod === 'monthly')
        {
            this.displayMinutes = true;
            this.displayHours = true;
            this.displayDays = false;
            this.displayMonths = true;
        }
    }
}