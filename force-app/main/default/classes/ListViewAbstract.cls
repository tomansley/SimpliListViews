/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 03-14-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-23-2020   tom@ansleyllc.com   Initial Version
 * 2.0   06-18-2021   tom@ansleyllc.com   Added offset to allow for larger datasets
 * 3.0   07-27-2021   tom@ansleyllc.com   Added logic to handle identification of inline-editing for rows and fields. Beefed up FieldWrapper to handle inline-editing (mainly type identification methods), 
 * 4.0   08-20-2021   tom@ansleyllc.com   Updated all strings to static final variables, Added display vs. non-display action params and added hyperlink action type 
 * 5.0   08-20-2021   tom@ansleyllc.com   Added SalesforceId to row to differentiate between rowId which includes row number 
 * 6.0   08-25-2021   tom@ansleyllc.com   Updated column logic to return type of column, added flag for total column identification on fields,  
 * 7.0   12-16-2021   tom@ansleyllc.com   Default value for action parameter not being set. Fixed.  
**/
public with sharing abstract class ListViewAbstract {
    
    public static Set<String> validTotalColumns = new Set<String>{ListViewHelper.TYPE_INTEGER, ListViewHelper.TYPE_DECIMAL, ListViewHelper.TYPE_CURRENCY, ListViewHelper.TYPE_DOUBLE, ListViewHelper.TYPE_NUMBER};
    public static Set<String> validNameColumnNames = new Set<String>{'Name', 'CaseNumber', 'Task_Name__c', 'ContractNumber'}; //holds the list of column names that if found will produce a link to the record.

    public String listviewMode = null;                                //holds the mode that the list view is being displayed as. NULL = any mode
    public List_View__c listview = null;                              //holds the list view record associated with this request.
    public List_View_Config__c config = null;                         //holds the SFDC list view config SObject
    public ListViewAbstract.ListViewConfigWrapper lvConfig = null;    //holds the list views config after its been wrapped.
    public List<ListViewHelper.ColumnSortData> columnSortData = null; //holds any sorting data coming in on the request
    public Set<String> joinRecordIds = null;                          //holds any join Ids that might be used to identify records.
    public String joinField = null;                                   //if getting data based on join Ids this field describes the join field to use.
    public Integer offset = -1;                                       //holds the offset value if we need to page data into the list view.
    public Boolean isShell = false;                                   //indicates whether the request should only retrieve the rowwrapper without data or all the data
    public String textSearchStr = '';                                 //holds the text search if the user entered one for a SOSL query
    public String compType = '';                                      //indicates the mode of the component calling for data.
    public String pageName = '';                                      //holds the page component name that this list view is associated with

    //----------------------------------------------------------------------------------
    // Method to be overridden
    //----------------------------------------------------------------------------------

    /**
    * @description Method called to return the data for this list view in a format which is
    *              consumable by the UI. This typically means converting SObject rows into
    *              the ListViewAbstract provided RowsWrapper, RowWrapper and FieldWrapper
    *              objects. These objects have additional fields which are used on the UI.
    * @author tom@ansleyllc.com | 10-29-2020 
    * @return RowsWrapper the returned data wrapped in metadata which is used by the UI
    **/
    public abstract RowsWrapper getData();

    /**
    * @description Method called to determine if the list view config parameters are complete or
    *              whether additional parameters need to be included. This could be the case where 
    *              a new list view has been created but the configuration does not yet exist and the 
    *              list view is requested to be displayed. This method should set all default configuration 
    *              and parameters to allow the list view to function appropriately.
    * @author tom@ansleyllc.com | 10-25-2020 
    * @param objectName the object or group name associated with the list view.
    * @param listViewName the list view API name associated with the list view.
    * @return List_View_Config__c 
    **/
    public abstract List<List_View_Config_Parameter__c> getConfigParams(List_View_Config__c config);

    /**
    * @description Method which returns a map of column labels to column API names. Based on the 
    *              implementation of the list view the column labels could be stored in a number 
    *              of places and there may be weird logic to get the values.
    * @author tom@ansleyllc.com | 10-26-2020 
    * @return Map<String, String> the map of column labels with column API names used as keys by the UI.
    **/
    public abstract List<ListViewColumn> getColumnData();

    //----------------------------------------------------------------------------------
    // Concrete methods
    //----------------------------------------------------------------------------------
    public void setTextSearchString(String textSearchStr)
    {
        this.textSearchStr = textSearchStr;
    }

    public void setMode(String compType)
    {
        this.compType = compType;
    }

    public void setPageName(String pageName)
    {
        this.pageName = pageName;
    }

    public void setIsShell(Boolean isShell)
    {
        this.isShell = isShell;
    }

    public void setRequestData(List_View__c listview)
    {
        setRequestData(listview, null, null, null, -1);
    }

    public void setRequestData(List_View__c listview, List<ListViewHelper.ColumnSortData> columnSortData, String joinField, Set<String> joinRecordIds, Integer offset)
    {
        System.debug(LoggingLevel.FINE, 'Starting ListViewAbstract.setRequestData - ' + listview);
        this.listview       = listview;
        this.columnSortData = columnSortData;
        this.joinField      = joinField;
        this.joinRecordIds  = joinRecordIds;
        this.offset         = offset;

        config = ListViewConfigHelper.getListViewConfig(listview.Object_Name__c, listview.API_Name__c);

        List<List_View_Config_Parameter__c> params = getConfigParams(config);

        lvConfig = new ListViewConfigWrapper(listview, config, params, listViewMode);

    }

    //-------------------------------------------------------------------
    //LIST VIEW - wrapper which holds list view information. Note that 
    //            we cannot pass any SObject to a lightning component so 
    //            need to add fields to this wrapper as we need them.
    //-------------------------------------------------------------------
    public class ListViewWrapper
    {
        public Integer offset   = -1;
        public Integer rowLimit = -1;
        public List_View__c listView;
    
        public ListViewWrapper(List_View__c listView)
        {
            this.listView = listView;
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
            return  'Last Modified By: ' + getLastModifiedBy() + ' - ' + getLastModifiedDate();
        }

        @AuraEnabled(cacheable=true)
        public String getLastModifiedBy()
        {
            return listView.LastModifiedBy.Name;
        }
        
        @AuraEnabled(cacheable=true)
        public DateTime getLastModifiedDate()
        {
            return listView.LastModifiedDate;
        }
        
        @AuraEnabled(cacheable=true)
        public String getListViewType()
        {
            return listView.RecordType.Name;
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getIsNonEditable()
        {
            if (ListViewController.hasModifyAll())
                return false;
            else
                return listView.Is_Non_Editable__c;
        }
        
        @AuraEnabled(cacheable=true)
        public String getDefaultSortOrder()
        {
            return listView.Default_Sort_Order__c;
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
        public Map<String, FieldWrapper> fieldMetaDataByName;
        public String csvData;
        public Boolean hasTotalsRow;
        public Boolean isCoreListView = false;
        public Boolean isEdited;
        public Boolean isDefaultSort = false;
        private ListViewConfigWrapper lvConfig = null;
        public String compType = '';
        public String queryString = ''; //the query string that was used to perform the query on the row data.
        
        public RowsWrapper(List_View__c listView, ListViewConfigWrapper lvConfig)
        {
            this.lvConfig = lvConfig;
            this.listView = new ListViewWrapper(listView);
            rows = new List<RowWrapper>();
            fieldMetaData = new List<FieldWrapper>();
            fieldMetaDataByName = new Map<String, FieldWrapper>();
            hasTotalsRow = false;
            objName    = listview.Object_Name__c;
            coreListId = listview.Core_ListView_Id__c;
            if (listView.RecordTypeId == ListViewHelper.coreRTId)
                isCoreListView = true;
            isEdited = false;
        }

        public ListViewConfigWrapper getListViewConfig() 
        {
            return lvConfig;
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
        public String getQueryString()
        {
            return queryString;
        }

        @AuraEnabled(cacheable=true)
        public String getUserTimeZone()
        {
            return UserInfo.getTimeZone().getID();
        }

        @AuraEnabled(cacheable=true)
        public Boolean getCanTextSearch()
        {
            return ListViewHelper.canPerformSOSLQuery(listView.listView);
        }

        @AuraEnabled
        public Boolean getIsEdited()
        {
            return isEdited;
        }

        @AuraEnabled
        public Boolean getIsDefaultSort()
        {
            return isDefaultSort;
        }

        public void setIsDefaultSort(Boolean isDefaultSort)
        {
            this.isDefaultSort = isDefaultSort;
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

        public void clearRows()
        {
            rows.clear();
        }

        public void setCompType(String compType)
        {
            this.compType = compType;
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
            fieldMetaDataByName.put(field.getName(), field);
        }

        public FieldWrapper getFieldMetaData(String fieldName)
        {
            return fieldMetaDataByName.get(fieldName);
        }

        @AuraEnabled(cacheable=true)
        public List<FieldWrapper> getFieldMetaData()
        {
            fieldMetaData.sort();
            return fieldMetaData;
        }

        @AuraEnabled(cacheable=true)
        public Integer getColumnCount(){
            return fieldMetaData.size();
        }

        @AuraEnabled(cacheable=true)
        public Integer getUIColumnCount(){
            return fieldMetaData.size() + 1; //includes extra column for checkbox column
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
            ListViewParam useAPINames = null;
            
            if (lvConfig != null)
                useAPINames = lvConfig.getParameter('ExportHeaderType');

            for (FieldWrapper column: fieldMetaData)
            {
                if (useAPINames == null || useAPINames.getValue() == ListViewHelper.FFALSE)
                    dataStr += '"' + column.label.replaceAll('"', '""') + '"' + ',';
                else
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
        public String recordTypeId;              //the record type id if it exists
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
        public String getRecordTypeId()
        {
            return recordTypeId;
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

        private FieldWrapper getFieldByAPIName(String apiName)
        {
            FieldWrapper field = null;
            for (FieldWrapper wrapper: getFields())
            {
                if (wrapper.getName() == apiName)
                {
                    field = wrapper;
                    break;
                }
            }

            return field;
        }

        private String getSplitColumn(Integer index)
        {
            if (parentWrapper.compType != ListViewHelper.MODE_SPLIT) return ''; //to reduce time for processing.

            String value = '';
            ListViewParam splitColumns = parentWrapper.getListViewConfig().getParameter(ListViewHelper.PARAM_SPLIT_COLUMNS);

            //if we have split columns to use
            if (splitColumns != null && !String.isEmpty(splitColumns.getValue()))
            {
                List<String> splitFields = splitColumns.getValue().split(',');

                //if we have as many split fields as we need based on the index
                if (splitFields.size() > index)
                {
                    //try to find the field data
                    FieldWrapper field = getFieldByAPIName(splitFields[index]);

                    //if we can find the field based on the API name
                    if (field != null)
                        value = field.getUIValue();
                    else
                        value = 'INVALID FIELD';
                //if not then use whatever is in the data at that column index
                } else {
                    List<ListViewAbstract.FieldWrapper> flds = getFields();
                    if (flds.size() > index)
                    {
                        FieldWrapper field = flds[index];
                        value = field.getUIValue();
                    } else {
                        value = '';
                    }
                }

            //if not then use whatever is in the data at that column index
            } else {
                List<ListViewAbstract.FieldWrapper> flds = getFields();
                if (flds.size() > index)
                {
                    FieldWrapper field = flds[index];
                    value = field.getUIValue();
                } else {
                    value = '';
                }
            }

            if (String.isEmpty(value))
                value = '--';

            return value;
        }

        @AuraEnabled(cacheable=true)
        public String getSplitColumnOne()
        {
            return getSplitColumn(0);
        }

        @AuraEnabled(cacheable=true)
        public String getSplitColumnTwo()
        {
            return getSplitColumn(1);
        }

        @AuraEnabled(cacheable=true)
        public String getSplitColumnThree()
        {
            return getSplitColumn(2);
        }

        @AuraEnabled(cacheable=true)
        public String getSplitColumnFour()
        {
            return getSplitColumn(3);
        }

        @AuraEnabled(cacheable=true)
        public String getDataAsCSVString()
        {
            if (parentWrapper.compType == ListViewHelper.MODE_SPLIT) return ''; //to reduce time for processing.

            String dataStr = '';

            if (!this.getIsTotals())
            {
                //get the field data. We make sure to escape delimiter
                for (FieldWrapper fieldData: getFields())
                {
                    if (fieldData.getIsDateTime() && fieldData.getFieldObject() != null)
                    {
                        dataStr += '"' + ((DateTime) fieldData.getFieldObject()).format() + '"' + ',';
                    } else if (fieldData.getIsDate() && fieldData.getFieldObject() != null)
                    {
                        dataStr += '"' + ((Date) fieldData.getFieldObject()).format() + '"' + ',';
                    } else {
                        dataStr += '"' + fieldData.getValue().replaceAll('"', '""') + '"' + ',';
                    }
                }

                dataStr = dataStr.removeEnd(',') + '\n';
            }
            return dataStr;
        }

        /**
        * @description Method which clones a row wrapper. 
        * @author tom@ansleyllc.com | 03-26-2021 
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
            rowClone.recordTypeId   = this.recordTypeId;
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

        /*
         * Method to calculate and set the css styles for fields and columns based on provided configuration styles.
         */
        public void calculateCSSStyles(List<ListViewColumnStyle> columnStyles)
        {
            System.debug(LoggingLevel.FINE, 'Calculating css styles for row!');
            HelperString.debug(columnStyles, 'Column styles are');
            HelperString.debug(fields.keySet(), 'Fields keyset');

            //for each condition
            for (ListViewColumnStyle style: columnStyles)
            {
                System.debug(LoggingLevel.FINE, 'Working style with field name - ' + style.getFieldName());

                //go through each field
                for (FieldWrapper field: fields.values())
                {
                    System.debug(LoggingLevel.FINE, 'Working field with name - ' + field.name.toLowerCase() + ' (' + field.getLongName().toLowerCase() + ')');
                    if (style.getFieldName().toLowerCase() == field.name.toLowerCase() || style.getFieldName().toLowerCase() == field.getLongName().toLowerCase())
                    {
                        field.setCSSStyle(style.getCSSString());
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
        public String width;

        public ListViewColumn(String label, String name, String type)
        {
            this.label = label;
            this.name = name;
            this.type = type;
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            if (label == null) return '';
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
        public Boolean getHasWidth()
        {
            if (String.isEmpty(width)) return false;

            return true;
        }

        @AuraEnabled(cacheable=true)
        public String getWidth()
        {
            return width + 'px';
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

        @AuraEnabled(cacheable=true)
        public Boolean getIsRichTextArea()
        {
            if (this.type == ListViewHelper.TYPE_RICH_TEXTAREA) return true;
            return false;    
        }

        public Integer compareTo(Object compareTo) {
            ListViewColumn desc2 = (ListViewColumn) compareTo;
            return this.getLabel().compareTo(desc2.getLabel());
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
        public String type;            //the type of the obj value
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
        public String columnWidth;     //indicates the preset column width.
        public String cssStyle;        //the css style that should be applied to this field based on the column styles configured

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

        public void setCSSStyle(String cssStyle)
        {
            this.cssStyle = cssStyle;
        }

        @AuraEnabled(cacheable=true)
        public String getCssStyle()
        {
            return cssStyle;
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
        public String getColumnWidth()
        {
            if (!String.isEmpty(columnWidth))
                return 'width: ' + columnWidth + 'px;';
            else
                return '';
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
            
            System.debug(LoggingLevel.DEBUG, 'IS EDITABLE - ' + isEditable + ' - ' + this.label);

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
                this.type = ListViewHelper.TYPE_IMAGE;
            else if (type == ListViewHelper.TYPE_STRING  && this.getValue().contains('<a href='))
                this.type = ListViewHelper.TYPE_HTML;
            else if (type == ListViewHelper.TYPE_COMBOBOX)
                this.type = ListViewHelper.TYPE_STRING;
            else 
                this.type = type;
        }

        /*
         * Method to return a pretty human readable version of the value.
         */
        @AuraEnabled(cacheable=true)
        public String getPrettyValue()
        {
            if (getFieldObject() instanceof Date && getIsDate())
                return ((Date) getFieldObject()).format();
            else if (getFieldObject() instanceof DateTime && getIsDateTime())
                return ((DateTime) getFieldObject()).format();
            else if (getFieldObject() instanceof Time && getIsTime()) {
                Time tm = ((Time) objValue);
                return HelperDate.getStringFromTime(tm);
            }else
                return getValue();
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
                    strValue = ListViewHelper.FFALSE;        //if boolean value is FALSE then send NOTHING
                else 
                    strValue = ListViewHelper.TTRUE;
            
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

            System.debug(LoggingLevel.FINE, 'Finished getValue for ' + this.getName() + ' with type - ' + this.getType() + ' - ' + strValue);
            return strValue;
        }

        public void setValue(Object objValue)
        {
            this.objValue = objValue;
        }

        public Object getFieldObject()
        {
            return this.objValue;
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
            else if (parentObjType == 'CustomObject')
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
                return CacheObjectLabels.get(parentObjType);
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
        public Boolean getIsRichTextArea()
        {
            if (this.type == ListViewHelper.TYPE_RICH_TEXTAREA) return true;
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
                        uiStr = ListViewHelper.TTRUE;
                } else {
                    uiStr = getValue();
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
        public Boolean getIsImage()
        {
            if (this.type == ListViewHelper.TYPE_IMAGE) return true;
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
        public String getCurrencyCode()
        {
            return UserInfo.getDefaultCurrency();
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

        @AuraEnabled(cacheable=true)
        public Integer getColumnIndex()
        {
            return columnIndex;    
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

    public class ListViewColumnStyle
    {
        public List_View_Config_Column_Style__c columnStyle;
        public String fieldName;
        public String font;
        public String decoration;
        public String style;
        public String transform;
        public String variant;
        public String weight;
        public String alignment;
        public String id;
        public String cssStr = null;

        public ListViewColumnStyle(List_View_Config_Column_Style__c columnStyle)
        {
            this.columnStyle = columnStyle;
            fieldName      = columnStyle.Field_Name__c;
            decoration     = columnStyle.Style_Decoration__c;
            font           = columnStyle.Style_Font__c;
            style          = columnStyle.Style_Style__c;
            transform      = columnStyle.Style_Transform__c;
            variant        = columnStyle.Style_Variant__c;
            weight         = columnStyle.Style_Weight__c;
            alignment      = columnStyle.Style_Alignment__c;
            id             = columnStyle.Id;
        }

        public List_View_Config_Column_Style__c getColumnStyle()
        {
            return columnStyle;
        }

        @AuraEnabled(cacheable=true)
        public String getFieldName()
        {
            return fieldName;
        }

        @AuraEnabled(cacheable=true)
        public String getDecoration()
        {
            return decoration;
        }

        @AuraEnabled(cacheable=true)
        public String getFont()
        {
            return font;
        }

        @AuraEnabled(cacheable=true)
        public String getStyle()
        {
            return style;
        }

        @AuraEnabled(cacheable=true)
        public String getTransform()
        {
            return transform;
        }

        @AuraEnabled(cacheable=true)
        public String getVariant()
        {
            return variant;
        }

        @AuraEnabled(cacheable=true)
        public String getWeight()
        {
            return weight;
        }

        @AuraEnabled(cacheable=true)
        public String getAlignment()
        {
            return alignment;
        }

        @AuraEnabled(cacheable=true)
        public String getId()
        {
            return id;
        }

        public String getCSSString()
        {
            if (this.cssStr == null) {
                this.cssStr = '';
                if (!String.isBlank(font)) this.cssStr += 'font-family: "' + font + '";';
                if (!String.isBlank(decoration)) this.cssStr += 'text-decoration:' + decoration + ';';
                if (!String.isBlank(style)) this.cssStr += 'font-style:' + style + ';';
                if (!String.isBlank(transform)) this.cssStr += 'text-transform:' + transform + ';';
                if (!String.isBlank(variant)) this.cssStr += 'font-variant:' + variant + ';';
                if (!String.isBlank(weight)) this.cssStr += 'font-weight:' + weight + ';';
                if (!String.isBlank(alignment)) this.cssStr += 'text-align:' + alignment + ';';
            }

            return cssStr;
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
        public String listViewMode;
        public List_View_Config__c listViewConfig;
        public DateTime lastModifiedDate;
        public String lastModifiedBy;
        public Map<String, ListViewParam> parameters;
        public List<ListViewCondition> conditions;
        public List<ListViewColumnStyle> columnStyles;
        public String name;
        public String label;
        public String obj;

        public ListViewConfigWrapper(String name, String obj, String listViewMode)
        {
            this.name         = name;
            this.obj          = obj;
            this.listViewMode = listViewMode;
            parameters        = new Map<String,ListViewParam>();
            conditions        = new List<ListViewCondition>();
            columnStyles      = new List<ListViewColumnStyle>();
        }

        /*
         * Constructor for if the params were not created yet and were created in this transaction.
         */
        public ListViewConfigWrapper(List_View__c listView, List_View_Config__c listViewConfig, List<List_View_Config_Parameter__c> params, String listViewMode)
        {
            this.listViewMode   = listViewMode;
            this.listView       = listView;
            this.listViewConfig = listViewConfig;
            this.name           = listViewConfig.Name;
            this.label          = listViewConfig.List_View_Label__c;
            this.obj            = listViewConfig.List_View_Object__c;
            lastModifiedDate    = listViewConfig.LastModifiedDate;
            lastModifiedBy      = listViewConfig.LastModifiedBy.Name;
            parameters          = new Map<String,ListViewParam>();
            conditions          = new List<ListViewCondition>();
            columnStyles        = new List<ListViewColumnStyle>();

            for (List_View_Config_Parameter__c param: params)
            {
                Boolean readonly = false;
                //these params are read only and are created/updated by other processes
                if (ListViewConfigHelper.READ_ONLY_PARAMS.contains(param.Parameter_Name__c))
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
            
            for (List_View_Config_Column_Style__c columnStyle: listViewConfig.List_View_Config_Column_Styles__r)
                columnStyles.add(new ListViewColumnStyle(columnStyle));
            
        }

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

        /*
         * Method to get the config parameters. This is where we keep the logic around
         * which parameters to provide based on the list view mode
         */
        @AuraEnabled(cacheable=true)
        public List<ListViewParam> getParameters()
        {
            List<ListViewParam> params = new List<ListViewParam>();
            
            for (ListViewParam param: parameters.values()) {

                if (listViewMode == null) {
                    params.add(param);
                
                //if we are in SPLIT mode then don't pass back the following params
                } else if (listViewMode == ListViewHelper.MODE_SPLIT) {
                    if (param.getName() != ListViewHelper.PARAM_TOTAL_COLUMNS
                        && param.getName() != ListViewHelper.PARAM_TOTAL_COLUMN_COLOR
                        && param.getName() != ListViewHelper.PARAM_REFRESH_RATE
                        && param.getName() != ListViewHelper.PARAM_SINGLE_CLICK_REFRESH
                        && param.getName() != ListViewHelper.PARAM_EXPORT_HEADER_TYPE
                        && param.getName() != ListViewHelper.PARAM_ALL_ROWS
                        && param.getName() != ListViewHelper.PARAM_PDF_ORIENT_PORTRAIT
                        && param.getName() != ListViewHelper.PARAM_PDF_THEME) {
                        params.add(param);
                    }
                } else {
                    params.add(param);
                }
            }
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

        @AuraEnabled(cacheable=true)
        public List<ListViewColumnStyle> getColumnStyles()
        {
            return columnStyles;
        }

        public String getDebugString() {
            String debug = '\n\n------------------- Config -------------------\n';
            debug += 'Name    - ' + name + '\n';
            debug += 'Label   - ' + label + '\n';
            debug += 'Obj     - ' + obj + '\n';
            debug += 'LV Mode - ' + listViewMode + '\n';
            for (ListViewParam param: getParameters())
                debug += '    Param   - ' + param.getName() + '\n';

            debug += '----------------------------------------------\n';
            
            return debug;
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
        public String getClassName()
        {
            return action.Apex_Class_Name__c;
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
        public String getMassCreateListViewName()
        {
            return action.Mass_Create_List_View_Name__c;
        }

        @AuraEnabled(cacheable=true)
        public String getSelectedRecVisibility()
        {
            return action.Selected_Record_Visibility__c;
        }

        @AuraEnabled(cacheable=true)
        public String getHyperlink()
        {
            String url = '';
            for (ActionParameterWrapper param: getAllParameters())
            {
                if (param.getAPIName().toUpperCase() == ListViewActionHelper.PARAM_KEY_URL.toUpperCase())
                {
                    url = param.getValue();
                    break;
                }
            }
            return url;
        }

        @AuraEnabled(cacheable=true)
        public String getEmailTemplateFolder()
        {
            String folder = '';
            for (ActionParameterWrapper param: getAllParameters())
            {
                if (param.getAPIName().toUpperCase() == ListViewActionHelper.PARAM_KEY_EMAIL_TEMP_FOLDER.toUpperCase())
                {
                    folder = param.getValue();
                    break;
                }
            }
            return folder;
        }

        @AuraEnabled(cacheable=true)
        public String getEmailTemplateWhatIdField()
        {
            String whatId = '';
            for (ActionParameterWrapper param: getAllParameters())
            {
                if (param.getAPIName().toUpperCase() == ListViewActionHelper.PARAM_KEY_EMAIL_WHAT_ID.toUpperCase())
                {
                    whatId = param.getValue();
                    break;
                }
            }
            return whatId;
        }

    }

    //---------------------------------------------------------
    //ACTION PARAM - class which wraps up an action parameter.
    //---------------------------------------------------------
    public class ActionParameterWrapper
    {
        public List_View_Action_Parameter__c param;
        private String paramType = null;
        private Object defaultValue = null;
        public String parentObjType;   //the API name of the object that this field looks up to

        public ActionParameterWrapper(List_View_Action_Parameter__c param)
        {
            this.param = param;
            this.defaultValue = param.Default_Value__c;
            this.paramType = param.Type__c.toLowerCase();
        }

        @AuraEnabled(cacheable=true)
        public String getLookupType()
        {
            return param.Lookup_Type__c;
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
            return paramType;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            String strValue = '';
            
            //No Value!
            if (this.defaultValue == null) {
                strValue = '';

            } else if (getIsBoolean()) 
            {
                if (defaultValue instanceof Boolean) 
                {
                    if (((Boolean) defaultValue) == false)
                        strValue = ListViewHelper.FFALSE;        //if boolean value is FALSE then send NOTHING
                    else 
                        strValue = ListViewHelper.TTRUE;
                } else {
                    strValue = String.valueOf(defaultValue);
                }                    
            } else if (getIsDateTime()) {
                //in case of tooling API value is datetime but comes in as a string so we need to check
                if (defaultValue instanceof DateTime) 
                    strValue = String.valueOf(((DateTime) defaultValue).getTime());
                else
                    strValue = String.valueOf(defaultValue);

            } else if (getIsDate()) {
                //in case of tooling API value is date but comes in as a string so we need to check
                if (defaultValue instanceof Date)
                {
                    DateTime dt = HelperDate.convertDateToDateTime((Date) defaultValue);
                    strValue = String.valueOf(dt.getTime()).removeEnd(' 00:00:00');
                } else {
                    strValue = String.valueOf(defaultValue);
                }

            } else if (getIsTime()) {
                //in case of tooling API value is time but comes in as a string so we need to check
                if (defaultValue instanceof Time)
                {
                    Time tm = ((Time) defaultValue);
                    //we don't care about the date...just the time.
                    DateTime dt = DateTime.newInstance(2000, 1, 1, tm.hour(), tm.minute(), tm.second());
                    strValue = String.valueOf(dt.getTime());
                } else {
                    strValue = String.valueOf(defaultValue);
                }

            //String
            } else {
                strValue = String.valueOf(defaultValue);
            }

            System.debug(LoggingLevel.FINE, 'Finished getValue with type - ' + this.getType() + ' - ' + strValue);
            return strValue;
        }

        /**
        * @description the value that is sent to the UI widgets. Sometimes that is different that what is displayed as text.
        **/
        @AuraEnabled(cacheable=true)
        public String getUIValue()
        {
            String uiStr = '';
            if (defaultValue != null)
            {
                if (getIsDateTime()) {
                        uiStr = String.valueOf(defaultValue).replace(' ', 'T') + 'Z';
                
                } else if (getIsDate()) {
                    uiStr = String.valueOf(defaultValue);
                
                } else if (getIsTime()) {
                    uiStr = String.valueOf(defaultValue);
                    
                } else if (getIsBoolean()) 
                {
                    if (defaultValue instanceof Boolean) 
                    {
                        if (((Boolean) defaultValue) == false)
                            uiStr = null;        //if boolean value is FALSE then send NOTHING
                        else 
                            uiStr = ListViewHelper.TTRUE;
                    } else {
                        if (String.valueOf(defaultValue) == ListViewHelper.FFALSE)
                            uiStr = null;
                        else 
                            uiStr = ListViewHelper.TTRUE;
                    }
                }
            }
            System.debug(LoggingLevel.FINE, 'getUIValue - ' + this.getType() + ' - ' + uiStr );
            return uiStr;
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
        
        public void setDefaultValue(Object objValue)
        {
            defaultValue = objValue;
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
        public Boolean getIsRichTextArea()
        {
            if (paramType == ListViewHelper.TYPE_RICH_TEXTAREA) return true;
            return false;    
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