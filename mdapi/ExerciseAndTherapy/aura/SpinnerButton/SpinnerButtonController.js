({
    handleclick : function(component, event, helper) {
        component.set("v.isLoading", true);
        var compEvent = component.getEvent("startEvent");
        compEvent.setParams({eventType:component.get("v.eventType"), 
                             scheduledClassID:component.get("v.scheduledClassID"), 
                             classAttendanceID:component.get("v.classAttendanceID"),
                             variant:component.get("v.variant")});
        compEvent.fire();
    }
})