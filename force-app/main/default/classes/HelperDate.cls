public with sharing class HelperDate {

    public static final String DAY = 'Day';
    public static final String MONTH = 'Month';
    public static final String YEAR = 'Year';
    public static final String HOUR = 'Hour';
    public static final String MINUTE = 'Minute';

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