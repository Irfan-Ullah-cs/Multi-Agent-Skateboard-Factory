package simulator;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.BasicStroke;
import java.awt.GradientPaint;
import java.awt.Font;

public class Board implements SkateboardPart {

    public void draw(Dimension size, Graphics2D g){
        int centerX = size.width / 2 - 80;
        int centerY = size.height / 2 + 20;
        
        // Shadow
        g.setColor(new Color(0, 0, 0, 40));
        g.fillRoundRect(centerX - 195, centerY - 22, 400, 55, 60, 60);
        
        // Board deck with gradient (wood grain effect)
        GradientPaint woodGradient = new GradientPaint(
            centerX - 200, centerY - 25,
            new Color(160, 100, 60),
            centerX - 200, centerY + 25,
            new Color(120, 70, 40)
        );
        g.setPaint(woodGradient);
        g.fillRoundRect(centerX - 200, centerY - 25, 400, 50, 60, 60);
        
        // Wood grain lines
        g.setColor(new Color(100, 60, 30, 80));
        g.setStroke(new BasicStroke(1));
        for (int i = 0; i < 8; i++) {
            int lineY = centerY - 20 + (i * 6);
            g.drawLine(centerX - 180, lineY, centerX + 180, lineY);
        }
        
        // Grip tape on top (dark textured area)
        GradientPaint gripGradient = new GradientPaint(
            centerX - 190, centerY - 22,
            new Color(40, 40, 40),
            centerX - 190, centerY - 5,
            new Color(60, 60, 60)
        );
        g.setPaint(gripGradient);
        g.fillRoundRect(centerX - 190, centerY - 22, 380, 18, 50, 50);
        
        // Grip tape texture dots
        g.setColor(new Color(80, 80, 80));
        for (int i = 0; i < 50; i++) {
            int dotX = centerX - 180 + (int)(Math.random() * 360);
            int dotY = centerY - 20 + (int)(Math.random() * 14);
            g.fillOval(dotX, dotY, 2, 2);
        }
        
        // Board outline
        g.setColor(new Color(80, 50, 20));
        g.setStroke(new BasicStroke(2));
        g.drawRoundRect(centerX - 200, centerY - 25, 400, 50, 60, 60);
        
        // Nose and tail kicks (curved ends)
        g.setColor(new Color(140, 90, 50));
        g.fillArc(centerX - 210, centerY - 15, 30, 30, 90, 180);
        g.fillArc(centerX + 180, centerY - 15, 30, 30, 270, 180);
        
        // Label
        g.setColor(new Color(44, 62, 80));
        g.setFont(new Font("Arial", Font.BOLD, 12));
        g.drawString("DECK", centerX + 70, centerY + 60);
    }
}
