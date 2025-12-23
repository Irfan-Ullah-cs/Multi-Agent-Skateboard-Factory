{ include("$jacamoJar/templates/common-cartago.asl") }

assembly_id(aa1).

!start.

+!start : assembly_id(AAID) <-
    .println("[", AAID, "] Assembly agent started");
    makeArtifact("order_space", "tools.OrderTupleSpace", [], OrdArtId);
    makeArtifact("auction_space", "tools.AuctionArtifact", [], AucArtId);
    makeArtifact("workstation_registry", "tools.WorkstationRegistryArtifact", [], RegID);
    
    focus(OrdArtId);
    focus(AucArtId);
    focus(RegID);
    .println("[AA] All artifacts created");
    !monitor.

+!monitor <-
    lookupArtifact("order_space", ArtID);
    getNextPendingOrder[artifact_id(ArtID)];
    .wait(1000);
    !monitor.

+next_pending_order(OrderID) <-
    .println("[AA] Got order: ", OrderID);
    lookupArtifact("order_space", ArtID);
    +raw_order(OrderID);
    readOrder(OrderID)[artifact_id(ArtID)];
    updateOrderStatus(OrderID, confirmed)[artifact_id(ArtID)];
    !run_contracting(OrderID).

// ==================== PHASE 2: CONTRACTING ====================

+!run_contracting(OrderID) <-
    .println("[AA] Phase 2: Contracting for ", OrderID);
    !request_parts(OrderID).

+!request_parts(OrderID) : raw_order(OrderID) <-
    .wait(500);
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
    order_max_delivery(MaxDelivery) <-
    
    lookupArtifact("auction_space", AucID);
    
    +order_details(OrderID, MaxCost, MaxDelivery, 200);
    +parts_needed(OrderID, board);
    +parts_needed(OrderID, trunk);
    +parts_needed(OrderID, wheels);
    
    callForProposal("board", 1, MaxCost, MaxDelivery)[artifact_id(AucID)];
    callForProposal("trunk", TrunkCount, MaxCost, MaxDelivery)[artifact_id(AucID)];
    callForProposal("wheels", WheelCount, MaxCost, MaxDelivery)[artifact_id(AucID)];
    
    !request_optional_parts(Rails, Connectivity, OrderID, MaxCost, MaxDelivery, AucID).

+!request_optional_parts("yes", Connectivity, OrderID, MaxCost, MaxDelivery, AucID) <-
    +parts_needed(OrderID, rails);
    callForProposal("rails", 1, MaxCost, MaxDelivery)[artifact_id(AucID)];
    !check_connectivity(Connectivity, OrderID, MaxCost, MaxDelivery, AucID).

+!request_optional_parts("no", Connectivity, OrderID, MaxCost, MaxDelivery, AucID) <-
    !check_connectivity(Connectivity, OrderID, MaxCost, MaxDelivery, AucID).

+!check_connectivity("yes", OrderID, MaxCost, MaxDelivery, AucID) <-
    +parts_needed(OrderID, connectivity);
    callForProposal("connectivity", 1, MaxCost, MaxDelivery)[artifact_id(AucID)];
    .wait(3000);
    !select_all_winners(OrderID).

+!check_connectivity("no", OrderID, MaxCost, MaxDelivery, AucID) <-
    .wait(3000);
    !select_all_winners(OrderID).

+!select_all_winners(OrderID) : order_details(OrderID, MaxCost, MaxDelivery, _) <-
    .println("[AA] Selecting winners...");
    lookupArtifact("auction_space", AucID);
    !select_winner_for_part(OrderID, board, MaxCost, MaxDelivery).

+!select_winner_for_part(OrderID, board, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    !process_part_winner(OrderID, board, MaxCost, MaxDelivery, AucID);
    ?order_details(OrderID, MC, MD, _);
    !select_winner_for_part(OrderID, trunk, MC, MD).

+!select_winner_for_part(OrderID, trunk, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    !process_part_winner(OrderID, trunk, MaxCost, MaxDelivery, AucID);
    ?order_details(OrderID, MC, MD, _);
    !select_winner_for_part(OrderID, wheels, MC, MD).

+!select_winner_for_part(OrderID, wheels, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    !process_part_winner(OrderID, wheels, MaxCost, MaxDelivery, AucID);
    !select_next_after_wheels(OrderID).

+!select_next_after_wheels(OrderID) : parts_needed(OrderID, rails) <-
    ?order_details(OrderID, MC, MD, _);
    !select_winner_for_part(OrderID, rails, MC, MD).

+!select_next_after_wheels(OrderID) : parts_needed(OrderID, connectivity) <-
    ?order_details(OrderID, MC, MD, _);
    !select_winner_for_part(OrderID, connectivity, MC, MD).

+!select_next_after_wheels(OrderID) <-
    !finalize_contracting(OrderID).

+!select_winner_for_part(OrderID, rails, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    !process_part_winner(OrderID, rails, MaxCost, MaxDelivery, AucID);
    !select_next_after_rails(OrderID).

+!select_next_after_rails(OrderID) : parts_needed(OrderID, connectivity) <-
    ?order_details(OrderID, MC, MD, _);
    !select_winner_for_part(OrderID, connectivity, MC, MD).

+!select_next_after_rails(OrderID) <-
    !finalize_contracting(OrderID).

+!select_winner_for_part(OrderID, connectivity, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    !process_part_winner(OrderID, connectivity, MaxCost, MaxDelivery, AucID);
    !finalize_contracting(OrderID).

+!process_part_winner(OrderID, PartType, MaxCost, MaxDelivery, AucID) <-
    getAuctionIDForPart(PartType)[artifact_id(AucID)];
    .wait(100);
    ?auction_id_for_part(AuctionID);
    getBestBid(AuctionID, MaxCost, MaxDelivery)[artifact_id(AucID)];
    .wait(100);
    ?best_bid_supplier(WinnerID);
    ?best_bid_price(WinPrice);
    ?best_bid_delivery(WinDelivery);
    processWinner(AuctionID, WinnerID, WinPrice, WinDelivery)[artifact_id(AucID)];
    +supplier_selected(OrderID, PartType, WinnerID, WinPrice, WinDelivery).

+!finalize_contracting(OrderID) <-
    .println("[AA] Contracting complete");
    !start_workstation_allocation(OrderID).

// ==================== PHASE 3: ALLOCATION ====================

+!start_workstation_allocation(OrderID) <-
    .println("[AA] Phase 3: Allocation for ", OrderID);
    !determine_assembly_sequence(OrderID);
    !allocate_workstations_for_order(OrderID).

+!determine_assembly_sequence(OrderID) : 
    parts_needed(OrderID, rails) & parts_needed(OrderID, connectivity) <-
    +assembly_sequence(OrderID, [trunk, wheels, rails, connectivity, quality]).

+!determine_assembly_sequence(OrderID) : parts_needed(OrderID, rails) <-
    +assembly_sequence(OrderID, [trunk, wheels, rails, quality]).

+!determine_assembly_sequence(OrderID) : parts_needed(OrderID, connectivity) <-
    +assembly_sequence(OrderID, [trunk, wheels, connectivity, quality]).

+!determine_assembly_sequence(OrderID) <-
    +assembly_sequence(OrderID, [trunk, wheels, quality]).

+!allocate_workstations_for_order(OrderID) : assembly_sequence(OrderID, Sequence) <-
    !allocate_sequence_workstations(OrderID, Sequence).

+!allocate_sequence_workstations(OrderID, []) <-
    .println("[AA] All workstations allocated");
    !start_assembly_execution(OrderID).

+!allocate_sequence_workstations(OrderID, [StationType|Rest]) <-
    !allocate_single_workstation(OrderID, StationType);
    !allocate_sequence_workstations(OrderID, Rest).

+!allocate_single_workstation(OrderID, StationType) <-
    lookupArtifact("workstation_registry", RegID);
    findAvailableWorkstations(StationType, 200)[artifact_id(RegID)];
    .wait(200);
    !try_allocate_best_workstation(OrderID, StationType).

+!try_allocate_best_workstation(OrderID, StationType) : 
    best_workstation(BestWS) & BestWS \== "none" <-
    lookupArtifact("workstation_registry", RegID);
    allocateWorkstation(BestWS, OrderID)[artifact_id(RegID)];
    .wait(100);
    ?allocation_result(Result);
    !handle_allocation_result(OrderID, StationType, BestWS, Result).

+!try_allocate_best_workstation(OrderID, StationType) <-
    .println("[AA] Waiting for ", StationType, " workstation...");
    .wait(2000);
    !allocate_single_workstation(OrderID, StationType).

+!handle_allocation_result(OrderID, StationType, WS, "success") <-
    +workstation_allocated(OrderID, StationType, WS);
    .println("[AA] Allocated: ", StationType, " -> ", WS).

+!handle_allocation_result(OrderID, StationType, WS, _) <-
    .wait(500);
    !allocate_single_workstation(OrderID, StationType).

// ==================== PHASE 4: EXECUTION WITH VISUALIZATION ====================

+!start_assembly_execution(OrderID) <-
    .println("[AA] Phase 4: Assembly Execution ", OrderID);
    
    // Create separate GUI window for THIS order
    .concat("skateboard_gui_", OrderID, GuiName);
    makeArtifact(GuiName, "simulator.Skateboard", [], GuiID);
    focus(GuiID);
    +gui_for_order(OrderID, GuiName);
    
    // Add board to visualization
    addBoard[artifact_id(GuiID)];
    .println("[AA] [GUI] Board added to display for ", OrderID);
    
    // Request deliveries and execute
    !request_all_deliveries(OrderID);
    !wait_for_all_parts(OrderID);
    
    ?assembly_sequence(OrderID, Sequence);
    !execute_assembly_sequence(OrderID, Sequence).

+!request_all_deliveries(OrderID) <-
    .findall([Part, Supplier, Price, Delivery], 
             supplier_selected(OrderID, Part, Supplier, Price, Delivery), 
             Suppliers);
    !send_delivery_requests(OrderID, Suppliers).

+!send_delivery_requests(OrderID, []).
+!send_delivery_requests(OrderID, [[Part, Supplier, Price, Delivery]|Rest]) <-
    .term2string(SupplierAtom, Supplier);
    .send(SupplierAtom, achieve, deliver_part(OrderID, Part, Delivery));
    +awaiting_part(OrderID, Part);
    !send_delivery_requests(OrderID, Rest).

+!wait_for_all_parts(OrderID) <-
    .findall(Part, awaiting_part(OrderID, Part), Awaiting);
    !check_parts_status(OrderID, Awaiting).

+!check_parts_status(OrderID, []).
+!check_parts_status(OrderID, Awaiting) <-
    .wait(500);
    .findall(Part, awaiting_part(OrderID, Part), Still);
    !check_parts_status(OrderID, Still).

+part_delivered(OrderID, PartType)[source(_)] <-
    .println("[AA] Delivered: ", PartType);
    -awaiting_part(OrderID, PartType).

// Execute assembly with GUI updates
+!execute_assembly_sequence(OrderID, []) <-
    .println("[AA] Assembly complete!");
    !finalize_order(OrderID).

+!execute_assembly_sequence(OrderID, [StationType|Rest]) <-
    .println("[AA] Executing: ", StationType);
    
    ?workstation_allocated(OrderID, StationType, WorkstationID);
    .term2string(WSAtom, WorkstationID);
    .send(WSAtom, achieve, execute_operation(OrderID, StationType));
    
    +awaiting_workstation(OrderID, StationType);
    !wait_for_workstation(OrderID, StationType);
    
    // UPDATE GUI VISUALIZATION - pass OrderID to find correct GUI
    !update_gui(OrderID, StationType);
    
    // Release workstation
    lookupArtifact("workstation_registry", RegID);
    releaseWorkstation(WorkstationID)[artifact_id(RegID)];
    -workstation_allocated(OrderID, StationType, WorkstationID);
    
    !execute_assembly_sequence(OrderID, Rest).

// GUI UPDATE PLANS - Each operation updates the correct order's GUI
+!update_gui(OrderID, trunk) <-
    ?gui_for_order(OrderID, GuiName);
    lookupArtifact(GuiName, GuiID);
    assembleTrunks[artifact_id(GuiID)];
    .println("[AA] [GUI] Trunks displayed for ", OrderID).

+!update_gui(OrderID, wheels) <-
    ?gui_for_order(OrderID, GuiName);
    lookupArtifact(GuiName, GuiID);
    mountWheels[artifact_id(GuiID)];
    .println("[AA] [GUI] Wheels displayed for ", OrderID).

+!update_gui(OrderID, rails) <-
    ?gui_for_order(OrderID, GuiName);
    lookupArtifact(GuiName, GuiID);
    attachRails[artifact_id(GuiID)];
    .println("[AA] [GUI] Rails displayed for ", OrderID).

+!update_gui(OrderID, connectivity) <-
    ?gui_for_order(OrderID, GuiName);
    lookupArtifact(GuiName, GuiID);
    installConnectivity[artifact_id(GuiID)];
    .println("[AA] [GUI] Connectivity displayed for ", OrderID).

+!update_gui(OrderID, quality) <-
    ?gui_for_order(OrderID, GuiName);
    lookupArtifact(GuiName, GuiID);
    performQualityCheck[artifact_id(GuiID)];
    .println("[AA] [GUI] Quality stamp displayed for ", OrderID).

// Wait for workstation completion
+!wait_for_workstation(OrderID, StationType) : workstation_done(OrderID, StationType) <-
    -workstation_done(OrderID, StationType);
    -awaiting_workstation(OrderID, StationType).

+!wait_for_workstation(OrderID, StationType) <-
    .wait(300);
    !wait_for_workstation(OrderID, StationType).

+workstation_complete(OrderID, StationType, _)[source(_)] <-
    +workstation_done(OrderID, StationType).

// Finalize
+!finalize_order(OrderID) <-
    .findall(Price, supplier_selected(OrderID, _, _, Price, _), Prices);
    !sum_list(Prices, TotalCost);
    .findall(Del, supplier_selected(OrderID, _, _, _, Del), Dels);
    !max_list(Dels, MaxDel);
    

    .println("[AA] ORDER COMPLETE: ", OrderID);
    .println("[AA] Total Cost: $", TotalCost);
    .println("[AA] Delivery: ", MaxDel, "h");
    
    // Update GUI with final order info
    ?gui_for_order(OrderID, GuiName);
    lookupArtifact(GuiName, GuiID);
    setOrderInfo(OrderID, TotalCost, MaxDel)[artifact_id(GuiID)];
    
    .send(ca1, tell, order_completed(OrderID, TotalCost, MaxDel));
    
    // Keep showing for 8 seconds before cleanup
    .wait(8000);
    !cleanup_order(OrderID).

+!sum_list([], 0).
+!sum_list([H|T], Sum) <-
    !sum_list(T, RestSum);
    Sum = H + RestSum.

+!max_list([X], X).
+!max_list([H|T], Max) <-
    !max_list(T, TMax);
    if (H > TMax) { Max = H } else { Max = TMax }.

+!cleanup_order(OrderID) <-
    .abolish(supplier_selected(OrderID, _, _, _, _));
    .abolish(parts_needed(OrderID, _));
    .abolish(assembly_sequence(OrderID, _));
    .abolish(order_details(OrderID, _, _, _));
    -gui_for_order(OrderID, _);
    -raw_order(OrderID).
