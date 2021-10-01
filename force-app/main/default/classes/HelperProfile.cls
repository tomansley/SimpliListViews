/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 10-01-2021
 * @last modified by  : tom.h.ansley@medtronic.com
**/
public with sharing class HelperProfile {

    private static Map<String, Profile> profilesByName = null;
    private static Map<String, Profile> profilesById = null;

    public static Boolean hasModifyAll()
    {
        List<PermissionSet> permSet = [SELECT ProfileId FROM PermissionSet WHERE PermissionsModifyAllData=true AND ProfileId = :UserInfo.getProfileId()];

        if (permSet.size() > 0)
            return true;
        else
            return false;
    }

    public static Boolean isSysAdmin()
    {
        String sysAdmin = System.label.System_Administrator;
        System.debug('LANGUAGE - ' + UserInfo.getLanguage());
        
        if (UserInfo.getLanguage() == 'ko') sysAdmin = '시스템 관리자'; //korean
        else if (UserInfo.getLanguage() == 'he') sysAdmin = 'מנהל מערכת'; //hebrew

        if (UserInfo.getProfileId() == getProfile(sysAdmin).Id)
            return true;
        return false;
    }

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
            System.debug(LoggingLevel.DEBUG, prof.Name + ' - ' + prof);
        }
        
        for (Profile prof: profiles)
        {
			profilesById.put(prof.Id, prof);
        }
    }
}