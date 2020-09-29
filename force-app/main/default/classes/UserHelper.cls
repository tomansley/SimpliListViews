/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 09-09-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-09-2020   tom.h.ansley@medtronic.com   Initial Version
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
        
        HelperSchema.checkSelectAccessible('SELECT Id, User.Name, UserRole.Name, FirstName, LastName, Profile.Name, UserRole.ParentRoleId, Email FROM User');
        
        Map<ID,User> userMap = new Map<ID,User>([SELECT Id, 
                                                        User.Name, 
                                                        UserRole.Name, 
                                                        FirstName, 
                                                        LastName, 
                                                        Profile.Name, 
                                                        UserRole.ParentRoleId, 
                                                        Email
                                                FROM User 
                                                WHERE Id IN :userIds]);
        
        return userMap;
    }

}