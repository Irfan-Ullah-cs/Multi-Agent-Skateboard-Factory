package simulator;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.BasicStroke;
import java.awt.Font;
import java.awt.geom.AffineTransform;

public class QualityCheck implements SkateboardPart {

    public void draw(Dimension size, Graphics2D g){
        int stampX = 80;
        int stampY = 180;
        
        // Save original transform
        AffineTransform originalTransform = g.getTransform();
        
        // Rotate stamp slightly for authentic look
        g.rotate(Math.toRadians(-12), stampX + 70, stampY + 50);
        
        // Outer stamp ring shadow
        g.setColor(new Color(0, 100, 0, 30));
        g.setStroke(new BasicStroke(5));
        g.drawOval(stampX + 3, stampY + 3, 140, 100);
        
        // Outer stamp ring
        g.setColor(new Color(39, 174, 96));
        g.setStroke(new BasicStroke(5));
        g.drawOval(stampX, stampY, 140, 100);
        
        // Inner stamp ring
        g.setStroke(new BasicStroke(3));
        g.drawOval(stampX + 10, stampY + 10, 120, 80);
        
        // Star decorations
        g.setStroke(new BasicStroke(2));
        drawStar(g, stampX + 25, stampY + 50, 8);
        drawStar(g, stampX + 115, stampY + 50, 8);
        
        // QUALITY text
        g.setFont(new Font("Arial", Font.BOLD, 18));
        g.drawString("QUALITY", stampX + 35, stampY + 45);
        
        // PASSED text
        g.setFont(new Font("Arial", Font.BOLD, 20));
        g.drawString("PASSED", stampX + 38, stampY + 70);
        
        // Decorative lines
        g.setStroke(new BasicStroke(2));
        g.drawLine(stampX + 30, stampY + 52, stampX + 110, stampY + 52);
        
        // Checkmark
        g.setStroke(new BasicStroke(4));
        g.drawLine(stampX + 50, stampY + 80, stampX + 65, stampY + 90);
        g.drawLine(stampX + 65, stampY + 90, stampX + 95, stampY + 70);
        
        // Restore original transform
        g.setTransform(originalTransform);
        
        // Approval badge in corner
        drawApprovalBadge(g, size.width - 200, 370);
    }
    
    private void drawStar(Graphics2D g, int x, int y, int size) {
        int[] xPoints = new int[10];
        int[] yPoints = new int[10];
        
        for (int i = 0; i < 10; i++) {
            double angle = Math.PI / 2 + i * Math.PI / 5;
            int radius = (i % 2 == 0) ? size : size / 2;
            xPoints[i] = x + (int)(radius * Math.cos(angle));
            yPoints[i] = y - (int)(radius * Math.sin(angle));
        }
        
        g.fillPolygon(xPoints, yPoints, 10);
    }
    
    private void drawApprovalBadge(Graphics2D g, int x, int y) {
        // Badge background
        g.setColor(new Color(39, 174, 96));
        g.fillRoundRect(x, y, 150, 50, 10, 10);
        
        // Badge border
        g.setColor(new Color(30, 140, 75));
        g.setStroke(new BasicStroke(3));
        g.drawRoundRect(x, y, 150, 50, 10, 10);
        
        // Inner border
        g.setColor(new Color(255, 255, 255, 100));
        g.setStroke(new BasicStroke(1));
        g.drawRoundRect(x + 5, y + 5, 140, 40, 8, 8);
        
        // Text
        g.setColor(Color.WHITE);
        g.setFont(new Font("Arial", Font.BOLD, 14));
        g.drawString("APPROVED", x + 35, y + 25);
        
        g.setFont(new Font("Arial", Font.PLAIN, 10));
        g.drawString("Ready for Shipping", x + 30, y + 40);
        
        // Checkmark icon
        g.setColor(Color.WHITE);
        g.setStroke(new BasicStroke(3));
        g.drawLine(x + 12, y + 25, x + 18, y + 32);
        g.drawLine(x + 18, y + 32, x + 28, y + 18);
    }
}
