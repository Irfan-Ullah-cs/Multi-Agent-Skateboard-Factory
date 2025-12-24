package tools;

import cartago.Artifact;
import cartago.OPERATION;
import cartago.OpFeedbackParam;

/**
 * WorkstationArtifact - Represents a physical workstation in the assembly plant
 * Each workstation can execute one assembly operation at a time
 */
public class WorkstationArtifact extends Artifact {
    
    private String type;
    private int energyConsumption;
    private int executionTime;
    private boolean isAvailable;
    private String currentOrder;
    
    /**
     * Initialize workstation with its properties
     * @param type - workstation type (trunk, wheels, rails, connectivity, quality)
     * @param energy - energy consumption per operation
     * @param time - execution time per operation
     */
    @OPERATION
    public void init(String type, int energy, int time) {
        this.type = type;
        this.energyConsumption = energy;
        this.executionTime = time;
        this.isAvailable = true;
        this.currentOrder = null;
        
        // Define observable properties
        defineObsProperty("ws_type", type);
        defineObsProperty("ws_energy", energy);
        defineObsProperty("ws_time", time);
        defineObsProperty("ws_available", true);
        defineObsProperty("ws_current_order", "none");
        defineObsProperty("ws_status", "idle");
        
        System.out.println("[Workstation] " + type + " workstation initialized - Energy: " + 
                          energy + ", Time: " + time);
    }
    
    /**
     * Execute an assembly operation
     * Locks the workstation during execution
     */
    @OPERATION
    public void execute() {
        if (!isAvailable) {
            System.out.println("[Workstation] ERROR: Workstation busy with order: " + currentOrder);
            return;
        }
        
        // Lock workstation
        isAvailable = false;
        updateObsProperty("ws_available", false);
        updateObsProperty("ws_status", "executing");
        
        System.out.println("[Workstation] " + type + " executing operation...");
        
        // Note: The actual wait/delay is handled by the agent
        // This just updates the state
        
        // Unlock workstation
        isAvailable = true;
        updateObsProperty("ws_available", true);
        updateObsProperty("ws_status", "idle");
        updateObsProperty("ws_current_order", "none");
        
        System.out.println("[Workstation] " + type + " operation complete");
    }
    
    /**
     * Execute operation for a specific order
     */
    @OPERATION
    public void executeForOrder(String orderID) {
        if (!isAvailable) {
            System.out.println("[Workstation] ERROR: Busy with order: " + currentOrder);
            failed("workstation_busy");
            return;
        }
        
        currentOrder = orderID;
        isAvailable = false;
        
        updateObsProperty("ws_available", false);
        updateObsProperty("ws_current_order", orderID);
        updateObsProperty("ws_status", "executing");
        
        System.out.println("[Workstation] " + type + " executing for order: " + orderID);
    }
    
    /**
     * Complete the current operation
     */
    @OPERATION
    public void completeOperation() {
        System.out.println("[Workstation] " + type + " completed order: " + currentOrder);
        
        currentOrder = null;
        isAvailable = true;
        
        updateObsProperty("ws_available", true);
        updateObsProperty("ws_current_order", "none");
        updateObsProperty("ws_status", "idle");
    }
    
    /**
     * Get workstation status
     */
    @OPERATION
    public void getStatus(OpFeedbackParam<String> status) {
        if (isAvailable) {
            status.set("available");
        } else {
            status.set("busy:" + currentOrder);
        }
    }
    
    /**
     * Check if workstation is available
     */
    @OPERATION
    public void isAvailable(OpFeedbackParam<Boolean> available) {
        available.set(isAvailable);
    }
    
    /**
     * Get energy consumption
     */
    @OPERATION  
    public void getEnergy(OpFeedbackParam<Integer> energy) {
        energy.set(energyConsumption);
    }
    
    /**
     * Get execution time
     */
    @OPERATION
    public void getTime(OpFeedbackParam<Integer> time) {
        time.set(executionTime);
    }
}
