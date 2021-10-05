/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 10-02-2021
 * @last modified by  : tom.h.ansley@medtronic.com
**/
public with sharing class HelperString {

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