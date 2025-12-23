package simulator;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.BasicStroke;
import java.awt.GradientPaint;
import java.awt.Font;

public class Rails implements SkateboardPart {

    public void draw(Dimension size, Graphics2D g){
        int centerX = size.width / 2 - 80;
        int centerY = size.height / 2 + 20;
        
        // Top rail
        drawRail(g, centerX - 185, centerY - 28, 370);
        
        // Bottom rail
        drawRail(g, centerX - 185, centerY + 22, 370);
        
        // Label
        g.setColor(new Color(41, 128, 185));
        g.setFont(new Font("Arial", Font.BOLD, 12));
        g.drawString("RAILS (2x)", centerX + 60, centerY - 45);
    }
    
    private void drawRail(Graphics2D g, int x, int y, int length) {
        int height = 8;
        
        // Rail shadow
        g.setColor(new Color(0, 0, 0, 30));
        g.fillRoundRect(x + 2, y + 2, length, height, 5, 5);
        
        // Main rail body with gradient (blue plastic)
        GradientPaint railGradient = new GradientPaint(
            x, y, new Color(52, 152, 219),
            x, y + height, new Color(41, 128, 185)
        );
        g.setPaint(railGradient);
        g.fillRoundRect(x, y, length, height, 5, 5);
        
        // Highlight stripe
        g.setColor(new Color(100, 180, 230, 150));
        g.fillRoundRect(x + 5, y + 1, length - 10, 2, 2, 2);
        
        // Mounting screws
        g.setColor(new Color(60, 60, 60));
        int[] screwPositions = {20, 80, 140, 200, 260, 320};
        for (int screwX : screwPositions) {
            if (screwX < length - 10) {
                // Screw head
                g.fillOval(x + screwX, y + 2, 5, 5);
                // Phillips head pattern
                g.setColor(new Color(40, 40, 40));
                g.setStroke(new BasicStroke(1));
                g.drawLine(x + screwX + 1, y + 4, x + screwX + 4, y + 4);
                g.drawLine(x + screwX + 2, y + 3, x + screwX + 2, y + 6);
                g.setColor(new Color(60, 60, 60));
            }
        }
        
        // Rail outline
        g.setColor(new Color(30, 100, 160));
        g.setStroke(new BasicStroke(1));
        g.drawRoundRect(x, y, length, height, 5, 5);
    }
}
