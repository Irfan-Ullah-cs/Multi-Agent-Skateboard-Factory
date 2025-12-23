package simulator;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.BasicStroke;
import java.awt.GradientPaint;
import java.awt.geom.RoundRectangle2D;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

import javax.swing.JFrame;
import javax.swing.JPanel;

import cartago.OPERATION;
import cartago.tools.GUIArtifact;

public class Skateboard extends GUIArtifact {

    SkateboardView view;
    private String orderId = "";
    private int totalCost = 0;
    private int deliveryTime = 0;

    @Override
    public void init(){
        view = new SkateboardView();
        view.setVisible(true);
    }

    // Actions that simulate the assembly progress

    @OPERATION void setOrderInfo(String orderId, int cost, int delivery){
        this.orderId = orderId;
        this.totalCost = cost;
        this.deliveryTime = delivery;
        view.setOrderInfo(orderId, cost, delivery);
        signal("orderInfoSet");
    }

    @OPERATION void addBoard(){
        view.addPart(new Board());
        view.markPartComplete("board");
        signal("boardAdded");
    }

    @OPERATION void assembleTrunks(){
        await_time(500);
        view.addPart(new Trunks());
        view.markPartComplete("trunks");
        signal("trunksAssembled");
    }

    @OPERATION void mountWheels(){
        await_time(500);
        view.addPart(new Wheels());
        view.markPartComplete("wheels");
        signal("wheelsMounted");
    }

    @OPERATION void attachRails(){
        await_time(300);
        view.addPart(new Rails());
        view.markPartComplete("rails");
        signal("railsAttached");
    }

    @OPERATION void installConnectivity(){
        await_time(400);
        view.addPart(new ConnectivityBox());
        view.markPartComplete("iot");
        signal("connectivityInstalled");
    }

    @OPERATION void performQualityCheck(){
        await_time(300);
        view.addPart(new QualityCheck());
        view.markPartComplete("quality");
        view.setComplete(true);
        signal("qualityCheckPassed");
    }


    class SkateboardView extends JFrame {

        SkateboardPanel skateboardPanel;
        ArrayList<SkateboardPart> partsToDraw;
        Set<String> completedParts;
        String orderInfo = "";
        String orderId = "";
        int cost = 0;
        int delivery = 0;
        boolean isComplete = false;

        public SkateboardView(){
            setTitle("Skateboard Assembly Plant");
            setSize(900, 700);
            setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
            setLocationRelativeTo(null);

            partsToDraw = new ArrayList<SkateboardPart>();
            completedParts = new HashSet<String>();
            skateboardPanel = new SkateboardPanel(this);
            setContentPane(skateboardPanel);
        }

        public synchronized void addPart(SkateboardPart part){
            partsToDraw.add(part);
            repaint();
        }

        public synchronized void markPartComplete(String partName){
            completedParts.add(partName.toLowerCase());
            repaint();
        }

        public synchronized boolean isPartComplete(String partName){
            return completedParts.contains(partName.toLowerCase());
        }

        public synchronized ArrayList<SkateboardPart> getParts(){
            return (ArrayList<SkateboardPart>)partsToDraw.clone();
        }

        public void setOrderInfo(String orderId, int cost, int delivery){
            this.orderId = orderId;
            this.cost = cost;
            this.delivery = delivery;
            this.orderInfo = String.format("Order: %s | Cost: $%d | Delivery: %dh", orderId, cost, delivery);
            setTitle("Skateboard Assembly - " + orderId);
            repaint();
        }

        public void setComplete(boolean complete){
            isComplete = complete;
            repaint();
        }

        public boolean isComplete(){
            return isComplete;
        }

        public int getCompletedCount(){
            return completedParts.size();
        }

        public String getOrderId(){
            return orderId;
        }

        public int getCost(){
            return cost;
        }

        public int getDelivery(){
            return delivery;
        }
    }

    class SkateboardPanel extends JPanel {

        SkateboardView view;

        public SkateboardPanel(SkateboardView view){
            this.view = view;
        }

        public void paintComponent(Graphics g) {
            super.paintComponent(g);
            Graphics2D g2d = (Graphics2D) g;
            
            // Enable anti-aliasing
            g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2d.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);

            Dimension size = getSize();
            
            // Gradient background
            GradientPaint bgGradient = new GradientPaint(0, 0, new Color(240, 244, 248), 
                                                          0, size.height, new Color(220, 228, 236));
            g2d.setPaint(bgGradient);
            g2d.fillRect(0, 0, size.width, size.height);
            
            // Header bar
            g2d.setColor(new Color(44, 62, 80));
            g2d.fillRect(0, 0, size.width, 60);
            
            // Title
            g2d.setColor(Color.WHITE);
            g2d.setFont(new Font("Arial", Font.BOLD, 24));
            g2d.drawString("Skateboard Assembly Plant", 20, 40);
            
            // Order ID badge
            if (!view.getOrderId().isEmpty()) {
                g2d.setColor(new Color(52, 152, 219));
                g2d.fillRoundRect(size.width - 150, 15, 130, 30, 15, 15);
                g2d.setColor(Color.WHITE);
                g2d.setFont(new Font("Arial", Font.BOLD, 14));
                g2d.drawString(view.getOrderId(), size.width - 120, 36);
            }

            // Progress bar section
            drawProgressBar(g2d, size);

            // Assembly area with shadow
            g2d.setColor(new Color(0, 0, 0, 30));
            g2d.fillRoundRect(52, 152, size.width - 100, size.height - 280, 20, 20);
            g2d.setColor(new Color(255, 255, 255, 200));
            g2d.fillRoundRect(50, 150, size.width - 100, size.height - 280, 20, 20);
            g2d.setColor(new Color(189, 195, 199));
            g2d.setStroke(new BasicStroke(2));
            g2d.drawRoundRect(50, 150, size.width - 100, size.height - 280, 20, 20);

            // Draw all assembled parts
            for (SkateboardPart part: view.getParts()){
                part.draw(size, g2d);
            }

            // Parts checklist
            drawPartsChecklist(g2d, size);

            // Bottom status bar
            drawStatusBar(g2d, size);
        }

        private void drawProgressBar(Graphics2D g2d, Dimension size) {
            int barX = 50;
            int barY = 80;
            int barWidth = size.width - 100;
            int barHeight = 25;
            
            // Background
            g2d.setColor(new Color(189, 195, 199));
            g2d.fillRoundRect(barX, barY, barWidth, barHeight, 12, 12);
            
            // Progress fill - when complete, fill entire bar
            int fillWidth;
            if (view.isComplete()) {
                fillWidth = barWidth;
                g2d.setColor(new Color(39, 174, 96));
            } else {
                // Calculate based on completed parts (max 6)
                int completed = view.getCompletedCount();
                fillWidth = (int)((double)completed / 6 * barWidth);
                GradientPaint progressGradient = new GradientPaint(barX, barY, new Color(52, 152, 219),
                                                                    barX + fillWidth, barY, new Color(41, 128, 185));
                g2d.setPaint(progressGradient);
            }
            g2d.fillRoundRect(barX, barY, fillWidth, barHeight, 12, 12);
            
            // Progress text
            g2d.setColor(Color.WHITE);
            g2d.setFont(new Font("Arial", Font.BOLD, 12));
            String progressText;
            if (view.isComplete()) {
                progressText = "COMPLETE!";
            } else {
                progressText = view.getCompletedCount() + " / 6 steps";
            }
            int textWidth = g2d.getFontMetrics().stringWidth(progressText);
            g2d.drawString(progressText, barX + (barWidth - textWidth) / 2, barY + 17);
            
            // Stage labels
            g2d.setFont(new Font("Arial", Font.PLAIN, 10));
            g2d.setColor(new Color(127, 140, 141));
            String[] stages = {"Board", "Trunks", "Wheels", "Rails", "IoT", "QC"};
            int stageWidth = barWidth / stages.length;
            for (int i = 0; i < stages.length; i++) {
                int labelX = barX + (stageWidth * i) + (stageWidth / 2) - 15;
                g2d.drawString(stages[i], labelX, barY + 40);
            }
        }

        private void drawPartsChecklist(Graphics2D g2d, Dimension size) {
            int checkX = size.width - 180;
            int checkY = 170;
            
            g2d.setColor(new Color(44, 62, 80, 200));
            g2d.fillRoundRect(checkX, checkY, 160, 180, 10, 10);
            
            g2d.setColor(Color.WHITE);
            g2d.setFont(new Font("Arial", Font.BOLD, 12));
            g2d.drawString("Parts Checklist", checkX + 30, checkY + 20);
            
            g2d.setFont(new Font("Arial", Font.PLAIN, 11));
            
            // Parts with their keys for checking completion
            String[][] parts = {
                {"board", "Board"},
                {"trunks", "Trunks (2x)"},
                {"wheels", "Wheels (4x)"},
                {"rails", "Rails (2x)"},
                {"iot", "IoT Box"},
                {"quality", "Quality Check"}
            };
            
            for (int i = 0; i < parts.length; i++) {
                int itemY = checkY + 45 + (i * 22);
                String partKey = parts[i][0];
                String partLabel = parts[i][1];
                boolean isChecked = view.isPartComplete(partKey);
                
                // Checkbox
                if (isChecked) {
                    g2d.setColor(new Color(39, 174, 96));
                    g2d.fillRoundRect(checkX + 10, itemY - 12, 16, 16, 4, 4);
                    g2d.setColor(Color.WHITE);
                    g2d.setStroke(new BasicStroke(2));
                    g2d.drawLine(checkX + 13, itemY - 4, checkX + 17, itemY);
                    g2d.drawLine(checkX + 17, itemY, checkX + 23, itemY - 8);
                } else {
                    g2d.setColor(new Color(127, 140, 141));
                    g2d.setStroke(new BasicStroke(1));
                    g2d.drawRoundRect(checkX + 10, itemY - 12, 16, 16, 4, 4);
                }
                
                // Part name
                if (isChecked) {
                    g2d.setColor(new Color(39, 174, 96));
                } else {
                    g2d.setColor(new Color(189, 195, 199));
                }
                g2d.drawString(partLabel, checkX + 35, itemY);
            }
        }

        private void drawStatusBar(Graphics2D g2d, Dimension size) {
            int barY = size.height - 60;
            
            // Status bar background
            if (view.isComplete()) {
                g2d.setColor(new Color(39, 174, 96));
            } else {
                g2d.setColor(new Color(44, 62, 80));
            }
            g2d.fillRect(0, barY, size.width, 60);
            
            g2d.setColor(Color.WHITE);
            g2d.setFont(new Font("Arial", Font.BOLD, 14));
            
            if (view.isComplete()) {
                g2d.drawString("ORDER COMPLETE - Ready for Delivery!", 20, barY + 25);
                
                // Show cost and delivery
                g2d.setFont(new Font("Arial", Font.PLAIN, 12));
                if (view.getCost() > 0) {
                    g2d.drawString("Total Cost: $" + view.getCost(), 20, barY + 45);
                    g2d.drawString("Delivery Time: " + view.getDelivery() + " hours", 200, barY + 45);
                }
            } else {
                g2d.drawString("Assembly in progress...", 20, barY + 35);
            }
            
            // Parts counter
            g2d.setFont(new Font("Arial", Font.PLAIN, 12));
            g2d.drawString("Parts: " + view.getCompletedCount(), size.width - 100, barY + 35);
        }
    }
}