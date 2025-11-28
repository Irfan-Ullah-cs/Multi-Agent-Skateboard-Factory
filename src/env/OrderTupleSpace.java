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
            defineObsProperty("order_spec", data[2]);
            defineObsProperty("order_prefs", data[3]);
            defineObsProperty("order_status", data[4]);
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