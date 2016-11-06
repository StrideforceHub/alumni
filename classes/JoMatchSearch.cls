public class JoMatchSearch {
    
    public static void getJobMatch(){
        //SELECT Id, Importance__c, Name, Weight__c, Years_of_Experience__c FROM Job_Qualification__c;
        //SELECT Id, Start_Date__c, End_Date__c, Years_of_Experience__c FROM Job_Seeker_Qualification__c;
        list<Job_Qualification__c> jobsQualificationList = [SELECT Id, Importance__c, Name, Weight__c, Years_of_Experience__c FROM Job_Qualification__c];
        list<Job_Seeker_Qualification__c> seekerQualificationList =[SELECT Id, Start_Date__c, End_Date__c, Years_of_Experience__c FROM Job_Seeker_Qualification__c];
        
 		system.debug(jobsQualificationList);
        system.debug(seekerQualificationList);
    }
    
    public static double getExperienceScore(){
       return 0;   
    }
    public static double getCertificationScore(){
      return 0;    
    }
    public static double getSkillsScore(){
      return 0;  
    }
    public static double getOverallScore(double expScore, double certScore, double skillScore){
        
        if(expScore == 0) 
            return 0;
        else{
            return expScore + certScore + skillScore;
        }      
        
    }
    
    JoMatchSearch jobSearch = new JoMatchSearch();   
}