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
}