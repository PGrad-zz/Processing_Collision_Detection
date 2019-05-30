
ArrayList<Ball> balls;

void setup() {
  size(3000, 2000);
  balls = new ArrayList<Ball>();
  for (int i = 0; i < 400; ++i)
    balls.add(create_ball());
}

PVector rainbow() {
  return new PVector(random(256), random(256), random(256));
}

float gFriction = 1.;

class FrameTime {
  int lastTime = 0;
  
  int avg = 0;
  
  int sampleFrameSize = 60;
  int samples = 0;
  
  float sum = 0.;
  
  int getFrameTime() {
    int time = millis();
    int interval = time - lastTime;
    
    lastTime = time;
    
    sum += interval;
    
    if (samples++ == sampleFrameSize) {
      samples = 0;
      avg = int(sum / sampleFrameSize);
      sum = 0.;
    }
    
    return avg;
  }
}

FrameTime gFrameTime = new FrameTime();

abstract class Shape {
  protected float m_x = 0;
  protected float m_y = 0;
  protected float m_speed = constrain((randomGaussian() + 3.) * 2., 0., 12.);
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
  public Ball lastHit = null;
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
  
  public void reflect(Ball other) {
    PVector collideDir = collideDirection(other);
    m_vDir = collideDir.mult(2 * collideDir.dot(m_vDir)).sub(m_vDir);
    m_speed *= gFriction;
  }
  
  public void swapVelocity(Ball other) {
    float tmp = m_speed;
    m_speed = other.Speed();
    other.setSpeed(tmp);
  }
}

Ball create_ball() {
  Ball ball = new Ball();
  ball.setX(random(1) * width);
  ball.setY(random(1) * height);
  ball.setColor(rainbow());
  return ball;
}

void show_text(String str, float x, float y) {
  textSize(24);
  fill(255, 255, 255);
  text(str, x, y);
}

void frame_counter() {
  String count = String.format("%02d ms", gFrameTime.getFrameTime());
  
  show_text(count, width - 100, height - 50);
}

void draw_balls() {
   for (Ball ball : balls)
     ball.lastHit = null;
  
   for (Ball ball : balls) {
     ball.move();
    
     for (Ball other : balls) {
       if (other == ball) {
         continue;
       }
        
       if (ball.collide(other)) {
         // Simulate an elastic collision with
         // equal-mass objects by swapping velocities
         // and having the ball reflect along the collision direction.
         ball.reflect(other);
         // If we swap velocities twice we wind up with the initial
         // velocities.
         if (other.lastHit != ball) {
           ball.swapVelocity(other);
           ball.lastHit = other;
         }
       }
    }
    
    ball.drawme();
  }
}

void draw() {
  background(64);
  
  draw_balls();
  
  frame_counter();
}
