
ArrayList<Ball> balls;

void setup() {
  size(1000, 1000);
  balls = new ArrayList<Ball>();
  for (int i = 0; i < 20; ++i)
    balls.add(create_ball());
}

PVector rainbow() {
  return new PVector(random(256), random(256), random(256));
}

abstract class Shape {
  protected float m_x = 0;
  protected float m_y = 0;
  protected float m_speed = random(.8, 1.) * 5.;
  protected PVector m_vDir = new PVector(random(1.), random(1.)).normalize();
  protected PVector m_color;
  
  public float X() { return m_x; }
  public float Y() { return m_y; }
  public float Speed() { return m_speed; }
  public PVector VDir() { return m_vDir; }
  
  public void setX(float x) { m_x = x; }
  public void setY(float y) { m_y = y; }
  public void setSpeed(float speed) { m_speed = speed; }
  public void setColor(PVector c) { m_color = c; }
  
  public abstract boolean within(float x, float y);
  
  public abstract void drawme();
  
  public void move() {
    m_x += m_speed * m_vDir.x;
    m_y += m_speed * m_vDir.y;
    
    if (m_x < 0 || m_x > width) {
      m_vDir.x *= -1;
    }
    
    if (m_y < 0  || m_y > height) {
      m_vDir.y *= -1;
    }
  }
}

class Ball extends Shape {
  private float m_radius = 12.5;
  
  public float Radius() {
    return m_radius;
  }
  
  public boolean within(float x, float y) {
    return dist(m_x, m_y, x, y) < m_radius;
  }
  
  public void drawme() {
    fill(m_color.x, m_color.y, m_color.z);
    circle(m_x, m_y, m_radius * 2.);
  }
  
  public boolean collide(Ball ball) {
    float centersDist = dist(m_x, m_y, ball.X(), ball.Y());
    // If the radii of the circles summed together are less than
    // or equal to the distance between the centers, then they collide.
    return (m_radius + ball.Radius()) >= centersDist;
  }
  
  public PVector collideDirection(Ball ball) {
    return (new PVector(m_x - ball.X(), m_y - ball.Y())).normalize();
  }
  
  public void ricochet(Ball other) { m_vDir.add(collideDirection(other)).normalize(); }
}

Ball create_ball() {
  Ball ball = new Ball();
  ball.setX(random(1) * width);
  ball.setY(random(1) * height);
  ball.setColor(rainbow());
  return ball;
}

void draw() {
  background(64);
  
  for (Ball ball : balls) {
    ball.move();
    
    for (Ball other : balls) {
       if (other == ball) {
         continue;
       }
        
       if (ball.collide(other)) {
         ball.ricochet(other);
       }
    }
    
    ball.drawme();
  }
}
