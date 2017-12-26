trigger Scheduled_Class_Trigger on Scheduled_Class__c (after update ) {
    
system.debug('<><><> In Scheduled_Class_Trigger');
    
    if (Trigger.isAfter && Trigger.isUpdate){
        // If a spare place come available on a Scheduled Class that has waitlisted students, 
        // then move waitlisted students on to that Scheduled Class until it is full
        // 
        // Events that can cause places to come free with students being waitlisted on scheduled classes are:
        // A - Class.Max_Attendees is increased -> apply the de-waitlisting to all impacted future Scheduled_Class records
        // B - A Student (i.e. Class_Attendance record) status changes from "Booked" to "Cancelled"
        // C - A Scheduled Class changes status from "Planned" to "Scheduled"
        // 
system.debug('<><><> Trigger.isAfter && Trigger.isUpdate');
        
        // SC_OpenPlaces_Map is a collection of future-dated Scheduled Classes previously with a waitlist 
        // with newly open places available after the update to the record
        Map<ID,Decimal> SC_OpenPlaces_Map = new Map<ID,Decimal>(); 
        Map<ID,Decimal> SC_WaitlistLength_Map = new Map<ID,Decimal>(); 
        
        // Get the Map of Scheduled Classes that we need to check and update waitlisted Class_Attendance records on
        for (integer i = 0 ; i< trigger.new.size(); i++) {
            if (trigger.old[i].open_places__c == 0 &&
                trigger.old[i].waitlist_length__c > 0 &&
                trigger.new[i].open_places__c > 0 && 
                trigger.new[i].Class_Date__c > datetime.now()) {
                   SC_OpenPlaces_Map.put(trigger.new[i].ID, trigger.new[i].open_places__c);
                   SC_WaitlistLength_Map.put(trigger.old[i].ID, trigger.old[i].waitlist_length__c);
                }
        }
system.debug('<><><> SC_OpenPlaces_Map: ' + SC_OpenPlaces_Map);
system.debug('<><><> SC_WaitlistLength_Map' + SC_WaitlistLength_Map);
        
		// Retrieve the waitlisted Class Attendance records on the Scheduled Classes in the map SC_OpenPlaces_Map
		// in date created order so we can update the people who are waitlisted in order that they joined the waitlist
		// 
		// CA_input_list is a list of students with a status of Waitlisted on the classes contained in the SC_OpenPlaces_Map collection 
        list<Class_Attendance__c> CA_input_list = new list<Class_Attendance__c>(
            [Select  ID, Scheduled_Class__c, Status__c from Class_Attendance__c
                        Where Status__c = 'Waitlisted'
             			and Scheduled_Class__c in :SC_OpenPlaces_Map.keyset()
                        Order by Scheduled_Class__c, CreatedDate]);
        
system.debug('<><><> CA_input_list: ' + CA_input_list);
        
        //CA_output_list is the list of previously waitlisted student Class Attendance records 
        //whose status should be changed from "Waitlisted" to "Booked"
        list<Class_Attendance__c> CA_output_list = new list<Class_Attendance__c>();
        integer k = 0;   
        // Loop through the Scheduled Classes assigning as many converted waitlisted places there are to the output list
        For (Id key : SC_OpenPlaces_Map.keyset()) {
            for (integer i=0 ; i < math.Min(SC_OpenPlaces_Map.get(key),SC_WaitlistLength_Map.get(key)) ; i++) {
                if (key <> CA_Input_list[i+k].Scheduled_Class__c) break;  //there are more open places than waitlisted students
                Class_Attendance__c CA = new Class_Attendance__c(ID=CA_Input_list[i+k].ID, Status__c = 'Booked');
                CA_output_list.add(CA);
system.debug('<><><> Key:' + Key + 'CA:' + CA); 
            }
            // increment k by the number of waitlist entries for this Scheduled Class so the next input item is for the next SC
system.debug('<><><> k before:' + k); 
            k = k + SC_WaitlistLength_Map.get(key).intvalue();
system.debug('<><><> k after:' + k); 
            if (k >= CA_input_list.size()) break;
        }
        
        // If we have updates to do, then do them and log any errors encountered
system.debug('<><><> CA_output_list:' + CA_output_list); 
        if (CA_output_list.size() > 0) {
            List<Database.SaveResult> results = Database.update(CA_output_list, false);  
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                        System.debug('Error: '+ err.getStatusCode() + ' ' + err.getMessage());
                    }
                }
            }
        }
        
    } 
    
}