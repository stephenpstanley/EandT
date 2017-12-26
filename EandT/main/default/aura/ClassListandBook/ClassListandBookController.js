({
    doInit: function(component, event, helper) {
        // call apex method for fetch all class records into list.
        console.log("Entering doInit");
        console.log("Calling helper class to refresh class schedule");
        helper.getFutureClassesandBookings(component, event);
        // set the userID attribute value
        component.set("v.StudentID" , $A.get("$SObjectType.CurrentUser.Id"));
        console.log("Current user ID: " + $A.get("$SObjectType.CurrentUser.Id") );
        console.log("Exiting doInit");   
    },
    
    handleSpinnerButton: function (component, event, helper){
        
        if(component.get("v.StudentID")) {
        } else {
            helper.doCommunityLogin(component, event, helper);
        }
        var ClickedButton = event.getSource();
        var params=event.getParams();
        console.log("EventType is:" + params.eventType);
        console.log("scheduledClassID is:" + params.scheduledClassID);  //ScheduledClassID
        console.log("classAttendanceID is:" + params.classAttendanceID);  //ClassAttendanceID
        console.log("variant is:" + params.variant);
        
        // if event type is register, then do the registration stuff
        if (params.eventType == 'Register') {
            var bookingStatus = "Booked"; // this tells the helper method what the booking status should be
            component.set("v.BookStatus",bookingStatus);
            helper.getBestConCardandClass(component, event, $A.get("$SObjectType.CurrentUser.Id"), params.scheduledClassID , function(){
                ClickedButton.set("v.isLoading", false);
            });
        } 
        if (params.eventType == 'Waitlist Me'){ // waitlist them
            var bookingStatus = "Waitlisted"; // this tells the helper method what the booking status should be
            component.set("v.BookStatus",bookingStatus);
            helper.getBestConCardandClass(component, event, $A.get("$SObjectType.CurrentUser.Id"), params.scheduledClassID , function(){
                ClickedButton.set("v.isLoading", false);
            });
        } 
        
        if (params.eventType == 'Cancel Waitlist'){ // Cancel their Waitlist entry
            var action = component.get("c.CancelWaitList"); 
            var toastEvent = $A.get("e.force:showToast");
            
            // Pass the ClassAttendanceID to the APEX Controller method  
            // Method: public static ID CancelWaitList(ID ClassAttendanceID)
            
            action.setParams({
                "ClassAttendanceID": params.classAttendanceID 
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log("Return state = " + state);
                if (state === 'SUCCESS') {
                    console.log("Session booking status updated" );
                    toastEvent.setParams({
                        title: "Success!",
                        message: "Removed the student from the waitlist",
                        type: "Success"
                    });
                    toastEvent.fire();

                    // refresh the class list                
                    var compEvent = component.getEvent("refreshListEvent");
                    compEvent.fire();
                    
                    
                } else {
                    console.log("Error state returned from APEX Controller 'CancelWaitList' method");
                    toastEvent.setParams({
                        title: "Error!",
                        message: "Failed to de-waitlist Class Attendance Record, ID= " + WaitListEntry,
                        type: "Error"
                    });
                    toastEvent.fire();
                    
                }
            });
            $A.enqueueAction(action);
            //Stop the spinner on the button
            ClickedButton.set("v.isLoading", false);
            
        }
        if (params.eventType == 'Cancel Booking'){ // Cancel their booking
            var bookingStatus = "Canceled"; // this tells the helper method what the booking status should be
            component.set("v.BookStatus",bookingStatus);
            helper.findClasstoCancel(component, event,  params.classAttendanceID , function(){
                ClickedButton.set("v.isLoading", false);
                
            });
        }        
        
    },
    
    Register: function(component, event, helper) {
        console.log("Entering Register function now");
        var bookingStatus = "Booked"; // this tells the helper method what the booking status should be+
        if(component.get("v.StudentID")) {
            console.log ("v.Student is defined");
        } else {
            console.log ("v.Student is NOT defined");
            helper.doCommunityLogin(component, event, helper);
        }
        component.set("v.BookStatus",bookingStatus);
        
        // Find if the student has a valid concession card for this scheduled class
        console.log('Booking Status: ' +  bookingStatus);
        console.log('ClassID: ' + component.get("v.ClassID"));
        console.log('StudentID: ' + component.get("v.StudentID"));
        console.log('Calling getBestConCardandClass');  
        
        helper.getBestConCardandClass(component, event, helper); 
        
        console.log('Returned from getBestConCardandClass');  
        
        
    },
    
    addtoWaitList: function(component, event, helper) {
        console.log("Entering Waitlist function now");
        if(component.get("v.StudentID")) {
            console.log ("v.Student is defined");
        } else {
            console.log ("v.Student is NOT defined so passing to helper to execute login");
            helper.doCommunityLogin(component, event, helper);
        }
        var bookingStatus = "Waitlisted"; // this tells the helper method what the booking status should be
        component.set("v.BookStatus",bookingStatus);
        
        // Find if the student has a valid concession card for this scheduled class
        console.log('Booking Status: ' +  bookingStatus);
        console.log('ClassID: ' + component.get("v.ClassID"));
        console.log('StudentID: ' + component.get("v.StudentID"));
        console.log('Calling getBestConCardandClass');  
        
        helper.getBestConCardandClass(component, event, helper); 
        
        console.log('Returned from getBestConCardandClass');  
        
    },
    
    onBookingConfirm : function(component, event, helper) {
        component.set("v.ShowBookingdlg", false);
        var CashorCard = component.get("v.PaymentOption");
        var bookingstatus = component.get("v.BookButtonLabel");
        if (CashorCard === "Casual") { // Set dummy concard ID to allow APEX method to run (no null params allowed)
            component.set("v.ConCardID","001000000000000");
        }
        console.debug('Booking status: ' + bookingstatus + ' Payment method: ' + CashorCard + ' Using Concession card: ' + component.get("v.ConCardID"));
        helper.newClassAttendance(component, event);
    },
    
    onBookingCancel : function(component, event, helper) {
        component.set("v.ShowBookingdlg", false);
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "info!", type: "info",
            message: "No class booking made"
        });
        toastEvent.fire(); 
    },
    
    onBookingRadio : function(component, event) {
        var elem = event.target;
        var selected = elem.value;
        console.log("Selected button: " + selected);
        component.set("v.PaymentOption", selected); 
    },
    
    
    CancelBooking: function(component, event, helper) {
        console.log("Entering CancelBooking function now");
        var bookingStatus = "Canceled"; // this tells the helper method what the booking status should be
        component.set("v.BookStatus",bookingStatus);
        
        // Find if the student has a valid concession card for this scheduled class
        console.log('Booking Status: ' +  bookingStatus);
        console.log('ClassID: ' + component.get("v.ClassID"));
        console.log('StudentID: ' + component.get("v.StudentID"));
        console.log('Calling helper.findClasstoCancel');  
        
        helper.findClasstoCancel(component, event, helper); 
        
        console.log('Returned from helper.findClasstoCancel');         
    },
    
    onCancelConfirm : function(component, event, helper) {
        component.set("v.ShowCanceldlg", false);
        console.log('Entered c.onCancelConfirm');
        var BookingtoCancel = component.get("v.ClsAttendanceID");
        
        var action = component.get("c.APEXCancelBooking"); 
        
        // Pass the ClassAttendanceID to the APEX Controller method  
        // Method: public static ID CancelBooking(ID ClassAttendanceID)
        
        action.setParams({
            "ClassAttendanceID": BookingtoCancel 
        });
        
        var toastEvent = $A.get("e.force:showToast");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("Return state = " + state);
            if (state === 'SUCCESS') {
                console.log("Session booking status updated to 'Canceled'" );
                toastEvent.setParams({
                    title: "Success!",
                    message: "Class booking successfully canceled",
                    type: "Success"
                });
                toastEvent.fire();

                // refresh the class list                
                var compEvent = component.getEvent("refreshListEvent");
                compEvent.fire();
            } else {
                console.log("Error state returned from APEX Controller 'CancelBooking' method");
                toastEvent.setParams({
                    title: "Error!",
                    message: "Failed to cancel Class booking, ID= " + BookingtoCancel + " name= " + component.get("v.ClassName"),
                    type: "Error"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
        
    },
    
    onCancelCancel : function(component, event, helper) {
        component.set("v.ShowCanceldlg", false);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "info!", type: "info",
            message: "Cancellation request abandoned"
        });
        toastEvent.fire(); 
            
    },
    
    
    popClassConfirmDialog : function (component, event, helper) {
        console.log('handling event GotmyClassEvent in popClassConfirmDialog');        
        var transactionType = event.getParam("eTxnType"); //  "Booked", "Waitlisted" or "Canceled"
        
        // set the class information for the modal
        
        console.log("class name" + event.getParam("eClassName"));
        component.set("v.ClassName",event.getParam("eClassName"));
        component.set("v.ClassDate",event.getParam("eClassDate"));
        component.set("v.ClassLocation",event.getParam("eClassLocation"));
        component.set("v.ClassType",event.getParam("eClassType"));
        component.set("v.ClassWaitlistLength",event.getParam("eClassWaitlistLength"));
        
        console.log('Class waitlist length: ' + event.getParam("eClassWaitlistLength"));        

        var ccID = event.getParam("eConCardID");
        component.set("v.ConCardValueBalance",event.getParam("eConCardRemainingValue"));
        component.set("v.ConCardSessionsBalance",event.getParam("eConCardRemainingSessions"));
		//re-initalise the payment option
        if (ccID == null) { 
            component.set("v.PaymentOption","Casual"); 
	        component.set("v.ConCardID",""); 
        } else {
            component.set("v.PaymentOption","concard"); 
	        component.set("v.ConCardID",ccID);
        }
        
        //... and show the correct modal
        console.log('pop the modal now by setting the boolean attribute on the correct dialog');
        if (transactionType == 'Canceled') {
            // These attributes needed if this is a cancellation request
            component.set("v.ClsAttendanceID",event.getParam("eClsAttendanceID")); 
            component.set("v.ClassCancelPaymentMethod",event.getParam("eClsPaymentMethod")); 
            component.set("v.ClsCancelFeeDue",event.getParam("eClsCancelFeeDue"));  
            console.log("Cancellation fee due: " + component.get("v.ClsCancelFeeDue"));
            var num = event.getParam("eClsCost");
            var n = num.toFixed(2);
            component.set("v.ClassCancelFee", n);
            console.log("Cancellation amount: " + component.get("v.ClassCancelFee"));
            component.set("v.ClassCancelSessions",event.getParam("eClsSessions"));       
            console.log("Cancellation sessions: " + component.get("v.ClassCancelSessions"));
            console.log("Class ID to confirm cancellation on: " + component.get("v.ClsAttendanceID"));
            component.set("v.ShowCanceldlg", true);  //Show the cancellation confirmation dialog
        } else {
            console.log("Payment method:" + component.get("v.PaymentOption"))
            component.set("v.ShowBookingdlg", true); //Show the booking / waitlisting confirmation dialog
        }        
    },   
    
    removeWaitlist: function(component, event, AttName) {
        console.log('Entered c.removeWaitlist');
        
        var WaitListEntry = event.getSource().get("v.value");
        console.log('Class Attendance ID to de-waitlist: ' + WaitListEntry);
        
        var action = component.get("c.CancelWaitList"); 
        var toastEvent = $A.get("e.force:showToast");
        
        // Pass the ClassAttendanceID to the APEX Controller method  
        // Method: public static ID CancelWaitList(ID ClassAttendanceID)
        
        action.setParams({
            "ClassAttendanceID": WaitListEntry 
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("Return state = " + state);
            if (state === 'SUCCESS') {
                console.log("Session booking status updated" );
                toastEvent.setParams({
                    title: "Success!",
                    message: "Removed the student from the waitlist",
                    type: "Success"
                });
                toastEvent.fire();
                
                // refresh the class list                
                var compEvent = component.getEvent("refreshListEvent");
                compEvent.fire();
                
                
            } else {
                console.log("Error state returned from APEX Controller 'CancelWaitList' method");
                toastEvent.setParams({
                    title: "Error!",
                    message: "Failed to de-waitlist Class Attendance Record, ID= " + WaitListEntry,
                    type: "Error"
                });
                toastEvent.fire();
                
            }
        });
        $A.enqueueAction(action);
        
    },
    
    
})