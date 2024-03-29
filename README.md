# SimpliListViews

Trying to figure out a problem? Try this FAQ page - https://github.com/tomansley/SimpliListViews/wiki/FAQ

## Feature Overview
* List views for all objects on one page
* Lists up to 2500 records allowed
* Include any field in list view
* Create list views based on complex SOQL query's and tooling API queries
* Create list view actions
* Inline editing
* Pin your favorite list view
* Multiple column sorting
* Footer calculations
* Row highlighting based on criteria
* Auto-refresh at configured intervals
* Export list view data with the click of a button
* Include deleted records in list view (records show in red)
* Configure the list view page at the org, page and list view level

## Overview
Users spend lots of time working with lists of data. In Salesforce those lists are spread throughout the application. Depending on user process, this can create unnecessary clicks and page loads. Let's make List Views great again! Simpli List Views helps reduce the clicks a user needs when moving from one object list view to another. All list views are displayed on one page.

Salesforce list views could also do with a spruce-up! Ever needed to look deeper into an object hierarchy? Now you can. Move beyond standard list views and add deeper hierarchical custom fields that reference objects multiple levels deeper. For example, on an Account list view you could see the account owners profile by using Owner.Profile.Name in the list views configuration.

And since you have decided to use Simpli List Views and plan on spending all your time using it, you can create actions for list views. Select records that need to be processed and choose an action. Actions can be universal (to delete records), object specific (to update object fields) or list view specific (process oriented action). Actions can be configured to have users enter data before processing the action and very specific actions can be developed using the API.

#### Note
* Only list views that all users or groups of users can see will be displayed. <b>Private list views are not displayed.</b>
* There is a list view processing button available on each page allowing for list views to be reprocessed as needed.

## Examples
A number of example lightning pages have been created to showcase the different configuration options available. The following examples can be seen as tabs in the Simpli List View app.
* Everything Example - displays all available list views with all available widgets.
* Admin Example - displays list views useful for admins. This includes a list of debug logs highlighting metadata list views.
* List Views Example - displays all list views for the Simpli List Views app. A capability type approach!
* Locked Down Example - displays only those list view objects that have been specified at the page layout level.
* Multi Component Example - displays the list view component along with other standard SFDC components.
* 2 List Views Example - displays two list view components next to each other and passes data between them based on selections.
* 3 List Views Example - displays three list view components and passes data between them based on selections.

## Configuration
There are 3 different levels of configuration that are available in the app.</p>
* Org-wide custom settings
* Component or page level settings
* List view configuration

### Org-Wide Custom Settings
These settings are maintained in the "List View Org Wide Setting" custom metadata type in the org setup. They affect all list views displayed in the SFDC org and are typically set by a system administrator at initial setup

* Allow Admin - Display the button to allow some admin changes to the list view component. Note - users with modify all data checked on their profile will always be able to see this button.
* Allow Automatic Data Refresh - Should the automatic data refresh button be available?
* Allow Data Export - Should the user be allowed to export data from the list view?
* Allow Inline Editing - Should inline editing be available to the user?
* Debug - Indicates whether extra debugging should be enabled. This may decrease performance.
* Display Actions Button - Are list view actions allowed? If not, the actions drop down picklist is not displayed
* Display List View Reprocessing Button - Can the user reprocess a list view if the config is stale? If not this button is not available.
* Display Modified - Indicates whether the last modified date and user should be displayed.
* Display Original List View Button - Display the button allowing the user to go directly to the original list view?
* Display Record Popovers - Indicates whether the record detail popover should be displayed when the user moves the mouse over the record URL or name.
* Display Row Count - Display the row count to the user? This is required if allowing exporting of data
* Display Selected Count - Display the selected row count to the user? This is required if allowing exporting of selected data
* Display Text Search - Indicates whether the user can use the text search capability for returned list view results
* Excluded Object Types - Indicates the objects that should not be allowed in the list view objects drop down
* Excluded Record Popover Types - Indicates those object types for which record detail popovers should not be displayed when the user moves the mouse over the record URL or name.
* Included Object Types - Indicates the objects that are allowed in the list view objects drop down. Note - if this setting is used no other objects are displayed
* Is Initialized - A read-only field indicating whether the core list views have been initialized
* List View Objects - A read-only field indicating the list view objects that are available to be displayed
* Max Rows Displayed - The maximum number of rows that will be displayed to the user. Note that Salesforce starts to timeout above 2500 depending on number of list view fields displayed. Use cautiously.
* Query Paging Size - The page size used when list views are returning more than 500 rows


### Component/Page Level Settings
These settings are maintained as part of the Lightning app that the component is a part of and deal with the look and feel of the Lightning component. They affect all list views displayed on the component in the page and are typically set by a system administrator when a new page is created. The settings are typically dictated by how the page is being used and perhaps what device.</p>
* Allow Admin - Display the button to allow some admin changes to the list view component. Note - users with modify all data checked on their profile will always be able to see this button.
* Allow Automatic Data Refresh - Should the automatic data refresh button be available?
* Allow Data Export - Should the user be allowed to export data from the list view?
* Allow Inline Editing - Should inline editing be available to the user?
* Display Actions Button - Are list view actions allowed? If not, the actions drop down picklist is not displayed
* Display List View Reprocessing Button - Can the user reprocess a list view if the config is stale? If not this button is not available.
* Display Modified - Indicates whether the last modified date and user should be displayed.
* Display Original List View Button - Display the button allowing the user to go directly to the original list view?
* Display Record Popovers - Indicates whether the record detail popover should be displayed when the user moves the mouse over the record URL or name.
* Display Row Count - Display the row count to the user? This is required if allowing exporting of data
* Display Selected Count - Display the selected row count to the user? This is required if allowing exporting of selected data
* Display Text Search - Indicates whether the user can use the text search capability for returned list view results
* Excluded Object Types - Indicates the objects that should not be allowed in the list view objects drop down
* Excluded Record Popover Types - Indicates those object types for which record detail popovers should not be displayed when the user moves the mouse over the record URL or name.
* Has Main Title - Indicates whether the name should be displayed as a header or not.
* Included Object Types - Indicates the objects that are allowed in the list view objects drop down. Note - if this setting is used no other objects are displayed
* Join Field Name - The API field name of the field that should be used by this component if it receives ids from another component. If blank, no joining takes place.
* Main Title - String used if the title is displayed. Names should be distinct within a lightning page.
* Mode - Indicates the mode the component should be displayed in. App Page = Multi List View, Single List View = Single List View
* Page Name - Unique string used to identify the list view component and its corresponding user configuration. Names should NEVER be changed.
* Single List View Api Name - The list view API name to use if displaying the component in SINGLE list view mode.
* Single List View Object - The list view object to use if displaying the component in SINGLE list view mode.
* Use Message Channel - Indicates whether the component should send messages when records are selected. This value only needs to be false in situations where many list view components are on the same page. If unsure....set to true!

### List View Configuration</b>
These settings affect individual list views in the SFDC org. They would typically be set by a user after the list view has been created. The user can change these settings by clicking on the list views admin button when viewing the list view. The settings data itself is found in the List View Configs object. Each config has a set of parameters (each corresponding to a configuration) that can be set based on needs.</p>
* <b>Additional Fields - </b>Holds the API field names of additional fields that should be displayed in the list view. This is handy for setting fields which might not be available in the standard list view builder. These fields might include lookup fields outside of those available via the standard Salesforce list view builder.
* <b>Include All Rows - </b>Indicates whether deleted and archived records should be included in list view results.
* <b>Return Size - </b>Indicates the number of rows that should be returned. This value is defaulted to 250. The higher this value, the more page performance will be reduced.
* <b>Refresh Rate - </b>Holds the number of seconds between refreshes if the list view can be auto refreshed.
* <b>Total Column Names - </b>Indicates the API field names of the columns within the list view that should have a total in the footer.
* <b>Total Columns Color - </b>The color that the footer row should be displayed in.

## Actions
Actions can be performed against a set of selected records in a list view. Actions can be specific to a type of object or available for all list views. Deleting a record is an example of an action that is available to all list views. The following actions have been implemented and made available in the app exchange package.
* Edit (single record) - edits the currently selected record
* Edit All (multiple records) - sets all records currently visible on the component to inline editing. Can only be used for list views of 100 records or less
* Delete (multiple records) - deletes all records that are selected
* Clone (single record) - clones the currently selected record
* New (single record) - create a new record (record type based on currently selected list view)
* Send Email (multiple records) - allows for the sending of emails to the chosen records. The email address is taken from a field on the record based on the following rules (in this precedence) - field configured on the action, does the object have a field called Email, does the object have a field called Email__c.
* Account Update (multiple records) - an example action which accepts two user entered fields and updates all selected records based on the input.
* Set Close Lost - an example action which marks all selected records as Close - Lost. Only available on the opportunity.
* Go To A Cool App - an example hyperlink which opens a new browser window/tab and takes the user to the configured URL. (List View object only)</li>

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
* <b>Display Order -</b>1
* <b>Type -</b>STRING
* <b>Default Value -</b>(leave blank)
* <b>Placeholder Text -</b>Put your first name here...

## Other Resources

Features Overview - https://www.youtube.com/watch?v=deoNfudkpEw

Install Guide - https://www.youtube.com/watch?v=PIzyrWuc1YA

Starting Out - https://www.youtube.com/watch?v=bJQchWEK34I

Sizing and Sorting - https://www.youtube.com/watch?v=Uqur5RiKwU0

Using Multiple Components On One Page - https://www.youtube.com/watch?v=nJyTWEPCUac

Creating Custom List View - https://www.youtube.com/watch?v=OLLpIvXqfWc

Large Datasets and Paging - https://www.youtube.com/watch?v=9eHD7ntFFs0

Custom List View Creation - https://youtu.be/OLLpIvXqfWc

Page Modes - https://youtu.be/SNDSkBCQR8Y

Actions - https://youtu.be/n29zVvM6Xtk