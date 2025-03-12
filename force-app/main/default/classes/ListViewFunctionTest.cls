public with sharing class ListViewFunctionTest extends ListViewFunction2 {
    public ListViewFunctionTest() {

    }

   
   /**
   * @description Method that must be overridden to implement the class.
   * @param value the value that is being passed into the function for processing
   * @param context the SObject associated with the value being passed in. Use key = 'SObject' to get it from the map
   * @return Object the returned value after processing.
   **/
    public override Object get(Object value, Map<String, Object> context) {
        String debug = '\n\n-------------- STARTING FUNCTION --------------\n';
        debug += 'Starting Value - ' + value + '\n';
        if (value == null) return null;
        //if (!(value instanceof String)) return value;
        Object obj = context.get('SObject');
        debug += 'Starting Obj - ' + JSON.serialize(obj) + '\n';

        if (obj != null) {
            SObject sobj = (SObject) obj;
            value = value + ' Test';
        } else {
            value = value + 'Test2';
        }
        
       value = String.valueOf(value).toUpperCase();

       debug += 'Ending value - ' + JSON.serialize(value) + '\n';
        debug += '-------------- ENDING FUNCTION --------------\n\n';

       System.debug(LoggingLevel.DEBUG, debug);
       return value;
    }
}