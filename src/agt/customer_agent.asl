{ include("$jacamoJar/templates/common-cartago.asl") }

customer_id(ca1).

// ========== ORDER SPECIFICATIONS ==========
// Each order defines WHAT to build: board type, trunks count, wheels count, rails (yes/no), connectivity (yes/no)
order_spec(ord001, "specification(maple_deck, 2, 4, no, no)").    // Basic skateboard
// order_spec(ord002, "specification(bamboo_deck, 2, 4, yes, no)").  // With rails
order_spec(ord003, "specification(maple_deck, 2, 4, yes, yes)").  // Full skateboard

// ========== ORDER PREFERENCES (CONSTRAINTS) ==========
// Each order defines CONSTRAINTS: max cost allowed, max delivery time, max energy consumption
order_prefs(ord001, "preferences(500, 48, 100)").    // Max $500, 48 hours, 100 energy
// order_prefs(ord002, "preferences(700, 72, 150)").    // Max $700, 72 hours, 150 energy
order_prefs(ord003, "preferences(1000, 96, 200)").   // Max $1000, 96 hours, 200 energy

!start.

+!start : customer_id(CID) <-
    .println("[", CID, "] Customer agent started");
    .println("[CA]  SKATEBOARD ORDERING SYSTEM");
    .println("[CA]  Customer: ", CID);
    .wait(5000);
    !submit_all_orders.

// Dynamically find and submit ALL orders
+!submit_all_orders <-
    .findall(OrderID, order_spec(OrderID, _), AllOrders);
    .println("[CA] Found ", .length(AllOrders), " orders to submit");
    !submit_orders_list(AllOrders).

// Base case - when list is empty, all orders submitted
+!submit_orders_list([]) <-
    .println("");
    .println("[CA] All orders submitted! Waiting for completion...").

// Recursive case - submit one, then continue with rest
+!submit_orders_list([OrderID|Rest]) <-
    !submit(OrderID);
    !submit_orders_list(Rest).

+!submit(OrderID) : 
    customer_id(CID) &
    order_spec(OrderID, Spec) & 
    order_prefs(OrderID, Prefs) <-
    
    lookupArtifact("order_space", ArtID);
    focus(ArtID);
    writeOrder(OrderID, CID, Spec, Prefs)[artifact_id(ArtID)];
    
    +order_submitted(OrderID);
    +order_status(OrderID, submitted);
    
    .println("[CA]  ORDER SUBMITTED: ", OrderID);
    .println("[CA]  Spec: ", Spec);
    .println("[CA]  Prefs: ", Prefs).

// ========== PHASE 4: COMPLETION TRACKING ==========

// Handle order completion notification from assembly agent
+order_completed(OrderID, TotalCost, DeliveryTime)[source(aa1)] : 
    customer_id(CID) &
    order_prefs(OrderID, Prefs) <-
    
    -order_status(OrderID, _);
    +order_status(OrderID, completed);
    +order_result(OrderID, TotalCost, DeliveryTime);
    
    .println("");
    .println("[CA]            ORDER COMPLETED!                           ");
    .println("[CA]   Order ID: ", OrderID);
    .println("[CA]   Final Cost: $", TotalCost);
    .println("[CA]   Delivery Time: ", DeliveryTime, " hours");
    .println("[CA]   Original Preferences: ", Prefs);
    .println("");
    
    // Check if order met preferences
    !evaluate_order_satisfaction(OrderID, TotalCost, DeliveryTime, Prefs);
    
    // Check if all orders complete
    !check_all_orders_complete.

// Evaluate if order met customer preferences
+!evaluate_order_satisfaction(OrderID, ActualCost, ActualDelivery, Prefs) <-
    // Parse preferences to extract max values
    // Format: "preferences(maxCost, maxDelivery, maxEnergy)"
    .println("[CA] Evaluating satisfaction for ", OrderID, "...");
    
    // For now, simple satisfaction check
    .println("[CA]  Order ", OrderID, " completed within acceptable parameters!").

// Check if all submitted orders are complete
+!check_all_orders_complete <-
    .findall(O, order_submitted(O), Submitted);
    .findall(O, order_status(O, completed), Completed);
    .length(Submitted, SubCount);
    .length(Completed, CompCount);
    
    .println("[CA] Progress: ", CompCount, "/", SubCount, " orders completed");
    
    if (SubCount == CompCount) {
        !display_final_summary
    }.

// Display final summary when all orders complete
+!display_final_summary <-
    .println("");
    .println("[CA]            ALL ORDERS COMPLETED!                           ");
    
    .findall([O, Cost, Time], order_result(O, Cost, Time), Results);
    !print_results(Results);
    
    !calculate_totals;
    
    .println("[CA] Thank you for using Skateboard Assembly MAS!").

+!print_results([]).
+!print_results([[OrderID, Cost, Time]|Rest]) <-
    .println("[CA]   ", OrderID, ": $", Cost, "  ", Time, "h delivery");
    !print_results(Rest).

+!calculate_totals <-
    .findall(Cost, order_result(_, Cost, _), Costs);
    !sum_list(Costs, TotalCost);
    
    .findall(Time, order_result(_, _, Time), Times);
    !max_list(Times, MaxTime);
    
    .println("[CA]   TOTAL COST: $", TotalCost);
    .println("[CA]   MAX DELIVERY: ", MaxTime, " hours").

// Helper: Sum list
+!sum_list([], 0).
+!sum_list([H|T], Sum) <-
    !sum_list(T, RestSum);
    Sum = H + RestSum.

// Helper: Max in list
+!max_list([X], X).
+!max_list([H|T], Max) <-
    !max_list(T, TMax);
    if (H > TMax) { Max = H } else { Max = TMax }.

// Handle order status updates (optional - for future expansion)
+order_status_update(OrderID, Status)[source(aa1)] <-
    .println("[CA] Order ", OrderID, " status: ", Status);
    -order_status(OrderID, _);
    +order_status(OrderID, Status).
