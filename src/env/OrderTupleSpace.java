package tools;

import cartago.Artifact;
import cartago.OPERATION;
import java.util.*;

public class OrderTupleSpace extends Artifact {
    
    private Map<String, String[]> orders;
    private List<String> pendingList;
    
    @OPERATION
    public void init() {
        orders = new HashMap<>();
        pendingList = new ArrayList<>();
        defineObsProperty("pending_orders", 0);
        defineObsProperty("confirmed_orders", 0);
        System.out.println("[OrderTupleSpace] Initialized");
    }
    
    @OPERATION
    public void writeOrder(String orderID, String customerID, 
                          String spec, String prefs) {
        orders.put(orderID, new String[]{orderID, customerID, spec, prefs, "pending"});
        pendingList.add(orderID);
        updateObsProperty("pending_orders", countPending());
        System.out.println("[OrderTupleSpace] Order written: " + orderID);
    }
    
    @OPERATION
    public void getNextPendingOrder() {
        if (!pendingList.isEmpty()) {
            String nextOrder = pendingList.get(0);
            defineObsProperty("next_pending_order", nextOrder);
        }
    }
    
    @OPERATION
    public void readOrder(String orderID) {
        if (orders.containsKey(orderID)) {
            String[] data = orders.get(orderID);
            
            defineObsProperty("order_id", data[0]);
            defineObsProperty("customer_id", data[1]);
            defineObsProperty("order_status", data[4]);
            
            // Parse specification string
            parseSpecification(data[2]);
            
            // Parse preferences string
            parsePreferences(data[3]);
        }
    }
    
    private void parseSpecification(String spec) {
        // Example: "specification(maple_deck, 2, 4, no, no)"
        try {
            String content = spec.substring(spec.indexOf("(") + 1, spec.lastIndexOf(")"));
            String[] parts = content.split(",");
            
            if (parts.length >= 5) {
                String boardType = parts[0].trim();
                int trunkCount = Integer.parseInt(parts[1].trim());
                int wheelCount = Integer.parseInt(parts[2].trim());
                String hasRails = parts[3].trim();
                String hasConnectivity = parts[4].trim();
                
                defineObsProperty("board_type", boardType);
                defineObsProperty("trunk_count", trunkCount);
                defineObsProperty("wheel_count", wheelCount);
                defineObsProperty("has_rails", hasRails);
                defineObsProperty("has_connectivity", hasConnectivity);
                
                System.out.println("[OrderTupleSpace] Parsed spec: board=" + boardType + 
                    ", trunks=" + trunkCount + ", wheels=" + wheelCount + 
                    ", rails=" + hasRails + ", conn=" + hasConnectivity);
            }
        } catch (Exception e) {
            System.out.println("[OrderTupleSpace] Error parsing spec: " + e.getMessage());
        }
    }
    
    @OPERATION
    public void getOrderData(String orderID) {
        if (orders.containsKey(orderID)) {
            String[] data = orders.get(orderID);
            
            // Parse and expose as observable properties with prefixed names
            parseSpecificationAlt(data[2]);
            parsePreferencesAlt(data[3]);
        }
    }

    private void parseSpecificationAlt(String spec) {
        try {
            String content = spec.substring(spec.indexOf("(") + 1, spec.lastIndexOf(")"));
            String[] parts = content.split(",");
            
            if (parts.length >= 5) {
                defineObsProperty("order_board_type", parts[0].trim());
                defineObsProperty("order_trunk_count", Integer.parseInt(parts[1].trim()));
                defineObsProperty("order_wheel_count", Integer.parseInt(parts[2].trim()));
                defineObsProperty("order_has_rails", parts[3].trim());
                defineObsProperty("order_has_connectivity", parts[4].trim());
            }
        } catch (Exception e) {
            System.out.println("[OrderTupleSpace] Error in getOrderData: " + e.getMessage());
        }
    }

    private void parsePreferencesAlt(String prefs) {
        try {
            String content = prefs.substring(prefs.indexOf("(") + 1, prefs.lastIndexOf(")"));
            String[] parts = content.split(",");
            
            if (parts.length >= 3) {
                defineObsProperty("order_max_cost", Integer.parseInt(parts[0].trim()));
                defineObsProperty("order_max_delivery", Integer.parseInt(parts[1].trim()));
                defineObsProperty("order_max_energy", Integer.parseInt(parts[2].trim()));
            }
        } catch (Exception e) {
            System.out.println("[OrderTupleSpace] Error in getOrderData: " + e.getMessage());
        }
    }
    
    private void parsePreferences(String prefs) {
        // Example: "preferences(500, 48, 100)"
        try {
            String content = prefs.substring(prefs.indexOf("(") + 1, prefs.lastIndexOf(")"));
            String[] parts = content.split(",");
            
            if (parts.length >= 3) {
                int maxCost = Integer.parseInt(parts[0].trim());
                int maxDelivery = Integer.parseInt(parts[1].trim());
                int maxEnergy = Integer.parseInt(parts[2].trim());
                
                defineObsProperty("max_cost", maxCost);
                defineObsProperty("max_delivery", maxDelivery);
                defineObsProperty("max_energy", maxEnergy);
                
                System.out.println("[OrderTupleSpace] Parsed prefs: cost=" + maxCost + 
                    ", delivery=" + maxDelivery + "h, energy=" + maxEnergy);
            }
        } catch (Exception e) {
            System.out.println("[OrderTupleSpace] Error parsing prefs: " + e.getMessage());
        }
    }
    
    @OPERATION
    public void updateOrderStatus(String orderID, String newStatus) {
        if (orders.containsKey(orderID)) {
            orders.get(orderID)[4] = newStatus;
            pendingList.remove(orderID);
            updateObsProperty("pending_orders", countPending());
            updateObsProperty("confirmed_orders", countConfirmed());
            System.out.println("[OrderTupleSpace] Order " + orderID + " -> " + newStatus);
        }
    }
    
    private int countPending() {
        return (int) orders.values().stream()
            .filter(o -> "pending".equals(o[4])).count();
    }
    
    private int countConfirmed() {
        return (int) orders.values().stream()
            .filter(o -> "confirmed".equals(o[4])).count();
    }
}
