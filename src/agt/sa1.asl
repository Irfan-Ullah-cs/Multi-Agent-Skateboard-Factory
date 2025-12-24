// Supply Agent 1 - Fast Delivery Strategy
// Specializes in quick turnaround times with competitive pricing
{ include("$jacamoJar/templates/common-cartago.asl") }

// Agent Identity
supplier_id(sa1).

// Supply Capabilities - Fast delivery, mid-range pricing
can_supply(board, 150, 18, 0.95).         // Price: $150, Delivery: 18h, Reputation: 95%
can_supply(trunk, 55, 14, 0.93).          // Price: $55, Delivery: 14h, Reputation: 93%
can_supply(wheels, 35, 12, 0.94).         // Price: $35, Delivery: 12h, Reputation: 94%
can_supply(rails, 75, 20, 0.92).          // Price: $75, Delivery: 20h, Reputation: 92%
can_supply(connectivity, 120, 24, 0.91).  // Price: $120, Delivery: 24h, Reputation: 91%

!start.

+!start : supplier_id(SID) <-
    .println("[", SID, "] Fast Delivery Supply Agent Started");
    .wait(2000);
    !monitor_auctions.

+!monitor_auctions <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .println("[SA1] Connected to auction environment");
    !listen_loop.

-!monitor_auctions <-
    .println("[SA1] Waiting for auction environment...");
    .wait(500);
    !monitor_auctions.

+!listen_loop <-
    .wait(500);
    !listen_loop.

// ========== AUCTION HANDLING ==========

+auction_open(AuctionID) : supplier_id(SID) <-
    .println("[SA1] New auction detected: ", AuctionID);
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
    !check_and_bid(AuctionID, SID, PartType).

+!check_and_bid(AuctionID, SID, PartType) : true <-
    .println("[SA1] Evaluating auction for part: ", PartType);
    .term2string(PartAtom, PartType);
    
    if (can_supply(PartAtom, Price, Delivery, Rep)) {
        .println("[SA1] Can supply ", PartAtom, " @ $", Price, ", delivery: ", Delivery, "h");
        lookupArtifact("auction_space", AucArtID);
        submitBid(AuctionID, SID, Price, Delivery)[artifact_id(AucArtID)];
        .println("[SA1] Bid submitted successfully")
    } else {
        if (can_supply(PartType, Price2, Delivery2, Rep2)) {
            .println("[SA1] Can supply ", PartType, " @ $", Price2, ", delivery: ", Delivery2, "h");
            lookupArtifact("auction_space", AucArtID);
            submitBid(AuctionID, SID, Price2, Delivery2)[artifact_id(AucArtID)];
            .println("[SA1] Bid submitted (fallback)")
        } else {
            .println("[SA1] Cannot supply ", PartType)
        }
    }.

+!check_and_bid(AuctionID, SID, PartType) <-
    .println("[SA1] Could not get auction details").

+auction_awarded(AuctionID) : supplier_id(SID) <-
    .println("[SA1] Contract awarded: ", AuctionID);
    +active_contract(AuctionID).

+auction_closed(AuctionID) <-
    .println("[SA1] Auction closed: ", AuctionID).

// ========== PHASE 4: DELIVERY ==========

+!deliver_part(OrderID, PartType, DeliveryTime) : supplier_id(SID) <-
    .println("");
    .println("");
    .println("[SA1]   DELIVERY REQUEST                  ");
    .println("[SA1]");
    .println("[SA1]   Order: ", OrderID);
    .println("[SA1]   Part: ", PartType);
    .println("[SA1]   ETA: ", DeliveryTime, " hours");
    .println("[SA1]");
    
    +delivering(OrderID, PartType);
    
    // Simulate delivery (50ms per hour)
    DeliveryMs = DeliveryTime * 50;
    .println("[SA1] Shipping... (", DeliveryMs, "ms)");
    .wait(DeliveryMs);
    
    .println("[SA1]  DELIVERED: ", PartType, " for ", OrderID);
    
    // Notify assembly agent
    .send(aa1, tell, part_delivered(OrderID, PartType));
    
    -delivering(OrderID, PartType);
    +delivered(OrderID, PartType).

-!deliver_part(OrderID, PartType, DeliveryTime) : supplier_id(SID) <-
    .println("[SA1] ERROR: Delivery failed for ", PartType);
    .send(aa1, tell, delivery_failed(OrderID, PartType, SID)).
