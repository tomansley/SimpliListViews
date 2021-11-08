/**
 * @description       : Helper class to handle anything UserRole related.
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-04-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   11-04-2021   tom@ansleyllc.com   Initial Version
**/
public with sharing class HelperRole {

    public static Map<UserRole, Object> userRoleHierarchy = null; //map of all roles in a hierarchical format
    public static Map<Id, UserRole> userRoles = null;             //list of all roles by Id

    /**
    * @description Method to identify whether the CURRENT user is either in the provided roles or the provided roles and their subordinates.
    * @author tom@ansleyllc.com | 10-29-2021 
    * @param roleNames the role names to check against.
    * @param includeSubOrds identifies if subordinates should be included as well
    * @return Boolean 

        Set<String> roleNames = new Set<String>{'CEO'};
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperRole.isUserInRoles(roleNames, true));

    **/
    public static Boolean isUserInRoles(Set<String> roleNames, Boolean includeSubOrds)
    {
        Id userRoleId = UserInfo.getUserRoleId();
        if (userRoleId == null) 
            return false;
        else
            return isUserInRoles(UserInfo.getUserRoleId(), roleNames, includeSubOrds);
    }

    /**
    * @description Method to identify whether a PROVIDED user is either in the provided roles or the provided roles and their subordinates.
    * @author tom@ansleyllc.com | 10-28-2021 
    * @param roleNames the role names to check against.
    * @param includeSubOrds identifies if subordinates should be included as well
    * @return Boolean 

        Set<String> roleNames = new Set<String>{'SVPSalesMarketing'};
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperRole.isUserInRoles('00E3h000000QlGYEA0', roleNames, true));

    **/
    public static Boolean isUserInRoles(Id userRoleId, Set<String> roleNames, Boolean includeSubOrds)
    {
        initializeRoleHierarchy();

        System.debug(LoggingLevel.DEBUG, 'Starting isUserInRoles(' + roleNames + ', ' + includeSubOrds + ')');
        
        Boolean result = false;

        UserRole userRole = HelperRole.userRoles.get(userRoleId);
        System.debug(LoggingLevel.DEBUG, 'User Role - ' + userRole.DeveloperName);

        //no subordinates
        if (!includeSubOrds)
        {
            for (String roleName: roleNames)
            {
                if (roleName == userRole.DeveloperName)
                    result = true;
            }
        
        //subordinates 
        } else {

            //for each role name provided to check against
            for (String roleName: roleNames)
            {
                //get the roles hierarchy
                Map<UserRole, Object> hierarchy = getUserRoleHierarchy(roleName);
                if (hierarchy != null)
                {
                    result = isRoleInHierarchy(userRole.DeveloperName, hierarchy);
                    if (result)
                        break;
                }
            }

        }

        System.debug(LoggingLevel.DEBUG, 'Finished isUserInRoles - ' + result);
        return result;
    }
        
    
    //--------------------------------------------------------------------------------------------------
    // PRIVATE METHODS
    //--------------------------------------------------------------------------------------------------

    /**
    * @description Method to initialize the role hierarchy. This is done once for all roles thus reducing the number of SOQL
    *              statements that need to be retrieved when traversing the role hierarchy.
    * @author tom@ansleyllc.com | 10-29-2021 
    **/
    private static void initializeRoleHierarchy()
    {
        if (HelperRole.userRoleHierarchy != null) return;

        HelperRole.userRoleHierarchy = new Map<UserRole, Object>();

        Map<Id, UserRole> userRoles = new Map<Id, UserRole>([SELECT DeveloperName,
                                                                    Name,
                                                                    ParentRoleId
                                                             FROM UserRole
                                                             ORDER BY ParentRoleId 
                                                             NULLS FIRST
                                                             LIMIT 5000]);

        HelperRole.userRoles = new Map<Id, UserRole>();
        HelperRole.userRoles.putAll(userRoles);

        //first add the top level parents
        for (Integer index = 0; index < userRoles.size(); index++)
        {
            UserRole userRole = userRoles.values().get(index);

            //if we have a top level user role
            if (userRole.ParentRoleId == null)
            {
                HelperRole.userRoleHierarchy.put(userRoles.remove(userRole.Id), new Map<UserRole, Object>());
                index--;
            }
        }

        //go through the list building the hierarchy for all children
        do {
            for (Integer index = 0; index < userRoles.size(); index++)
            {
                UserRole userRole = userRoles.values().get(index);

                Map<UserRole,Object> childList = getChildrenList(userRole, HelperRole.userRoleHierarchy);

                if (childList != null)
                {
                    childList.put(userRoles.remove(userRole.Id), new Map<UserRole, Object>());
                    index--;
                }
            }

        } while (!userRoles.isEmpty());

        String debug = JSON.serializePretty(userRoleHierarchy);
        System.debug(LoggingLevel.DEBUG, 'NEW ROLE HIERARCHY - ' + debug);
    }

    private static Map<UserRole, Object> getChildrenList(UserRole userRole, Map<UserRole, Object> hierarchy)
    {
        Map<UserRole, Object> childList = null;

        //search for the parent user role in the first level of the provided hierarchy
        for (UserRole parentUserRole: hierarchy.keySet())
        {
            //if we find it then set it and we can bug out
            if (parentUserRole.Id == userRole.ParentRoleId)
                childList = (Map<UserRole, Object>) hierarchy.get(parentUserRole);
        }
        
        //if we cannot find the parent then try further down the hierarchy
        if (childList == null)
        {
            for (Object obj: hierarchy.values())
            {
                Map<UserRole, Object> childHierarchy = (Map<UserRole, Object>) obj;
                childList = getChildrenList(userRole, childHierarchy);
                if (childList != null)
                    break;
            }
        }
        
        return childList;
    }

    private static Map<UserRole, Object> getUserRoleHierarchy(String roleName)
    {
        return getUserRoleHierarchy(roleName, HelperRole.userRoleHierarchy);
    }

    /**
    * @description Method which, given a user role developer name and a hierarchy returns the user roles hierarchy
    * @author tom@ansleyllc.com | 10-29-2021 
    * @param roleName 
    * @param hierarchy 
    * @return Map<UserRole, Object> 
    **/
    private static Map<UserRole, Object> getUserRoleHierarchy(String roleName, Map<UserRole, Object> hierarchy)
    {
        Map<UserRole, Object> roleHierarchy = null;

        //search for the parent user role in the first level of the provided hierarchy
        for (UserRole topUserRole: hierarchy.keySet())
        {
            //if we find it then set it and we can bug out
            if (topUserRole.DeveloperName == roleName)
                roleHierarchy = (Map<UserRole, Object>) hierarchy.get(topUserRole);
        }
        
        //if we cannot find the role hierarchy then try further down the hierarchy
        if (roleHierarchy == null)
        {
            for (Object obj: hierarchy.values())
            {
                Map<UserRole, Object> childHierarchy = (Map<UserRole, Object>) obj;
                roleHierarchy = getUserRoleHierarchy(roleName, childHierarchy);
                if (roleHierarchy != null)
                    break;
            }
        }
        
        return roleHierarchy;
    }

    /**
    * @description Method which, given a user role developer name and a hierarchy returns the user roles hierarchy
    * @author tom@ansleyllc.com | 10-29-2021 
    * @param roleName 
    * @param hierarchy 
    * @return Map<UserRole, Object> 
    **/
    private static Boolean isRoleInHierarchy(String roleName, Map<UserRole, Object> hierarchy)
    {
        Boolean result = false;

        //search for the parent user role in the first level of the provided hierarchy
        for (UserRole topUserRole: hierarchy.keySet())
        {
            //if we find it then set it and we can bug out
            if (topUserRole.DeveloperName == roleName)
                result = true;
        }
        
        //if we cannot find the role hierarchy at the top then try further down the hierarchy
        if (!result)
        {
            for (Object obj: hierarchy.values())
            {
                Map<UserRole, Object> childHierarchy = (Map<UserRole, Object>) obj;
                result = isRoleInHierarchy(roleName, childHierarchy);
                if (result)
                    break;
            }
        }
        
        return result;
    }

}