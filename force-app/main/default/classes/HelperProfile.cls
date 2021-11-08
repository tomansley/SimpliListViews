/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-02-2021
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class HelperProfile {

    private static Map<String, Profile> profilesByName = null;
    private static Map<String, Profile> profilesById = null;
    private static Boolean hasModifyAll = null;

    public static Boolean hasModifyAll()
    {
        if (hasModifyAll == null)
        {
            List<PermissionSet> permSet = [SELECT ProfileId FROM PermissionSet WHERE PermissionsModifyAllData=true AND ProfileId = :UserInfo.getProfileId()];

            if (permSet.size() > 0)
                hasModifyAll = true;
            else
                hasModifyAll = false;
        }
        return hasModifyAll;
    }
/*
    public static Profile getProfile(String name)
    {
        Profile profile = null;
        
        if (profilesByName == null) 
        {
            getProfiles();
        }
        
        return profilesByName.get(name);
    }
    
    public static Profile getProfile(Id profId)// you should cast your argument as an Id so that the other method isn't called instead
    {
        Profile profile = null;
        
        if (profilesById == null) 
        {
            getProfiles();
        }

        return profilesById.get(profId);
    }
    
    public static void getProfiles()
    {
    	
    	profilesByName = new Map<String, Profile>();
        profilesById = new Map<String, Profile>();
    	
        List<Profile> profiles = new List<Profile>([SELECT Id, Name FROM Profile LIMIT 2000]);
                        			
		for (Profile prof: profiles)
        {
			profilesByName.put(prof.Name, prof);
            System.debug(LoggingLevel.FINE, prof.Name + ' - ' + prof);
        }
        
        for (Profile prof: profiles)
        {
			profilesById.put(prof.Id, prof);
        }
    }
    */
}