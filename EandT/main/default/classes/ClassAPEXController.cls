Public without sharing class ClassAPEXController {
    
    @AuraEnabled
    public Static List<sObject> myFutureClasses (ID StudentID ) { 
        // We are querying for future classes where this student is an attendee
        // and the future class has not been canceled
        return [SELECT Id, Class_Date__c, Class_Name__c, Status__c, 
                Actual_Cost__c, Actual_Sessions__c, Cancel_Date__c,
                Cancellation_Fee_Due__c, Concession_Card__c, Payment_Method__c,
                Scheduled_Class__c, Scheduled_Class__r.Location__c, Scheduled_Class__r.Status__c,
                Scheduled_Class__r.Type__c
                FROM Class_Attendance__c
                where Student__c = :StudentID AND Class_Date__c >= Today
                AND Scheduled_Class__r.Status__c != 'Canceled'
                Order by Class_Date__c ASC
               ];
    }
    
    @AuraEnabled
    public Static List<sObject> myPriorClasses (ID StudentID ) { 
        // We are querying for prior classes where this student is an attendee
        // and the class itself was not canceled
        return [SELECT Id, Class_Date__c, Class_Name__c, Status__c, 
                Actual_Cost__c, Actual_Sessions__c, Cancel_Date__c,
                Cancellation_Fee_Due__c, Concession_Card__c, Payment_Method__c,
                Scheduled_Class__c, Scheduled_Class__r.Location__c, Scheduled_Class__r.Status__c,
                Scheduled_Class__r.Type__c
                FROM Class_Attendance__c
                where Student__c = :StudentID AND Class_Date__c < Today
                AND Scheduled_Class__r.Status__c != 'Canceled'
                Order by Class_Date__c DESC
               ];
    }
    
    @AuraEnabled
    public Static Scheduled_Class__c ClassDetails(ID SchedClassID) {
        // Find the details of the selected class
        system.debug('Looking for details for class id:' +  SchedClassID);
        
        return [Select ID, 	Class__r.Name, Class_date__c, Casual_Price__c, Concession_Price__c, Location__c, Type__c, Waitlist_Length__c
                from Scheduled_Class__c where ID = :SchedClassID];
    }
    
    @AuraEnabled
    public Static Concession_Card__c myBestConcessionCard (ID StudentID, ID SchedClassID) {
        
        // Find the date and type of the selected class
        Scheduled_Class__c ChosenClass = [Select Class_date__c, Type__c from Scheduled_Class__c where ID = :SchedClassID];
        
        System.debug('StudentID:' + StudentID + ', Class Date' + ChosenClass.Class_Date__c.Date());
        
        //Find the corresponding account id to this Community user
        User CommunityUser = [Select contact.AccountId from user where id =:StudentID ];
        
        // Retrieve the best Concession card  - ie shortest dated unexpired card that maps to this Scheduled Class
        try {
            Return [SELECT Id, Name, Sessions__c, Sessions_Balance__c, Sessions_Used__c, Class_Type__r.Name,
                    Value__c, Value_Balance__c, Value_Used__c
                    FROM Concession_Card__c
                    where Customer__c = :CommunityUser.contact.AccountID AND Expiry_Date__c >= :ChosenClass.Class_Date__c.Date()
                    AND Class_type__r.Name = :ChosenClass.Type__c
                    AND Card_Expired__c = FALSE
                    Order by Expiry_Date__c ASC
                    Limit 1
                   ];
        } catch (Exception ex) {
            System.debug('No suitable cards found - returning null');
            Concession_Card__c nullcard = new Concession_Card__c();
            Return nullcard;  // no rows returned.  This user hasn't got a valid concession card for the selected class date and type
            
        }
        
    }
    
    
    @AuraEnabled
    public Static ID RegisterNow(ID SchedClassID, ID StudentID, ID ConCardID, String RegistrationStatus, String PaymentMethod) {
        
        system.debug('RegisterNow: Class ID: '+ SchedClassID + 'Student ID' + StudentID + 'Card ID' + ConCardID + 'RegType: ' + RegistrationStatus);
        // get the contact id for the passed in user / student id
        User Con = [Select contact.account.ID from user where ID = :StudentID];
        Class_Attendance__c CA = new Class_Attendance__c();
        CA.Student__c = Con.contact.account.ID;
        CA.Scheduled_Class__c = SchedClassID;
        CA.Status__c = RegistrationStatus; //'Booked' or 'Waitlisted'
        system.debug('RegisterNow: ID test: '+ string.valueof(ConCardID));
        If (PaymentMethod == 'concard') {
            CA.Concession_Card__c = ConCardID;
            CA.Payment_Method__c = 'Concession Card';
        } else {
            CA.Payment_Method__c = 'Casual';
        }
        system.debug('RegisterNow: Record to insert: ' + CA );
        try {
            insert CA;
        	system.debug('RegisterNow: Inserted record ID:' + CA.ID);
        } catch(DmlException e) {
            System.debug('RegisterNow: An unexpected error has occurred: ' + e.getMessage());
        }
        return CA.Id;
    }
    
@AuraEnabled    
    public Static myClasseswrapper ClasstoCancel(ID CA_ID){
        // Get details for the class that has been asked to be canceled and return a single record with the details needed
        // 
        List<User> u = [SELECT u.Id,u.ContactId, u.Contact.AccountID
                        FROM User u 
                        WHERE u.Id = :UserInfo.getUserId()
                        AND u.IsActive = True];
        
        ID CurrentUser;
        If (u.size() == 1) {
            CurrentUser=u[0].Contact.AccountID;
        } else {
            CurrentUser= '';
        }
        
        Class_attendance__c CA = [Select ID, Scheduled_Class__c, Status__c, Payment_Method__c, Actual_Cost__c, Actual_Sessions__c      
               					From Class_attendance__c 
                               where ID= :CA_ID];
        
        Scheduled_Class__c SC = [Select ID, Name, Class_Date__c, Location__c, Open_Places__c, Type__c, Waitlist_Length__c, Status__c, Class__r.Name
                                FROM Scheduled_Class__c 
                                Where ID=:CA.Scheduled_Class__c];
        
        Return new myClasseswrapper(SC, CA.Status__c, CurrentUser, CA.ID, CA.Payment_Method__c, CA.Actual_Cost__c, CA.Actual_Sessions__c);


    }
    
    
    
    @AuraEnabled
    public Static List<myClasseswrapper> AllFutureClasses() { 
        // We are querying for future classes. If the current user is an attendee
        // then we need to show that they can't book on it
        // If the user is not logged in, then all classes with spaces show as bookable
        // If the class is full, then show that.  If the student is booked on a full class then show they are booked
        // 
        // If the session is anonymous then the Guest user ID will have no assigned classes 
        
        // Find the ID of the Current Logged in user or return '' if not logged in
        // This may actually return the Guest user If session is anonymous
        List<User> u = [SELECT u.Id,u.ContactId, u.Contact.AccountID
                        FROM User u 
                        WHERE u.Id = :UserInfo.getUserId()
                        AND u.IsActive = True];
        
        ID CurrentUser;
        If (u.size() == 1) {
            CurrentUser=u[0].Contact.AccountID;
        } else {
            CurrentUser= '';
        }
        
        System.debug('Logged in user is: ' + CurrentUser);
        
        List<Scheduled_Class__c> FutureClassList =  [SELECT ID, Class_Date__c, Class__r.Name, Location__c, Open_Places__c, Type__c,Waitlist_Length__c,
                                                     Status__c, Class__r.Do_not_expose_to_Community__c 
                                                     FROM Scheduled_Class__c
                                                     where Class_Date__c >= Today
                                                     AND Status__c != 'Canceled'
                                                     Order by Class_Date__c ASC];
        
        List<Class_Attendance__c> myFutureAttendances = [SELECT ID, Scheduled_Class__c, Status__c, 	Payment_Method__c, 
                                                         Actual_Cost__c, Actual_Sessions__c
                                                         FROM Class_Attendance__c 
                                                         Where Student__c = :CurrentUser AND Scheduled_Class__c in :FutureClassList
                                                         // AND (Status__c = 'Booked' OR Status__c = 'Waitlisted') - removed to allow "hidden" classes to be exposed to community
                                                         ORDER BY Class_Date__c ASC];
        //Create map of My Future attendance statuses, payment methods, costs, sessions etc with the ID of the Scheduled Class as the index
        Map<Id, String> StatusMap = new Map<Id, String>();
        Map<Id, Id> ClsAttendanceIDMap = new Map<Id, ID>();
        Map<Id, String> ClsAttendancePaymentMap = new Map<Id, String>();        
        Map<Id, Decimal> ClsAttendanceCostMap = new Map<Id, Double>();        
        Map<Id, Decimal> ClsAttendanceSessionMap = new Map<Id, Double>();        
		// This map holds all classes attended
        Map<Id, Id> ClsEverBookedIDMap = new Map<Id, ID>();

		// Build all the required Maps
        For (integer i=0; i<myFutureAttendances.size(); i++ ) {
            if (myFutureAttendances[i].Status__c=='Booked' || myFutureAttendances[i].Status__c=='Waitlisted') {
                // only populate the Maps if there is a current booking or waitlisting record
                StatusMap.put(myFutureAttendances[i].Scheduled_Class__c, myFutureAttendances[i].Status__c);
                ClsAttendanceIDMap.put(myFutureAttendances[i].Scheduled_Class__c, myFutureAttendances[i].ID);
                ClsAttendancePaymentMap.put(myFutureAttendances[i].Scheduled_Class__c, myFutureAttendances[i].Payment_Method__c);
                ClsAttendanceCostMap.put(myFutureAttendances[i].Scheduled_Class__c, myFutureAttendances[i].Actual_Cost__c);
                ClsAttendanceSessionMap.put(myFutureAttendances[i].Scheduled_Class__c, myFutureAttendances[i].Actual_Sessions__c);
            }
            // Add the Class Attendance ID to the map containing calsses that have ever been attended so we can expose these classes
            // to authenticated users even if the classes are mrked as not to be exposed on the Community page
            // (See help text for Class__c.Do_not_expose_to_Community__c field for an explanation of why )
            ClsEverBookedIDMap.put(myFutureAttendances[i].Scheduled_Class__c, myFutureAttendances[i].ID);
        }
        
        
        List<myClasseswrapper> myClassList = new List<myClasseswrapper>();
        
        for (Scheduled_Class__c   c : FutureClassList){
            If (StatusMap.ContainsKey(c.ID)) { //then there is a current booking or waitlisting record so it is safe to expose on the community
                myClassList.add(new myClasseswrapper(c, StatusMap.get(c.ID), CurrentUser, ClsAttendanceIDMap.get(c.ID),
                                                    ClsAttendancePaymentMap.get(c.ID), ClsAttendanceCostMap.get(c.ID), ClsAttendanceSessionMap.get(c.ID)));
            } else {
                If (!c.Class__r.Do_not_expose_to_Community__c) { // If there is no restriction on showing this class to the community add it
                    myClassList.add(new myClasseswrapper(c, '', CurrentUser, null, null, null, null));
                } else {
                    if (ClsEverBookedIDMap.ContainsKey(c.ID)) { // if there is a restriction, only expose it if this user has an attendance record at any status
                        myClassList.add(new myClasseswrapper(c, '', CurrentUser, null, null, null, null));
                    }
                }
            }
        }

        For (  myClasseswrapper mcw : myClassList) {
                    system.debug('Returned record: ' + mcw);
        }   

        
        return myClassList;
    }       
    
    Public class myClasseswrapper
    {
        @AuraEnabled
        public ID ClsID {get; set;}
        @AuraEnabled
        public datetime ClsDate {get; set;}
        @AuraEnabled
        public String ClsName {get; set;}
        @AuraEnabled
        public String ClsLocation {get; set;}
        @AuraEnabled
        public Double ClsPlaces {get; set;}  // The number of places available
        @AuraEnabled
        Public String ClsType {get; set;}
        @AuraEnabled
        Public String ClsListStatus {get; set;} // This is the status value for the class to be displayed on the list - i.e. places available or Full
        @AuraEnabled
        public String StudentStatus {get; set;} //This is the Class_Attendance status (Booked, Waitlisted etc)
        @AuraEnabled
        public String ClsStudentID {get; set;}
        @AuraEnabled
        public String ClsAttendanceID {get; set;}
        @AuraEnabled
        public Double ClsWaitlistLength {get; set;}
        @AuraEnabled
        public String ClsPaymentMethod {get; set;}
        @AuraEnabled
        public Decimal ClsCost {get; set;}
        @AuraEnabled
        public Decimal ClsSessions {get; set;}
        @AuraEnabled        
        public Boolean ClsCancelFeeDue {get; set;}
        @AuraEnabled
        public String eventType {get; set;}
        @AuraEnabled 
        public String variant {get; set;}
        public myClasseswrapper(Scheduled_Class__c SC, String AttStatus, ID ThisUser, ID AttendeesClassID, 
                                String AttPaymentMethod, Decimal AttCost, Decimal AttSessions)
        {
            ClsID = SC.ID;
            ClsDate = SC.Class_Date__c;
            ClsName = SC.Class__r.Name;
            ClsLocation = SC.Location__c;
            ClsPlaces = SC.Open_Places__c;
            ClsType = SC.Type__c;
            if ( SC.Status__c == 'Proposed' ) {
                ClsListStatus = 'Class Planned';
            } else if (SC.Open_Places__c < 1) {
                ClsListStatus = 'Class Full';
            } else {
                ClsListStatus = 'Places Available';
            }
            StudentStatus = AttStatus; //This is the Class_Attendance status (Booked, Waitlisted etc)
            ClsStudentID = ThisUser;
            ClsAttendanceID = AttendeesClassID;
            ClsWaitlistLength = SC.Waitlist_Length__c;
            ClsPaymentMethod = AttPaymentMethod;            
            ClsCost = AttCost;
            ClsSessions = AttSessions;
            ClsCancelFeeDue = (System.now().date() >= SC.Class_Date__c.date() ); // Fee due if canceled on (or after) the day of the class
            if (StudentStatus == 'Booked') {
                eventType = 'Cancel Booking';
                variant = 'destructive';
            } else if (StudentStatus == 'Waitlisted') {
                eventType = 'Cancel Waitlist';
                variant = 'destructive';
            } else if ( (ClsAttendanceID == null) && ((ClsPlaces <1) || (ClsListStatus == 'Class Planned')) ){
                eventType = 'Waitlist Me';
                variant = 'neutral';
            } else if ( (StudentStatus == 'Cancelled') || (StudentStatus == 'Waitlist - Cancelled') || (ClsAttendanceID == null)
                       && (ClsPlaces >0) &&
                       (ClsListStatus != 'Class Planned') && (ClsListStatus != 'Cancelled')) {
                           eventType = 'Register'; 
                           variant = 'brand';
                       } else { 
                           system.debug('Unexpected combination of statuses found:');
                           system.debug('StudentStatus: ' + StudentStatus + ' ClsAttendanceID:' + ClsAttendanceID +
                                        ' ClsPlaces:' + ClsPlaces + ' ClsListStatus: ' + ClsListStatus );
                       }
            
            System.debug('Now: ' + System.now().date() + ' Class Date:' + SC.Class_Date__c.date() + ' Fee due: ' + ClsCancelFeeDue);
            

            
        }
    }
    
    
    @AuraEnabled
    public Static myBookingwrapper mySelectedBooking(ID StudentID, ID SchedClassID) { 
        //Build the Wrapper object to allow the confirmation pop-up to be filled in
        
        System.debug('Best Concession card: ' + myBestConcessionCard(StudentID, SchedClassID));
        System.debug('Selected Class: ' + ClassDetails(SchedClassID));
        myBookingwrapper myBooking = new myBookingwrapper(ClassDetails(SchedClassID),
                                                          myBestConcessionCard(StudentID, SchedClassID));
        
        system.debug('Returned BookingWrapper: ' + myBooking);
        
        return myBooking;
    }    
    
    Public class myBookingwrapper
    {
        @AuraEnabled
        public ID ClsID {get; set;}
        @AuraEnabled
        public datetime ClsDate {get; set;}
        @AuraEnabled
        public String ClsName {get; set;}
        @AuraEnabled
        public String ClsLocation {get; set;}
        @AuraEnabled
        Public String ClsType {get; set;}
        @AuraEnabled
        Public Decimal ClsConcessionPrice {get; set;}        
        @AuraEnabled
        Public Decimal ClsCasualPrice {get; set;} 
        @AuraEnabled
        public Double ClsWaitlistLength {get; set;}
        @AuraEnabled
        public ID ConID {get; set;} 
        @AuraEnabled
        public String ConName {get; set;} 
        @AuraEnabled
        public Decimal ConSessions {get; set;}         
        @AuraEnabled
        public Decimal ConSessionsBalance {get; set;}         
        @AuraEnabled
        public Decimal ConSessionsUsed {get; set;}         
        @AuraEnabled
        public String ConClassType {get; set;}         
        @AuraEnabled
        public Decimal ConValue {get; set;} 
        @AuraEnabled
        public Decimal ConValueBalance {get; set;}         
        @AuraEnabled
        public Decimal ConValueUsed {get; set;} 
        public myBookingwrapper(Scheduled_Class__c SC, Concession_Card__c CC)
        {
            System.debug('In wrapper set up for myBookingWrapper');
            ClsID = SC.ID;
            ClsDate = SC.Class_Date__c;
            ClsName = SC.Class__r.Name;
            ClsLocation = SC.Location__c;
            ClsType = SC.Type__c;
            ClsConcessionPrice = SC.Concession_Price__c;
            ClsCasualPrice = SC.Casual_Price__c;
            ClsWaitlistLength = SC.Waitlist_Length__c;
            ConID = CC.Id;
            ConName = CC.Name;
            ConSessions = CC.Sessions__c;
            ConSessionsBalance = CC.Sessions_Balance__c;
            ConSessionsUsed = CC.Sessions_Used__c;
            ConClassType = CC.Class_Type__r.Name;
            ConValue = CC.Value_Used__c;
            ConValueBalance = CC.Value_Balance__c;
            ConValueUsed= CC.Value_Used__c;
        }
    }
    
    
    @AuraEnabled
    public static ID CancelWaitList(ID ClassAttendanceID) {
        
        Class_Attendance__c WLTC = [Select ID from Class_Attendance__c where ID = :ClassAttendanceID];
        
        WLTC.Status__c = 'Waitlist - Canceled';
        WLTC.Cancel_Date__c = Date.Today();
        
        try {
            update WLTC;
        } catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }
        return WLTC.Id;
    }

    @AuraEnabled
    public static ID APEXCancelBooking(ID ClassAttendanceID) {
        
        system.debug(' About to cancel Class_Attendance__c.ID=' + ClassAttendanceID);
        Class_Attendance__c CB = [Select ID from Class_Attendance__c where ID = :ClassAttendanceID];
        
        CB.Status__c = 'Canceled';
        CB.Cancel_Date__c = Date.Today();
        
        try {
            update CB;
        } catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }
        return CB.Id;
    }
    
}