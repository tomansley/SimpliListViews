# SimpliListViews

## Feature Overview
* A Salesforce lightning app exchange managed package
* Only for Lightning (uses LWC therefore My Domain must be set)
* Reduces number of clicks
* Customize list view fields beyond standard list view field options
* Create custom list view actions
* Configure the list view page at the org, page and list view level

## Overview
Users spend lots of time working with lists of data. In Salesforce those lists are spread throughout the application. Depending on user process, this can create unnecessary clicks and page loads. Simpli List Views helps reduce the clicks a user needs when moving from one object list view to another. All list views are displayed on one page.

Salesforce list views could also do with a spruce-up! Ever needed to look deeper into an object hierarchy? Now you can. Move beyond standard list views and add deeper hierarchical custom fields that reference objects multiple levels deeper. For example, on an Account list view you could see the account owners profile by using Owner.Profile.Name in the list views configuration.

And since you have decided to use Simpli List Views and plan on spending all your time using it, you can create actions for list views. Select records that need to be processed and choose an action. Actions can be universal (to delete records), object specific (to update object fields) or list view specific (process oriented action). Actions can be configured to have users enter data before processing the action and very specific actions can be developed using the API.

#### Note
* Only list views that all users or groups of users can see will be displayed. <b>Private list views are not displayed.</b>
* There is a list view processing button available on each page allowing for list views to be reprocessed as needed.

## Examples
A number of example lightning pages have been created to showcase the different configuration options available. The following examples can be seen as tabs in the Simpli List View app.
* List Views Example 1 - displays all available widgets as well as all list views.
* List Views Example 2 - displays list views with no widgets except header text.
* List Views Example 3 - displays list views with no widgets or header text. The simplest it gets!
* List Views Example 4 - displays only those list view objects that have been specified at the page layout level.
* List Views Example 5 - displays a more mobile centric view with all widgets removed.
* List Views Example 6 - displays the list view component along with other standard SFDC components.
* List Views Example 7 - displays two list view components next to each other. Useful for related information viewing.

## Configuration
There are 3 different levels of configuration that are available in the app.</p>
* Org-wide custom settings
* Component or page level settings
* List view configuration

### Org-Wide Custom Settings
These settings are maintained in the "List View Org Wide Setting" custom metadata type in the org setup. They affect all list views displayed in the SFDC org and are typically set by a system administrator at initial setup
* <b>Included Object Types -</b> Indicates those object types that should always be included in the object drop down on the list view component. This is a comma-seperated list of object API names. Note that if this value is blank ALL object types are included by default.
* <b>Excluded Object Types -</b> Indicates those object types that should always be excluded from the object drop down on the list view component. This is a comma-seperated list of object API names. Excluded objects have precedence over included objects.

### Component/Page Level Settings
These settings are maintained as part of the Lightning app that the component is a part of and deal with the look and feel of the Lightning component. They affect all list views displayed on the component in the page and are typically set by a system administrator when a new page is created. The settings are typically dictated by how the page is being used and perhaps what device.</p>
* <b>Has Main Title - </b> Indicates whether the main title on the list view component should be displayed.
* <b>Main Title - </b>Identifies what the title on the component should be if the title is being displayed.
* <b>Display Actions - </b>Indicates whether the actions dropdown should be displayed.
* <b>Display List View Reprocessing Button - </b>Indicates whether the list view reprocessing button should be displayed. This button allows the user to refresh the list view data based on core list view configuration that may have been changed.
* <b>Included Objects - </b>A comma delimited list of API object names that are to be included on the page. If blank, all objects are included.
* <b>Excluded Objects - </b>A comma delimited list of API object names that are to be excluded from the page. If blank, no objects are excluded.

### List View Configuration</b>
These settings affect individual list views in the SFDC org. They would typically be set at a user level after the list view has been created. The settings are found in the List View Configs object. Each config has a set of parameters that can be set based on needs.</p>
* <b>AdditionalFields - </b>Holds the API field names of additional fields that should be displayed in the list view. This is handy for setting fields which might not be available in the standard list view builder. These fields might include lookup fields outside of those available.

## Actions
Actions can be performed against a set of selected records in a list view. Actions can be specific to a type of object or available for all list views. Deleting a record is an example of an action that is available to all list views. Currently 2 actions have been implemented and made available in the app exchange package. Delete and Account Update.

### Action Configuration
All actions are configured for use by the application. Their configuration is held in the List View Actions table (simpli_lv__List_View_Action__c). The following described each field - 
* <b>Label -</b> the label that will be displayed to the user for the action.
* <b>Object Type -</b> the object type that this action is specific to. If no object type is specified the action is available to be used by all list views.
* <b>Apex Class Name -</b> the name of the apex class that holds all processing logic for this action. The apex class specified must extend the simpli_lv.ListViewAction interface.

### Action Implementation
If an action is needed that is not currently available it can be implemented. It is highly encouraged to submit actions back to the app exchange package developer for addition in later releases if they are of a more abstract nature and can be used by lots of users.

#### ListViewAction Interface
The following is some example code which implements the ListViewAction interface -

```
global with sharing class ListViewActionHelloWorld extends simpli_lv.ListViewAction {

    /*
     * This method is required to implement the ListViewAction interface. If processing is successful the
     * UI component expects the string 'Ok' to be returned. Any other string and the UI component assumes
     * processing has failed and the returned string is used as the error message displayed.
     *
     * @param recordIds a list of recordIds that have been sent for processing.
     * @param fieldValues a list of key/value parameters. These parameters are configured.
     */
    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
    {
        System.debug('Hello - ' + (String) fieldValues.get('FirstName') + '. This is where the processing of the records takes place');

        return simpli_lv.ListViewAction.RESULT_OK;
    }
    
}
```

Things to remember during implementation
* the class must be global, otherwise the app will not be able to see it.
* the action is performed as a single transaction. This implies that all governor limits must be adhered to.
* always place processing into a try/catch. The UI component will wait for a valid response before displaying anything to the user.

#### Action Configuration
Once the action has been implemented it then needs to be configured for use by the list views. A new List View Actions record must be created. To follow on from the example above the record would look like the following - 
* <b>Label -</b> Hello World
* <b>Object Type -</b>(leave blank)
* <b>Apex Class Name -</b>ListViewActionHelloWorld

If there are parameters that need to be returned by the user these need to be configured as well. Using the example above we will create one parameter -
* <b>Label -</b>First Name
* <b>Field API Name -</b>FirstName
* <b>Type -</b>STRING
* <b>Default Value -</b>(leave blank)
* <b>Placeholder Text -</b>Put your first name here...
