{ include("$jacamoJar/templates/common-cartago.asl") }

supplier_id(sa3).

// sa3: Mid-price, mid-delivery, best reputation
can_supply(board, 155, 22, 0.97).      // $155, 22hr delivery, 97% reputation
can_supply(trunk, 52, 16, 0.96).       // $52, 16hr, 96% reputation
can_supply(wheels, 32, 14, 0.98).      // $32, 14hr, 98% reputation

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