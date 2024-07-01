public with sharing class ListViewActionWrapper {

    public Action action;
    public List<ActionParameterWrapper> displayParameters;
    public List<ActionParameterWrapper> nonDisplayParameters;

    public ListViewActionWrapper(List_View_Action__c action)
    {
        this.action = new Action(action);
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
        return action.primaryKey;
    }

    @AuraEnabled(cacheable=true)
    public String getLabel() //do not change this. Its used on the UI for SelectOption
    {
        return action.label;
    }

    @AuraEnabled(cacheable=true)
    public String getValue() //do not change this. Its used on the UI for SelectOption
    {
        return action.primaryKey;
    }

    @AuraEnabled(cacheable=true)
    public String getClassName()
    {
        return action.apexClassName;
    }

    @AuraEnabled(cacheable=true)
    public String getObjectType()
    {
        return action.objectType;
    }

    @AuraEnabled(cacheable=true)
    public Boolean getIsHyperlink()
    {
        return action.isHyperlink;
    }

    @AuraEnabled(cacheable=true)
    public Boolean getIsFlow()
    {
        return action.isFlow;
    }

    @AuraEnabled(cacheable=true)
    public String getFlowAPIName()
    {
        return action.flowAPIName;
    }

    @AuraEnabled(cacheable=true)
    public String getFlowType()
    {
        return action.flowType;
    }

    @AuraEnabled(cacheable=true)
    public String getFlowFrameHeight()
    {
        return action.flowFrameHeight;
    }

    @AuraEnabled(cacheable=true)
    public String getFlowFrameWidth()
    {
        return action.flowFrameWidth;
    }

    @AuraEnabled(cacheable=true)
    public String getMassCreateListViewName()
    {
        return action.massCreateListViewName;
    }

    @AuraEnabled(cacheable=true)
    public String getSelectedRecVisibility()
    {
        return action.selectedRecordVisibility;
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

    public class Action
    {
        public String id;
        public String label;
        public String apexClassName;
        public String objectType;
        public String primaryKey;
        public String subtype;
        public String recordTypeId;
        public String recordTypeName;
        public String permissions;
        public Boolean isHyperlink;
        public Boolean isActive;
        public Boolean isFlow;
        public String flowAPIName;
        public String flowFrameHeight;
        public String flowFrameWidth;
        public String flowType;
        public String massCreateListViewName;
        public String selectedRecordVisibility;
        public String componentName;

        public Action(List_View_Action__c action)
        {
            id = action.Id;
            label = action.Label__c;
            apexClassName = action.Apex_Class_Name__c;
            objectType = action.Object_Type__c;
            primaryKey = action.Primary_Key__c;
            subtype = action.Subtype__c;
            recordTypeId = action.RecordTypeId;
            recordTypeName = action.RecordType.Name;
            permissions = action.Permissions__c;
            isHyperlink = action.Is_Hyperlink__c;
            isActive = action.Is_Active__c;
            isFlow = action.Is_Flow__c;
            flowAPIName = action.Flow_API_Name__c;
            flowFrameHeight = action.Flow_Frame_Height__c;
            flowFrameWidth = action.Flow_Frame_Width__c;
            flowType = action.Flow_Type__c;
            massCreateListViewName = action.Mass_Create_List_View_Name__c;
            selectedRecordVisibility = action.Selected_Record_Visibility__c;
            componentName = action.Component_Name__c;
        }
    }

    //---------------------------------------------------------
    //ACTION PARAM - class which wraps up an action parameter.
    //---------------------------------------------------------
    public class ActionParameterWrapper
    {
        public String lookupType;
        public String paramType = null;
        public String fieldAPIName;
        public String label;
        public String placeHolderText;
        public Decimal displayOrder;

        private Object defaultValue = null;
        public String parentObjType;   //the API name of the object that this field looks up to

        public ActionParameterWrapper(List_View_Action_Parameter__c param)
        {
            displayOrder      = param.Display_Order__c;
            placeHolderText   = param.Placeholder_Text__c;
            lookupType        = param.Lookup_Type__c;
            fieldAPIName      = param.Field_API_Name__c;
            label             = param.Label__c;
            this.defaultValue = param.Default_Value__c;
            this.paramType    = param.Type__c.toLowerCase();
        }

        @AuraEnabled(cacheable=true)
        public String getLookupType()
        {
            return lookupType;
        }

        @AuraEnabled(cacheable=true)
        public String getAPIName()
        {
            return fieldAPIName;
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return label;
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
            return placeholderText;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsDisplayed()
        {
            if (displayOrder == -1)
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