({
    
    getFutureClassesandBookings: function(component, event) {
        // refresh the list of classes and lok up the current user's attendance status
        var action = component.get("c.AllFutureClasses");
        
        console.log('Fetching future classes - calling AllFutureClasses method in Apex controller');  
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("in getFutureClassesandBookings, Return state = " + state);
            if (state === "SUCCESS") 
            {//set response value in ClassRecordList attribute on component.
                var returnedRecords = response.getReturnValue();
var i = 0;
                console.log("Rec " + i + " ClsID: " + returnedRecords[i].ClsID + " "
                                + " ClsDate: " + returnedRecords[i].ClsDate + " "
                                + " ClsName: " + returnedRecords[i].ClsName + " "
                                + " ClsLocation: " + returnedRecords[i].ClsLocation + " "
                                + " ClsPlaces: " + returnedRecords[i].ClsPlaces + " "
                                + " ClsType: " + returnedRecords[i].ClsType + " "
                                + " ClsListStatus: " + returnedRecords[i].ClsListStatus + " "
                                + " StudentStatus: |" + returnedRecords[i].StudentStatus + "| "
                                + " ClsStudentID: " + returnedRecords[i].ClsStudentID + " "
                                + " ClsAttendanceID: " + returnedRecords[i].ClsAttendanceID + " "
                                + " ClsWaitlistLength: " + returnedRecords[i].ClsWaitlistLength + " "
                                + " ClsPaymentMethod: " + returnedRecords[i].ClsPaymentMethod + " "
                                + " ClsCost: " + returnedRecords[i].ClsCost + " "
                                + " ClsSessions: " +returnedRecords[i].ClsSessions + " "
                                + " ClsCancelFeeDue: " + returnedRecords[i].ClsCancelFeeDue + " "
                                + " eventType: " + returnedRecords[i].eventType + " "
                                + " variant: " + returnedRecords[i].variant + " "
                               );


                component.set("v.ClassRecordList", response.getReturnValue());
                
            } else {
                console.log("Error state returned from APEX Controller AllFutureClasses");
            }
        });
        $A.enqueueAction(action);
    },
    
    getBestConCardandClass: function(component, event, StudentID, SchedClassID, callBack) {
        console.log('Entering getBestConCardandClass'); 
     
        // Check to see if the Student has a valid Concession card that can be used on this class
        var action = component.get('c.mySelectedBooking');
        // Pass the Attendee record and classID to the APEX controller to find the best Concard if any       
        action.setParams({
            "StudentID": StudentID,  
            "SchedClassID": SchedClassID           
        });
        
        console.log('StudentID: ' + StudentID + ' SchedClassID: ' + SchedClassID );
        console.log('Calling mySelectedBooking method in APEX controller');
        
        action.setCallback(this, function(response) { 
            if (callBack) { // this calls the callBack function passed in that resets the spinner to stop spinning
                callBack();
            }  
            var state = response.getState();
            console.log("Return state = " + state);
            if (state === 'SUCCESS') {
                component.set('v.ConCardID', response.getReturnValue().ConID);
                component.set('v.ConName', response.getReturnValue().ConName);
                component.set('v.ConCardValue', response.getReturnValue().ConValue);
                component.set('v.ConCardValueUsed', response.getReturnValue().ConValueUsed);
                component.set('v.ConCardValueBalance', response.getReturnValue().ConValueBalance);
                component.set('v.ConCardSessions', response.getReturnValue().ConSessions);
                component.set('v.ConCardSessionsUsed', response.getReturnValue().ConSessionsUsed);
                component.set('v.ConClassType', response.getReturnValue().ConClassType);
                component.set('v.ConCardSessionsBalance', response.getReturnValue().ConSessionsBalance);
                component.set('v.ClassID', response.getReturnValue().ClsID);
                component.set('v.ClassDate', response.getReturnValue().ClsDate);
                component.set('v.ClassCasualPrice', response.getReturnValue().ClsCasualPrice);
                component.set('v.ClassConcessionPrice', response.getReturnValue().ClsConcessionPrice);
                component.set('v.ClassLocation', response.getReturnValue().ClsLocation);
                component.set('v.ClassType', response.getReturnValue().ClsType);
                component.set('v.ClassName', response.getReturnValue().ClsName);
                
                // Tell the handler which pops the dialog box that the data has been returned
                var compEvent = component.getEvent("GotmyClassEvent");
                console.log("Payment method: " +response.getReturnValue().ClsPaymentMethod);
                compEvent.setParams({ "eClsCasualPrice" : response.getReturnValue().ClsCasualPrice,
                                     "eClsConcessionPrice" : response.getReturnValue().ClsConcessionPrice,
                                     "eConCardID" : response.getReturnValue().ConID,
                                     "eConCardRemainingSessions" : response.getReturnValue().ConSessionsBalance,
                                     "eConCardRemainingValue" : response.getReturnValue().ConValueBalance,
                                     "eClassName" : response.getReturnValue().ClsName,
                                     "eClassDate" : response.getReturnValue().ClsDate,
                                     "eClassLocation" : response.getReturnValue().ClsLocation,
                                     "eClassType" : response.getReturnValue().ClsType,
                                     "eClassWaitlistLength" : response.getReturnValue().ClsWaitlistLength,
                                     "eClsAttendanceID" : response.getReturnValue().ClsAttendanceID,
                                     "eClsCancelFeeDue" : response.getReturnValue().ClsCancelFeeDue,
                                     "eClsPaymentMethod" : response.getReturnValue().ClsPaymentMethod,
                                     "eClsCost" : response.getReturnValue().ClsCost,
                                     "eClsSessions" : response.getReturnValue().ClsSessions,
                                     "eTxnType" : component.get("v.BookStatus")
                                    });
                console.log("Before Event FIRE waitlist length:" + response.getReturnValue().ClsWaitlistLength);
                
                
                console.log("Fire the COMPONENT event - GotmyClassEvent");
                compEvent.fire();
                
            } else {
                console.log('Error trying to find best concession card and requested Class')
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            
        });
        $A.enqueueAction(action);   
        
        console.log('Finished in getBestConCardandClass'); 
        
    },
    
    findClasstoCancel: function(component, event, ClassAttendanceID, callBack) {
        var action = component.get('c.ClasstoCancel');
        // Pass the Class_attendance_ID to the APEX controller to find the details of the class to cancel      
        action.setParams({
            "CA_ID": ClassAttendanceID  
        });
        console.log('ClassAttendancetoCancel (ID): ' + ClassAttendanceID );
        console.log('Calling ClasstoCancel method in APEX controller');
        
        
        $A.enqueueAction(action);   
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("Return state = " + state);
            if (state === 'SUCCESS') {
                component.set('v.ClassID', response.getReturnValue().ClsID);
                component.set('v.ClassDate', response.getReturnValue().ClsDate);
                component.set('v.ClassLocation', response.getReturnValue().ClsLocation);
                component.set('v.ClassType', response.getReturnValue().ClsType);
                component.set('v.ClassName', response.getReturnValue().ClsName);
                component.set('v.ClsAttendanceID',response.getReturnValue().ClsAttendanceID);
                component.set('v.ClassCancelPaymentMethod',response.getReturnValue().ClsPaymentMethod);
                component.set('v.ClassCancelFee',response.getReturnValue().ClsCost);
                component.set('v.ClassCancelSessions',response.getReturnValue().ClsSessions);
                component.set('v.ClsCancelFeeDue',response.getReturnValue().ClsCancelFeeDue);
                
                console.log("Processing return response from APEX COntroller ClasstoCancel ID is: " + response.getReturnValue().ClsAttendanceID);
                
                // Tell the handler which pops the dialog box that the data has been returned
                var compEvent = component.getEvent("GotmyClassEvent");
                compEvent.setParams({ "eClsCasualPrice" : response.getReturnValue().ClsCasualPrice,
                                     "eClsConcessionPrice" : response.getReturnValue().ClsConcessionPrice,
                                     "eConCardID" : response.getReturnValue().ConID,
                                     "eConCardRemainingSessions" : response.getReturnValue().ConSessionsBalance,
                                     "eConCardRemainingValue" : response.getReturnValue().ConValueBalance,
                                     "eClassName" : response.getReturnValue().ClsName,
                                     "eClassDate" : response.getReturnValue().ClsDate,
                                     "eClassLocation" : response.getReturnValue().ClsLocation,
                                     "eClassType" : response.getReturnValue().ClsType,
                                     "eClassWaitlistLength" : response.getReturnValue().ClsWaitlistLength,
                                     "eClsAttendanceID" : response.getReturnValue().ClsAttendanceID,
                                     "eClsCancelFeeDue" : response.getReturnValue().ClsCancelFeeDue,
                                     "eClsPaymentMethod" : response.getReturnValue().ClsPaymentMethod,
                                     "eClsCost" : response.getReturnValue().ClsCost,
                                     "eClsSessions" : response.getReturnValue().ClsSessions,
                                     "eTxnType" : component.get("v.BookStatus")
                                    });                
                console.log("Class cost: " + component.get('v.ClassCancelFee') + " Class Sessions: " + component.get('v.ClassCancelSessions'));
                console.log("Before Event FIRE waitlist length:" + response.getReturnValue().ClsWaitlistLength);
                console.log("Fire the COMPONENT event - GotmyClassEvent");
                compEvent.fire();
                //Stop the spinner on the button
                var ClickedButton = event.getSource();
                ClickedButton.set("v.isLoading", false);
                
            } else {
                console.log('Error trying to find best concession card and requested Class to book or cancel');
            }
        });        
        
    },
    
    
    newClassAttendance: function(component, event, AttName) {
        console.log('Entered helper.newClassAttendance');
        var action = component.get("c.RegisterNow"); 
        var toastEvent = $A.get("e.force:showToast");
        var bookingStatus = component.get("v.BookStatus");
        var PaymentMethod = component.get("v.PaymentOption");
        
        
        // Pass the ClassID, StudentID, CardID and RegistrationStatus to create a Class_Attendance record  
        // Method: Register (ID SchedClassID, ID StudentID, ID ConCardID, String RegistrationStatus)
        
        console.log('Setting parameters to create booking record');  
        console.log("SchedClassID:" + component.get("v.ClassID"));
        console.log("StudentID: " + component.get("v.StudentID"));  
        console.log('Payment option: ' + PaymentMethod);
        console.log("ConCardID: " + component.get("v.ConCardID"));  
        console.log("RegistrationStatus: " + bookingStatus);
        
        action.setParams({
            "SchedClassID": component.get("v.ClassID"),            
            "StudentID": component.get("v.StudentID"),  
            "ConCardID": component.get("v.ConCardID"),  
            "RegistrationStatus": component.get("v.BookStatus"),
            "PaymentMethod" : PaymentMethod
        });
        
        
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            console.log("Return state = " + state);
            if (state === 'SUCCESS') {
                console.log("ID of new Class Attendance Record: " + response.getReturnValue());
                toastEvent.setParams({
                    title: "Success!",
                    message: "Successfully " + bookingStatus + " the student for the requested class",
                    type: "Success"
                });
                toastEvent.fire();
                
                // refresh the class list
                var compEvent = component.getEvent("refreshListEvent");
                compEvent.fire();
                
                
            } else {
                console.log("Error state returned from APEX Controller 'Register' method");
                toastEvent.setParams({
                    title: "Error!",
                    message: "Failed to add a" + bookingStatus + " record for Scheduled Class" + component.get("v.ClassName"),
                    type: "Error"
                });
                toastEvent.fire();
                
            }
        });
        $A.enqueueAction(action);
        
    },
    
    CancelClassAttendance: function(component, event, AttName) {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "Progress!",
            message: "I've just been asked to cancel attendance record for " + component.get("v.ClsAttendanceID"),
            type: "Success",
            duration:" 5000"
        });
        toastEvent.fire();
        
    }, 
    
    doCommunityLogin: function(component, event, helper) {
        
        console.log("They need to login to register");
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "Login Please",
            message: "You have to login (and if necessary, register) in order to do this",
            type: "Success",
            duration:" 10000"
        });
        toastEvent.fire();
        window.open("https://eandt-developer-edition.ap1.force.com/pilates/login?startURL=%2Fpilates%2Fs%2F%3Ft%3D1512008731132","_self")
        
    },
    
})