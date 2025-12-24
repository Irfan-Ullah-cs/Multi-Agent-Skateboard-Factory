# Skateboard Assembly Multi-Agent System

A multi-agent based support system for a lean automated skateboard assembly plant, developed using the JaCaMo platform (Jason + CArtAgO + Moise).



## Description

This project implements a complete multi-agent system that simulates a skateboard assembly plant. Customers can order custom skateboards with various configurations, and the system automatically handles:

- **Order Processing**: Customer orders with specifications and preferences
- **Supplier Contracting**: FIPA Contract Net Protocol auctions to select best suppliers
- **Workstation Allocation**: Energy-optimized workstation selection with mutual exclusion
- **Assembly Execution**: Sequential assembly with real-time GUI visualization
- **Quality Control**: Final inspection before delivery

### Skateboard Configurations

| Component | Quantity | Optional |
|-----------|----------|----------|
| Board (Deck) | 1 | No |
| Trunks (Trucks) | 2 | No |
| Wheels | 4 | No |
| Rails | 2 | Yes |
| Connectivity Box (IoT) | 1 | Yes |

## Features

- **Dynamic Order Submission**: Add any number of orders without code changes
- **Concurrent Processing**: Multiple orders processed simultaneously
- **Resource Contention Handling**: Workstations shared with mutual exclusion
- **Cost Optimization**: Suppliers selected based on price and delivery time
- **Energy-Aware Allocation**: Workstations selected by lowest energy consumption
- **Real-Time Visualization**: GUI shows assembly progress for each order
- **Constraint Satisfaction**: Orders respect customer budget and delivery deadlines

## Architecture

### Agents

| Agent | Count | Responsibilities |
|-------|-------|------------------|
| Customer Agent (ca) | 1 | Submit orders, track completion |
| Assembly Agent (aa) | 1 | Coordinate entire assembly process |
| Supply Agent (sa) | 3 | Bid on parts, deliver components |
| Workstation Agent (wa) | 10 | Execute assembly operations |

### Supply Agent Strategies

| Agent | Strategy | Characteristics |
|-------|----------|-----------------|
| SA1 | Fast Delivery | Higher prices, shorter delivery times |
| SA2 | Cost Optimization | Lowest prices, longer delivery times |
| SA3 | Quality/Reputation | Mid-range prices, highest reputation |

### CArtAgO Artifacts

| Artifact | Purpose |
|----------|---------|
| OrderTupleSpace | Customer-Assembly communication |
| AuctionArtifact | FIPA Contract Net Protocol implementation |
| WorkstationRegistry | Track and allocate workstations |
| WorkstationArtifact | Individual workstation operations |
| Skateboard (GUI) | Visual assembly progress |

## Project Structure

```
MASB/
├── src/
│   ├── agt/
│   │   ├── assembly_agent.asl      # Main coordinator agent
│   │   ├── customer_agent.asl      # Order submission agent
│   │   ├── workstation_agent.asl   # Workstation controller
│   │   ├── sa1.asl                 # Fast delivery supplier
│   │   ├── sa2.asl                 # Cost optimization supplier
│   │   └── sa3.asl                 # Quality/reputation supplier
│   ├── env/
│   │   ├── tools/
│   │   │   ├── OrderTupleSpace.java
│   │   │   ├── AuctionArtifact.java
│   │   │   ├── WorkstationRegistryArtifact.java
│   │   │   └── WorkstationArtifact.java
│   │   └── simulator/
│   │       ├── Skateboard.java     # Main GUI artifact
│   │       ├── SkateboardPart.java # Part interface
│   │       ├── Board.java
│   │       ├── Trunks.java
│   │       ├── Wheels.java
│   │       ├── Rails.java
│   │       ├── ConnectivityBox.java
│   │       └── QualityCheck.java
│   └── org/
│       └── org.xml                 # Moise organization (optional)
├── mASB.jcm         # JaCaMo project file
├── build.gradle                    # Gradle build configuration
└── README.md
```

## Installation

### Prerequisites

- Java JDK 17 or higher
- Gradle 7.0 or higher
- JaCaMo 1.2 or higher

### Setup

1. Clone the repository:
```bash
git clone https://github.com/Irfan-Ullah-cs/Multi-Agent-Skateboard-Factory.git
cd MASB
```

2. Build the project:
```bash
./gradlew build
```

3. Run the system:
```bash
./gradlew run
```

## Usage

### Configuring Orders

Edit `src/agt/customer_agent.asl` to add or modify orders:

```prolog
// Order specification: board_type, trunks, wheels, rails(yes/no), connectivity(yes/no)
order_spec(ord001, "specification(maple_deck, 2, 4, no, no)").    // Basic
order_spec(ord002, "specification(bamboo_deck, 2, 4, yes, no)").  // With rails
order_spec(ord003, "specification(maple_deck, 2, 4, yes, yes)").  // Full

// Order preferences: max_cost, max_delivery_hours, max_energy
order_prefs(ord001, "preferences(500, 48, 100)").
order_prefs(ord002, "preferences(700, 72, 150)").
order_prefs(ord003, "preferences(1000, 96, 200)").
```

Orders are automatically discovered and submitted - no need to modify plan code!

### Workstation Configuration

Workstations are configured in `skateboard_assembly.jcm`:

```
agent wa1_trunk: workstation_agent.asl {
    beliefs: workstation_id(wa1_trunk)
             workstation_type(trunk)
             energy_consumption(15)
             execution_time(20)
}
```

## System Flow


![Sequence Diagram](/visualization/sequence.png)


## GUI Visualization

Each order gets its own visualization window showing:

- **Header**: Order ID badge
- **Progress Bar**: 6-stage completion indicator
- **Assembly View**: Real-time skateboard construction
- **Parts Checklist**: Component completion tracking
- **Status Bar**: Cost, delivery time, completion status

### Assembly Stages

1. Board (Deck) - Base component
2. Trunks (Trucks) - Mounting hardware
3. Wheels - 4 wheels with bearings
4. Rails - Optional side protection
5. IoT Module - Optional connectivity box
6. Quality Check - Final inspection stamp

   ![Skateboard Assembly Visualization](/visualization/visualization.gif)

## Sample Output

```
Please See outputlog.txt file for output
```

## Technologies Used

- **Jason**: BDI agent programming language (AgentSpeak)
- **CArtAgO**: Environment/artifact framework
- **Moise**: Organizational modeling (optional)
- **Java Swing**: GUI visualization
- **Gradle**: Build automation

## Authors

- Irfan Ullah, Sajid - MAC 2025
- University Jean Monnet and Ecole de Mines de Saint-Etienne
- Course: Cyber Physical and Social Systems: AI & IoT

## Acknowledgments

- JaCaMo development team for the multi-agent platform
- Course instructors for project guidance
- FIPA for Contract Net Protocol specification

## License

This project is developed for educational purposes as part of the MAC 2025 course.

## Project Status

**Completed** - All core phases implemented:

- [x] Phase 1: Order Intake
- [x] Phase 2: Supplier Contracting (FIPA Contract Net)
- [x] Phase 3: Workstation Allocation
- [x] Phase 4: Assembly Execution with GUI
- [x] Phase 5: Moise Organization (Optional)
