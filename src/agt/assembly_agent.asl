{ include("$jacamoJar/templates/common-cartago.asl") }

assembly_id(aa1).
processed_orders([]).

!start.

+!start : assembly_id(AAID) <-
    .println("[", AAID, "] Assembly agent started");
    makeArtifact("order_space", "tools.OrderTupleSpace", [], OrdArtId);
    makeArtifact("auction_space", "tools.AuctionArtifact", [], AucArtId);
    focus(OrdArtId);
    focus(AucArtId);
    .println("[AA] Artifacts created");
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
    order_max_delivery(MaxDelivery) <-
    
    .println("[AA] Order ", OrderID, " - Board: ", BoardType, ", Trunks: ", TrunkCount, ", Wheels: ", WheelCount);
    .println("[AA] Preferences - Max cost: $", MaxCost, ", Max delivery: ", MaxDelivery, "h");
    
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    
    +order_details(OrderID, MaxCost, MaxDelivery);
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

+!select_all_winners(OrderID) : order_details(OrderID, MaxCost, MaxDelivery) <-
    .println("[AA] ===== PHASE 2: SELECTING WINNERS FOR ORDER: ", OrderID, " =====");
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !select_winner_for_part(OrderID, board, MaxCost, MaxDelivery).

+!select_winner_for_part(OrderID, board, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, board, MaxCost, MaxDelivery, AucID);
    ?order_details(OrderID, MC, MD);
    !select_winner_for_part(OrderID, trunk, MC, MD).

+!select_winner_for_part(OrderID, trunk, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, trunk, MaxCost, MaxDelivery, AucID);
    ?order_details(OrderID, MC, MD);
    !select_winner_for_part(OrderID, wheels, MC, MD).

+!select_winner_for_part(OrderID, wheels, MaxCost, MaxDelivery) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, wheels, MaxCost, MaxDelivery, AucID);
    !select_next_after_wheels(OrderID).

+!select_next_after_wheels(OrderID) : parts_needed(OrderID, rails) <-
    ?order_details(OrderID, MC, MD);
    !select_winner_for_part(OrderID, rails, MC, MD).

+!select_next_after_wheels(OrderID) : parts_needed(OrderID, connectivity) <-
    ?order_details(OrderID, MC, MD);
    !select_winner_for_part(OrderID, connectivity, MC, MD).

+!select_next_after_wheels(OrderID) <-
    !finalize_contracting(OrderID).

+!select_winner_for_part(OrderID, rails, MaxCost, MaxDelivery) : parts_needed(OrderID, rails) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, rails, MaxCost, MaxDelivery, AucID);
    !select_next_after_rails(OrderID).

+!select_next_after_rails(OrderID) : parts_needed(OrderID, connectivity) <-
    ?order_details(OrderID, MC, MD);
    !select_winner_for_part(OrderID, connectivity, MC, MD).

+!select_next_after_rails(OrderID) <-
    !finalize_contracting(OrderID).

+!select_winner_for_part(OrderID, connectivity, MaxCost, MaxDelivery) : parts_needed(OrderID, connectivity) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, connectivity, MaxCost, MaxDelivery, AucID);
    !finalize_contracting(OrderID).

+!select_next_after_wheels(OrderID) : parts_needed(OrderID, rails) <-
    order_details(OrderID, MC, MD);
    !select_winner_for_part(OrderID, rails, MC, MD).

+!select_next_after_wheels(OrderID) : parts_needed(OrderID, connectivity) <-
    order_details(OrderID, MC, MD);
    !select_winner_for_part(OrderID, connectivity, MC, MD).

+!select_next_after_wheels(OrderID) <-
    !finalize_contracting(OrderID).

+!select_winner_for_part(OrderID, rails, MaxCost, MaxDelivery) : parts_needed(OrderID, rails) <-
    lookupArtifact("auction_space", AucID);
    focus(AucID);
    !process_part_winner(OrderID, rails, MaxCost, MaxDelivery, AucID);
    !select_next_after_rails(OrderID).

+!select_next_after_rails(OrderID) : parts_needed(OrderID, connectivity) <-
    order_details(OrderID, MC, MD);
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
    
    -order_details(OrderID, _, _);
    -raw_order(OrderID);
    .println("[AA] Ready for Phase 3: Allocating workstations").