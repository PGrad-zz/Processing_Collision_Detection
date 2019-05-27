float xSpeedMax = 3.;
float ySpeedMax = 5.;
Ball balls[];

void setup() {
  size(300, 300);
  balls = new Ball[]{ create_ball(), create_ball() };
}

abstract class Shape {
  protected float m_x = 0;
  protected float m_y = 0;
  protected float m_xSpeed = 0.;
  protected float m_ySpeed = 0.;
  
  public void setX(float x) { m_x = x; }
  public void setY(float y) { m_y = y; }
  public void setXSpeed(float xSpeed) { m_xSpeed = xSpeed; }
  public void setYSpeed(float ySpeed) { m_ySpeed = ySpeed; }
  
  public abstract boolean within(float x, float y);
  
  public abstract void drawme();
  
  public void move() {
    m_x += m_xSpeed;
    m_y += m_ySpeed;
    
    if (m_x < 0 || m_x > width) {
      m_xSpeed *= -1;
    }
    
    if (m_y < 0  || m_y > height) {
      m_ySpeed *= -1;
    }
  }
}

class Ball extends Shape {
  private float m_radius = 25;
  
  public boolean within(float x, float y) {
    return dist(m_x, m_y, x, y) < m_radius;
  }
  
  public void drawme() {
    circle(m_x, m_y, m_radius);
  }
}

Ball create_ball() {
  Ball ball = new Ball();
  ball.setX(random(1) * width);
  ball.setY(random(1) * height);
  ball.setXSpeed(random(.1, 1) * xSpeedMax);
  ball.setYSpeed(random(.1, 1) * ySpeedMax);
  return ball;
}

void draw() {
  background(64);
  
  for (Ball ball : balls) {
    ball.move();
    
    if (ball.within(mouseX, mouseY)) {
      fill(255, 0, 0);
    } else {
      fill(0, 255, 0);
    }
    
    ball.drawme();
  }
}
