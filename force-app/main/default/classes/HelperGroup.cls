/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-04-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   11-04-2021   tom@ansleyllc.com   Initial Version
**/
public with sharing class HelperGroup {

    public static Map<String, Group> groupsByName = new Map<String, Group>();
    public static Map<Id, Group> groupsById = new Map<Id, Group>();

    public static Map<String, Group> getGroupsByName(Set<Id> groupIds)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting getGroupsByName(' + groupIds + ')');
        List<Id> groupIdsList = new List<Id>(groupIds);

        Map<String, Group> existingGroups = new Map<String, Group>();
        for (Integer index = 0; index < groupIdsList.size(); index++)
        {
            String groupName = groupIdsList.get(index);
            if (groupsByName.containsKey(groupName))
            {
                existingGroups.put(groupName, groupsByName.get(groupIdsList.remove(index)));
                index--;
            }
        }

        if (!groupIdsList.isEmpty()) 
        {

            List<Group> groups = [SELECT Id,
                                        DeveloperName,
                                        (SELECT Id, 
                                                UserOrGroupId, 
                                                Group.DeveloperName,
                                                Group.Type
                                        FROM GroupMembers)
                                FROM Group 
                                WHERE Id IN :groupIdsList];

            for (Group grp: groups)
            {
                groupsByName.put(grp.DeveloperName, grp);
                groupsById.put(grp.Id, grp);
                existingGroups.put(grp.DeveloperName, grp);
            }
        }

        return groupsByName;
    }

    public static Map<String, Group> getGroupsByName(Set<String> groupNames)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting getGroupsByName(' + groupNames + ')');
        List<String> groupNamesList = new List<String>(groupNames);

        Map<String, Group> existingGroups = new Map<String, Group>();
        for (Integer index = 0; index < groupNamesList.size(); index++)
        {
            String groupName = groupNamesList.get(index);
            if (groupsByName.containsKey(groupName))
            {
                existingGroups.put(groupName, groupsByName.get(groupNamesList.remove(index)));
                index--;
            }
        }


        if (!groupNamesList.isEmpty()) 
        {

            List<Group> groups = [SELECT Id,
                                        DeveloperName,
                                        (SELECT Id, 
                                                UserOrGroupId, 
                                                Group.DeveloperName,
                                                Group.Type
                                        FROM GroupMembers)
                                FROM Group 
                                WHERE DeveloperName IN :groupNamesList];

            for (Group grp: groups)
            {
                groupsByName.put(grp.DeveloperName, grp);
                groupsById.put(grp.Id, grp);
                existingGroups.put(grp.DeveloperName, grp);
            }

        }

        return existingGroups;
    }

    /**
    * @description Method to identify if a user is in a given set of groups. Note this method recursively checks groups.
    * @author tom@ansleyllc.com | 10-28-2021 
    * @param groupNames the top level group names to check from
    * @param userId the user Id to check for.
    * @return Boolean 

        Set<String> groupNames = new Set<String>{'Test_Group'};
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperGroup.getIsUserInGroups(groupNames, '0053h000001aBgk'));

    **/
    public static Boolean isUserInGroups(Set<String> userGroupNames, String userId)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting isUserInGroups(' + userGroupNames + ', ' + userId + ')');
        System.debug(LoggingLevel.DEBUG, 'HelperGroup.groupsByName - ' + groupsByName.keySet());
        System.debug(LoggingLevel.DEBUG, 'HelperGroup.groupsById   - ' + groupsById.keySet());

        if (userGroupNames.isEmpty()) throw new ListViewException('At least one group name must be provided when checking for group membership');
        if (String.isEmpty(userId)) throw new ListViewException('At least one user Id must be provided when checking for group membership');

        //get the group ids given the group names

        Set<Group> groups = new Set<Group>();
        for (String groupName: userGroupNames)
        {
            Group grp = HelperGroup.groupsByName.get(groupName);
            if (grp != null)
                groups.add(grp);
        }

        return isUserInGroups(groups, userId);
    }
        
    
    //--------------------------------------------------------------------------------------------------
    // PRIVATE METHODS
    //--------------------------------------------------------------------------------------------------

    /**
    * @description Method to identify if a user is in a given set of groups.
    * @author tom@ansleyllc.com | 10-15-2021 
    * @param groupIds the ids of the groups to check if the user is a member of
    * @param userId the list of users that the determination is being made on
    * @return Boolean whether the user is in one of the provided groups 
    **/
    private static Boolean isUserInGroups(Set<Group> groups, String userId)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting isUserInGroups(' + groups + ', ' + userId + ')');
        System.debug(LoggingLevel.DEBUG, 'HelperGroup.groupsByName - ' + groupsByName.keySet());
        System.debug(LoggingLevel.DEBUG, 'HelperGroup.groupsById   - ' + groupsById.keySet());

        if (groups.isEmpty()) return false; //throw new ListViewException('At least one group must be provided when checking for group membership');
        if (String.isEmpty(userId)) throw new ListViewException('At least one user Id must be provided when checking for group membership');

        //first thing is get all group members
        List<GroupMember> members = new List<GroupMember>();
        for (Group grp: groups)
            members.addAll(grp.GroupMembers);

        Set<Id> tmpGroupIds = new Set<Id>();
        for (GroupMember member: members)
        {            
            //if our member is a USER record
            if (String.valueOf(member.UserOrGroupId).startsWith('005'))
            {
                System.debug(LoggingLevel.DEBUG, 'MEM is user - ' + member);
                if (member.UserOrGroupId == userId)
                {
                    System.debug(LoggingLevel.DEBUG, 'MATCH!!!');
                    return true;
                }

            //if our member is a GROUP record
            } else if (String.valueOf(member.UserOrGroupId).startsWith('00G'))
            {
                System.debug(LoggingLevel.DEBUG, 'MEM is group - ' + member);
                System.debug(LoggingLevel.DEBUG, 'MEM group type - ' + member.Group.Type);
                tmpGroupIds.add(member.UserOrGroupId);
            }
        }

        //if we have GROUP records inside the groups then recursively check them.
        Boolean result = false;
        if (!tmpGroupIds.isEmpty())
        {
            //we check if any of the groups are of type ROLE or ROLE SUBORDINATE
            Set<String> roleNames = new Set<String>();
            Set<String> roleSubNames = new Set<String>();
            List<Group> tmpGroups = [SELECT Id, Type, DeveloperName FROM Group WHERE Id IN :tmpGroupIds];
            for (Group grp: tmpGroups)
            {
                if (grp.Type == 'Role')
                {
                    roleNames.add(grp.DeveloperName.removeEnd('A'));
                    tmpGroupIds.remove(grp.Id);
                } else if(grp.Type == 'RoleAndSubordinates') 
                {
                    roleSubNames.add(grp.DeveloperName.removeEnd('D'));
                    tmpGroupIds.remove(grp.Id);
                }

            }
            System.debug(LoggingLevel.DEBUG, 'RoleNames    - ' + roleNames);
            System.debug(LoggingLevel.DEBUG, 'roleSubNames - ' + roleSubNames);

            //if we have role names then check them
            if (!roleNames.isEmpty())
            {
                result = HelperRole.isUserInRoles(roleNames, false);
            }

            //if we have role sub names then check them
            if (!roleSubNames.isEmpty() && !result)
            {
                result = HelperRole.isUserInRoles(roleSubNames, true);
            }

            //if we still have group Ids then check those
            if (!tmpGroupIds.isEmpty() && !result)
            {
                System.debug(LoggingLevel.DEBUG, 'We have more group ids to check');
                Set<Group> grps = new Set<Group>(getGroupsByName(tmpGroupIds).values());
                result = isUserInGroups(grps, userId);
            }
        }

        return result;
    }

}