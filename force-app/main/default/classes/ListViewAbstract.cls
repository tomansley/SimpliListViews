/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 07-27-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-23-2020   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   06-18-2021   tom.h.ansley@medtronic.com   Added offset to allow for larger datasets
 * 3.0   07-27-2021   tom.h.ansley@medtronic.com   Added logic to handle identification of inline-editing for rows and fields. Beefed up FieldWrapper to handle inline-editing (mainly type identification methods), 
**/
public with sharing abstract class ListViewAbstract {
    
    public static Set<String> validTotalColumns = new Set<String>{'integer', 'decimal', 'currency'};
    public static Set<String> validNameColumnNames = new Set<String>{'name', 'casenumber'}; //holds the list of column names that if found will produce a link to the record.

    public List_View__c listview = null;                              //holds the list view record associated with this request.
    public List_View_Config__c config = null;                         //holds the SFDC list view config SObject
    public ListViewAbstract.ListViewConfigWrapper lvConfig = null;    //holds the list views config after its been wrapped.
    public List<ListViewHelper.ColumnSortData> columnSortData = null; //holds any sorting data coming in on the request
    public Set<String> joinRecordIds = null;                          //holds any join Ids that might be used to identify records.
    public String joinField = null;                                   //if getting data based on join Ids this field describes the join field to use.
    public Integer offset = -1;                                       //holds the offset value if we need to page data into the list view.

    //----------------------------------------------------------------------------------
    // Method to be overridden
    //----------------------------------------------------------------------------------

    /**
    * @description Method called to return the data for this list view in a format which is
    *              consumable by the UI. This typically means converting SObject rows into
    *              the ListViewAbstract provided RowsWrapper, RowWrapper and FieldWrapper
    *              objects. These objects have additional fields which are used on the UI.
    * @author tom.h.ansley@medtronic.com | 10-29-2020 
    * @return RowsWrapper the returned data wrapped in metadata which is used by the UI
    **/
    public abstract RowsWrapper getData();

    /**
    * @description Method called to determine if the list view config parameters are complete or
    *              whether additional parameters need to be included. This could be the case where 
    *              a new list view has been created but the configuration does not yet exist and the 
    *              list view is requested to be displayed. This method should set all default configuration 
    *              and parameters to allow the list view to function appropriately.
    * @author tom.h.ansley@medtronic.com | 10-25-2020 
    * @param objectName the object or group name associated with the list view.
    * @param listViewName the list view API name associated with the list view.
    * @return List_View_Config__c 
    **/
    public abstract List<List_View_Config_Parameter__c> getConfigParams(List_View_Config__c config);


    //----------------------------------------------------------------------------------
    // Concrete methods
    //----------------------------------------------------------------------------------
    
    /**
    * @description Method which returns a map of column labels to column API names. Based on the 
    *              implementation of the list view the column labels could be stored in a number 
    *              of places and there may be weird logic to get the values.
    * @author tom.h.ansley@medtronic.com | 10-26-2020 
    * @return Map<String, String> the map of column labels with column API names used as keys by the UI.
    **/
    public Map<String, String> getColumnLabels()
    {
        SObject exampleRow = null;   

        //try to get a true example row
        List<SObject> objectRows = null;
        
        if (listview.SubType__c != 'Tooling') //cannot get an example row if we are working with the tooling API
        {
            if (listview.RecordTypeId == ListViewHelper.coreRTId)
                objectRows = ListViewHelper.getListViewData(listview, lvConfig, null, null, null, true, -1);
            else 
                objectRows = ListViewHelper.getListViewData(listview.Core_ListView_Query__c, lvConfig, null, null, null, true, -1);
        }
        
        if (objectRows != null && objectRows.size() > 0) 
        {
            exampleRow = objectRows[0];
        //if no row then use object type (which will not work if there are weird additional fields.)
        } else {
            Type t = Type.forName(listview.Object_Name__c);
            exampleRow = (SObject) t.newInstance();
        }

        Map<String, String> colLabels = new Map<String, String>();

        //get all columns from the list view
        List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);

        //get the CORE SFDC COLUMN meta data
        for (Object column: allColumns)
        {
            Map<String, Object> columnData = (Map<String, Object>) column;

            String fieldName = (String) columnData.get('fieldNameOrPath');
            Boolean hidden   = (Boolean) columnData.get('hidden');

            if (hidden == null || !hidden)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, fieldName);
         
                if (d != null && !d.isChildRel)
                    colLabels.put(fieldName, d.label);
            }
            
        }

        //set the CUSTOM COLUMN meta data into the rows wrapper
        if (lvConfig != null 
            && lvConfig.getParameter('AdditionalFields') != null 
            && lvConfig.getParameter('AdditionalFields').getValue() != null
            && lvConfig.getParameter('AdditionalFields').getValue() != '')
        {
            //get the field names in a list
            List<String> fields = lvConfig.getParameter('AdditionalFields').getValue().deleteWhitespace().split(',');

            System.debug(LoggingLevel.DEBUG, 'Additional Fields - ' + fields);

            for (String fieldName: fields)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, fieldName);
         
                if (d != null)
                    colLabels.put(fieldName, d.label);
            }
        }

        return colLabels;
    }

    public void setRequestData(List_View__c listview)
    {
        setRequestData(listview, null, null, null, -1);
    }

    /*
        List<List_View_Config__c> lvConfigs = ListViewConfigHelper.getListViewConfig('All', 'All');

    */
    public void setRequestData(List_View__c listview, List<ListViewHelper.ColumnSortData> columnSortData, String joinField, Set<String> joinRecordIds, Integer offset)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewAbstract.setRequestData - ' + listview);
        this.listview       = listview;
        this.columnSortData = columnSortData;
        this.joinField      = joinField;
        this.joinRecordIds  = joinRecordIds;
        this.offset         = offset;

        List<List_View_Config__c> lvConfigs = ListViewConfigHelper.getListViewConfig(listview.Object_Name__c, listview.API_Name__c);

        //if we have a configuration
        if (lvConfigs.size() > 0) 
        {
            config = lvConfigs[0];

            List<List_View_Config_Parameter__c> params = getConfigParams(config);

            lvConfig = new ListViewConfigWrapper(config, params);

        } else {
            throw new ListViewException('Configuration for list view not found. Please reprocess list view');
        }

    }

    //-------------------------------------------------------------------
    //LIST VIEW - wrapper which holds list view information. Note that 
    //            we cannot pass any SObject to a lightning component so 
    //            need to add fields to this wrapper as we need them.
    //-------------------------------------------------------------------
    public class ListViewWrapper
    {
        public DateTime lastModifiedDate;
        public String lastModifiedBy;
        public String listviewType;
        public Integer offset   = -1;
        public Integer rowLimit = -1;
    
        public ListViewWrapper(List_View__c listView)
        {
            lastModifiedDate = listView.LastModifiedDate;
            lastModifiedBy   = listView.LastModifiedBy.Name;
            listviewType     = listView.RecordType.Name;
        }

        @AuraEnabled(cacheable=false)
        public Integer getOffset()
        {
            return offset;
        }

        @AuraEnabled(cacheable=false)
        public Integer getRowLimit()
        {
            return rowLimit;
        }

        @AuraEnabled(cacheable=true)
        public String getLastModifiedText()
        {
            return  'Last Modified By: ' + lastModifiedBy + ' - ' + lastModifiedDate;
        }

        @AuraEnabled(cacheable=true)
        public String getLastModifiedBy()
        {
            return lastModifiedBy;
        }
        
        @AuraEnabled(cacheable=true)
        public DateTime getLastModifiedDate()
        {
            return lastModifiedDate;
        }
        
        @AuraEnabled(cacheable=true)
        public String getListViewType()
        {
            return listviewType;
        }
        
    }

    //-------------------------------------------------------------------
    //ROWS - class which wraps up ALL row data for sending to front end.
    //       this includes the table data itself as well as any rows, 
    //       row or field config.
    //-------------------------------------------------------------------
    public class RowsWrapper
    {
        public String objName;
        public String coreListId;
        public ListViewWrapper listView;
        public List<RowWrapper> rows;
        public List<FieldWrapper> fieldMetaData;
        public String csvData;
        public Boolean hasTotalsRow;
        public Boolean isCoreListView = false;
        public Boolean isEdited;
        
        public RowsWrapper(List_View__c listView)
        {
            this.listView = new ListViewWrapper(listView);
            rows = new List<RowWrapper>();
            fieldMetaData = new List<FieldWrapper>();
            hasTotalsRow = false;
            objName    = listview.Object_Name__c;
            coreListId = listview.Core_ListView_Id__c;
            if (listView.RecordTypeId == ListViewHelper.coreRTId)
                isCoreListView = true;
            isEdited = false;
        }

        @AuraEnabled(cacheable=true)
        public String getObjectName()
        {
            return objName;
        }

        @AuraEnabled(cacheable=true)
        public String getCoreListId()
        {
            return coreListId;
        }

        @AuraEnabled
        public Boolean getIsEdited()
        {
            return isEdited;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsCoreListView()
        {
            return isCoreListView;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getHasTotalsRow()
        {
            return hasTotalsRow;
        }

        @AuraEnabled(cacheable=true)
        public Integer getRowCount()
        {
            if (hasTotalsRow)
                return rows.size()-1;
            else
                return rows.size();
        }

        public void addRow(RowWrapper row)
        {
            rows.add(row);
            row.parentWrapper = this;
            row.rowId = row.rowId + ':' + getRowCount();

        }

        @AuraEnabled(cacheable=true)
        public List<RowWrapper> getRows()
        {
            return rows;
        }   	
        
        public void addFieldMetaData(FieldWrapper field)
        {
            fieldMetaData.add(field);
        }

        @AuraEnabled(cacheable=true)
        public List<FieldWrapper> getFieldMetaData()
        {
            fieldMetaData.sort();
            return fieldMetaData;
        }

        @AuraEnabled(cacheable=true)
        public ListViewWrapper getListView()
        {
            return listView;
        }

        /*
         * Method to retrieve the data in CSV format.
         */
        @AuraEnabled(cacheable=true)
        public String getDataAsString()
        {
            String dataStr = getHeadersAsCSVString();

            //if we have no data then return
            if (rows == null || rows.size() == 0) return dataStr;

            //for each row of data
            for (RowWrapper row: rows)
                dataStr += row.getDataAsCSVString();

            return dataStr;
        }

        @AuraEnabled(cacheable=true)
        public String getHeadersAsCSVString()
        {
            String dataStr = '';

            for (FieldWrapper column: fieldMetaData)
            {
                dataStr += '"' + column.name.replaceAll('"', '""') + '"' + ',';
            }

            dataStr = dataStr.removeEnd(',') + '\n';

            return dataStr;
        }

        //Example - https://simpli-list-view-dev-dev-ed.lightning.force.com/lightning/o/Account/list?filterName=00B3h000003ZfMQEA0
        @AuraEnabled(cacheable=true)
        public String getCoreListViewURL()
        {
            if (coreListId != null && coreListId != '')
                return URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/o/' + objName + '/list?filterName=' + coreListId;
            else
                return '';
        }

        public String getDebugString()
        {
            String debug = '\n\n----------------------------------------------------------\n';
            debug += 'Row Object          - ' + objName + '\n';
            debug += 'Core List Id        - ' + coreListId + '\n';
            debug += 'Row Count           - ' + rows.size() + '\n';
            debug += 'Has Totals Row      - ' + hasTotalsRow + '\n';
            debug += 'Is Core List View   - ' + isCoreListView + '\n';
            debug += 'Field Metadata Size - ' + fieldMetaData.size() + '\n\n';
            debug += '    Field Metadata' + '\n';
            for (FieldWrapper metadata: fieldMetaData)
            {
                debug += '    Name - ' + metadata.name + ', Column Index - ' + metadata.columnIndex + ', Label - ' + metadata.label + ', Type - ' + metadata.type + '\n';
            }
            debug += '' + '\n';
            debug += '    Row Data' + '\n';

            for (RowWrapper row: rows)
            {
                debug += '    Id - ' + row.rowId + ', Fields Size - ' + row.fields.size() + ', Is Deleted - ' + row.isDeleted + ', Is Totals - ' + row.isTotals + '\n';
                for (String fieldKey: row.fields.keySet())
                {
                    FieldWrapper field = row.fields.get(fieldKey);
                    debug += '        Key - ' + fieldKey + ', Name - ' + field.name + ', Label - ' + field.label + ', Value - ' + field.getValue() + ', Type - ' + field.getType() + '\n';
                }                    
                debug += '' + '\n';
            }
            debug += '----------------------------------------------------------\n\n';

            return debug;
        }
        
    }
    
    //-----------------------------------------------------------
    //ROW - wrapper which holds one ROW of field data and config.
    //-----------------------------------------------------------
    public class RowWrapper
    {
        RowsWrapper parentWrapper;               //pointer to the parent wrapper
        public Map<String, FieldWrapper> fields; //the list of fields and values for the row
        public String rowId;                     //the SFDC record id. USed to identify rows on the UI
        public Boolean highlight;                //indicates whether the row should be highlighted due to conditions set by user
        public String highlightColor;            //the color the row should be set to if being highlighted.
        public Boolean isTotals;                 //indicates whether this row is a totals row.
        public Boolean isDeleted;                //indicates whether this row is for a deleted record.
        public Boolean isEdited;                 //indicates whether the row has been edited or not.

        public RowWrapper(String rowId)
        {
            this.rowId = rowId;
            this.highlight = false;
            this.highlightColor = '';
            fields = new Map<String, FieldWrapper>();
            isTotals = false;
            isEdited = false;
        }

        public void addField(FieldWrapper field)
        {
            System.debug(LoggingLevel.FINE, 'Adding Field - ' + field.getName() + ':' + field.columnIndex + ' -- ' + field);
            fields.put(field.getName() + ':' + field.columnIndex, field);
            field.key = rowId + ':' + String.valueOf(field.columnIndex);
        }

        @AuraEnabled(cacheable=true)
        public List<FieldWrapper> getFields()
        {
            //get all fields by column index
            Map<Integer, FieldWrapper> fieldsByColumn = new Map<Integer, FieldWrapper>();
            for (FieldWrapper field: fields.values())
                fieldsByColumn.put(field.columnIndex, field);

            //go through metadata adding fake information for blank fields.
            for (FieldWrapper column: parentWrapper.getFieldMetaData())
            {
                if (fieldsByColumn.get(column.columnIndex) == null)
                {
                    addField(new FieldWrapper('', '', 'string', String.valueOf(column.columnIndex), column.columnIndex));
                }
            }
            List<FieldWrapper> sortedFields = fields.values();
            sortedFields.sort();

            return sortedFields;
        }

        public FieldWrapper getField(String apiName)
        {
            return fields.get(apiName);
        }
        
        @AuraEnabled(cacheable=true)
        public String getRowId()
        {
            return rowId;
        }

        @AuraEnabled(cacheable=true)
        public String getCheckBoxId()
        {
            return 'checkbox:' + rowId;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getHighlight()
        {
            return highlight;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsTotals()
        {
            return isTotals;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsDeleted()
        {
            return isDeleted;
        }

        @AuraEnabled
        public Boolean getIsEdited()
        {
            return isEdited;
        }

        @AuraEnabled(cacheable=true)
        public String getHighlightColor()
        {
            return highlightColor;
        }

        @AuraEnabled(cacheable=true)
        public String getDataAsCSVString()
        {
            String dataStr = '';

            //get the field data. We make sure to escape delimiter
            for (FieldWrapper rowData: getFields())
            {
                dataStr += '"' + rowData.value.replaceAll('"', '""') + '"' + ',';
            }

            dataStr = dataStr.removeEnd(',') + '\n';

            return dataStr;
        }

        /**
        * @description Method which clones a row wrapper. 
        * @author tom.h.ansley@medtronic.com | 03-26-2021 
        * @param deleteFieldData identifies if the field values within the field wrappers should be deleted.
        * @return RowWrapper 
        **/
        public RowWrapper cloneWrapper(Boolean deleteFieldData)
        {
            RowWrapper clone = new RowWrapper(rowId);
            clone.fields = new Map<String, FieldWrapper>();
            for (FieldWrapper field: fields.values())
            {
                String value = '';
                if (!deleteFieldData)
                    value = field.value;
                FieldWrapper cloneField = new FieldWrapper(field.label, value, field.type, field.name, field.columnIndex);
                cloneField.setURL(field.getURL());
                clone.addField(cloneField);
            }
            clone.highlight = this.highlight;
            clone.highlightColor = this.highlightColor;
            clone.isTotals = this.isTotals;
            clone.isDeleted = this.isDeleted;
    
            return clone;
        }

        /*
         * Method to calculate and set the conditional highlighting of rows based on provided configuration conditions.
         * We pass in the condition details each time as its a complex object that cannot be passed to the lightning UI
         */
        public void calculateHighlighting(Map<String, List<ListViewCondition>> lvConfigConditions)
        {
            System.debug(LoggingLevel.DEBUG, 'Calculating highlighting for row!');
            System.debug(LoggingLevel.DEBUG, 'Conditions are - ' + lvConfigConditions);
            //for each field
            for (FieldWrapper field: fields.values())
            {
                System.debug(LoggingLevel.DEBUG, 'Looking at field with name = ' + field.name + ' and value = ' + field.value);

                //check of there is a condition name which matches a field
                List<ListViewCondition> conditions = lvConfigConditions.get(field.name.toLowerCase());
                if (conditions == null && !String.isEmpty(field.getLongName()))
                    conditions = lvConfigConditions.get(field.getLongName().toLowerCase());

                //if there is then validate
                if (conditions != null)
                {

                    System.debug(LoggingLevel.DEBUG, 'We have ' + conditions.size() + ' matching conditions!');

                    List<List_View_Config_Condition__c> lvConditions = new List<List_View_Config_Condition__c>();
                    for (ListViewCondition condition: conditions)
                        lvConditions.add(condition.getCondition());

                    String color = ListViewConfigHelper.validateFieldCondition(field.value, field.type, lvConditions);

                    System.debug(LoggingLevel.DEBUG, 'Condition validation result = ' + color);

                    //get the highlight color as well regardless.
                    if (color != '')
                        highlightColor = color;
                }
            }
        }
    }

    //---------------------------------------------------------------------
    //FIELD - wrapper holding data for a single cell in a table. This data 
    //        includes both table data as well as config for how it should 
    //        be displayed.
    //---------------------------------------------------------------------
    public class FieldWrapper implements Comparable
    {

        public String label;
        public String value;
        public String idValue;
        public String type;
        public String url;             //the URL that the field should display if one is available.
        public String urlTarget;      //identifies the target of the URL
        public String name;            //the short API name of the field. i.e. quantity
        public String longName;        //the long API name of the field i.e. opportunitylineitems.quantity
        public Boolean sortDir;        //true = asc, false = desc
        public String sortIndex;
        public Integer columnIndex;    //identifies the column that this field is a part of
        public String key;
        public Boolean isSortable;     //identifies whether the field is sortable.
        public Boolean isEditable;     //identifies whether the field can be edited inline.
        public String fieldObjName;    //the API name of the object that this field looks up to

        public FieldWrapper(String label, String value, String type, String name, Integer columnIndex)
        {
            this.label       = label;
            this.name        = name;
            this.sortDir     = true;
            this.sortIndex   = '';
            this.columnIndex = columnIndex;
            this.isSortable  = true;
            this.urlTarget   = '_self';

            this.setValue(value);
            this.setType(type);

            String debug = '\n\n---------------------------------------------------------------\n';
            debug       += 'Label - ' + this.label + '\n';
            debug       += 'type - ' + this.type + '\n';
            debug       += 'value - ' + this.value + '\n';
            debug       += 'name - ' + this.name + '\n';
            debug       += 'columnIndex - ' + this.columnIndex + '\n';
            debug       += '---------------------------------------------------------------\n';
            System.debug(LoggingLevel.FINE, debug);
        }
        
        public FieldWrapper(String label, String type, String name, Integer columnIndex)
        {
            this.label       = label;
            this.name        = name;
            this.sortdir     = true;
            this.sortIndex   = '';
            this.columnIndex = columnIndex;
            this.isSortable  = true;

            this.setType(type);

            String debug = '\n\n---------------------------------------------------------------\n';
            debug       += 'Label - ' + this.label + '\n';
            debug       += 'type - ' + this.type + '\n';
            debug       += 'value - ' + this.value + '\n';
            debug       += 'name - ' + this.name + '\n';
            debug       += 'columnIndex - ' + this.columnIndex + '\n';
            debug       += '---------------------------------------------------------------\n';
            System.debug(LoggingLevel.FINE, debug);
        }
        
        @AuraEnabled(cacheable=true)
        public String getKey()
        {
            return key;
        }
        
        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return label;
        }
        
        @AuraEnabled(cacheable=true)
        public String getName()
        {
            return name;
        }

        public String getLongName()
        {
            return longName;
        }
        
        @AuraEnabled(cacheable=true)
        public String getSortingTooltip()
        {
            return 'Sort By ' + label;
        }
        
        @AuraEnabled(cacheable=true)
        public String getSortIndex()
        {
            return sortIndex;
        }
        
        @AuraEnabled(cacheable=true)
        public String getSortIndexDisplay()
        {
            if (sortIndex == null || sortIndex == '') return '';
            return String.valueOf(Integer.valueOf(sortIndex) + 1); //add one as we don't want to start on a zero'th value for users!
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getSortDir()
        {
            return sortDir;
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getSortable()
        {
            return isSortable;
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsEditable()
        {
            //only editable if its a field that is on the main object or a lookup.
            if (this.name.countMatches('.') > 1 || (this.name.countMatches('.') == 1 && !this.name.contains('.Name'))) return false;
            
            return isEditable;    
        }

        public void setIsEditable(Boolean isEditable)
        {
            //cannot edit geolocation fields individually
            if (name.contains('__s'))
                this.isEditable = false;
            else 
                this.isEditable = isEditable;
        }
        
        @AuraEnabled(cacheable=true)
        public String getType()
        {
            return type;
        }

        public void setType(String type)
        {
            if (type == 'string' && this.name.contains('.Name'))
                this.type = 'lookup';
            else 
                this.type = type;
        }
        
        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return value;
        }

        public void setValue(String value)
        {
            if (value == null)
                this.value = '';
            else if (this.type == 'date')
                this.value = value.removeEnd(' 00:00:00');
            else    
                this.value = value;
        }

        @AuraEnabled(cacheable=true)
        public String getIdValue()
        {
            return idValue;
        }

        public void setIdValue(String idValue)
        {
            this.idValue = idValue;
        }

        @AuraEnabled
        public Boolean getHasURL()
        {
            if (this.url == null) return false;
            return true;    
        }
        
        public void setURL(String url)
        {
            this.url = url;
        }

        @AuraEnabled(cacheable=true)
        public String getURL()
        {
            return url;
        }
        
        @AuraEnabled(cacheable=true)
        public String getURLTarget()
        {
            return urlTarget;
        }
        
        @AuraEnabled(cacheable=true)
        public String getFieldObjName()
        {
            return fieldObjName;
        }

        public void setFieldObjName(String fieldObjName)
        {
            this.fieldObjName = fieldObjName;
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsString()
        {
            if (this.type == 'string') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsURL()
        {
            if (this.type == 'url') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsBoolean()
        {
            if (this.type == 'boolean') return true;
            return false;    
        }
        
        /**
        * @description the value that is sent to the UI widgets. Sometimes that is different that what is displayed as text.
        **/
        @AuraEnabled(cacheable=true)
        public String getUIValue()
        {
            String uiStr = value;
            if (getIsBoolean()) //if boolean value is FALSE then send NOTHING
            {
                if (uiStr == 'false')
                    uiStr = null;
            } else if (getIsDateTime()) { //replace string value of '2021-03-04 1
                if (!String.isEmpty(uiStr))
                    uiStr = uiStr.replace(' ', 'T') + 'Z';
            }
            return uiStr;
        }
        
        /*
         * For those values that need to be returned as a list for display purposes.
         */
        @AuraEnabled(cacheable=true)
        public List<String> getUIMultiPicklistValues()
        {
            if (value != null)
                return value.split(';');
            else
                return new List<String>();
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsLookup()
        {
            if (this.type == 'lookup') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsCurrency()
        {
            if (this.type == 'currency') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDate()
        {
            if (this.type == 'date') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDateTime()
        {
            if (this.type == 'datetime') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsTime()
        {
            if (this.type == 'time') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPicklist()
        {
            if (this.type == 'picklist') return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsMultiPicklist()
        {
            if (this.type == 'multipicklist') return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsDecimal()
        {
            if (this.type == 'decimal') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsInteger()
        {
            if (this.type == 'integer') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDouble()
        {
            if (this.type == 'double') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPercent()
        {
            if (this.type == 'percent') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPhone()
        {
            if (this.type == 'phone') return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsEmail()
        {
            if (this.type == 'email') return true;
            return false;    
        }
        
        public Integer compareTo(Object compareTo) {
            FieldWrapper field = (FieldWrapper) compareTo;
            if (this.columnIndex > field.columnIndex) return 1;
            else if (this.columnIndex < field.columnIndex) return -1;
            else return 0;
        }
    }

    public class ListViewCondition
    {
        public List_View_Config_Condition__c condition;
        public String fieldName;
        public String operator;
        public String value;
        public String order;
        public String color;
        public String id;

        public ListViewCondition(List_View_Config_Condition__c condition)
        {
            this.condition = condition;
            fieldName      = condition.Field_Name__c;
            operator       = condition.Operator__c;
            value          = condition.Value__c;
            order          = condition.Order__c;
            color          = condition.Highlight_Color__c;
            id             = condition.Id;
        }

        public List_View_Config_Condition__c getCondition()
        {
            return condition;
        }

        @AuraEnabled(cacheable=true)
        public String getFieldName()
        {
            return fieldName;
        }

        @AuraEnabled(cacheable=true)
        public String getOperator()
        {
            return operator;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return value;
        }

        @AuraEnabled(cacheable=true)
        public String getOrder()
        {
            return order;
        }

        @AuraEnabled(cacheable=true)
        public String getColor()
        {
            return color;
        }

        @AuraEnabled(cacheable=true)
        public String getId()
        {
            return id;
        }

    }

    //-------------------------------------------------------------------
    //LIST VIEW - wrapper which holds list view CONFIG information. Note 
    //CONFIG      that we cannot pass any SObject to a lightning component 
    //            so need to add fields to this wrapper as we need them.
    //-------------------------------------------------------------------
    public class ListViewConfigWrapper
    {
        public List_View_Config__c listViewConfig;
        public DateTime lastModifiedDate;
        public String lastModifiedBy;
        public Map<String, ListViewParam> parameters;
        public Map<String, List<ListViewCondition>> conditions;
        public String name;
        public String obj;

        public ListViewConfigWrapper(String name, String obj)
        {
            this.name = name;
            this.obj = obj;
            parameters       = new Map<String,ListViewParam>();
            conditions       = new Map<String, List<ListViewCondition>>();
        }

        /*
         * Constructor for if the params were not created yet and were created in this transaction.
         */
        public ListViewConfigWrapper(List_View_Config__c listView, List<List_View_Config_Parameter__c> params)
        {
            this.listViewConfig = listView;
            this.name        = listView.Name;
            this.obj         = listView.List_View_Object__c;
            lastModifiedDate = listView.LastModifiedDate;
            lastModifiedBy   = listView.LastModifiedBy.Name;
            parameters       = new Map<String,ListViewParam>();
            conditions       = new Map<String, List<ListViewCondition>>();

            for (List_View_Config_Parameter__c param: params)
            {
                Boolean readonly = false;
                //these params are read only and are created/updated by automated process on refresh
                if (param.Parameter_Name__c == 'ListViewObjects' || param.Parameter_Name__c == 'IsInitialized')
                    readonly = true;

                parameters.put(param.Parameter_Name__c, new ListViewParam(param.Parameter_Label__c,
                                                                        param.Parameter_Name__c, 
                                                                        param.Parameter_Value__c, 
                                                                        param.Parameter_Type__c,
                                                                        readonly));
            }

            System.debug(LoggingLevel.DEBUG, 'All config params - ' + parameters);


            for (List_View_Config_Condition__c condition: listView.List_View_Config_Conditions__r)
            {
                List<ListViewCondition> conditionList = conditions.get(condition.Field_Name__c.toLowerCase());
                if (conditionList == null)
                {
                    conditionList = new List<ListViewCondition>();
                    conditions.put(condition.Field_Name__c.toLowerCase(), conditionList);
                }
                conditionList.add(new ListViewCondition(condition));
            }
            
        }

        public ListViewConfigWrapper(List_View_Config__c listView)
        {
            this(listView, listView.List_View_Config_Parameters__r);
        }

        @AuraEnabled(cacheable=true)
        public String getName()
        {
            return name;
        }
        
        @AuraEnabled(cacheable=true)
        public String getObject()
        {
            return obj;
        }
        
        @AuraEnabled(cacheable=true)
        public String getLastModifiedText()
        {
            return  'Last Modified By: ' + lastModifiedBy + ' - ' + lastModifiedDate;
        }

        @AuraEnabled(cacheable=true)
        public String getLastModifiedBy()
        {
            return lastModifiedBy;
        }
        
        @AuraEnabled(cacheable=true)
        public DateTime getLastModifiedDate()
        {
            return lastModifiedDate;
        }

        @AuraEnabled(cacheable=true)
        public List<ListViewParam> getParameters()
        {
            List<ListViewParam> params = parameters.values();
            params.sort();

            return params;
        }

        public ListViewParam getParameter(String name)
        {
            return parameters.get(name);
        }

        @AuraEnabled(cacheable=true)
        public List<ListViewCondition> getConditions()
        {
            List<ListViewCondition> allConditions = new List<ListViewCondition>();
            for (String name: conditions.keySet())
                allConditions.addAll(conditions.get(name));

            return allConditions;
        }

        public List<ListViewCondition> getCondition(String field)
        {
            return conditions.get(field);
        }


        
    }

    public class ListViewParam implements Comparable
    {
        public Id paramId;
        public String name;
        public String label;
        public String value;
        public String type;
        public String description;
        public Boolean readonly;

        public ListViewParam(String label, String name, String value, String type, Boolean readonly)
        {
            this.label = label;
            this.name = name;
            this.value = value;
            this.type = type;
            this.description = '';
            this.readonly = readonly;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getReadOnly()
        {
            return readonly;
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return label;
        }

        @AuraEnabled(cacheable=true)
        public String getName()
        {
            return name;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return value;
        }

        /*
         * For those values that need to be returned as a list for display purposes.
         */
        @AuraEnabled(cacheable=true)
        public List<String> getListValues()
        {
            if (value != null)
                return value.split(',');
            else
                return new List<String>();
        }

        @AuraEnabled(cacheable=true)
        public String getType()
        {
            return type;
        }

        @AuraEnabled(cacheable=true)
        public String getPlaceHolder()
        {
            return 'Enter a value here...';
        }

        @AuraEnabled(cacheable=true)
        public String getDescription()
        {
            //USER CONFIG SETTINGS
            if (name == 'AdditionalFields')
                description = 'String holding the additional API field names that should be returned in the list view data (comma delimited).';
            else if (name == 'ReturnSize')
                description = 'The maximum number of rows of data that will be returned. Note that org and lightning page configuration take precedence.';
            else if (name == 'RefreshRate')
                description = 'The number of seconds between refreshes if the list view can be auto refreshed. Refresh rate must be between 10 and 500';
            else if (name == 'TotalColumns')
                description = 'Comma delimited string holding the column API names within the list view that should have a total in the footer.';
            else if (name == 'TotalColumnsColor')
                description = 'The HTML color that the footer row should be displayed in. i.e. #6C95BD.';
            else if (name == 'AllRows')
                description = 'Indicates whether deleted and archived records should be included in list view results. Deleted records are displayed in red in the list';
            
            //ORG WIDE SETTINGS
            else if (name == 'AllowAutomaticDataRefresh')
                description = 'Should the automatic data refresh button be available';
            else if (name == 'AllowInlineEditing')
                description = 'Should inline editing be available to the user';
            else if (name == 'AllowDataExport')
                description = 'Should the user be allowed to export data from the list view';
            else if (name == 'DisplayActionsButton')
                description = 'Are list view actions allowed. If not the actions drop down picklist is not displayed';
            else if (name == 'DisplayListViewReprocessingButton')
                description = 'Can the user reprocess a list view if the config is stale';
            else if (name == 'DisplayOriginalListViewButton')
                description = 'Display the button allowing the user to go directly to the original list view';
            else if (name == 'DisplayRowCount')
                description = 'Display the row count to the user. This is required if allowing exporting of data';
            else if (name == 'DisplaySelectedCount')
                description = 'Display the selected row count to the user. This is required if allowing exporting of selected data';
            else if (name == 'ExcludedObjectTypes')
                description = 'Indicates the objects that should not be allowed in the list view objects drop down';
            else if (name == 'IncludedObjectTypes')
                description = 'Indicates the objects that are allowed in the list view objects drop down. Note - if this setting is used no other objects are displayed';
            else if (name == 'IsInitialized')
                description = 'A read-only field indicating whether the core list views have been initialized';
            else if (name == 'ListViewObjects')
                description = 'A read-only field indicating the list view objects that are available to be displayed';
            else if (name == 'MaxRowsDisplayed')
                description = 'The maximum number of rows that will be displayed to the user. Note that Salesforce starts to timeout above 2500 depending on number of list view fields displayed';
            else if (name == 'QueryPagingSize')
                description = 'The page size used when list views are returning more than 500 rows';
            return description;
        }

        /*
         * Method which indicates whether an update should occur on this parameter immediately after its been changed vs.
         * after the user leaves the input field.
         */
        @AuraEnabled(cacheable=true)
        public Boolean getUpdateImmediate()
        {
            if (getType().toLowerCase() == 'color' 
                || getType().toLowerCase() == 'boolean') 
                return true;
            else 
                return false;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsBoolean()
        {
            if (getType().toLowerCase() == 'boolean') 
                return true;
            else 
                return false;            
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsListString()
        {
            if (getType().toLowerCase() == 'list(string)') 
                return true;
            else 
                return false;            
        }

        public Integer compareTo(Object compareTo) {
            ListViewParam param2 = (ListViewParam) compareTo;
            return label.compareTo(param2.label);
        }
    }

    //---------------------------------------
    //ACTION - class which wraps up an action
    //---------------------------------------
    public class ActionWrapper
    {
        public List_View_Action__c action;
        public List<ActionParameterWrapper> parameters;

        public ActionWrapper(List_View_Action__c action)
        {
            this.action = action;
            parameters = new List<ActionParameterWrapper>();
            for (List_View_Action_Parameter__c param: action.List_View_Action_Parameters__r)
                parameters.add(new ActionParameterWrapper(param));
        }

        @AuraEnabled(cacheable=true)
        public List<ActionParameterWrapper> getParameters()
        {
            return parameters;    
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return action.Label__c;
        }

        @AuraEnabled(cacheable=true)
        public String getObjectType()
        {
            return action.Object_Type__c;
        }

    }

    //---------------------------------------------------------
    //ACTION PARAM - class which wraps up an action parameter.
    //---------------------------------------------------------
    public class ActionParameterWrapper
    {
        public List_View_Action_Parameter__c param;

        public ActionParameterWrapper(List_View_Action_Parameter__c param)
        {
            this.param = param;
        }

        @AuraEnabled(cacheable=true)
        public String getAPIName()
        {
            return param.Field_API_Name__c;
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return param.Label__c;
        }

        @AuraEnabled(cacheable=true)
        public String getType()
        {
            return param.Type__c;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return param.Default_Value__c;
        }

        @AuraEnabled(cacheable=true)
        public String getPlaceholder()
        {
            return param.Placeholder_Text__c;
        }

    }

}