{ include("$jacamoJar/templates/common-cartago.asl") }

supplier_id(sa2).

// sa2: Low price, longer delivery
can_supply(board, 140, 30, 0.88).      // $140, 30hr delivery, 88% reputation
can_supply(trunk, 50, 20, 0.90).       // $50, 20hr, 90% reputation
can_supply(wheels, 30, 24, 0.89).      // $30, 24hr, 89% reputation

!start.

+!start : supplier_id(SID) <-
    .println("[", SID, "] Supply agent started");
    .wait(2000);
    !monitor_auctions.

+!monitor_auctions <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .println("[SA] ", SID, " Focused on auction_space");
    !listen_to_auctions.

+!monitor_auctions : true <-
    .println("[SA] Waiting for auction_space to be created...");
    .wait(500);
    !monitor_auctions.

+!listen_to_auctions <-
    .wait(500);
    !listen_to_auctions.

+auction_open(AuctionID) : supplier_id(SID) <-
    .println("[SA] Auction opened: ", AuctionID);
    !evaluate_bid(AuctionID, SID).

+!evaluate_bid(AuctionID, SID) : true <-
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    .wait(100);
    !maybe_submit_bid(AuctionID, SID).

+!maybe_submit_bid(AuctionID, SID) : 
    can_supply(PartType, UnitPrice, DeliveryTime, Reputation) <-
    
    lookupArtifact("auction_space", AucArtID);
    focus(AucArtID);
    
    .println("[SA] Submitting bid for: ", PartType, " from ", SID);
    submitBid(AuctionID, SID, UnitPrice, DeliveryTime)[artifact_id(AucArtID)];
    .println("[SA] Bid submitted from ", SID).

+auction_awarded(AuctionID) : supplier_id(SID) <-
    .println("[SA] ", SID, " Contract won: ", AuctionID);
    +active_contracts(AuctionID).

+auction_closed(AuctionID) : true <-
    .println("[SA] Auction closed: ", AuctionID).