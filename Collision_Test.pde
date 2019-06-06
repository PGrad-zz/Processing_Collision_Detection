
ArrayList<Ball> balls;

void setup() {
  size(3000, 2000);
  balls = new ArrayList<Ball>();
  for (int i = 0; i < 200; ++i)
    balls.add(create_ball());
}

PVector rainbow() {
  return new PVector(random(256), random(256), random(256));
}

float gFriction = 1.;

class FrameTime {
  int lastTime = 0;
  
  int avg = 0;
  
  int sampleFrameSize = 5;
  int samples = 0;
  
  float sum = 0.;
  
  int getFrameTime() {
    int time = millis();
    int interval = time - lastTime;
    
    lastTime = time;
    
    sum += interval;
    
    if (++samples == sampleFrameSize) {
      samples = 0;
      avg = int(sum / sampleFrameSize);
      sum = 0.;
    }
    
    return avg;
  }
}

class KineticEnergy {
  int avg = 0;
  
  int sampleFrameSize = 5;
  int samples = 0;
  
  float sum = 0.;
  
  void addEnergy(float energy) {
    sum += energy;
  }
  
  float getEnergy() {
    if (++samples == sampleFrameSize) {
        samples = 0;
        avg = int(sum / sampleFrameSize);
        sum = 0.;
     }
      
    return avg;
  }
}

QuadTree tree = new QuadTree();

FrameTime gFrameTime = new FrameTime();

KineticEnergy gEnergy = new KineticEnergy();

class QNode {
  // Divide into four quadrants, going
  // CCW. First quad is pos x and y.
  private QNode parent = null;
  private QNode first = null;
  private QNode second = null;
  private QNode third = null;
  private QNode fourth = null;
  private Shape shape = null;
  private float x, y;
  
  public QNode(Shape shape) {
    this.shape = shape;
    this.x = shape.X();
    this.y = shape.Y();
  }
  
  private QNode _find(QNode node, Shape _shape) {
    if (node == null)
      return null;
    else
      return node.find(_shape);
  }
  
  public QNode find(Shape _shape) {
    if (shape == _shape)
      return this;
    if (x <= _shape.X() && y <= _shape.Y()) {
      return _find(first, _shape);
    }
    else if (x > _shape.X() && y <= _shape.Y()) {
      return _find(second, _shape);
    }
    else if (x > _shape.X() && y > _shape.Y()) {
      return _find(third, _shape);
    }
    else {
      return _find(fourth, _shape);
    }
  }
  
  private QNode _insert(QNode node, QNode parent, Shape _shape) {
    if (node == null) {
      node = new QNode(_shape);
      node.parent = parent;
    }
    else {
      node.insert(_shape);
    }
    return node;
  }
  
  public void insert(Shape _shape) {
    if (shape == _shape)
      return;
    if (x <= _shape.X() && y <= _shape.Y()) {
      first = _insert(first, this, _shape);
    }
    else if (x > _shape.X() && y <= _shape.Y()) {
      second = _insert(second, this, _shape);
    }
    else if (x > _shape.X() && y > _shape.Y()) {
      third = _insert(third, this, _shape);
    }
    else {
      fourth = _insert(fourth, this, _shape);
    }
  }
  
  private void retrieveAll(QNode node, float radius, QNode center, ArrayList<Shape> list) {
    retrieveInRadius(node.first, radius, center, list);
    retrieveInRadius(node.second, radius, center, list);
    retrieveInRadius(node.third, radius, center, list);
    retrieveInRadius(node.fourth, radius, center, list);
  }
  
  private void retrieveInRadius(QNode node, float radius, QNode center, ArrayList<Shape> list) {
    if (node == null)
      return;
    
    if (node == center) {
      retrieveAll(node, radius, center, list);
    }
    else {
      PVector distVec = new PVector(node.x - center.x, node.y - center.y);
      
      float other_radius = node.shape.getMaxBound();
      
      if (abs(distVec.x) <= (radius + other_radius) || abs(distVec.y) <= (radius + other_radius)) {
        list.add(node.shape);
        retrieveAll(node, radius, center, list);
      }
      else {
        PVector xAxis = new PVector(1, 0);
        
        float angle = (distVec.y) / abs(distVec.y) * PVector.angleBetween(xAxis, distVec) * 180 / PI;
        
        if (-45 < angle || angle <= 45) {
          retrieveInRadius(node.second, radius, center, list);
          retrieveInRadius(node.third, radius, center, list);
        } else if (45 < angle || angle <= 135) {
          retrieveInRadius(node.third, radius, center, list);
          retrieveInRadius(node.fourth, radius, center, list);
        } else if (135 < angle || angle <= -135) {
          retrieveInRadius(node.first, radius, center, list);
          retrieveInRadius(node.fourth, radius, center, list);
        } else  {
          retrieveInRadius(node.first, radius, center, list);
          retrieveInRadius(node.second, radius, center, list);
        }
      }
    }
  }
  
  public ArrayList<Shape> retrieve(Shape _shape) {
    ArrayList<Shape> shapes = new ArrayList<Shape>();
    
    QNode node = find(_shape);
    
    if (node == null)
      return shapes;
    
    float radius = _shape.getMaxBound();   
    
    if (node.parent == null)
      retrieveInRadius(node, radius, node, shapes);
    else
      retrieveInRadius(node.parent, radius,node, shapes);
      
    return shapes;
  }
}

class QuadTree {
  private QNode root = null;
  
  public QNode find(Shape _shape) {
    if (root == null)
      return null;
    else
      return root.find(_shape);
  }
  
  public void insert(Shape _shape) {
    if (root == null)
      root = new QNode(_shape);
    else
      root.insert(_shape);
  }
  
  public ArrayList<Shape> retrieve(Shape _shape) {
    if (root == null) {
      return null;
    }
    else
      return root.retrieve(_shape);
  }
  
  private void _clear(QNode node) {
    if (node == null)
      return;
    else {
      _clear(node.first);
      node.first = null;
      _clear(node.second);
      node.second = null;
      _clear(node.third);
      node.third = null;
      _clear(node.fourth);
      node.fourth = null;
    }
  }
  
  public void clear() {
    _clear(root);
    root = null;
  }
}

abstract class Shape {
  protected float m_x = 0;
  protected float m_y = 0;
  protected float m_speed = constrain((randomGaussian() + 3.), 0., 12);
  protected PVector m_vDir = new PVector(random(1.), random(1.)).normalize();
  protected PVector m_color;
  
  public float X() { return m_x; }
  public float Y() { return m_y; }
  public PVector Pos() { return new PVector(m_x, m_y, 0); }
  public float Speed() { return m_speed; }
  public PVector VDir() { return m_vDir; }
  
  public void setX(float x) { m_x = x; }
  public void setY(float y) { m_y = y; }
  public void setSpeed(float speed) { m_speed = speed; }
  public void setColor(PVector c) { m_color = c; }
  public void setVDir(PVector vDir) { m_vDir = vDir; }
  
  public abstract boolean within(float x, float y);
  
  public abstract float getMaxBound();
  
  public abstract void drawme();
  
  public abstract Shape clone();
  
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
    if (lastHit == null)
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
  
  public float getMaxBound() {
    return m_radius;
  }
  
  public Shape clone() {
    Ball clone = new Ball();
    clone.setX(m_x);
    clone.setY(m_y);
    clone.setSpeed(m_speed);
    clone.setVDir(m_vDir);
    return clone;
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

void energy_counter() {
  String count = String.format("%.2f J", gEnergy.getEnergy());
  
  show_text(count, width - 300, height - 50);
}

void count_energy(Shape shape) {
  gEnergy.addEnergy(.5 * shape.Speed() * shape.Speed());
}

void draw_balls() {
   tree.clear();
   
   for (Ball ball : balls) {
     ball.lastHit = null;
     tree.insert(ball);
   }
  
   for (Ball ball : balls) {
     ArrayList<Shape> others = tree.retrieve(ball);
     println(others.size());
     for (Shape shape : others) {
       Ball other = (Ball) shape;
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
    
    count_energy(ball);
    
    ball.move();
    
    ball.drawme();
  }
}

void draw_balls_unopt() {   
   for (Ball ball : balls) {
     ball.lastHit = null;
   }
  
   for (Ball ball : balls) {
     for (Ball other : balls) {
       if (other == ball)
         continue;
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
         
         fill(255, 255, 255);
       }
     }
    
    count_energy(ball);
    
    ball.move();
    
    ball.drawme();
  }
}

void draw() {
  background(64);
  
  draw_balls();
  
  frame_counter();
  
  energy_counter();
}
