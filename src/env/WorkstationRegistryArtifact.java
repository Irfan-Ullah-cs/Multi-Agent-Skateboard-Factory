package tools;

import cartago.Artifact;
import cartago.OPERATION;
import java.util.*;

public class WorkstationRegistryArtifact extends Artifact {
    
    private Map<String, List<String>> workstationsByType;
    private Map<String, Map<String, Object>> workstationInfo;
    private Map<String, String> allocations; // workstationID -> orderID
    
    @OPERATION
    public void init() {
        workstationsByType = new HashMap<>();
        workstationInfo = new HashMap<>();
        allocations = new HashMap<>();
        
        // Initialize workstation types
        workstationsByType.put("trunk", new ArrayList<>());
        workstationsByType.put("wheels", new ArrayList<>());
        workstationsByType.put("rails", new ArrayList<>());
        workstationsByType.put("connectivity", new ArrayList<>());
        workstationsByType.put("quality", new ArrayList<>());
        
        // Define all observable properties upfront with initial values
        defineObsProperty("registry_status", "initialized");
        defineObsProperty("available_workstations", "");
        defineObsProperty("available_count", 0);
        defineObsProperty("best_workstation", "none");
        defineObsProperty("best_ws_energy", 0);
        defineObsProperty("best_ws_time", 0);
        defineObsProperty("allocation_result", "none");
        
        System.out.println("[WorkstationRegistry] Registry initialized");
    }
    
    @OPERATION
    public void registerWorkstation(String workstationID, String type, int energy, int time) {
        // Add to type list if not already present
        if (!workstationsByType.containsKey(type)) {
            workstationsByType.put(type, new ArrayList<>());
        }
        
        if (!workstationsByType.get(type).contains(workstationID)) {
            workstationsByType.get(type).add(workstationID);
        }
        
        Map<String, Object> info = new HashMap<>();
        info.put("type", type);
        info.put("energy", energy);
        info.put("time", time);
        info.put("available", true);
        workstationInfo.put(workstationID, info);
        
        System.out.println("[Registry] Registered: " + workstationID + " (" + type + 
                          ") - Energy: " + energy + ", Time: " + time);
    }
    
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
        
        // Sort by energy consumption (lowest first) for optimal selection
        available.sort((a, b) -> {
            int energyA = (Integer) workstationInfo.get(a).get("energy");
            int energyB = (Integer) workstationInfo.get(b).get("energy");
            return Integer.compare(energyA, energyB);
        });
        
        // Update observable properties (they already exist from init)
        String availableList = String.join(",", available);
        updateObsProperty("available_workstations", availableList);
        updateObsProperty("available_count", available.size());
        
        // Provide the BEST (lowest energy) workstation directly
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
    
    @OPERATION
    public void allocateWorkstation(String workstationID, String orderID) {
        if (workstationInfo.containsKey(workstationID)) {
            Map<String, Object> info = workstationInfo.get(workstationID);
            boolean isAvailable = (Boolean) info.get("available");
            
            if (isAvailable) {
                info.put("available", false);
                allocations.put(workstationID, orderID);
                updateObsProperty("allocation_result", "success");
                System.out.println("[Registry] ✓ Allocated " + workstationID + " to order: " + orderID);
            } else {
                String currentOrder = allocations.get(workstationID);
                updateObsProperty("allocation_result", "busy");
                System.out.println("[Registry] ✗ " + workstationID + " busy with order: " + currentOrder);
            }
        } else {
            updateObsProperty("allocation_result", "not_found");
            System.out.println("[Registry] ✗ Workstation not found: " + workstationID);
        }
    }
    
    @OPERATION
    public void releaseWorkstation(String workstationID) {
        if (workstationInfo.containsKey(workstationID)) {
            workstationInfo.get(workstationID).put("available", true);
            String orderID = allocations.remove(workstationID);
            System.out.println("[Registry] Released " + workstationID + " (was order: " + orderID + ")");
        }
    }
    
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