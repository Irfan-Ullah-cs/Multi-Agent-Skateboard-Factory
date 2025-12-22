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

// Initializes the supply agent and begins the auction monitoring process
+!start : supplier_id(SID) <-
    .println("[", SID, "] Fast Delivery Supply Agent Started");
    .wait(2000);
    !monitor_auctions.

// Establishes connection to the auction environment and starts listening for auctions
+!monitor_auctions <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .println("[SA1] Connected to auction environment");
    !listen_to_auctions.

// Handles cases where auction environment is not yet available
+!monitor_auctions : true <-
    .println("[SA1] Waiting for auction environment to be created...");
    .wait(500);
    !monitor_auctions.

// Continuously listens for new auction notifications
+!listen_to_auctions <-
    .wait(500);
    !listen_to_auctions.

// Responds to new auction announcements by evaluating bidding opportunities
+auction_open(AuctionID) : supplier_id(SID) <-
    .println("[SA1] New auction detected: ", AuctionID);
    !evaluate_bid(AuctionID, SID).

// Prepares for bid evaluation by accessing auction details
+!evaluate_bid(AuctionID, SID) : true <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .wait(100);
    !maybe_submit_bid(AuctionID, SID).

// Retrieves auction details and initiates bid checking process
+!maybe_submit_bid(AuctionID, SID) <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    
    getAuctionDetails(AuctionID)[artifact_id(AucArtID)];
    .wait(200);
    
    !check_and_bid(AuctionID, SID).

// Evaluates if agent can supply the requested part and submits bid if capable
+!check_and_bid(AuctionID, SID) :
    auction_part_type(PartType) <-
    
    .println("[SA1] Evaluating auction for part: ", PartType);
    
    // Convert string to atom for belief matching
    .term2string(PartAtom, PartType);
    
    if (can_supply(PartAtom, Price, Delivery, Rep)) {
        .println("[SA1] Can supply ", PartAtom, " @ $", Price, ", delivery: ", Delivery, "h");
        lookupArtifact("auction_space", AucArtID);
        submitBid(AuctionID, SID, Price, Delivery)[artifact_id(AucArtID)];
        .println("[SA1] Bid submitted successfully");
    } else {
        // Fallback: try direct variable matching
        if (can_supply(PartType, Price2, Delivery2, Rep2)) {
            .println("[SA1] Can supply ", PartType, " @ $", Price2, ", delivery: ", Delivery2, "h");
            lookupArtifact("auction_space", AucArtID);
            submitBid(AuctionID, SID, Price2, Delivery2)[artifact_id(AucArtID)];
            .println("[SA1] Bid submitted successfully (fallback)");
        } else {
            .println("[SA1] Cannot supply ", PartType, " - skipping auction");
        }
    }.

// Handles error cases where auction details are not available
+!check_and_bid(AuctionID, SID) <-
    .println("[SA1] ERROR: Could not retrieve auction details for ", AuctionID).

// Processes auction award notifications and updates contract records
+auction_awarded(AuctionID) : supplier_id(SID) <-
    .println("[SA1] Contract awarded: ", AuctionID);
    +active_contract(AuctionID).

// Logs auction closure events for tracking purposes
+auction_closed(AuctionID) : true <-
    .println("[SA1] Auction closed: ", AuctionID).
