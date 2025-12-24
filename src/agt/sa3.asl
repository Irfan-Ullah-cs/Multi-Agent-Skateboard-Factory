// Supply Agent 3 - Quality and Reputation Strategy
// Specializes in highest quality parts with premium reputation
{ include("$jacamoJar/templates/common-cartago.asl") }

// Agent Identity
supplier_id(sa3).

// Supply Capabilities - Mid-price, best reputation and quality
can_supply(board, 155, 22, 0.97).         // Price: $155, Delivery: 22h, Reputation: 97%
can_supply(trunk, 52, 16, 0.96).          // Price: $52, Delivery: 16h, Reputation: 96%
can_supply(wheels, 32, 14, 0.98).         // Price: $32, Delivery: 14h, Reputation: 98%
can_supply(rails, 70, 18, 0.95).          // Price: $70, Delivery: 18h, Reputation: 95%
can_supply(connectivity, 110, 20, 0.94).  // Price: $110, Delivery: 20h, Reputation: 94%

!start.

+!start : supplier_id(SID) <-
    .println("[", SID, "] Quality & Reputation Supply Agent Started");
    .wait(2000);
    !monitor_auctions.

+!monitor_auctions <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .println("[SA3] Connected to auction environment");
    !listen_loop.

-!monitor_auctions <-
    .println("[SA3] Waiting for auction environment...");
    .wait(500);
    !monitor_auctions.

+!listen_loop <-
    .wait(500);
    !listen_loop.

// ========== AUCTION HANDLING ==========

+auction_open(AuctionID) : supplier_id(SID) <-
    .println("[SA3] New auction detected: ", AuctionID);
    !evaluate_bid(AuctionID, SID).

+!evaluate_bid(AuctionID, SID) <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .wait(100);
    !maybe_submit_bid(AuctionID, SID).

+!maybe_submit_bid(AuctionID, SID) <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    getAuctionDetails(AuctionID, PartType)[artifact_id(AucArtID)];
    .wait(200);
    !check_and_bid(AuctionID, SID).

+!check_and_bid(AuctionID, SID) : auction_part_type(PartType) <-
    .println("[SA3] Evaluating auction for part: ", PartType);
    .term2string(PartAtom, PartType);
    
    if (can_supply(PartAtom, Price, Delivery, Rep)) {
        .println("[SA3] Can supply ", PartAtom, " @ $", Price, ", delivery: ", Delivery, "h");
        lookupArtifact("auction_space", AucArtID);
        submitBid(AuctionID, SID, Price, Delivery)[artifact_id(AucArtID)];
        .println("[SA3] Bid submitted successfully")
    } else {
        if (can_supply(PartType, Price2, Delivery2, Rep2)) {
            .println("[SA3] Can supply ", PartType, " @ $", Price2, ", delivery: ", Delivery2, "h");
            lookupArtifact("auction_space", AucArtID);
            submitBid(AuctionID, SID, Price2, Delivery2)[artifact_id(AucArtID)];
            .println("[SA3] Bid submitted (fallback)")
        } else {
            .println("[SA3] Cannot supply ", PartType)
        }
    }.

+!check_and_bid(AuctionID, SID) <-
    .println("[SA3] Could not get auction details").

+auction_awarded(AuctionID) : supplier_id(SID) <-
    .println("[SA3] Contract awarded: ", AuctionID);
    +active_contract(AuctionID).

+auction_closed(AuctionID) <-
    .println("[SA3] Auction closed: ", AuctionID).

// ========== PHASE 4: DELIVERY ==========

+!deliver_part(OrderID, PartType, DeliveryTime) : supplier_id(SID) <-
    .println("");
    .println("[SA3]");
    .println("[SA3]   DELIVERY REQUEST                  │");
    .println("[SA3] ");
    .println("[SA3]   Order: ", OrderID);
    .println("[SA3]   Part: ", PartType);
    .println("[SA3]   ETA: ", DeliveryTime, " hours");
    .println("[SA3]");
    
    +delivering(OrderID, PartType);
    
    // Simulate delivery (50ms per hour)
    DeliveryMs = DeliveryTime * 50;
    .println("[SA3] Shipping... (", DeliveryMs, "ms)");
    .wait(DeliveryMs);
    
    .println("[SA3]  DELIVERED: ", PartType, " for ", OrderID);
    
    // Notify assembly agent
    .send(aa1, tell, part_delivered(OrderID, PartType));
    
    -delivering(OrderID, PartType);
    +delivered(OrderID, PartType).

-!deliver_part(OrderID, PartType, DeliveryTime) : supplier_id(SID) <-
    .println("[SA3] ERROR: Delivery failed for ", PartType);
    .send(aa1, tell, delivery_failed(OrderID, PartType, SID)).
