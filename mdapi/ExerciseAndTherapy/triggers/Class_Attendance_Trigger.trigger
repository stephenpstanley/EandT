trigger Class_Attendance_Trigger on Class_Attendance__c (after insert, after update, after delete) {
    public class ClassAttendanceException extends Exception {}
    
    if ((Trigger.isAfter) && (trigger.IsInsert ||trigger.IsUpdate)) {
        //Prevent a user being booked on a Scheduled Class more than once.
        //When adding a Booked or Waitlisted Class Attendance record, 
        //Check for identical Scheduled Class ID, Stundent ID and status = 'Booked' or 'Waitlisted'
        //
        // Create sets of Sheduled Classes and Student Id's to feed to the validation query
        set<ID> ScheduledClassSet = new set<ID>();
        set<ID> ScheduledStudentSet = new set<ID>();
        For (Class_Attendance__c ca : trigger.new) {
            ScheduledClassSet.add(ca.Scheduled_Class__c);
            ScheduledStudentSet.add(ca.Student__c);
        }
        System.debug('Class set: ' + ScheduledClassSet);
        System.debug('Student set: ' + ScheduledStudentSet);
        
        
        AggregateResult[] PotentialDuplicates = [Select Student__c, Scheduled_Class__c, count(ID) numDups from Class_Attendance__c
                                                 where (Status__c = 'Booked' OR Status__c = 'Waitlisted')
                                                 AND Student__c in :ScheduledStudentSet 
                                                 AND Scheduled_Class__c in:ScheduledClassSet
                                                 Group By Student__c, Scheduled_Class__c
                                                Having count(ID) > 1];
        
        System.debug('PotentialDuplicates: ' + PotentialDuplicates );
        
        if (PotentialDuplicates.size() > 0){

            Throw new ClassAttendanceException('You cant add a booking or waitlist entry for someone already booked or waitlisted. See debug log for details');
            System.debug(PotentialDuplicates.size() + 'duplicates found');
            System.debug(PotentialDuplicates);
        }
             
    }
    
    
    if ((trigger.isInsert && Trigger.isafter) || (trigger.isUpdate && Trigger.isafter))  {
        // work out the effect on Concession cards used and session assigned to them
        // 
        //Add all affected cards to a set. By using a set you can add the same ConCard ID
        //multiple times.  The beauty of using a set is that any card added more than once
        //only gets added to the list once.  Second time around, the duplicate add is ignored
        set<id> ConCardIds = new set<id>();
        
        //When adding new ClassAttendances we need to recalculate the running totals on 
        //cards assigned to the ClassAttendances - only do this if the Concession Card is not null
        if(trigger.isInsert){
            for(Class_Attendance__c ca : trigger.new){
                IF (ca.Concession_Card__c != NULL) 
                    ConCardIds.add(ca.Concession_Card__c);
            }
        }
        //When updating ClassAttendances we need to recalulate the balances on donor and recipent
        //Concession Cards.  Don't the card to the list if the new or old field is null - only recalc the
        //ConCard roll up value if it is affected by the update (i.e., the update adds or removes a card
        //from the Concession Card field - or if both)
        if(trigger.isUpdate){
            for(Class_Attendance__c ca : trigger.new){
                IF (ca.Concession_Card__c != NULL) 
                    ConCardIds.add(ca.Concession_Card__c);
            }
            for(Class_Attendance__c ca : trigger.old){
                IF (ca.Concession_Card__c != NULL) 
                    ConCardIds.add(ca.Concession_Card__c);    
            }
        }
        //When deleting records - only add to the list if the old record had a Concession Card on it.
        if(trigger.isDelete){
            for(Class_Attendance__c ca : trigger.old){
                IF (ca.Concession_Card__c != NULL) 
                    ConCardIds.add(ca.Concession_Card__c);
            }
        }
        
        //Create two Maps - one for the sum of number of sessions used and one for the sum of
        //currency credit used up. 
        
        //Sum of number of sessions
        map<id,double> ConCardMapSession = new map<id,double>();
        //Sum of Values:
        map<id,double> ConCardMapValue = new map<id,double>();
        
        //Query Sessions Used and Value used from Class Attendances and add them to the two Maps. 
        //Each Map will contain a ConCard ID and the assocated amount (sessions or value) used in 
        //Class Attendances. Grouping by Concession Card Id returns a signel row per card with
        //the two sum values in the row which can themn be put in each Map
        for(AggregateResult q : [select Concession_Card__c,
                                 sum(Actual_Sessions__c) Sum_Sessions,
                                 sum(Actual_cost__c) Sum_Costs
                                 from Class_Attendance__c where Concession_Card__c IN :ConCardIds group by Concession_Card__c]){
                                     ConCardMapSession.put((Id)q.get('Concession_Card__c'),(Double)q.get('Sum_Sessions'));
                                     ConCardMapValue.put((Id)q.get('Concession_Card__c'),(Double)q.get('Sum_Costs'));
                                 }
        
        List<SObject> ConCardsToUpdate = new List<SObject>();
        
        //Run the for loop on ConcessionCards using the non-duplicate set of Concession Card Ids
        //Get the sum value from the map and create a list of Concession Cards to update
        for(Concession_Card__c c : [Select Id, Sessions_Used__c, Value_Used__c from Concession_Card__c 
                                    where Id IN :ConCardIds]){
                                        Double SessionSum = ConCardMapSession.get(c.Id);
                                        c.Sessions_Used__c = SessionSum;
                                        Double AmountSum = ConCardMapValue.get(c.Id);
                                        c.Value_Used__c = AmountSum;
                                        ConCardsToUpdate.add(c);
                                    }
        
        update ConCardsToUpdate;
    }
    
}