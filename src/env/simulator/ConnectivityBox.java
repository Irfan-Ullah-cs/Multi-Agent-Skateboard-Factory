package simulator;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.BasicStroke;
import java.awt.GradientPaint;
import java.awt.Font;

public class ConnectivityBox implements SkateboardPart {

    public void draw(Dimension size, Graphics2D g){
        int centerX = size.width / 2 - 80;
        int centerY = size.height / 2 + 20;
        
        int boxX = centerX - 35;
        int boxY = centerY - 12;
        int boxWidth = 70;
        int boxHeight = 28;
        
        // Box shadow
        g.setColor(new Color(0, 0, 0, 40));
        g.fillRoundRect(boxX + 3, boxY + 3, boxWidth, boxHeight, 8, 8);
        
        // Main box body (dark electronics enclosure)
        GradientPaint boxGradient = new GradientPaint(
            boxX, boxY, new Color(50, 50, 55),
            boxX, boxY + boxHeight, new Color(30, 30, 35)
        );
        g.setPaint(boxGradient);
        g.fillRoundRect(boxX, boxY, boxWidth, boxHeight, 8, 8);
        
        // Top bezel/edge
        g.setColor(new Color(70, 70, 75));
        g.fillRoundRect(boxX, boxY, boxWidth, 4, 8, 8);
        
        // LED panel area
        g.setColor(new Color(25, 25, 30));
        g.fillRoundRect(boxX + 5, boxY + 8, 40, 14, 4, 4);
        
        // Power LED (green, glowing)
        drawLED(g, boxX + 10, boxY + 11, new Color(0, 255, 100), true);
        
        // Bluetooth LED (blue)
        drawLED(g, boxX + 22, boxY + 11, new Color(0, 150, 255), true);
        
        // WiFi LED (orange)
        drawLED(g, boxX + 34, boxY + 11, new Color(255, 180, 0), true);
        
        // Antenna
        g.setColor(new Color(80, 80, 80));
        g.setStroke(new BasicStroke(2));
        g.drawLine(boxX + 55, boxY - 8, boxX + 55, boxY + 2);
        g.setColor(new Color(60, 60, 60));
        g.fillOval(boxX + 52, boxY - 12, 6, 6);
        
        // Signal waves from antenna
        g.setColor(new Color(0, 200, 100, 100));
        g.setStroke(new BasicStroke(1));
        g.drawArc(boxX + 45, boxY - 18, 20, 20, 30, 120);
        g.drawArc(boxX + 40, boxY - 23, 30, 30, 30, 120);
        
        // USB port
        g.setColor(new Color(20, 20, 20));
        g.fillRect(boxX + 50, boxY + 10, 15, 8);
        g.setColor(new Color(100, 100, 100));
        g.fillRect(boxX + 52, boxY + 12, 11, 4);
        
        // Box outline
        g.setColor(new Color(60, 60, 65));
        g.setStroke(new BasicStroke(1));
        g.drawRoundRect(boxX, boxY, boxWidth, boxHeight, 8, 8);
        
        // Ventilation holes
        g.setColor(new Color(20, 20, 25));
        for (int i = 0; i < 3; i++) {
            g.fillOval(boxX + 5 + (i * 6), boxY + boxHeight - 6, 3, 3);
        }
        
        // Label
        g.setColor(new Color(39, 174, 96));
        g.setFont(new Font("Arial", Font.BOLD, 12));
        g.drawString("IoT MODULE", centerX + 45, centerY - 50);
        
        // Tech specs
        g.setFont(new Font("Arial", Font.PLAIN, 9));
        g.setColor(new Color(127, 140, 141));
        g.drawString("GPS + BT + WiFi", centerX + 45, centerY - 38);
    }
    
    private void drawLED(Graphics2D g, int x, int y, Color color, boolean on) {
        int size = 8;
        
        if (on) {
            // Glow effect
            g.setColor(new Color(color.getRed(), color.getGreen(), color.getBlue(), 60));
            g.fillOval(x - 3, y - 3, size + 6, size + 6);
            
            // LED body
            GradientPaint ledGradient = new GradientPaint(
                x, y, color.brighter(),
                x + size, y + size, color
            );
            g.setPaint(ledGradient);
            g.fillOval(x, y, size, size);
            
            // Highlight
            g.setColor(new Color(255, 255, 255, 150));
            g.fillOval(x + 1, y + 1, 3, 3);
        } else {
            g.setColor(new Color(color.getRed()/3, color.getGreen()/3, color.getBlue()/3));
            g.fillOval(x, y, size, size);
        }
    }
}
