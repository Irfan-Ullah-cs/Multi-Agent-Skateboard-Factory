{ include("$jacamoJar/templates/common-cartago.asl") }

assembly_id(aa1).
processed_orders([]).

!start.

+!start : assembly_id(AAID) <-
    .println("[", AAID, "] Assembly agent started");
    makeArtifact("order_space", "tools.OrderTupleSpace", [], OrdArtId);
    makeArtifact("auction_space", "tools.AuctionArtifact", [], AucArtId);
    makeArtifact("workstation_registry", "tools.WorkstationRegistryArtifact", [], RegID);
    focus(OrdArtId);
    focus(AucArtId);
    focus(RegID);
    .println("[AA] Artifacts created (including workstation registry)");
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
    +raw_order(OrderID);
    readOrder(OrderID)[artifact_id(ArtID)];
    updateOrderStatus(OrderID, confirmed)[artifact_id(ArtID)];
    .println("[AA] Confirmed: ", OrderID);
    !run_contracting(OrderID).

+!run_contracting(OrderID) : true <-
    .println("[AA] Starting contracting for: ", OrderID);
    !request_parts(OrderID).

+!request_parts(OrderID) : raw_order(OrderID) <-
    .wait(500);
    lookupArtifact("order_space", OrdArtID);
    focus(OrdArtID);
    readOrder(OrderID)[artifact_id(OrdArtID)];
    !extract_order_data(OrderID).

+!extract_order_data(OrderID) : true <-
    lookupArtifact("order_space", OrdArtID);
    getOrderData(OrderID)[artifact_id(OrdArtID)];
    .wait(200);
    !process_order_cfps(OrderID).

+!process_order_cfps(OrderID) : 
    order_board_type(BoardType) &
    order_trunk_count(TrunkCount) &
    order_wheel_count(WheelCount) &
    order_has_rails(Rails) &
    order_has_connectivity(Connectivity) &
    order_max_cost(MaxCost) &
    order_max_delivery(MaxDelivery) &
    order_max_energy(MaxEnergy) <-
    
    .println("[AA] Order ", OrderID, " - Board: ", BoardType, ", Trunks: ", TrunkCount, ", Wheels: ", WheelCount);
    .println("[AA] Preferences - Max cost: $", MaxCost, ", Max delivery: ", MaxDelivery, "h, Max energy: ", MaxEnergy);
    
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    
    +order_details(OrderID, MaxCost, MaxDelivery, MaxEnergy);
    +parts_needed(OrderID, board);
    +parts_needed(OrderID, trunk);
    +parts_needed(OrderID, wheels);
    
    .println("[AA] Calling CFP for board");
    callForProposal("board", 1, MaxCost, MaxDelivery)[artifact_id(AucID)];
    
    .println("[AA] Calling CFP for trunk");
    callForProposal("trunk", TrunkCount, MaxCost, MaxDelivery)[artifact_id(AucID)];
    
    .println("[AA] Calling CFP for wheels");
    callForProposal("wheels", WheelCount, MaxCost, MaxDelivery)[artifact_id(AucID)];
    
    !request_optional_parts(Rails, Connectivity, OrderID, MaxCost, MaxDelivery, AucID).

// Fallback if max_energy not available
+!process_order_cfps(OrderID) : 
    order_board_type(BoardType) &
    order_trunk_count(TrunkCount) &
    order_wheel_count(WheelCount) &
    order_has_rails(Rails) &
    order_has_connectivity(Connectivity) &
    order_max_cost(MaxCost) &
    order_max_delivery(MaxDelivery) <-
    
    .println("[AA] Order ", OrderID, " - Board: ", BoardType, ", Trunks: ", TrunkCount, ", Wheels: ", WheelCount);
    .println("[AA] Preferences - Max cost: $", MaxCost, ", Max delivery: ", MaxDelivery, "h");
    
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    
    +order_details(OrderID, MaxCost, MaxDelivery, 200);  // Default energy
    +parts_needed(OrderID, board);
    +parts_needed(OrderID, trunk);
    +parts_needed(OrderID, wheels);
    
    .println("[AA] Calling CFP for board");
    callForProposal("board", 1, MaxCost, MaxDelivery)[artifact_id(AucID)];
    
    .println("[AA] Calling CFP for trunk");
    callForProposal("trunk", TrunkCount, MaxCost, MaxDelivery)[artifact_id(AucID)];
    
    .println("[AA] Calling CFP for wheels");
    callForProposal("wheels", WheelCount, MaxCost, MaxDelivery)[artifact_id(AucID)];
    
    !request_optional_parts(Rails, Connectivity, OrderID, MaxCost, MaxDelivery, AucID).

+!request_optional_parts(Rails, Connectivity, OrderID, MaxCost, MaxDelivery, AucID) : Rails = "yes" <-
    +parts_needed(OrderID, rails);
    .println("[AA] Calling CFP for rails");
    callForProposal("rails", 1, MaxCost, MaxDelivery)[artifact_id(AucID)];
    !check_connectivity(Connectivity, OrderID, MaxCost, MaxDelivery, AucID).

+!request_optional_parts(Rails, Connectivity, OrderID, MaxCost, MaxDelivery, AucID) : Rails = "no" <-
    !check_connectivity(Connectivity, OrderID, MaxCost, MaxDelivery, AucID).

+!check_connectivity(Connectivity, OrderID, MaxCost, MaxDelivery, AucID) : Connectivity = "yes" <-
    +parts_needed(OrderID, connectivity);
    .println("[AA] Calling CFP for connectivity");
    callForProposal("connectivity", 1, MaxCost, MaxDelivery)[artifact_id(AucID)];
    .wait(3000);
    !select_all_winners(OrderID).

+!check_connectivity(Connectivity, OrderID, MaxCost, MaxDelivery, AucID) : Connectivity = "no" <-
    .wait(3000);
    !select_all_winners(OrderID).

+!select_all_winners(OrderID) : order_details(OrderID, MaxCost, MaxDelivery, MaxEnergy) <-
    .println("[AA] ===== PHASE 2: SELECTING WINNERS FOR ORDER: ", OrderID, " =====");
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !select_winner_for_part(OrderID, board, MaxCost, MaxDelivery).

+!select_winner_for_part(OrderID, board, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, board, MaxCost, MaxDelivery, AucID);
    ?order_details(OrderID, MC, MD, ME);
    !select_winner_for_part(OrderID, trunk, MC, MD).

+!select_winner_for_part(OrderID, trunk, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, trunk, MaxCost, MaxDelivery, AucID);
    ?order_details(OrderID, MC, MD, ME);
    !select_winner_for_part(OrderID, wheels, MC, MD).

+!select_winner_for_part(OrderID, wheels, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, wheels, MaxCost, MaxDelivery, AucID);
    !select_next_after_wheels(OrderID).

+!select_next_after_wheels(OrderID) : parts_needed(OrderID, rails) <-
    ?order_details(OrderID, MC, MD, ME);
    !select_winner_for_part(OrderID, rails, MC, MD).

+!select_next_after_wheels(OrderID) : parts_needed(OrderID, connectivity) <-
    ?order_details(OrderID, MC, MD, ME);
    !select_winner_for_part(OrderID, connectivity, MC, MD).

+!select_next_after_wheels(OrderID) <-
    !finalize_contracting(OrderID).

+!select_winner_for_part(OrderID, rails, MaxCost, MaxDelivery) : parts_needed(OrderID, rails) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, rails, MaxCost, MaxDelivery, AucID);
    !select_next_after_rails(OrderID).

+!select_next_after_rails(OrderID) : parts_needed(OrderID, connectivity) <-
    ?order_details(OrderID, MC, MD, ME);
    !select_winner_for_part(OrderID, connectivity, MC, MD).

+!select_next_after_rails(OrderID) <-
    !finalize_contracting(OrderID).

+!select_winner_for_part(OrderID, connectivity, MaxCost, MaxDelivery) : parts_needed(OrderID, connectivity) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, connectivity, MaxCost, MaxDelivery, AucID);
    !finalize_contracting(OrderID).

+!process_part_winner(OrderID, PartType, MaxCost, MaxDelivery, AucID) <-
    .println("[AA] Selecting winner for part: ", PartType);
    
    getAuctionIDForPart(PartType)[artifact_id(AucID)];
    .wait(100);
    
    ?auction_id_for_part(AuctionID);
    .println("[AA] Found auction: ", AuctionID);
    
    getBestBid(AuctionID, MaxCost, MaxDelivery)[artifact_id(AucID)];
    .wait(100);
    
    ?best_bid_supplier(WinnerID);
    ?best_bid_price(WinPrice);
    ?best_bid_delivery(WinDelivery);
    
    .println("[AA] Best bid: ", WinnerID, " @ $", WinPrice, " delivery: ", WinDelivery, "h");
    
    processWinner(AuctionID, WinnerID, WinPrice, WinDelivery)[artifact_id(AucID)];
    
    +supplier_selected(OrderID, PartType, WinnerID, WinPrice, WinDelivery);
    
    .println("[AA] Winner selected for ", PartType, ": ", WinnerID).

+!finalize_contracting(OrderID) <-
    .println("[AA] ===== PHASE 2 CONTRACTING COMPLETE FOR ORDER: ", OrderID, " =====");
    
    .findall([Part, Supplier, Price, Delivery], 
             supplier_selected(OrderID, Part, Supplier, Price, Delivery), 
             Suppliers);
    .println("[AA] Selected suppliers: ", Suppliers);
    
    .println("[AA] Ready for Phase 3: Allocating workstations");
    
    // Start Phase 3
    !start_workstation_allocation(OrderID).

// ==================== PHASE 3: WORKSTATION ALLOCATION ====================

+!start_workstation_allocation(OrderID) <-
    .println("[AA] ===== PHASE 3: WORKSTATION ALLOCATION FOR ORDER: ", OrderID, " =====");
    
    // Connect to existing registry
    !ensure_registry_connected;
    
    // Determine assembly sequence based on order parts
    !determine_assembly_sequence(OrderID);
    
    // Start allocating workstations
    !allocate_workstations_for_order(OrderID).

+!ensure_registry_connected <-
    .println("[AA] Connecting to workstation registry...");
    lookupArtifact("workstation_registry", RegID);
    focus(RegID);
    .println("[AA] Connected to workstation registry").

-!ensure_registry_connected <-
    .println("[AA] ERROR: Could not connect to registry, retrying...");
    .wait(1000);
    !ensure_registry_connected.

// Assembly sequence determination
+!determine_assembly_sequence(OrderID) : 
    parts_needed(OrderID, rails) & parts_needed(OrderID, connectivity) <-
    +assembly_sequence(OrderID, [trunk, wheels, rails, connectivity, quality]);
    .println("[AA] Full assembly sequence: trunk -> wheels -> rails -> connectivity -> quality").

+!determine_assembly_sequence(OrderID) : 
    parts_needed(OrderID, rails) <-
    +assembly_sequence(OrderID, [trunk, wheels, rails, quality]);
    .println("[AA] Rails assembly sequence: trunk -> wheels -> rails -> quality").

+!determine_assembly_sequence(OrderID) : 
    parts_needed(OrderID, connectivity) <-
    +assembly_sequence(OrderID, [trunk, wheels, connectivity, quality]);
    .println("[AA] Connectivity assembly sequence: trunk -> wheels -> connectivity -> quality").

+!determine_assembly_sequence(OrderID) : true <-
    +assembly_sequence(OrderID, [trunk, wheels, quality]);
    .println("[AA] Basic assembly sequence: trunk -> wheels -> quality").

// Allocate all workstations for order
+!allocate_workstations_for_order(OrderID) : assembly_sequence(OrderID, Sequence) <-
    .println("[AA] Allocating workstations for sequence: ", Sequence);
    !allocate_sequence_workstations(OrderID, Sequence).

+!allocate_sequence_workstations(OrderID, []) <-
    .println("[AA] ===== ALL WORKSTATIONS ALLOCATED FOR ORDER: ", OrderID, " =====");
    
    // Show allocation summary
    .findall([Type, WS], workstation_allocated(OrderID, Type, WS), Allocations);
    .println("[AA] Allocated workstations: ", Allocations);
    
    +all_workstations_allocated(OrderID);
    .println("[AA] Ready for Phase 4: Assembly execution").

+!allocate_sequence_workstations(OrderID, [StationType|Rest]) <-
    .println("[AA] Allocating ", StationType, " workstation...");
    !allocate_single_workstation(OrderID, StationType);
    !allocate_sequence_workstations(OrderID, Rest).

// Allocate a single workstation type
+!allocate_single_workstation(OrderID, StationType) : order_details(OrderID, _, _, MaxEnergy) <-
    lookupArtifact("workstation_registry", RegID);
    focus(RegID);
    
    .println("[AA] Searching for available ", StationType, " workstations (max energy: ", MaxEnergy, ")");
    findAvailableWorkstations(StationType, MaxEnergy)[artifact_id(RegID)];
    .wait(200);
    
    !try_allocate_best_workstation(OrderID, StationType).

// Fallback if order_details doesn't have energy
+!allocate_single_workstation(OrderID, StationType) <-
    lookupArtifact("workstation_registry", RegID);
    focus(RegID);
    
    .println("[AA] Searching for available ", StationType, " workstations");
    findAvailableWorkstations(StationType, 200)[artifact_id(RegID)];
    .wait(200);
    
    !try_allocate_best_workstation(OrderID, StationType).

// Use the best_workstation observable property directly
+!try_allocate_best_workstation(OrderID, StationType) : 
    best_workstation(BestWS) & BestWS \== "none" & available_count(Count) & Count > 0 <-
    
    .println("[AA] Best available: ", BestWS);
    
    lookupArtifact("workstation_registry", RegID);
    allocateWorkstation(BestWS, OrderID)[artifact_id(RegID)];
    .wait(100);
    
    // Check allocation result
    ?allocation_result(Result);
    !handle_allocation_result(OrderID, StationType, BestWS, Result).

// No workstations available
+!try_allocate_best_workstation(OrderID, StationType) : 
    best_workstation("none") <-
    .println("[AA] No ", StationType, " workstations available - waiting...");
    .wait(2000);
    !allocate_single_workstation(OrderID, StationType).

+!try_allocate_best_workstation(OrderID, StationType) : 
    available_count(0) <-
    .println("[AA] No ", StationType, " workstations available - waiting...");
    .wait(2000);
    !allocate_single_workstation(OrderID, StationType).

// Fallback
+!try_allocate_best_workstation(OrderID, StationType) <-
    .println("[AA] Waiting for workstation data...");
    .wait(1000);
    !allocate_single_workstation(OrderID, StationType).

// Handle allocation result
+!handle_allocation_result(OrderID, StationType, WS, "success") <-
    +workstation_allocated(OrderID, StationType, WS);
    .println("[AA] ✓ ", StationType, " workstation ", WS, " allocated to ", OrderID).

+!handle_allocation_result(OrderID, StationType, WS, "busy") <-
    .println("[AA] ✗ ", WS, " is busy, trying next...");
    .wait(500);
    !allocate_single_workstation(OrderID, StationType).

+!handle_allocation_result(OrderID, StationType, WS, Result) <-
    .println("[AA] ✗ Allocation failed: ", Result, " - retrying...");
    .wait(1000);
    !allocate_single_workstation(OrderID, StationType).