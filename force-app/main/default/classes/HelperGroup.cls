/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class HelperGroup {

    /**
    * @description Method to identify if a user is in a given set of groups.
    * @author tom@ansleyllc.com | 10-15-2021 
    * @param groupNames the names of the groups to check if the user is a member of
    * @param userId the list of users that the determination is being made on
    * @return Map<Id, Boolean> a map holding the user Id as they key and whether the user is in one of the provided groups 

        Set<String> groupNames = new Set<String>{'Test_Group'};
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperGroup.getIsUserInGroups(groupNames, UserInfo.getUserId()));

    **/
    public static Map<Id, Boolean> getIsUsersInGroups(Set<String> groupNames, Set<Id> userIds)
    {
        if (groupNames.isEmpty() || groupNames == null) throw new ListViewException('At least one group name must be provided when checking for group membership');
        if (userIds.isEmpty() || userIds == null) throw new ListViewException('At least one user Id must be provided when checking for group membership');

        List<GroupMember> members = [SELECT Id, 
                                            UserOrGroupId, 
                                            Group.DeveloperName,
                                            Group.Type
                                    FROM GroupMember 
                                    WHERE UserOrGroupId IN :userIds
                                        AND Group.DeveloperName IN :groupNames];

        Map<Id, Boolean> results = new Map<Id, Boolean>();
        for (GroupMember member: members)
        {
            results.put(member.UserOrGroupId, true);
        }

        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + results);
        return results;
    }

    public static Boolean getIsUserInGroups(Set<String> groupNames, String userId)
    {
        Set<Id> userIds = new Set<Id>{userId};
        Map<Id, Boolean> results = getIsUsersInGroups(groupNames, userIds);
        if (results.isEmpty())
            return false;
        else
            return true;
    }

}