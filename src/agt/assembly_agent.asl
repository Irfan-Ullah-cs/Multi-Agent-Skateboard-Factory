{ include("$jacamoJar/templates/common-cartago.asl") }

assembly_id(aa1).
processed_orders([]).

!start.

+!start : assembly_id(AAID) <-
    .println("[", AAID, "] Assembly agent started");
    makeArtifact("order_space", "tools.OrderTupleSpace", [], ArtId);
    focus(ArtId);
    .println("[AA] Artifact created");
    !monitor.

+!monitor <-
    lookupArtifact("order_space", ArtID);
    focus(ArtID);
    getNextPendingOrder[artifact_id(ArtID)];
    .wait(1000);
    !monitor.

+next_pending_order(OrderID) <-
    .println("[AA] Got order: ", OrderID);
    lookupArtifact("order_space", ArtID);
    focus(ArtID);
    readOrder(OrderID)[artifact_id(ArtID)];
    updateOrderStatus(OrderID, confirmed)[artifact_id(ArtID)];
    .println("[AA] Confirmed: ", OrderID).