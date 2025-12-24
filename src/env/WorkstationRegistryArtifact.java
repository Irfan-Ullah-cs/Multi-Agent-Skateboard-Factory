package tools;

import cartago.Artifact;
import cartago.OPERATION;
import java.util.*;

/**
 * WorkstationRegistryArtifact - Central registry for all workstations
 * Tracks availability and handles allocation/release with mutual exclusion
 */
public class WorkstationRegistryArtifact extends Artifact {
    
    private Map<String, List<String>> workstationsByType;
    private Map<String, Map<String, Object>> workstationInfo;
    private Map<String, String> allocations; // workstationID -> orderID
    
    @OPERATION
    public void init() {
        workstationsByType = new HashMap<>();
        workstationInfo = new HashMap<>();
        allocations = new HashMap<>();
        
        // Initialize workstation type lists
        workstationsByType.put("trunk", new ArrayList<>());
        workstationsByType.put("wheels", new ArrayList<>());
        workstationsByType.put("rails", new ArrayList<>());
        workstationsByType.put("connectivity", new ArrayList<>());
        workstationsByType.put("quality", new ArrayList<>());
        
        // IMPORTANT: Define ALL observable properties upfront with initial values
        // This avoids the "invalid observable property" error
        defineObsProperty("registry_status", "initialized");
        defineObsProperty("available_workstations", "");
        defineObsProperty("available_count", 0);
        defineObsProperty("best_workstation", "none");
        defineObsProperty("best_ws_energy", 0);
        defineObsProperty("best_ws_time", 0);
        defineObsProperty("allocation_result", "none");
        
        System.out.println("[WorkstationRegistry] Registry initialized");
    }
    
    /**
     * Register a workstation with the registry
     */
    @OPERATION
    public void registerWorkstation(String workstationID, String type, int energy, int time) {
        // Ensure type list exists
        if (!workstationsByType.containsKey(type)) {
            workstationsByType.put(type, new ArrayList<>());
        }
        
        // Add workstation if not already registered
        if (!workstationsByType.get(type).contains(workstationID)) {
            workstationsByType.get(type).add(workstationID);
        }
        
        // Store workstation info
        Map<String, Object> info = new HashMap<>();
        info.put("type", type);
        info.put("energy", energy);
        info.put("time", time);
        info.put("available", true);
        workstationInfo.put(workstationID, info);
        
        System.out.println("[Registry] Registered: " + workstationID + " (" + type + 
                          ") - Energy: " + energy + ", Time: " + time);
    }
    
    /**
     * Find available workstations of a given type within energy constraints
     * Returns the best (lowest energy) workstation
     */
    @OPERATION
    public void findAvailableWorkstations(String type, int maxEnergy) {
        List<String> available = new ArrayList<>();
        List<String> typeWorkstations = workstationsByType.get(type);
        
        if (typeWorkstations != null) {
            for (String wsID : typeWorkstations) {
                Map<String, Object> info = workstationInfo.get(wsID);
                if (info != null) {
                    boolean isAvailable = (Boolean) info.get("available");
                    int energy = (Integer) info.get("energy");
                    
                    if (isAvailable && energy <= maxEnergy) {
                        available.add(wsID);
                    }
                }
            }
        }
        
        // Sort by energy consumption (lowest first)
        available.sort((a, b) -> {
            int energyA = (Integer) workstationInfo.get(a).get("energy");
            int energyB = (Integer) workstationInfo.get(b).get("energy");
            return Integer.compare(energyA, energyB);
        });
        
        // Update observable properties using updateObsProperty (NOT remove/define)
        String availableList = String.join(",", available);
        updateObsProperty("available_workstations", availableList);
        updateObsProperty("available_count", available.size());
        
        // Set best workstation (first in sorted list = lowest energy)
        if (!available.isEmpty()) {
            String bestWS = available.get(0);
            int bestEnergy = (Integer) workstationInfo.get(bestWS).get("energy");
            int bestTime = (Integer) workstationInfo.get(bestWS).get("time");
            
            updateObsProperty("best_workstation", bestWS);
            updateObsProperty("best_ws_energy", bestEnergy);
            updateObsProperty("best_ws_time", bestTime);
            
            System.out.println("[Registry] Found " + available.size() + " available " + type + 
                              " workstations. Best: " + bestWS + " (energy: " + bestEnergy + ")");
        } else {
            updateObsProperty("best_workstation", "none");
            updateObsProperty("best_ws_energy", 0);
            updateObsProperty("best_ws_time", 0);
            
            System.out.println("[Registry] No available " + type + " workstations found");
        }
    }
    
    /**
     * Allocate a workstation to an order (with mutual exclusion)
     */
    @OPERATION
    public void allocateWorkstation(String workstationID, String orderID) {
        if (workstationInfo.containsKey(workstationID)) {
            Map<String, Object> info = workstationInfo.get(workstationID);
            boolean isAvailable = (Boolean) info.get("available");
            
            if (isAvailable) {
                // Mark as allocated
                info.put("available", false);
                allocations.put(workstationID, orderID);
                
                updateObsProperty("allocation_result", "success");
                System.out.println("[Registry]  Allocated " + workstationID + " to order: " + orderID);
            } else {
                String currentOrder = allocations.get(workstationID);
                updateObsProperty("allocation_result", "busy");
                System.out.println("[Registry]  " + workstationID + " busy with order: " + currentOrder);
            }
        } else {
            updateObsProperty("allocation_result", "not_found");
            System.out.println("[Registry]  Workstation not found: " + workstationID);
        }
    }
    
    /**
     * Release a workstation back to the pool
     */
    @OPERATION
    public void releaseWorkstation(String workstationID) {
        if (workstationInfo.containsKey(workstationID)) {
            workstationInfo.get(workstationID).put("available", true);
            String orderID = allocations.remove(workstationID);
            System.out.println("[Registry] Released " + workstationID + " (was order: " + orderID + ")");
        }
    }
    
    /**
     * Get current registry status (for debugging)
     */
    @OPERATION
    public void getRegistryStatus() {
        int totalWorkstations = workstationInfo.size();
        int availableCount = 0;
        
        StringBuilder status = new StringBuilder();
        for (Map.Entry<String, Map<String, Object>> entry : workstationInfo.entrySet()) {
            boolean available = (Boolean) entry.getValue().get("available");
            if (available) availableCount++;
            status.append(entry.getKey()).append(":").append(available ? "free" : "busy").append(" ");
        }
        
        System.out.println("[Registry] Status: " + availableCount + "/" + totalWorkstations + 
                          " available - " + status.toString());
    }
}
