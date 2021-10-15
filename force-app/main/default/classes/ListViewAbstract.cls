/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 10-13-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-23-2020   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   06-18-2021   tom.h.ansley@medtronic.com   Added offset to allow for larger datasets
 * 3.0   07-27-2021   tom.h.ansley@medtronic.com   Added logic to handle identification of inline-editing for rows and fields. Beefed up FieldWrapper to handle inline-editing (mainly type identification methods), 
 * 4.0   08-20-2021   tom.h.ansley@medtronic.com   Updated all strings to static final variables, Added display vs. non-display action params and added hyperlink action type 
 * 5.0   08-20-2021   tom.h.ansley@medtronic.com   Added SalesforceId to row to differentiate between rowId which includes row number 
 * 6.0   08-25-2021   tom.h.ansley@medtronic.com   Updated column logic to return type of column, added flag for total column identification on fields,  
**/
public with sharing abstract class ListViewAbstract {
    
    public static Set<String> validTotalColumns = new Set<String>{ListViewHelper.TYPE_INTEGER, ListViewHelper.TYPE_DECIMAL, ListViewHelper.TYPE_CURRENCY, ListViewHelper.TYPE_DOUBLE, ListViewHelper.TYPE_NUMBER};
    public static Set<String> validNameColumnNames = new Set<String>{'Name', 'CaseNumber'}; //holds the list of column names that if found will produce a link to the record.

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
    public List<ListViewColumn> getColumnData()
    {
        SObject exampleRow = null;   

        //try to get a true example row
        List<SObject> objectRows = null;
        
        if (listview.SubType__c != ListViewHelper.SUBTYPE_TOOLING) //cannot get an example row if we are working with the tooling API
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

        List<ListViewColumn> listViewColumns = new List<ListViewColumn>();

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
                    listViewColumns.add(new ListViewColumn(d.label, fieldName, d.type.name().toLowerCase()));
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

            System.debug(LoggingLevel.FINE, 'Additional Fields - ' + fields);

            for (String fieldName: fields)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, fieldName);
         
                if (d != null)
                    listViewColumns.add(new ListViewColumn(d.label, fieldName, d.type.name().toLowerCase()));
            }
        }

        return listViewColumns;
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
        System.debug(LoggingLevel.FINE, 'Starting ListViewAbstract.setRequestData - ' + listview);
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

            lvConfig = new ListViewConfigWrapper(listview, config, params);

        } else {
            throw new ListViewException('Configuration for list view with name "' + listview.Label__c + '" not found. Please reprocess list view');
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

        @AuraEnabled(cacheable=true)
        public String getUserTimeZone()
        {
            return UserInfo.getTimeZone().getID();
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
                    debug += '        Key - ' + fieldKey + ', Name - ' + field.name + ', Long Name - ' + field.longName + ', Label - ' + field.label + ', Value - ' + field.getValue() + ', Type - ' + field.getType() + ', objValueId - ' + field.objValueId + ', URL Str - ' + field.urlStr + ', parentObjType - ' + field.parentObjType + ', isTotalsRow - ' + field.isTotalsRow + ', isEditable - ' + field.isEditable + '\n';
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
        public String sfdcId;                    //the SFDC record id
        public String rowId;                     //the SFDC record id + row # in dataset. i.e. 001ZZZZ:1. USed to identify rows on the UI
        public Boolean highlight;                //indicates whether the row should be highlighted due to conditions set by user
        public String highlightColor;            //the color the row should be set to if being highlighted.
        public Boolean isTotals;                 //indicates whether this row is a totals row.
        public Boolean isDeleted;                //indicates whether this row is for a deleted record.
        public Boolean isEdited;                 //indicates whether the row has been edited or not.
        public Boolean isEditable;               //indicates whether the row is editable or not.
        public Boolean isDisplayed;              //indicates whether the row should be displayed or not. (used with text search)

        public RowWrapper(String rowId)
        {
            this.sfdcId         = rowId;
            this.rowId          = rowId;
            this.highlight      = false;
            this.highlightColor = '';
            fields              = new Map<String, FieldWrapper>();
            isTotals            = false;
            isEdited            = false;
            isEditable          = true;
            isDisplayed         = true;
        }

        public void addField(FieldWrapper field)
        {
            field.setKey(this.getRowId());
            fields.put(field.getName() + ':' + field.columnIndex, field);
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
                    addField(new FieldWrapper('', ListViewHelper.TYPE_STRING, String.valueOf(column.columnIndex), column.columnIndex));
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
        public String getSalesforceId()
        {
            return sfdcId;
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
        public Boolean getIsEditable()
        {
            return isEditable;
        }

        public void setIsEditable(Boolean isEditable)
        {
            this.isEditable = isEditable;
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

        @AuraEnabled
        public Boolean getIsDisplayed()
        {
            return isDisplayed;
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

            if (!this.getIsTotals())
            {
                //get the field data. We make sure to escape delimiter
                for (FieldWrapper fieldData: getFields())
                {
                    dataStr += '"' + fieldData.getValue().replaceAll('"', '""') + '"' + ',';
                }

                dataStr = dataStr.removeEnd(',') + '\n';
            }
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

            //Clone ROW
            RowWrapper rowClone = new RowWrapper(rowId);
            rowClone.parentWrapper  = this.parentWrapper;
            rowClone.highlight      = this.highlight;
            rowClone.sfdcId         = this.sfdcId;
            rowClone.highlightColor = this.highlightColor;
            rowClone.isTotals       = this.isTotals;
            rowClone.isDeleted      = this.isDeleted;
            rowClone.isEdited       = this.isEdited;
            rowClone.isDisplayed    = this.isDisplayed;
            rowClone.fields         = new Map<String, FieldWrapper>();


            //Clone FIELDS
            for (FieldWrapper field: fields.values())
            {
                rowClone.addField(field.cloneField(deleteFieldData));
            }
    
            return rowClone;
        }

        /*
         * Method to calculate and set the conditional highlighting of rows based on provided configuration conditions.
         * We pass in the condition details each time as its a complex object that cannot be passed to the lightning UI
         */
        public void calculateHighlighting(List<ListViewCondition> conditions)
        {
            System.debug(LoggingLevel.FINE, 'Calculating highlighting for row!');
            System.debug(LoggingLevel.FINE, 'Conditions are - ' + conditions);

            //REVERSE conditions due to precedence
            List<ListViewCondition> revConditions = new List<ListViewCondition>();

            for(Integer i = conditions.size() - 1; i >= 0; i--){
                revConditions.add(conditions[i]);
            }            

            //for each condition
            for (ListViewCondition condition: revConditions)
            {
                System.debug(LoggingLevel.FINE, 'Working with - ' + condition.getFieldName());

                //go through each field
                for (FieldWrapper field: fields.values())
                {

                    //if we have a match between field name and condition field name
                    if (condition.getFieldName() == field.name.toLowerCase() || condition.getFieldName() == field.getLongName().toLowerCase())
                    {

                        System.debug(LoggingLevel.FINE, 'We have a matching condition!');

                        String color = ListViewConfigHelper.validateFieldCondition(field.getValue(), field.type, condition.getCondition());

                        System.debug(LoggingLevel.FINE, 'Condition validation result = ' + color);

                        //get the highlight color as well regardless.
                        if (color != '')
                            highlightColor = color;
                    }

                }
            }

        }
    }

    //---------------------------------------------------------------------
    //COLUMN - wrapper holding data for a single column in a table.
    //---------------------------------------------------------------------
    public class ListViewColumn implements Comparable
    {
        public String label;
        public String name;
        public String type;

        public ListViewColumn(String label, String name, String type)
        {
            this.label = label;
            this.name = name;
            this.type = type;
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return label;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return name;
        }

        @AuraEnabled(cacheable=true)
        public String getType()
        {
            return type;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsString()
        {
            if (this.type == ListViewHelper.TYPE_STRING) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsTextArea()
        {
            if (this.type == ListViewHelper.TYPE_TEXTAREA) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsURL()
        {
            if (this.type == ListViewHelper.TYPE_URL) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsBoolean()
        {
            if (this.type == ListViewHelper.TYPE_BOOLEAN) return true;
            return false;    
        }
                
        @AuraEnabled(cacheable=true)
        public Boolean getIsLookup()
        {
            if (this.type == ListViewHelper.TYPE_LOOKUP) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsCurrency()
        {
            if (this.type == ListViewHelper.TYPE_CURRENCY) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDate()
        {
            if (this.type == ListViewHelper.TYPE_DATE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDateTime()
        {
            if (this.type == ListViewHelper.TYPE_DATETIME) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsTime()
        {
            if (this.type == ListViewHelper.TYPE_TIME) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPicklist()
        {
            if (this.type == ListViewHelper.TYPE_PICKLIST) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsMultiPicklist()
        {
            if (this.type == ListViewHelper.TYPE_MULTI_PICK) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsDecimal()
        {
            if (this.type == ListViewHelper.TYPE_DECIMAL) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsInteger()
        {
            if (this.type == ListViewHelper.TYPE_INTEGER) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDouble()
        {
            if (this.type == ListViewHelper.TYPE_DOUBLE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPercent()
        {
            if (this.type == ListViewHelper.TYPE_PERCENT) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPhone()
        {
            if (this.type == ListViewHelper.TYPE_PHONE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsEmail()
        {
            if (this.type == ListViewHelper.TYPE_EMAIL) return true;
            return false;    
        }

        public Integer compareTo(Object compareTo) {
            ListViewColumn desc2 = (ListViewColumn) compareTo;
            return label.compareTo(desc2.label);
        }
    }

    //---------------------------------------------------------------------
    //FIELD - wrapper holding data for a single cell in a table. This data 
    //        includes both table data as well as config for how it should 
    //        be displayed.
    //---------------------------------------------------------------------
    public class FieldWrapper implements Comparable
    {

        public String label;           //the label of the field
        public Object objValue;        //the value as an Object
        public String objValueId;      //the id of the objValue record if it is a lookup
        public SObject fieldObj;       //the SObject associated with the field. Used when retrieving lookup information
        public String type;
        public String urlStr;          //the URL that the field should display if one is available.
        public String urlTarget;       //identifies the target of the URL
        public String name;            //the short API name of the field. i.e. quantity
        public String longName;        //the long API name of the field i.e. opportunitylineitems.quantity
        public Boolean sortDir;        //true = asc, false = desc
        public String sortIndex;
        public Integer columnIndex;    //identifies the column that this field is a part of
        public String key;
        public Boolean isSortable;     //identifies whether the field is sortable.
        public Boolean isEditable;     //identifies whether the field can be edited inline.
        public String parentObjType;   //the API name of the object that this field looks up to
        public Boolean isTotalsRow;    //identifies whether the row this field is a part of is a totals row.

        public FieldWrapper(String label, Object objValue, String type, String name, Integer columnIndex, String parentObjType)
        {
            this.label         = label;
            this.name          = name;
            this.sortDir       = true;
            this.sortIndex     = '';
            this.columnIndex   = columnIndex;
            this.isSortable    = true;
            this.urlTarget     = '_self';
            this.objValue      = objValue;
            this.parentObjType = parentObjType;
            this.longName      = '';
            this.isTotalsRow   = false;

            this.setValue(objValue);
            this.setType(type); //must be below setValue() as it uses value to determine type in some cases.
            
            String debug = '\n\n---------------------------------------------------------------\n';
            debug       += 'Label - ' + this.label + '\n';
            debug       += 'type - ' + this.type + '\n';
            debug       += 'object - ' + this.objValue + '\n';
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
            this.isTotalsRow = false;

            this.setType(type);

            String debug = '\n\n---------------------------------------------------------------\n';
            debug       += 'Label - ' + this.label + '\n';
            debug       += 'type - ' + this.type + '\n';
            debug       += 'name - ' + this.name + '\n';
            debug       += 'columnIndex - ' + this.columnIndex + '\n';
            debug       += '---------------------------------------------------------------\n';
            System.debug(LoggingLevel.FINE, debug);
        }

        public void setIsTotalsRow(Boolean isTotalsRow)
        {
            this.isTotalsRow = isTotalsRow;
        }

        public void setKey(String rowId)
        {
            key = rowId + ':' + String.valueOf(this.columnIndex);
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

        public void setFieldObj(SObject fieldObj)
        {
            this.fieldObj = fieldObj;
            if (String.isEmpty(objValueId) && fieldObj != null)
                objValueId = String.valueOf(fieldObj.get('Id'));

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
            if (type == ListViewHelper.TYPE_STRING && this.name.contains('.Name'))
                this.type = ListViewHelper.TYPE_LOOKUP;
            else if (type == ListViewHelper.TYPE_STRING  && this.getValue().contains('<img src='))
                this.type = ListViewHelper.TYPE_HTML;
            else if (type == ListViewHelper.TYPE_STRING  && this.getValue().contains('<a href='))
                this.type = ListViewHelper.TYPE_HTML;
            else 
                this.type = type;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            String strValue = '';
            
            //No Value!
            if (this.objValue == null) {
                strValue = '';

            } else if (this.isTotalsRow)
            {
                strValue = String.valueOf(objValue);

            } else if (getIsBoolean()) 
            {
                if (((Boolean) objValue) == false)
                    strValue = 'false';        //if boolean value is FALSE then send NOTHING
                else 
                    strValue = 'true';
            
            } else if (getIsDateTime()) {
                //in case of tooling API value is datetime but comes in as a string so we need to check
                if (objValue instanceof DateTime) 
                    strValue = String.valueOf(((DateTime) objValue).getTime());
                else
                    strValue = String.valueOf(objValue);

            } else if (getIsDate()) {
                //in case of tooling API value is date but comes in as a string so we need to check
                if (objValue instanceof Date)
                {
                    DateTime dt = HelperDate.convertDateToDateTime((Date) objValue);
                    strValue = String.valueOf(dt.getTime()).removeEnd(' 00:00:00');
                } else {
                    strValue = String.valueOf(objValue);
                }

            } else if (getIsTime()) {
                //in case of tooling API value is time but comes in as a string so we need to check
                if (objValue instanceof Time)
                {
                    Time tm = ((Time) objValue);
                    //we don't care about the date...just the time.
                    DateTime dt = DateTime.newInstance(2000, 1, 1, tm.hour(), tm.minute(), tm.second());
                    strValue = String.valueOf(dt.getTime());
                } else {
                    strValue = String.valueOf(objValue);
                }

            //String
            } else {
                strValue = String.valueOf(objValue);
            }

            System.debug(LoggingLevel.FINE, 'Finished getValue with type - ' + this.type + ' - ' + strValue);
            return strValue;
        }

        public void setValue(Object objValue)
        {
            this.objValue = objValue;
        }

        @AuraEnabled(cacheable=true)
        public String getObjValueId()
        {
            return objValueId;
        }

        public void setObjValueId(String objValueId)
        {
            this.objValueId = objValueId;
        }

        @AuraEnabled
        public Boolean getHasURL()
        {
            if (String.isEmpty(this.urlStr)) return false;
            return true;    
        }
        
        public void createURL()
        {
            System.debug(LoggingLevel.FINE, 'createURL called - ' + parentObjType + ', ' + objValueId + ', ' + fieldObj);
            String urlStr = '';
            urlTarget = '_blank';

            if (parentObjType == 'ApexLog')
                urlStr = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/setup/ApexDebugLogDetail/page?address=%2Fp%2Fsetup%2Flayout%2FApexDebugLogDetailEdit%2Fd%3Fapex_log_id%3D' + String.valueOf(objValue);
            else if (parentObjType == 'ApexClassOrTrigger')
                urlStr = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objValueId;
            else if (fieldObj != null)
                urlStr = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + String.valueOf(fieldObj.get('Id')) + '/view';
            else if (this.name == 'id')
                urlStr = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + String.valueOf(objValue) + '/view';
            else
                urlStr = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + objValueId + '/view';
            
            this.urlStr = urlStr;
            System.debug(LoggingLevel.FINE, 'createURL result - ' + urlStr);
        }

        @AuraEnabled(cacheable=true)
        public String getURL()
        {
            return urlStr;
        }
        
        @AuraEnabled(cacheable=true)
        public String getURLTarget()
        {
            return urlTarget;
        }
        
        @AuraEnabled(cacheable=true)
        public String getFieldObjLabel()
        {
            if (!String.isEmpty(parentObjType))
                return HelperSchema.getObjectLabel(parentObjType);
            else
                return '';
        }

        @AuraEnabled(cacheable=true)
        public String getFieldObjName()
        {
            return parentObjType;
        }

        public void setParentObjType(String parentObjType)
        {
            this.parentObjType = parentObjType;
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsId()
        {
            if (this.type == ListViewHelper.TYPE_ID) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsString()
        {
            if (this.type == ListViewHelper.TYPE_STRING) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsTextArea()
        {
            if (this.type == ListViewHelper.TYPE_TEXTAREA) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsURL()
        {
            if (this.type == ListViewHelper.TYPE_URL) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsBoolean()
        {
            if (this.type == ListViewHelper.TYPE_BOOLEAN) return true;
            return false;    
        }
        
        /**
        * @description the value that is sent to the UI widgets. Sometimes that is different that what is displayed as text.
        **/
        @AuraEnabled(cacheable=true)
        public String getUIValue()
        {
            String uiStr = '';
            if (!this.isTotalsRow && objValue != null)
            {
                if (getIsDateTime()) {
                        uiStr = String.valueOf(objValue).replace(' ', 'T') + 'Z';
                
                } else if (getIsDate()) {
                    uiStr = String.valueOf(objValue);
                
                } else if (getIsTime()) {
                    uiStr = String.valueOf(objValue);
                    
                } else if (getIsBoolean()) 
                {
                    if (((Boolean) objValue) == false)
                        uiStr = null;        //if boolean value is FALSE then send NOTHING
                    else 
                        uiStr = 'true';
                }
            }
            System.debug(LoggingLevel.FINE, 'getUIValue - ' + this.getType() + ' - ' + uiStr );
            return uiStr;
        }
        
        /*
         * For those values that need to be returned as a list for display purposes.
         */
        @AuraEnabled(cacheable=true)
        public List<String> getUIMultiPicklistValues()
        {
            if (objValue != null && objValue instanceof String)
                return String.valueOf(objValue).split(';');
            else
                return new List<String>();
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsHTML()
        {
            if (this.type == ListViewHelper.TYPE_HTML) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsNotHTML()
        {
            if (this.type == ListViewHelper.TYPE_HTML) return false;
            return true;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsLookup()
        {
            if (this.type == ListViewHelper.TYPE_LOOKUP) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsCurrency()
        {
            if (this.type == ListViewHelper.TYPE_CURRENCY) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDate()
        {
            if (this.type == ListViewHelper.TYPE_DATE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDateTime()
        {
            if (this.type == ListViewHelper.TYPE_DATETIME) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsTime()
        {
            if (this.type == ListViewHelper.TYPE_TIME) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPicklist()
        {
            if (this.type == ListViewHelper.TYPE_PICKLIST) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsMultiPicklist()
        {
            if (this.type == ListViewHelper.TYPE_MULTI_PICK) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsDecimal()
        {
            if (this.type == ListViewHelper.TYPE_DECIMAL) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsInteger()
        {
            if (this.type == ListViewHelper.TYPE_INTEGER) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDouble()
        {
            if (this.type == ListViewHelper.TYPE_DOUBLE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPercent()
        {
            if (this.type == ListViewHelper.TYPE_PERCENT) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPhone()
        {
            if (this.type == ListViewHelper.TYPE_PHONE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsEmail()
        {
            if (this.type == ListViewHelper.TYPE_EMAIL) return true;
            return false;    
        }

        public FieldWrapper cloneField(Boolean deleteFieldData)
        {
            Object objValue = null;
            if (!deleteFieldData)
                objValue = this.objValue;
            FieldWrapper cloneField = new FieldWrapper(label, objValue, type, name, columnIndex, parentObjType);
            cloneField.isSortable = isSortable;
            cloneField.setIsTotalsRow(isTotalsRow);
            cloneField.longName = longName;
            cloneField.urlTarget = urlTarget;
            cloneField.sortDir = sortDir;
            cloneField.urlStr = urlStr;
            cloneField.setFieldObj(fieldObj);
            cloneField.objValueId = objValueId;

            //if we are not deleting the field then it means its the header record so allow edits.
            if (!deleteFieldData)
            {
                cloneField.setIsEditable(isEditable);

            //if we are deleting the field it means its a child record so no edits allowed.
            } else {
                cloneField.setIsEditable(false);
            }

            return cloneField;
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
        public List_View__c listView;
        public List_View_Config__c listViewConfig;
        public DateTime lastModifiedDate;
        public String lastModifiedBy;
        public Map<String, ListViewParam> parameters;
        public List<ListViewCondition> conditions;
        public String name;
        public String label;
        public String obj;

        public ListViewConfigWrapper(String name, String obj)
        {
            this.name = name;
            this.obj = obj;
            parameters       = new Map<String,ListViewParam>();
            conditions       = new List<ListViewCondition>();
        }

        /*
         * Constructor for if the params were not created yet and were created in this transaction.
         */
        public ListViewConfigWrapper(List_View__c listView, List_View_Config__c listViewConfig, List<List_View_Config_Parameter__c> params)
        {
            this.listView       = listView;
            this.listViewConfig = listViewConfig;
            this.name        = listViewConfig.Name;
            this.label       = listViewConfig.List_View_Label__c;
            this.obj         = listViewConfig.List_View_Object__c;
            lastModifiedDate = listViewConfig.LastModifiedDate;
            lastModifiedBy   = listViewConfig.LastModifiedBy.Name;
            parameters       = new Map<String,ListViewParam>();
            conditions       = new List<ListViewCondition>();

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

            System.debug(LoggingLevel.FINE, 'All config params - ' + parameters);


            for (List_View_Config_Condition__c condition: listViewConfig.List_View_Config_Conditions__r)
                conditions.add(new ListViewCondition(condition));
            
        }

        //public ListViewConfigWrapper(List_View_Config__c listViewConfig)
        //{
         //   this(listViewConfig, listViewConfig.List_View_Config_Parameters__r);
        //}

        public List_View__c getListView()
        {
            return listView;
        }

        @AuraEnabled(cacheable=true)
        public String getName()
        {
            return name;
        }
        
        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return label;
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
            return conditions;
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
            return ListViewConfigDescriptions.getLongDescription(name);
        }

        /*
         * Method which indicates whether an update should occur on this parameter immediately after its been changed vs.
         * after the user leaves the input field.
         */
        @AuraEnabled(cacheable=true)
        public Boolean getUpdateImmediate()
        {
            if (getType().toLowerCase() == 'color' 
                || getType().toLowerCase() == ListViewHelper.TYPE_BOOLEAN) 
                return true;
            else 
                return false;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsBoolean()
        {
            if (getType().toLowerCase() == ListViewHelper.TYPE_BOOLEAN) 
                return true;
            else 
                return false;            
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsListString()
        {
            if (getName() == 'ExcludedObjectTypes'  //total hack as we cannot add new picklist values!
                || getName() == 'IncludedObjectTypes'
                || getName() == 'ExcludedRecordPopoverTypes') 
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
        public List<ActionParameterWrapper> displayParameters;
        public List<ActionParameterWrapper> nonDisplayParameters;

        public ActionWrapper(List_View_Action__c action)
        {
            this.action = action;
            displayParameters = new List<ActionParameterWrapper>();
            nonDisplayParameters = new List<ActionParameterWrapper>();
            for (List_View_Action_Parameter__c param: action.List_View_Action_Parameters__r)
            {
                ActionParameterWrapper wrapper = new ActionParameterWrapper(param);
                if (wrapper.getIsDisplayed())
                    displayParameters.add(wrapper);
                else
                    nonDisplayParameters.add(wrapper);
            }
        }

        @AuraEnabled(cacheable=true)
        public Boolean getHasDisplayParameters()
        {
            if (displayParameters.size() > 0)
                return true;
            else
                return false;
        }

        @AuraEnabled(cacheable=true)
        public List<ActionParameterWrapper> getDisplayParameters()
        {
            return displayParameters;    
        }

        @AuraEnabled(cacheable=true)
        public List<ActionParameterWrapper> getNonDisplayParameters()
        {
            return nonDisplayParameters;    
        }

        @AuraEnabled(cacheable=true)
        public List<ActionParameterWrapper> getAllParameters()
        {
            List<ActionParameterWrapper> all = new List<ActionParameterWrapper>();
            all.addAll(nonDisplayParameters);
            all.addAll(displayParameters);
            return all;    
        }

        @AuraEnabled(cacheable=true)
        public String getPrimaryKey()
        {
            return action.Primary_Key__c;
        }

        @AuraEnabled(cacheable=true)
        public String getLabel() //do not change this. Its used on the UI for SelectOption
        {
            return action.Label__c;
        }

        @AuraEnabled(cacheable=true)
        public String getValue() //do not change this. Its used on the UI for SelectOption
        {
            return action.Primary_Key__c;
        }

        @AuraEnabled(cacheable=true)
        public String getObjectType()
        {
            return action.Object_Type__c;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsHyperlink()
        {
            return action.Is_Hyperlink__c;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsFlow()
        {
            return action.Is_Flow__c;
        }

        @AuraEnabled(cacheable=true)
        public String getFlowAPIName()
        {
            return action.Flow_API_Name__c;
        }

        @AuraEnabled(cacheable=true)
        public String getFlowType()
        {
            return action.Flow_Type__c;
        }

        @AuraEnabled(cacheable=true)
        public String getFlowFrameHeight()
        {
            return action.Flow_Frame_Height__c;
        }

        @AuraEnabled(cacheable=true)
        public String getFlowFrameWidth()
        {
            return action.Flow_Frame_Width__c;
        }

        @AuraEnabled(cacheable=true)
        public String getHyperlink()
        {
            String url = '';
            for (ActionParameterWrapper param: nonDisplayParameters)
            {
                if (param.getAPIName().toUpperCase() == ListViewActionHelper.PARAM_KEY_URL)
                    url = param.getValue();
            }
            return url;
        }
    }

    //---------------------------------------------------------
    //ACTION PARAM - class which wraps up an action parameter.
    //---------------------------------------------------------
    public class ActionParameterWrapper
    {
        public List_View_Action_Parameter__c param;
        private String paramType = null;

        public ActionParameterWrapper(List_View_Action_Parameter__c param)
        {
            this.param = param;
            this.paramType = param.Type__c.toLowerCase();
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

        @AuraEnabled(cacheable=true)
        public Boolean getIsDisplayed()
        {
            if (param.Display_Order__c == -1)
                return false;
            else    
                return true;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsString()
        {
            if (paramType == ListViewHelper.TYPE_STRING) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsTextArea()
        {
            if (paramType == ListViewHelper.TYPE_TEXTAREA) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsURL()
        {
            if (paramType == ListViewHelper.TYPE_URL) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsBoolean()
        {
            if (paramType == ListViewHelper.TYPE_BOOLEAN) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsLookup()
        {
            if (paramType == ListViewHelper.TYPE_LOOKUP) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsCurrency()
        {
            if (paramType == ListViewHelper.TYPE_CURRENCY) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDate()
        {
            if (paramType == ListViewHelper.TYPE_DATE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDateTime()
        {
            if (paramType == ListViewHelper.TYPE_DATETIME) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsTime()
        {
            if (paramType == ListViewHelper.TYPE_TIME) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPicklist()
        {
            if (paramType == ListViewHelper.TYPE_PICKLIST) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsMultiPicklist()
        {
            if (paramType == ListViewHelper.TYPE_MULTI_PICK) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsDecimal()
        {
            if (paramType == ListViewHelper.TYPE_DECIMAL) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsInteger()
        {
            if (paramType == ListViewHelper.TYPE_INTEGER) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsDouble()
        {
            if (paramType == ListViewHelper.TYPE_DOUBLE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPercent()
        {
            if (paramType == ListViewHelper.TYPE_PERCENT) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsPhone()
        {
            if (paramType == ListViewHelper.TYPE_PHONE) return true;
            return false;    
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsEmail()
        {
            if (paramType == ListViewHelper.TYPE_EMAIL) return true;
            return false;    
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsRichText()
        {
            if (paramType == ListViewHelper.TYPE_RICH_TEXTAREA) return true;
            return false;    
        }
    }

}