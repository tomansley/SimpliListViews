/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-02-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-29-2021   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   08-02-2021   tom.h.ansley@medtronic.com   Added convertDateToDateTime() method
**/
public with sharing class HelperDate {

    public static final String DAY = 'Day';
    public static final String MONTH = 'Month';
    public static final String YEAR = 'Year';
    public static final String HOUR = 'Hour';
    public static final String MINUTE = 'Minute';

    public static DateTime convertDateToDateTime(Date theDate)
    {
        return DateTime.newInstance(theDate.year(), theDate.month(), theDate.day());
    }

    /*
     * HelperDate.getBatchJobScheduleString(HelperDate.MINUTE, 10);
     */
    public static String getBatchJobScheduleString(String lengthType, Integer lengthFromNow)
    {

        DateTime dt = System.now();

        if (lengthType == DAY) dt = dt.addDays(lengthFromNow);
        if (lengthType == MONTH) dt = dt.addMonths(lengthFromNow);
        if (lengthType == YEAR) dt = dt.addYears(lengthFromNow);
        if (lengthType == HOUR) dt = dt.addHours(lengthFromNow);
        if (lengthType == MINUTE) dt = dt.addMinutes(lengthFromNow);

        
        String day = string.valueOf(dt.day());
        String month = string.valueOf(dt.month());
        String hour = string.valueOf(dt.hour());
        String minute = string.valueOf(dt.minute());
        String second = string.valueOf(dt.second());
        String year = string.valueOf(dt.year());
        
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.debug(LoggingLevel.DEBUG, 'Schedule - ' + strSchedule);
        
        return strSchedule;
    }

}