{ include("$jacamoJar/templates/common-cartago.asl") }

// Agent beliefs come from MAS file parameters

!start.

+!start : workstation_id(WSID) & workstation_type(Type) & 
          energy_consumption(Energy) & execution_time(Time) <-
    .println("[", WSID, "] Workstation agent started - Type: ", Type);
    
    // Create unique artifact for this workstation
    .concat("ws_", WSID, ArtifactName);
    makeArtifact(ArtifactName, "tools.WorkstationArtifact", [Type, Energy, Time], WSArtID);
    focus(WSArtID);
    +my_workstation_artifact(ArtifactName, WSArtID);
    
    // Wait for assembly agent to create registry
    .wait(2000);
    
    // Register with the registry
    !register_with_registry(WSID, Type, Energy, Time);
    
    // Start monitoring for work requests
    !monitor_for_work.

// Register with the workstation registry
+!register_with_registry(WSID, Type, Energy, Time) <-
    .println("[", WSID, "] Attempting to register with registry...");
    lookupArtifact("workstation_registry", RegID);
    focus(RegID);
    registerWorkstation(WSID, Type, Energy, Time)[artifact_id(RegID)];
    .println("[", WSID, "] ✓ Successfully registered with registry");
    +registered_successfully.

// Retry registration if it fails
-!register_with_registry(WSID, Type, Energy, Time) <-
    .println("[", WSID, "] Registry not available yet, retrying in 2s...");
    .wait(2000);
    !register_with_registry(WSID, Type, Energy, Time).

// Monitor for execution requests
+!monitor_for_work : workstation_id(WSID) <-
    .wait(1000);
    !monitor_for_work.

// Handle execution trigger from assembly agent
+execute_request(OrderID, WSID) : 
    workstation_id(WSID) & 
    my_workstation_artifact(ArtName, ArtID) <-
    
    .println("[", WSID, "] Received execution request for order: ", OrderID);
    
    // Execute the workstation operation
    execute[artifact_id(ArtID)];
    
    .println("[", WSID, "] ✓ Completed execution for order: ", OrderID);
    
    // Notify assembly agent
    .send(aa1, tell, workstation_execution_complete(OrderID, WSID)).

// React to being allocated (from registry observable property)
+allocation_success(WSID) : workstation_id(WSID) <-
    .println("[", WSID, "] Allocation confirmed by registry").

// For debugging - show workstation status periodically
+!show_status : workstation_id(WSID) & workstation_type(Type) <-
    .println("[", WSID, "] Status check - Type: ", Type, ", Registered: ", registered_successfully).