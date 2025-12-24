package simulator;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.BasicStroke;
import java.awt.GradientPaint;
import java.awt.Font;

public class Wheels implements SkateboardPart {

    public void draw(Dimension size, Graphics2D g){
        int centerX = size.width / 2 - 80;
        int centerY = size.height / 2 + 20;
        
        // Wheel positions (on the axles)
        int[][] wheelPos = {
            {centerX - 155, centerY + 45},  // Front left
            {centerX - 55, centerY + 45},   // Front right
            {centerX + 65, centerY + 45},   // Rear left
            {centerX + 165, centerY + 45}   // Rear right
        };
        
        for (int[] pos : wheelPos) {
            drawWheel(g, pos[0], pos[1]);
        }
        
        // Label
        g.setColor(new Color(44, 62, 80));
        g.setFont(new Font("Arial", Font.BOLD, 12));
        g.drawString("WHEELS (4x)", centerX + 55, centerY + 115);
    }
    
    private void drawWheel(Graphics2D g, int x, int y) {
        int radius = 22;
        
        // Wheel shadow
        g.setColor(new Color(0, 0, 0, 40));
        g.fillOval(x - radius + 3, y - radius + 3, radius * 2, radius * 2);
        
        // Outer wheel (polyurethane - red/orange gradient)
        GradientPaint wheelGradient = new GradientPaint(
            x - radius, y - radius, new Color(220, 60, 60),
            x + radius, y + radius, new Color(180, 40, 40)
        );
        g.setPaint(wheelGradient);
        g.fillOval(x - radius, y - radius, radius * 2, radius * 2);
        
        // Wheel edge highlight
        g.setColor(new Color(255, 100, 100, 100));
        g.setStroke(new BasicStroke(2));
        g.drawArc(x - radius + 2, y - radius + 2, radius * 2 - 4, radius * 2 - 4, 45, 90);
        
        // Inner wheel ring
        g.setColor(new Color(150, 30, 30));
        g.setStroke(new BasicStroke(3));
        g.drawOval(x - radius + 5, y - radius + 5, radius * 2 - 10, radius * 2 - 10);
        
        // Wheel core (plastic center)
        GradientPaint coreGradient = new GradientPaint(
            x - 10, y - 10, new Color(240, 240, 240),
            x + 10, y + 10, new Color(200, 200, 200)
        );
        g.setPaint(coreGradient);
        g.fillOval(x - 12, y - 12, 24, 24);
        
        // Core pattern (spokes)
        g.setColor(new Color(180, 180, 180));
        g.setStroke(new BasicStroke(2));
        for (int i = 0; i < 6; i++) {
            double angle = i * Math.PI / 3;
            int x1 = x + (int)(4 * Math.cos(angle));
            int y1 = y + (int)(4 * Math.sin(angle));
            int x2 = x + (int)(10 * Math.cos(angle));
            int y2 = y + (int)(10 * Math.sin(angle));
            g.drawLine(x1, y1, x2, y2);
        }
        
        // Bearing (center)
        GradientPaint bearingGradient = new GradientPaint(
            x - 5, y - 5, new Color(220, 220, 220),
            x + 5, y + 5, new Color(160, 160, 160)
        );
        g.setPaint(bearingGradient);
        g.fillOval(x - 6, y - 6, 12, 12);
        
        // Bearing center hole
        g.setColor(new Color(80, 80, 80));
        g.fillOval(x - 2, y - 2, 4, 4);
        
        // Wheel outline
        g.setColor(new Color(120, 20, 20));
        g.setStroke(new BasicStroke(2));
        g.drawOval(x - radius, y - radius, radius * 2, radius * 2);
    }
}
