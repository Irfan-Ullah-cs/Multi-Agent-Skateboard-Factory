package tools;

import cartago.Artifact;
import cartago.OPERATION;
import java.util.*;

public class WorkstationArtifact extends Artifact {
    
    private String workstationType;
    private int energyConsumption;
    private int executionTime;
    private boolean isAvailable;
    private String currentOrderID;
    
    @OPERATION
    public void init(String type, int energy, int time) {
        this.workstationType = type;
        this.energyConsumption = energy;
        this.executionTime = time;
        this.isAvailable = true;
        this.currentOrderID = null;
        
        defineObsProperty("workstation_type", type);
        defineObsProperty("energy_consumption", energy);
        defineObsProperty("execution_time", time);
        defineObsProperty("is_available", true);
        defineObsProperty("current_order", "none");
        
        System.out.println("[Workstation] " + type + " workstation initialized - Energy: " + energy + ", Time: " + time);
    }
    
    @OPERATION
    public void allocateToOrder(String orderID) {
        if (isAvailable) {
            isAvailable = false;
            currentOrderID = orderID;
            updateObsProperty("is_available", false);
            updateObsProperty("current_order", orderID);
            defineObsProperty("allocation_result", "success");
            System.out.println("[Workstation] " + workstationType + " allocated to order: " + orderID);
        } else {
            defineObsProperty("allocation_result", "busy");
            System.out.println("[Workstation] " + workstationType + " allocation failed - already busy with: " + currentOrderID);
        }
    }
    
    @OPERATION
    public void execute() {
        if (!isAvailable && currentOrderID != null) {
            System.out.println("[Workstation] " + workstationType + " executing for order: " + currentOrderID + " (time: " + executionTime + "ms, energy: " + energyConsumption + ")");
            
            // Simulate execution time
            try {
                Thread.sleep(executionTime * 100); // Scale down for demo
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            
            // Complete execution
            isAvailable = true;
            String completedOrder = currentOrderID;
            currentOrderID = null;
            
            updateObsProperty("is_available", true);
            updateObsProperty("current_order", "none");
            defineObsProperty("execution_complete", completedOrder);
            
            System.out.println("[Workstation] " + workstationType + " completed execution for order: " + completedOrder);
        }
    }
    
    @OPERATION
    public void getWorkstationInfo() {
        defineObsProperty("ws_type", workstationType);
        defineObsProperty("ws_energy", energyConsumption);
        defineObsProperty("ws_time", executionTime);
        defineObsProperty("ws_available", isAvailable);
    }
    
    @OPERATION
    public void releaseWorkstation() {
        isAvailable = true;
        currentOrderID = null;
        updateObsProperty("is_available", true);
        updateObsProperty("current_order", "none");
        System.out.println("[Workstation] " + workstationType + " released and available");
    }
}