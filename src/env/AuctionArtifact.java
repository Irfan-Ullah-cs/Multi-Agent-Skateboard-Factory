// AuctionArtifact.java
// Implements FIPA Contract Net Protocol for skateboard part procurement
// Manages auction lifecycle from call-for-proposal to winner selection
// FIXED: Uses OpFeedbackParam to prevent race condition in concurrent auctions

package tools;

import cartago.Artifact;
import cartago.OPERATION;
import cartago.OpFeedbackParam;
import java.util.*;

public class AuctionArtifact extends Artifact {
    
    private Map<String, Map<String, Object>> auctions;
    private Map<String, List<Map<String, Object>>> bids;
    private List<String> openAuctions;
    private int auctionCounter;
    
    // Initializes the auction environment with empty data structures
    @OPERATION
    public void init() {
        auctions = new HashMap<>();
        bids = new HashMap<>();
        openAuctions = new ArrayList<>();
        auctionCounter = 0;
        System.out.println("[AuctionArtifact] Auction environment initialized");
    }
    
    // Creates a new auction for a specific part type with constraints
    @OPERATION
    public void callForProposal(String partType, int quantity, 
                                double maxPrice, int maxDelivery) {
        auctionCounter++;
        String auctionID = "AUC_" + partType + "_" + auctionCounter;
        
        Map<String, Object> auctionData = new HashMap<>();
        auctionData.put("auctionID", auctionID);
        auctionData.put("partType", partType);
        auctionData.put("quantity", quantity);
        auctionData.put("maxPrice", maxPrice);
        auctionData.put("maxDelivery", maxDelivery);
        auctionData.put("status", "open");
        auctionData.put("createdAt", System.currentTimeMillis());
        
        auctions.put(auctionID, auctionData);
        bids.put(auctionID, new ArrayList<>());
        openAuctions.add(auctionID);
        
        defineObsProperty("auction_open", auctionID);
        System.out.println("[Auction] CFP: " + auctionID + " for " + partType);
    }
    
    // Processes bid submissions from supply agents for open auctions
    @OPERATION
    public void submitBid(String auctionID, String supplierID, 
                         double bidPrice, int deliveryTime) {
        if (auctions.containsKey(auctionID) && "open".equals(auctions.get(auctionID).get("status"))) {
            Map<String, Object> bid = new HashMap<>();
            bid.put("auctionID", auctionID);
            bid.put("supplierID", supplierID);
            bid.put("bidPrice", bidPrice);
            bid.put("deliveryTime", deliveryTime);
            bid.put("timestamp", System.currentTimeMillis());
            
            bids.get(auctionID).add(bid);
            System.out.println("[Auction] Bid: " + supplierID + " -> $" + bidPrice + " for " + auctionID);
        }
    }
    
    // FIXED: Uses OpFeedbackParam to return part type directly to calling agent
    // This prevents race condition when multiple agents call simultaneously
    @OPERATION
    public void getAuctionDetails(String auctionID, OpFeedbackParam<String> partTypeOut) {
        if (auctions.containsKey(auctionID)) {
            Map<String, Object> auction = auctions.get(auctionID);
            String partType = (String) auction.get("partType");
            
            // Return value directly to calling agent - no shared property!
            partTypeOut.set(partType);
            
            System.out.println("[Auction] Details for " + auctionID + ": " + partType);
        } else {
            partTypeOut.set("unknown");
            System.out.println("[Auction] ERROR: Auction not found: " + auctionID);
        }
    }
    
    // Closes an auction and prevents further bid submissions
    @OPERATION
    public void closeAuction(String auctionID) {
        if (auctions.containsKey(auctionID)) {
            auctions.get(auctionID).put("status", "closed");
            defineObsProperty("auction_closed", auctionID);
            System.out.println("[Auction] Closed: " + auctionID);
        }
    }
    
    // Evaluates all bids and determines the winning bid based on constraints
    @OPERATION
    public void getBestBid(String auctionID, double maxPrice, int maxDelivery) {
        if (bids.containsKey(auctionID)) {
            List<Map<String, Object>> auctionBids = bids.get(auctionID);
            
            Map<String, Object> bestBid = null;
            double bestPrice = Double.MAX_VALUE;
            
            System.out.println("[Auction] Evaluating " + auctionBids.size() + " bids for " + auctionID);
            
            for (Map<String, Object> bid : auctionBids) {
                double bidPrice = (double) bid.get("bidPrice");
                int deliveryTime = (int) bid.get("deliveryTime");
                String supplierID = (String) bid.get("supplierID");
                
                System.out.println("[Auction] Checking: " + supplierID + " @ $" + bidPrice + ", " + deliveryTime + "h");
                
                // Check if bid meets constraints
                if (bidPrice <= maxPrice && deliveryTime <= maxDelivery) {
                    if (bidPrice < bestPrice) {
                        bestPrice = bidPrice;
                        bestBid = bid;
                        System.out.println("[Auction] New best: " + supplierID + " @ $" + bidPrice);
                    }
                }
            }
            
            if (bestBid != null) {
                String winner = (String) bestBid.get("supplierID");
                double price = (double) bestBid.get("bidPrice");
                int delivery = (int) bestBid.get("deliveryTime");
                
                defineObsProperty("best_bid_supplier", winner);
                defineObsProperty("best_bid_price", price);
                defineObsProperty("best_bid_delivery", delivery);
                System.out.println("[Auction] Winner for " + auctionID + ": " + winner + " @ $" + price);
            } else {
                defineObsProperty("best_bid_supplier", "none");
                System.out.println("[Auction] No valid bids for " + auctionID);
            }
        }
    }
    
    // Finds the first open auction for a specific part type
    @OPERATION
    public void getAuctionIDForPart(String partType) {
        String auctionID = null;
        
        for (String id : openAuctions) {
            if (auctions.containsKey(id)) {
                String auctionPartType = (String) auctions.get(id).get("partType");
                if (partType.equals(auctionPartType)) {
                    auctionID = id;
                    break;
                }
            }
        }
        
        if (auctionID != null) {
            defineObsProperty("auction_id_for_part", auctionID);
            System.out.println("[Auction] Found auction for " + partType + ": " + auctionID);
        } else {
            defineObsProperty("auction_id_for_part", "not_found");
            System.out.println("[Auction] No auction for: " + partType);
        }
    }
    
    // Finalizes auction by awarding contract to winning supplier
    @OPERATION
    public void processWinner(String auctionID, String winnerID, double winPrice, int winDelivery) {
        if (auctions.containsKey(auctionID)) {
            Map<String, Object> auction = auctions.get(auctionID);
            
            auction.put("status", "awarded");
            auction.put("winner", winnerID);
            auction.put("winPrice", winPrice);
            auction.put("winDelivery", winDelivery);
            
            openAuctions.remove(auctionID);
            
            defineObsProperty("auction_awarded", auctionID);
            System.out.println("[Auction] Awarded " + auctionID + " to " + winnerID + " @ $" + winPrice);
        }
    }
    
    // Retrieves all bids for a specific auction
    @OPERATION
    public void getAllBidsForAuction(String auctionID) {
        if (bids.containsKey(auctionID)) {
            List<Map<String, Object>> auctionBids = bids.get(auctionID);
            
            for (int i = 0; i < auctionBids.size(); i++) {
                Map<String, Object> bid = auctionBids.get(i);
                String bidInfo = bid.get("supplierID") + ":" + 
                               bid.get("bidPrice") + ":" + 
                               bid.get("deliveryTime");
                defineObsProperty("bid_" + i, bidInfo);
            }
            defineObsProperty("total_bids", auctionBids.size());
        }
    }
    
    // Provides summary of all currently open auctions
    @OPERATION
    public void getOpenAuctions() {
        String auctionList = String.join(",", openAuctions);
        defineObsProperty("all_open_auctions", auctionList);
        defineObsProperty("total_open_auctions", openAuctions.size());
    }
}