float G = 6.67430e-11f;   // m^3 kg^-1 s^-2 (gravitational constant)
float c = 299792458;      // m/s (speed of light)
float total_mass=0;

ArrayList<object> o;    //list of massive objects 
spacetime grid;         //the gird element representing the spacetime fabric

void setup()
{
  size(700, 700, P3D);

  /** Objects initialization **/
  grid = new spacetime(20, -3*width);  
  o = new ArrayList<object>();

  //earth
  object _o = new object(5.97e24f, 20, width/2, height/2, -width/4);
  o.add(_o);  
  //moon
  object _o2 = new object(7.35e22f, 5.5, width/2+70, height/2-50, -width/4-70);
  o.add(_o2);
  //venus
  object _o3 = new object(4.87e24f, 19, -250, height/2, -4*width/3);
  o.add(_o3);
  //mars
  object _o4 = new object(6.42e23f, 11, width+400, height/2, -7*width/4);
  o.add(_o4);
  
  /*
    as of this version, it's only required to calculate the matrix once since the universe is static, however 
    future versions will feature dynamically instantiable massive objects, which would require a refresh of 
    the grid every time the o object list changes.
  */
  grid.calculateYMatrix();

  lights();
}

void draw()
{
  background(0);
  stroke(255);

  grid.show();
  for (object _o : o)
    _o.show();
}

class spacetime
{
  /*
    - step: how tight the spacetime grid looks  
    - horizon: limit value for the z 
    - x_range: dynamically adjusted limit value for the x
    - y[][]: the y value of each point of the grid, calculated accordingly
  */
  float step, horizon, x_range;
  float y[][];
  
  spacetime(float _step, float _horizon)
  { 
    step = _step;
    horizon = _horizon;
    
    x_range=3*width/2;
    
    float x_limit = x_range;
    
    //initializing the y[][] matrix based on the newly set dimensions of the spacetime grid
    y = new float[(int) ((width-horizon)/step)+1][];
    for(float z=horizon, i=0; z<=width; z+=step, i+=1)
    {
      y[(int) i] = new float[(int) ((width+2*x_limit)/step)+1];
      if ((z-horizon)/step==2) x_limit-=step; //x_limit decreases each 2 loops, merely as a memory-saving feature
    }
  }
  
  void show()
  {
    float x, z, x_limit = x_range;
    int i, j;

    //calculateYMatrix(); //calculates the Y value for each point of the grid
    
    stroke(100);
    for(z=horizon+step, i=1; z<=width; z+=step, i++)
    {
      for(x=-x_limit+step, j=1; x<=width+x_limit; x+=step, j++)
      {
        line(x,y[i][j],z, x-step,y[i][j-1],z);
        line(x,y[i][j],z, x,y[i-1][j],z-step);
      }
      if ((z-horizon)/step==2) x_limit-=step; 
    }
  }
  
  void calculateYMatrix()
  {
    float x, z, x_limit = x_range, y_max=0;
    int i, j;
   
    for(z=horizon, i=0; z<=width; z+=step, i++)
    {
      for(x=-x_limit, j=0; x<=width+x_limit; x+=step, j++)
      {
        y[i][j] = getY(x, z);
        if (y_max < y[i][j]) y_max = y[i][j];
      }
      if ((z-horizon)/step==2) x_limit-=step; 
    }
    
    //translates the raw values contained in the matrix into Processing pixel logic
    normalizeYMatrix(y_max);
  }
  
  float getY(float x, float z)
  {
    /*
      computes the y values for each point of the grid using Flamm's Parabloid
      $ y = \sum_{i \in o}\sqrt{r_s(r_i - r_s)} $
      where
      r is the distance from the center of mass and r_s is the Schwarzschild radius
    */

    float y_total = 0, dx, dz, r, rs;
    //scales the distance values from pixel logic to actual universal distances, normalized by the sqrt of the total mass
    float scale_factor = 3.16e25f / sqrt(total_mass); 

    for (object _o : o)
    { 
      dx = (x - _o.x) * scale_factor;
      dz = (z - _o.z) * scale_factor;
      r = sqrt(dx*dx + dz*dz);
      rs = 2 * G * _o.mass / (c * c);
      if (r > rs)
        y_total += sqrt(rs * (r - rs));
    }

    return y_total;
  }
  
  void normalizeYMatrix(float y_max)
  {  
    /*
      applies a series of translformations to convert the raw y values to values
      that can actually be displayed.

      -1-
        each y value is inverted, since the y axis (in pixels) is inverted in respect
        to the cartesian y axes.
      
      -2-
        each y value is scaled down, to compensate for the previous scaling uo of x & z
        coordinates. the scale factor differs, as the goal is to (arbitrarily) normalize
        the y value in a way they appear clearly and meaningfully on the window. 

      -3-
        each value is translated by a certain quantity, that depends on the value of the
        maxium y. what this translation aims to do  is, basically, to move the entire
        grid down (up, in pixel logic) the y axis to have it graphycally start at a y
        (pixel) value equal to 1/3 of the height of the window.
    */

    float x, z, x_limit = x_range;
    int i, j;
    y_max = -y_max;
    float scale_factor = 0.00003f;
    float translation_reach = 1*height/3-(y_max* scale_factor);

    for(z=horizon, i=0; z<=width; z+=step, i++)
    {
      for(x=-x_limit, j=0; x<=width+x_limit; x+=step, j++)
      {
        y[i][j] = -y[i][j] * scale_factor + translation_reach;
      }
      if ((z-horizon)/step==2) x_limit-=step;
    }
  }
  
}

class object 
{
  float mass, rad, vel, rs; 
  float x, y, z;
  
  object(float _mass, float _rad, float _x, float _y, float _z)
  {
    rad = _rad;
    mass = _mass;
    total_mass+=mass;
    x=_x;
    y=_y;
    z=_z;
    
    rs = 2 * G * mass / (c * c);
  }
  
  void show()
  {
    noStroke();
    push(); //enters local coordinate system
    translate(x, y, z);
    sphere(rad);
    pop(); //exits local coordinate system
  }
  
  void update()
  {
    //for future applcation
  }
}
