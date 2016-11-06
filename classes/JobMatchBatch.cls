public class JobMatchBatch implements Database.Batchable<sObject>{

    //Database.executeBatch(new JobMatchBatch(), 2000);

   public Database.QueryLocator start(Database.BatchableContext BC){
       
      // return Database.getQueryLocator('SELECT Id FROM Job_Posting__c WHERE Id=\'a071a00000LebZ2\'');
      return Database.getQueryLocator('SELECT Id FROM Job_Posting__c WHERE Closing_Date__c >= TODAY OR Closing_Date__c = NULL');
   }

   public void execute(Database.BatchableContext BC, List<Job_Posting__c> scope){

      List<Job_Match__c> jobMatches = new  List<Job_Match__c>();
       
          
     Set<Id> jobPosting = new Set<Id>();
     for(Job_Posting__c s : scope){
        jobPosting.add(s.Id);     	
     }
       List<Job_Seeker_Qualification__c> jobsQualificationList = [SELECT Id, Importance__c, Name, Weight__c, Years_of_Experience__c, Qualifications__c, Job_Posting__c, RecordTypeId                                                         
                                                           FROM Job_Seeker_Qualification__c
                                                           WHERE Job_Posting__c IN:jobPosting AND Qualifications__c != NULL];
       Map<Id, List<Job_Seeker_Qualification__c>> jMap = new Map<Id, List<Job_Seeker_Qualification__c>>();
     
       Set<string> qualifications = new Set<string>();
       for(Job_Seeker_Qualification__c s : jobsQualificationList){
           qualifications.add(s.Qualifications__c);
           if(jMap.containsKey(s.Job_Posting__c)){
               List<Job_Seeker_Qualification__c> tempList = jMap.get(s.Job_Posting__c);
               tempList.add(s);
               jMap.put(s.Job_Posting__c, tempList);
           }else{
               jMap.put(s.Job_Posting__c, new List<Job_Seeker_Qualification__c>{s});
           }
            
       }
       
       list<Job_Seeker_Qualification__c> seekerQualificationList =[SELECT Id, Start_Date__c, End_Date__c, Years_of_Experience__c, Job_Seeker__c, Qualifications__c, RecordTypeId
                                                                   FROM Job_Seeker_Qualification__c
                                                                   WHERE Qualifications__c IN:qualifications AND Job_Seeker__c != NULL];
       Map<Id, List<Job_Seeker_Qualification__c>> jsMap = new Map<Id, List<Job_Seeker_Qualification__c>>();
         
       for(Job_Seeker_Qualification__c s : seekerQualificationList){
          
           if(jsMap.containsKey(s.Job_Seeker__c)){
               List<Job_Seeker_Qualification__c> tempList = jsMap.get(s.Job_Seeker__c);
               tempList.add(s);
               jsMap.put(s.Job_Seeker__c, tempList);
           }else{
               jsMap.put(s.Job_Seeker__c, new List<Job_Seeker_Qualification__c>{s});
           }
            
       }
       
       for(Id jpId:jMap.keySet()){
           List<Job_Seeker_Qualification__c> jqlist = jMap.get(jpId);
           for(Id jsId:jsMap.keySet()){
               List<Job_Seeker_Qualification__c> jslist = jsMap.get(jsId);              
               integer totalQualifications =  jqlist.size();
              /* integer matchQualifications = getCompare(jqlist, jslist);
               integer result = totalQualifications - matchQualifications;
               double matchScore = (1- (result/totalQualifications))*100;
               
               system.debug('Total, Match, Result, Score' + totalQualifications + ',' + matchQualifications + ',' + result + ',' + matchScore);*/
               double matchScore = getCompare(jqlist, jslist);
               if(matchScore > 0)
               	jobMatches.add(new Job_Match__c(Job_Seeker__c = jsId, Job_Posting__c = jpId, Percent_Match__c = matchScore, Upsert_Key__c= jpId + '|' + jsId));
           }
       }
      system.debug(jobMatches);
	  UPSERT jobMatches Upsert_Key__c;       
      
    }
    
    public static double getCompare(List<Job_Seeker_Qualification__c> jqlist, List<Job_Seeker_Qualification__c> jslist){
        integer matchesFound = 0;
        double percentageScore= 0.0;
        List<Job_Seeker_Qualification__c> jobRequire = new List<Job_Seeker_Qualification__c>();
        for(Job_Seeker_Qualification__c jq:jqlist){
            if (jq.Importance__c == 'Required'){
                jobRequire.add(jq);
            }
        }
        
        integer numberRequire = jobRequire.size();
        integer seekerReq = 0;
        for(Job_Seeker_Qualification__c jq:jobRequire){
            for(Job_Seeker_Qualification__c js:jslist){
                if(jq.Qualifications__c == js.Qualifications__c){
                    seekerReq++;
                }
            }
        }
        
        if(seekerReq < numberRequire)
            return 0;
         double totalMatch = 0.0;
        for(Job_Seeker_Qualification__c jq:jqlist){
            double yearJob = jq.Years_of_Experience__c;          
            if(yearJob == null)
                yearJob = 0.0; 
            if(yearJob > 10)
                yearJob=10;
            double weightJob = jq.Weight__c;
            if(weightJob == null)
                weightJob = 5.0;
            weightJob = (10 -weightJob)*10;
            for(Job_Seeker_Qualification__c js:jslist){
                double seekYear = js.Years_of_Experience__c;
                if(seekYear == null)
                    seekYear = 0.0;  
                 if(seekYear > 10)
                	seekYear=10;
                if(jq.Qualifications__c == js.Qualifications__c){ 
                    if(yearJob != 0){
                        double tempExp = (((seekYear/yearJob)*100)+weightJob)/2 ;             
                    	totalMatch += tempExp;
                    }                     
                   
                    // double tempExp =-1*(Math.log(Math.abs(yearJob - seekYear))) + 0.01;
                    // double tempExp =Math.log(Math.abs(yearJob - seekYear)) + 0.01;                         
                    // weightExp.add(new Map<string, double>{'weight'=>weightJob, 'exp'=>tempExp });          
                }               
            }
        }
        
        if(jqlist.size() == 0)
            return 0;
        
        percentageScore = totalMatch/jqlist.size();
        return percentageScore;
    }
    
    public void finish(Database.BatchableContext BC){
    }
    
}