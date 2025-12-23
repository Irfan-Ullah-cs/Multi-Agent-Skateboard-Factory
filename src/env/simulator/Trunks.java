package simulator;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.BasicStroke;
import java.awt.GradientPaint;
import java.awt.Font;

public class Trunks implements SkateboardPart {

    public void draw(Dimension size, Graphics2D g){
        int centerX = size.width / 2 - 80;
        int centerY = size.height / 2 + 20;
        
        // Draw front truck
        drawTruck(g, centerX - 140, centerY + 25);
        
        // Draw rear truck
        drawTruck(g, centerX + 60, centerY + 25);
        
        // Label
        g.setColor(new Color(44, 62, 80));
        g.setFont(new Font("Arial", Font.BOLD, 12));
        g.drawString("TRUCKS (2x)", centerX + 55, centerY + 95);
    }
    
    private void drawTruck(Graphics2D g, int x, int y) {
        // Baseplate shadow
        g.setColor(new Color(0, 0, 0, 30));
        g.fillRect(x + 2, y + 2, 80, 12);
        
        // Baseplate (top plate that mounts to deck)
        GradientPaint baseplateGradient = new GradientPaint(
            x, y, new Color(180, 180, 180),
            x, y + 12, new Color(140, 140, 140)
        );
        g.setPaint(baseplateGradient);
        g.fillRect(x, y, 80, 12);
        
        // Baseplate bolts
        g.setColor(new Color(60, 60, 60));
        g.fillOval(x + 8, y + 3, 6, 6);
        g.fillOval(x + 66, y + 3, 6, 6);
        g.fillOval(x + 8, y + 3, 6, 6);
        
        // Kingpin area
        g.setColor(new Color(100, 100, 100));
        g.fillRect(x + 35, y + 10, 10, 8);
        
        // Hanger shadow
        g.setColor(new Color(0, 0, 0, 30));
        g.fillRoundRect(x - 8, y + 20, 98, 12, 5, 5);
        
        // Hanger (main truck body with axle)
        GradientPaint hangerGradient = new GradientPaint(
            x - 10, y + 18, new Color(200, 200, 200),
            x - 10, y + 30, new Color(160, 160, 160)
        );
        g.setPaint(hangerGradient);
        g.fillRoundRect(x - 10, y + 18, 100, 12, 5, 5);
        
        // Axle (extends beyond hanger for wheels)
        g.setColor(new Color(120, 120, 120));
        g.fillRect(x - 18, y + 22, 116, 5);
        
        // Axle nuts
        g.setColor(new Color(80, 80, 80));
        g.fillOval(x - 20, y + 20, 8, 8);
        g.fillOval(x + 92, y + 20, 8, 8);
        
        // Bushings (colored rubber)
        g.setColor(new Color(255, 100, 100));
        g.fillRect(x + 32, y + 12, 16, 6);
        
        // Outline
        g.setColor(new Color(100, 100, 100));
        g.setStroke(new BasicStroke(1));
        g.drawRect(x, y, 80, 12);
        g.drawRoundRect(x - 10, y + 18, 100, 12, 5, 5);
    }
}
