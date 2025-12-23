{ include("$jacamoJar/templates/common-cartago.asl") }

// Beliefs are passed from .jcm file:
// workstation_id, workstation_type, energy_consumption, execution_time

!start.

+!start : workstation_id(WSID) & workstation_type(Type) & 
          energy_consumption(Energy) & execution_time(Time) <-
    .println("[", WSID, "] Workstation agent started - Type: ", Type);
    
    // Create unique artifact for this workstation
    .concat("ws_artifact_", WSID, ArtifactName);
    makeArtifact(ArtifactName, "tools.WorkstationArtifact", [Type, Energy, Time], WSArtID);
    focus(WSArtID);
    +my_artifact(ArtifactName, WSArtID);
    +my_energy(Energy);
    +my_time(Time);
    
    // Wait for registry to be created by assembly agent
    .wait(2000);
    
    // Register with the registry
    !register_with_registry(WSID, Type, Energy, Time);
    
    // Ready for work
    !idle_loop.

// Register with workstation registry
+!register_with_registry(WSID, Type, Energy, Time) <-
    .println("[", WSID, "] Attempting to register with registry...");
    lookupArtifact("workstation_registry", RegID);
    focus(RegID);
    registerWorkstation(WSID, Type, Energy, Time)[artifact_id(RegID)];
    .println("[", WSID, "]  Successfully registered with registry");
    +registered.

-!register_with_registry(WSID, Type, Energy, Time) <-
    .println("[", WSID, "] Registry not ready, retrying in 2s...");
    .wait(2000);
    !register_with_registry(WSID, Type, Energy, Time).

// Idle loop - just keeps agent alive
+!idle_loop <-
    .wait(5000);
    !idle_loop.

// ==================== PHASE 4: EXECUTION ====================

// Handle execute_operation request from assembly agent
+!execute_operation(OrderID, StationType) : 
    workstation_id(WSID) & 
    my_artifact(ArtName, ArtID) &
    my_time(ExecTime) &
    my_energy(Energy) <-
    
    .println("");
    .println("[", WSID, "]");
    .println("[", WSID, "]   EXECUTING OPERATION                 ");
    .println("[", WSID, "] ");
    .println("[", WSID, "]   Order: ", OrderID);
    .println("[", WSID, "]   Type: ", StationType);
    .println("[", WSID, "]   Duration: ", ExecTime, " time units");
    .println("[", WSID, "]   Energy: ", Energy, " units");
    .println("[", WSID, "] ");
    
    // Mark as busy
    +executing(OrderID, StationType);
    
    // Execute on artifact
    execute[artifact_id(ArtID)];
    
    // Simulate execution time (scaled: 100ms per time unit)
    ExecutionMs = ExecTime * 100;
    .println("[", WSID, "] Processing... (", ExecutionMs, "ms)");
    .wait(ExecutionMs);
    
    .println("[", WSID, "]  Operation complete!");
    
    // Mark as done
    -executing(OrderID, StationType);
    
    // Notify assembly agent
    .send(aa1, tell, workstation_complete(OrderID, StationType, WSID));
    
    .println("[", WSID, "] Notified assembly agent").

// Fallback without timing info
+!execute_operation(OrderID, StationType) : 
    workstation_id(WSID) & 
    my_artifact(ArtName, ArtID) <-
    
    .println("[", WSID, "] Executing ", StationType, " for order: ", OrderID);
    
    +executing(OrderID, StationType);
    
    execute[artifact_id(ArtID)];
    .wait(1500);
    
    -executing(OrderID, StationType);
    
    .send(aa1, tell, workstation_complete(OrderID, StationType, WSID));
    .println("[", WSID, "]  Complete").

// Error handler
-!execute_operation(OrderID, StationType) : workstation_id(WSID) <-
    .println("[", WSID, "] ERROR: Failed to execute for order: ", OrderID);
    .send(aa1, tell, workstation_failed(OrderID, StationType, WSID)).

// Status query (for debugging)
+!status : workstation_id(WSID) & workstation_type(Type) <-
    if (executing(Order, Op)) {
        .println("[", WSID, "] BUSY - Order: ", Order, ", Op: ", Op)
    } else {
        .println("[", WSID, "] IDLE - Type: ", Type)
    }.
