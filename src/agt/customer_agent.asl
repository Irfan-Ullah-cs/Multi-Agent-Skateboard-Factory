{ include("$jacamoJar/templates/common-cartago.asl") }

customer_id(ca1).

// ========== ORDER SPECIFICATIONS ==========
// Each order defines WHAT to build: board type, trunks count, wheels count, rails (yes/no), connectivity (yes/no)
order_spec(ord001, "specification(maple_deck, 2, 4, no, no)").    // Basic skateboard: maple deck, 2 trunks, 4 wheels
order_spec(ord002, "specification(bamboo_deck, 2, 4, yes, no)").  // With rails: bamboo deck, add 2 rails
order_spec(ord003, "specification(maple_deck, 2, 4, yes, yes)").  // Full skateboard: all components

// ========== ORDER PREFERENCES (CONSTRAINTS) ==========
// Each order defines CONSTRAINTS: max cost allowed, max delivery time, max energy consumption
order_prefs(ord001, "preferences(500, 48, 100)").    // Max $500, 48 hours, 100 energy units
order_prefs(ord002, "preferences(700, 72, 150)").    // Max $700, 72 hours, 150 energy units
order_prefs(ord003, "preferences(1000, 96, 200)").   // Max $1000, 96 hours, 200 energy units


submitted_orders([]).

!start.

+!start : customer_id(CID) <-
    .println("[", CID, "] Customer agent started");
    .wait(5000);
    !submit_all_orders.

+!submit_all_orders : true <-
    .println("[CA] Submitting orders");
    !submit(ord001);
    !submit(ord002);
    !submit(ord003).

+!submit(OrderID) : 
    customer_id(CID) &
    order_spec(OrderID, Spec) & 
    order_prefs(OrderID, Prefs) <-
    
    lookupArtifact("order_space", ArtID);
    focus(ArtID);
    writeOrder(OrderID, CID, Spec, Prefs)[artifact_id(ArtID)];
    .println("[CA] Submitted: ", OrderID).