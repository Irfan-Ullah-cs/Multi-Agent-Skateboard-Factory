// AuctionArtifact.java
package tools;

import cartago.Artifact;
import cartago.OPERATION;
import java.util.*;

public class AuctionArtifact extends Artifact {
    
    private Map<String, Map<String, Object>> auctions;
    private Map<String, List<Map<String, Object>>> bids;
    private List<String> openAuctions;
    private int auctionCounter;
    
    @OPERATION
    public void init() {
        auctions = new HashMap<>();
        bids = new HashMap<>();
        openAuctions = new ArrayList<>();
        auctionCounter = 0;
        System.out.println("[AuctionArtifact] Initialized");
    }
    
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
        defineObsProperty("last_auction_id", auctionID);
        System.out.println("[Auction] CFP opened: " + auctionID + " for " + partType);
    }
    
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
            System.out.println("[Auction] Bid received: " + supplierID + " -> " + bidPrice);
        }
    }
    
    @OPERATION
    public void closeAuction(String auctionID) {
        if (auctions.containsKey(auctionID)) {
            auctions.get(auctionID).put("status", "closed");
            defineObsProperty("auction_closed", auctionID);
            System.out.println("[Auction] CFP closed: " + auctionID);
        }
    }
    
    @OPERATION
    public void selectWinner(String auctionID, String winnerID, 
                             double winPrice, int winDelivery) {
        if (auctions.containsKey(auctionID)) {
            Map<String, Object> auction = auctions.get(auctionID);
            auction.put("winner", winnerID);
            auction.put("winPrice", winPrice);
            auction.put("winDelivery", winDelivery);
            auction.put("status", "awarded");
            
            defineObsProperty("auction_awarded", auctionID);
            System.out.println("[Auction] Winner selected for " + auctionID + ": " + winnerID + " @ $" + winPrice);
        }
    }
    
    @OPERATION
    public void getBidsForAuction(String auctionID) {
        if (bids.containsKey(auctionID)) {
            List<Map<String, Object>> auctionBids = bids.get(auctionID);
            defineObsProperty("bid_count", auctionBids.size());
            
            for (int i = 0; i < auctionBids.size(); i++) {
                Map<String, Object> bid = auctionBids.get(i);
                defineObsProperty("bid_" + i, bid.toString());
            }
            System.out.println("[Auction] Retrieved " + auctionBids.size() + " bids for " + auctionID);
        }
    }
    
    @OPERATION
    public void getAllBidsForAuction(String auctionID) {
        if (bids.containsKey(auctionID)) {
            List<Map<String, Object>> auctionBids = bids.get(auctionID);
            
            for (int i = 0; i < auctionBids.size(); i++) {
                Map<String, Object> bid = auctionBids.get(i);
                String bidStr = bid.get("supplierID") + ":" + 
                            bid.get("bidPrice") + ":" + 
                            bid.get("deliveryTime");
                defineObsProperty("bid_" + i, bidStr);
            }
            defineObsProperty("total_bids", auctionBids.size());
            System.out.println("[Auction] Bids returned for " + auctionID + ": " + auctionBids.size());
        }
    }
    
    @OPERATION
    public void getOpenAuctions() {
        String auctionList = String.join(",", openAuctions);
        defineObsProperty("all_open_auctions", auctionList);
        defineObsProperty("total_open_auctions", openAuctions.size());
        System.out.println("[Auction] Total open auctions: " + openAuctions.size() + " -> " + auctionList);
    }
    
    @OPERATION
    public void getBestBid(String auctionID, double maxPrice, int maxDelivery) {
        if (bids.containsKey(auctionID)) {
            List<Map<String, Object>> auctionBids = bids.get(auctionID);
            
            Map<String, Object> bestBid = null;
            double bestPrice = Double.MAX_VALUE;
            
            for (Map<String, Object> bid : auctionBids) {
                double bidPrice = (double) bid.get("bidPrice");
                int deliveryTime = (int) bid.get("deliveryTime");
                
                if (bidPrice <= maxPrice && deliveryTime <= maxDelivery) {
                    if (bidPrice < bestPrice) {
                        bestPrice = bidPrice;
                        bestBid = bid;
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
                System.out.println("[Auction] Best bid for " + auctionID + ": " + winner + " @ $" + price + ", delivery: " + delivery + "h");
            } else {
                defineObsProperty("best_bid_supplier", "none");
                System.out.println("[Auction] No valid bids for " + auctionID + " meeting constraints (budget: $" + maxPrice + ", deadline: " + maxDelivery + "h)");
            }
        }
    }
    
    @OPERATION
    public void getAuctionIDForPart(String partType) {
        String auctionID = null;
        
        for (String id : openAuctions) {
            if (id.contains("_" + partType + "_")) {
                auctionID = id;
            }
        }
        
        if (auctionID != null) {
            defineObsProperty("auction_id_for_part", auctionID);
            System.out.println("[Auction] Auction ID for " + partType + ": " + auctionID);
        } else {
            defineObsProperty("auction_id_for_part", "not_found");
            System.out.println("[Auction] No open auction found for part: " + partType);
        }
    }
    
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
}