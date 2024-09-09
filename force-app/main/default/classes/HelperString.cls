/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 09-06-2024
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class HelperString {

    public static String toUpperCaseExceptLiterals(String oldSOQL)
    {
        boolean atEnd = false;

        String newSOQL = '';
        do {
            Integer index = oldSOQL.indexOf('\'');
            if (index == -1) {
                //mark that we are at the end
                atEnd = true;
                //set the remainder of the query to upper case and add to new query
                newSOQL += oldSOQL.toUpperCase();
            } else {
                //set all characters leading up to the single quote to uppercase and add to the new query 
                newSOQL += oldSOQL.substring(0, index+1).toUpperCase();
                //remove the characters leading up to the single quote from the original query
                oldSOQL = oldSOQL.substring(index+1);

                //get the index of the matching single quote
                index = oldSOQL.indexOf('\'');
                //add all characters leading up to the single quote to the new query 
                newSOQL += oldSOQL.substring(0, index+1); //NOT UPPERCASE
                //remove the characters leading up to the single quote from the original query
                oldSOQL = oldSOQL.substring(index+1);

            }

        } while (!atEnd);

        return newSOQL;
    }

    public static String scrubSOQL(String soql)
    {
        soql = soql.replaceAll('\\s+', ' '); //get rid of all extra spaces

        return soql;
    }

    /*
     * Method that takes a string that is to be split and a split char
     * and returns a set of strings.
     */
    public static Set<String> getSetFromString(String data, String splitChar, Boolean setLowerCase)
    {
        Set<String> dataSet = new Set<String>();
        
        if (data == null || data == '')
            return dataSet;

        dataSet = new Set<String>(data.split(splitChar));

        if (setLowerCase)
        {
            Set<String> tmpDataSet = new Set<String>();
            for (String str: dataSet)
                tmpDataSet.add(str.toLowerCase());
            dataSet = tmpDataSet;
        }

        return dataSet;
    }

    /*
     * Method that takes a string that is to be split and a split char
     * and returns a set of strings.
     */
    public static Set<String> getSetFromString(String data, String splitChar)
    {
        return getSetFromString(data, splitChar, false);
    }

    public static String getStringFromList(List<Object> data, String splitChar)
    {
        String dataStr = '';

        if (data == null)
            return dataStr;

        if (splitChar == null)
            splitChar = ',';

        for (Object item: data)
            dataStr += String.valueOf(item) + splitChar;

        dataStr = dataStr.removeEnd(splitChar);

        return dataStr;
    }

    public static String getStringFromSet(Set<String> data, String splitChar)
    {
        String dataStr = '';

        if (data == null)
            return dataStr;

        if (splitChar == null)
            splitChar = ',';

        for (String item: data)
            dataStr += item + splitChar;

        dataStr = dataStr.removeEnd(splitChar);

        return dataStr;
    }

    public static void debug(Object obj, String label)
    {
        System.debug(LoggingLevel.DEBUG, label + ' - ' + JSON.serialize(obj));
    }

    /*
        System.debug('Site - ' + HelperString.getSiteFromURL('https://deliverymg000000000--full.sandbox.my.site.com/logistics/s/detail/0037y00000W7yLDAAZ'));
        */
    public static String getSiteFromURL(String url)
    {
        return url.substringBetween('my.site.com/', '/s/');
    }

}