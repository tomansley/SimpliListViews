/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-21-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class HelperString {

    public static String scrubSOQL(String soql)
    {
        soql = soql.replaceAll('\\s+', ' '); //get rid of all extra spaces

        return soql;
    }

    /*
     * Method that takes a string that is to be split and a split char
     * and returns a set of strings.
     */
    public static Set<String> getSetFromString(String data, String splitChar)
    {
        Set<String> dataSet = new Set<String>();
        
        if (data == null || data == '')
            return dataSet;

        dataSet = new Set<String>(data.split(splitChar));

        return dataSet;
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
}