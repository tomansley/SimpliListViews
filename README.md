# SimpliListViews

## Feature Overview
* A Salesforce lightning app exchange managed package
* Only for Lightning (uses LWC so My Domain must be set)
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
