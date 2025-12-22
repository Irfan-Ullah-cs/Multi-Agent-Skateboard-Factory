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

// Initializes the supply agent and begins the auction monitoring process
+!start : supplier_id(SID) <-
    .println("[", SID, "] Cost Optimization Supply Agent Started");
    .wait(2000);
    !monitor_auctions.

// Establishes connection to the auction environment and starts listening for auctions
+!monitor_auctions <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .println("[SA2] Connected to auction environment");
    !listen_to_auctions.

// Handles cases where auction environment is not yet available
+!monitor_auctions : true <-
    .println("[SA2] Waiting for auction environment to be created...");
    .wait(500);
    !monitor_auctions.

// Continuously listens for new auction notifications
+!listen_to_auctions <-
    .wait(500);
    !listen_to_auctions.

// Responds to new auction announcements by evaluating bidding opportunities
+auction_open(AuctionID) : supplier_id(SID) <-
    .println("[SA2] New auction detected: ", AuctionID);
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
    
    .println("[SA2] Evaluating auction for part: ", PartType);
    
    // Convert string to atom for belief matching
    .term2string(PartAtom, PartType);
    
    if (can_supply(PartAtom, Price, Delivery, Rep)) {
        .println("[SA2] Can supply ", PartAtom, " @ $", Price, ", delivery: ", Delivery, "h");
        lookupArtifact("auction_space", AucArtID);
        submitBid(AuctionID, SID, Price, Delivery)[artifact_id(AucArtID)];
        .println("[SA2] Bid submitted successfully");
    } else {
        // Fallback: try direct variable matching
        if (can_supply(PartType, Price2, Delivery2, Rep2)) {
            .println("[SA2] Can supply ", PartType, " @ $", Price2, ", delivery: ", Delivery2, "h");
            lookupArtifact("auction_space", AucArtID);
            submitBid(AuctionID, SID, Price2, Delivery2)[artifact_id(AucArtID)];
            .println("[SA2] Bid submitted successfully (fallback)");
        } else {
            .println("[SA2] Cannot supply ", PartType, " - skipping auction");
        }
    }.

// Handles error cases where auction details are not available
+!check_and_bid(AuctionID, SID) <-
    .println("[SA2] ERROR: Could not retrieve auction details for ", AuctionID).

// Processes auction award notifications and updates contract records
+auction_awarded(AuctionID) : supplier_id(SID) <-
    .println("[SA2] Contract awarded: ", AuctionID);
    +active_contract(AuctionID).

// Logs auction closure events for tracking purposes
+auction_closed(AuctionID) : true <-
    .println("[SA2] Auction closed: ", AuctionID).
