/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 12-16-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-09-2020   tom@ansleyllc.com   Initial Version
 * 2.0   12-15-2021   tom@ansleyllc.com   Removed old methods for checking object accessibility. Added getFieldRelationship() method. Fixed getSFDCFieldLabel() and isValidSFDCFieldName() methods.
**/
public with sharing class UserHelper {

    private static User currentUser = null;
    
    public static User getCurrentUser()
    {
        if (currentUser == null)
        {
            currentUser = UserHelper.getUserDetails(UserInfo.getUserId());
        }
        
        return currentUser;
    }

    /*
     * Method to get a single user from their Id
     */
    public static User getUserDetails(Id userId)
    {
        User usr = null;
        List<Id> userIds = new List<Id>();
        userIds.add(userId);
        Map<ID,User> userMap = UserHelper.getUserDetails(userIds);
        if (userMap.size() > 0)
            usr = userMap.values()[0];
            
        return usr;
    }

    /*
     * Method to get user details given user Ids
     * @param userIds the list of Ids of the users who's details are being retrieved.
     * @return the list of users
     */
    public static Map<ID,User> getUserDetails(List<Id> userIds)
    {    
        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Id, 
                        User.Name, 
                        UserRole.Name, 
                        FirstName, 
                        LastName, 
                        Profile.Name, 
                        IsActive,
                        UserRole.ParentRoleId, 
                        Email
                FROM User 
                WHERE Id IN :userIds]);
        
        Map<Id, User> userMap = new Map<Id, User>( (List<User>) dec.getRecords());

        return userMap;
    }

}