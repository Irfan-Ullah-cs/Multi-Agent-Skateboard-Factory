// Supply Agent 2 - Cost Optimization Strategy
// Specializes in lowest prices with longer delivery times
{ include("$jacamoJar/templates/common-cartago.asl") }

// Agent Identity
supplier_id(sa2).

// Supply Capabilities - Low price, longer delivery
can_supply(board, 140, 30, 0.88).         // Price: $140, Delivery: 30h, Reputation: 88%
can_supply(trunk, 50, 20, 0.90).          // Price: $50, Delivery: 20h, Reputation: 90%
can_supply(wheels, 30, 24, 0.89).         // Price: $30, Delivery: 24h, Reputation: 89%
can_supply(rails, 60, 32, 0.87).          // Price: $60, Delivery: 32h, Reputation: 87%
can_supply(connectivity, 100, 36, 0.86).  // Price: $100, Delivery: 36h, Reputation: 86%

!start.

+!start : supplier_id(SID) <-
    .println("[", SID, "] Cost Optimization Supply Agent Started");
    .wait(2000);
    !monitor_auctions.

+!monitor_auctions <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .println("[SA2] Connected to auction environment");
    !listen_loop.

-!monitor_auctions <-
    .println("[SA2] Waiting for auction environment...");
    .wait(500);
    !monitor_auctions.

+!listen_loop <-
    .wait(500);
    !listen_loop.

// ========== AUCTION HANDLING ==========

+auction_open(AuctionID) : supplier_id(SID) <-
    .println("[SA2] New auction detected: ", AuctionID);
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
    .println("[SA2] Evaluating auction for part: ", PartType);
    .term2string(PartAtom, PartType);
    
    if (can_supply(PartAtom, Price, Delivery, Rep)) {
        .println("[SA2] Can supply ", PartAtom, " @ $", Price, ", delivery: ", Delivery, "h");
        lookupArtifact("auction_space", AucArtID);
        submitBid(AuctionID, SID, Price, Delivery)[artifact_id(AucArtID)];
        .println("[SA2] Bid submitted successfully")
    } else {
        if (can_supply(PartType, Price2, Delivery2, Rep2)) {
            .println("[SA2] Can supply ", PartType, " @ $", Price2, ", delivery: ", Delivery2, "h");
            lookupArtifact("auction_space", AucArtID);
            submitBid(AuctionID, SID, Price2, Delivery2)[artifact_id(AucArtID)];
            .println("[SA2] Bid submitted (fallback)")
        } else {
            .println("[SA2] Cannot supply ", PartType)
        }
    }.

+!check_and_bid(AuctionID, SID, PartType) <-
    .println("[SA1] Could not get auction details").

+auction_awarded(AuctionID) : supplier_id(SID) <-
    .println("[SA2] Contract awarded: ", AuctionID);
    +active_contract(AuctionID).

+auction_closed(AuctionID) <-
    .println("[SA2] Auction closed: ", AuctionID).

// ========== PHASE 4: DELIVERY ==========

+!deliver_part(OrderID, PartType, DeliveryTime) : supplier_id(SID) <-
    .println("");
    .println("[SA2]");
    .println("[SA2]   DELIVERY REQUEST                  ");
    .println("[SA2]");
    .println("[SA2]   Order: ", OrderID);
    .println("[SA2]   Part: ", PartType);
    .println("[SA2]   ETA: ", DeliveryTime, " hours");
    .println("[SA2]");
    
    +delivering(OrderID, PartType);
    
    // Simulate delivery (50ms per hour)
    DeliveryMs = DeliveryTime * 50;
    .println("[SA2] Shipping... (", DeliveryMs, "ms)");
    .wait(DeliveryMs);
    
    .println("[SA2]  DELIVERED: ", PartType, " for ", OrderID);
    
    // Notify assembly agent
    .send(aa1, tell, part_delivered(OrderID, PartType));
    
    -delivering(OrderID, PartType);
    +delivered(OrderID, PartType).

-!deliver_part(OrderID, PartType, DeliveryTime) : supplier_id(SID) <-
    .println("[SA2] ERROR: Delivery failed for ", PartType);
    .send(aa1, tell, delivery_failed(OrderID, PartType, SID)).
