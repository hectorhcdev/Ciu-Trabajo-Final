import processing.video.*;
import java.lang.*;
import cvimage.*;
import java.util.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.*;
import java.awt.Color;
import java.util.concurrent.*;
import processing.sound.*;
public enum GameScenes {
  DEBUG_MODE,
  MAIN_MENU,
  GAME,
  WIN,
  LOSE
}

GameScenes scene;

DebugCDCalibrator debugCDCalibrator;
InGameCDCalibrator ingameCDCalibrator;

SceneDrawer sceneDrawer;
MyButton quitButton, confirmButton, playAgainButton, quitButton2;

CDController cdController;
int rotation = 0;
int value;
int count = 0;
int posX;
int posY;
int y;
int y2;
Capture cam;
PImage back;
SoundFile shootSound;
SoundFile explosionSound;
PImage hitPoints_image;

PlayerShip jugador1;
EnemyShip enemigo1;
Bullet bala1;

int counter;
int nThreads;
ExecutorService executor;
float timer;
static volatile int objectCount;

boolean hitBoxBullets = false;

//Imagenes
PImage shipI;
PImage bossI;
PImage bulletS;
PImage bulletB;
PImage shipI1;

Juego juego;
void setup() {
  size(1280, 720, P3D);
  
  //Inicializamos las imagenes
  shipI=loadImage("./Assets/Images/Space Ship.png");
  bossI=loadImage("./Assets/Boss - UFO.png");
  bulletS=loadImage("./Assets/Images/Space Ship Bullet.png");
  bulletB=loadImage("./Assets/Images/Boss small bullet.png");
  shipI1=loadImage("./Assets/Images/Enemy - satellite.png");
  
  //Cosas
  scene = GameScenes.MAIN_MENU;
  cam = new Capture(this, 1280, 720);

  debugCDCalibrator = new DebugCDCalibrator();
  ingameCDCalibrator = new InGameCDCalibrator();
  back=loadImage("./Assets/Images/Background.png");
  shootSound=new SoundFile(this,"./Assets/Sounds/shot_1.wav");
  shootSound.amp(0.3);
  explosionSound=new SoundFile(this,"./Assets/Sounds/explosion.mp3");
  explosionSound.amp(0.1);
  cdController = new CDController(cam, ingameCDCalibrator);
  setupObjects();

  value = 5;
  y=0;
  y2=0;
  posX=width/2;
  posY= height/2;

  //Creamos los hilos
  println("Numero de procesadores: " + Runtime.getRuntime().availableProcessors());
  //El mejor número de hilos es un poco más que el número de procesadores
  nThreads = Runtime.getRuntime().availableProcessors()+2;
  //println("Numero de hilos: " + nThreads);
  executor = Executors.newFixedThreadPool(nThreads);

  // Creamos la clase que usaremos para pintar por pantalla
  sceneDrawer = new SceneDrawer();
  confirmButton = new MyButton(loadImage("./Assets/Images/Confirm button.png"), loadImage("./Assets/Images/Confirm button-pressed.png"));
  quitButton = new MyButton(loadImage("./Assets/Images/Quit button.png"), loadImage("./Assets/Images/Quit button-pressed.png"));

  playAgainButton = new MyButton(loadImage("./Assets/Images/Play again button.png"), loadImage("./Assets/Images/Play again button-pressed.png"));
  quitButton2 = new MyButton(loadImage("./Assets/Images/Quit button2.png"), loadImage("./Assets/Images/Quit button2-pressed.png"));
  
  // cargamos la vida 
  hitPoints_image = loadImage("./Assets/Images/Heart.png");


  //Inicializamos el juego
  juego = new Juego();
  juego.cargarNivelesPredeterminados();
  HiloGeneracionNivel hilo2 = new HiloGeneracionNivel();
}



void setupObjects() {
  //PImage imagen, String type, float x, float y, float vel, float acc, float angle, float hitPoints
  //types -> normal, rebote, serpiente
  hitBoxBullets = true;
  shipI1.resize(50,50);
  bulletB.resize(20,20);
  //naves
  jugador1 = new PlayerShip(shipI, width/2, height/2, 5.0, 0.0, GameObject.top, 10);
  //enemigo1 = new EnemyShip(bossI, "rebote", width/2, height/16, 5.0, 1.0, 0.0, 200);
  //enemigo1.imageRotation = 270.0;
  //jugador1.sethitBox(true);
  jugador1.setWeapon(bulletS, "limon", 1, 270.0, 10, color(0,255,0));
  jugador1.setWeapon(bulletS, "circuloInvertido2", 1, 270.0, 10, color(255,0,255));
  jugador1.setWeapon(bulletS, "circuloInvertido", 1, 180.0, 10, color(255,0,255));
  
  /*
  EnemyShip enemigoPrueba = new EnemyShip(shipI1, "rebote", 30, 30, 5.0, 0.1, GameObject.right, 50000);
  enemigoPrueba.setimageRotation(0.0);
  EnemyShip [] enemigosTest =  enemigoPrueba.multyCopy(20);
  for (int i = 0; i < 20 ; i++){
    enemigosTest[i].movement(30,(30*i)+30);
    enemigosTest[i].setWeapon(bulletB, "rebote", 1, enemigosTest[i].getAngle(), 10, 0.0001, color(255,0,0));

  }
 */
  //armas
  //enemigo1.setWeapon(bulletB, "normal", 1, 90.0, 10, color(255,0,0));
}

void draw() {
  background(0);
  println("Frames: " + frameRate + "\t-- Número de objetos: " + GameObject.listaObjetos.size());
  //cdController.updateColorDetection();
  HiloCamara hilo1 = new HiloCamara();
  if (scene == GameScenes.DEBUG_MODE) {
    sceneDrawer.drawDebugScreen(cdController);
  }else if (scene == GameScenes.MAIN_MENU) {
    sceneDrawer.drawIngameScreen(cdController, confirmButton, quitButton);
  }else if (scene == GameScenes.GAME) {

    if(y>=height){
      y=0;
    }else{
      y=y+20;
    }
    
    y2=y-back.height;
    //y = constrain(y, 0, back.height - height);
    image(back, 0, y);
    image(back, 0, y2);
    for(int i = 0; i < jugador1.hitPoints; i++) {
        image(hitPoints_image, i*35,50);
    }
    //image(cdController.getFilteredImage(),0,0);
    //println(cdController.getRecognizedRect());
    //counter = GameObject.listaObjetos.size();
    //-- Temporal prueba nivel
    
    //Arrancamos los hilos
    timer = millis() / 1000;
    for(int i = 0; i< GameObject.listaObjetos.size(); i++){
      GameObject o = GameObject.listaObjetos.get(i);
      o.show();
    }

    synchronized (GameObject.listaObjetos){
      counter = 0;
      Iterator ite = GameObject.listaObjetos.iterator();
      while (ite.hasNext()){
        GameObject o = (GameObject) ite.next();
        Runnable worker = new WorkerThread(o, counter);
        executor.execute(worker);
        counter ++;
      }
    }
  }else if(scene == GameScenes.WIN){
    sceneDrawer.gameEndScreen(cdController, playAgainButton, quitButton2, true);
  }else if(scene == GameScenes.LOSE){
    sceneDrawer.gameEndScreen(cdController, playAgainButton, quitButton2, false);
  }
}

synchronized void subCounter(){
    counter = counter - 1;
    println(counter);
}

//println("Frames: " + frameRate);
public class WorkerThread implements Runnable {
  String name;
  Thread t;
  int i ;
  GameObject object;
  public WorkerThread(GameObject o, int i){
    object = o;
    this.i = i;
    name = "hilo ->" + i;
    //t = new Thread(this, name);
    //t.start();
    //System.out.println("New thread: " + name);
  }

  public void run(){
      objectController(this.object);
      //println(this.name + " esta trabajando");
  }
}

public class HiloCamara implements Runnable {
  String name;
  Thread t;
  int i ;
  
  GameObject object;
  public HiloCamara(){
    name = "hilo -> HiloCamara";
    t = new Thread(this, name);
    t.start();
    System.out.println("New thread: " + name);
  }

  public void run(){
      cdController.updateColorDetection();
  }
}

public class HiloGeneracionNivel implements Runnable {
  String name;
  Thread t;
  int i ;
  
  GameObject object;
  public HiloGeneracionNivel(){
    name = "hilo -> HiloGeneracionNivel";
    t = new Thread(this, name);
    t.start();
    System.out.println("New thread: " + name);
  }

  public void run(){
      juego.ejecutar(0);
  }
}

void objectController(GameObject obj){
    // Sección de jugador
    if (obj instanceof Ship){
      Ship objS = (Ship) obj;
      if (objS.hasWeapon()){
        Weapon mWeapon = objS.getWeapon();
        if(mWeapon.frequencyShoot > 0     &&
           timer - mWeapon.internalTimer >= mWeapon.frequencyShoot){
          objS.shoot();
          mWeapon.internalTimer = timer;
        }
      }
    }

    if (obj instanceof PlayerShip) {
      Rect posRect=cdController.getRecognizedRect();
      if(posRect!= null){
        posX=posRect.x;
        posY=posRect.y;
      }
      obj.setPosition(mouseX, mouseY);
      if (this.frameCount%15 == 0){
        obj.setimageRotation(rotation);
        //rotation = (rotation + 15)%360;
      }
    }

    synchronized(GameObject.listaObjetos){
      if (obj instanceof Bullet){
        Bullet objB = (Bullet) obj;
        Iterator ite = GameObject.listaObjetos.copy().lista.iterator();
        while (ite.hasNext()){
          GameObject o = (GameObject) ite.next();
          if (o instanceof Ship){
            Ship objS = (Ship) o;
            if (objB.myShip instanceof PlayerShip){
               if ((objS instanceof EnemyShip) && (objB.hasCollisioned(objS))){
                 objS.sufferDamage(objB.getDamage());
                 objB.die();
               }
            }else if (objB.myShip instanceof EnemyShip){
              if ((objS instanceof PlayerShip)&& (objB.hasCollisioned(objS))){
                objS.sufferDamage(objB.getDamage());
                objB.die();
              }
            }
          }
        }
      }
    }

    // seccion de colisiones
    // exterior
    synchronized(GameObject.listaObjetos){
      if (obj.hasExited(200)){
          obj.die();
      }
    }


    obj.movement();

    // contador
    if (count > 10) {
      count = 0;
    }
}

void playshootSound(){
    this.shootSound.play();
}

void playExplosionSound(){
    this.explosionSound.play();
}

void keyPressed(){
  if (key == '1'){
    scene = GameScenes.DEBUG_MODE;
  }else if(key == '2'){
    scene = GameScenes.MAIN_MENU;
  }else if(key == '3'){
    scene = GameScenes.GAME;
  }
}

void mouseDragged() {
  if(scene == GameScenes.DEBUG_MODE){
    CDCalibrator calibrator = cdController.getCalibrator();
    calibrator.mouseDragged();
  }else if(scene == GameScenes.MAIN_MENU){
    CDCalibrator calibrator = cdController.getCalibrator();
    calibrator.mouseDragged();
  }
}

int i = 0;
void mousePressed() {
  if(scene == GameScenes.DEBUG_MODE){
    CDCalibrator calibrator = cdController.getCalibrator();
    calibrator.mousePressed();
    
    
  }else if(scene == GameScenes.MAIN_MENU){
    CDCalibrator calibrator = cdController.getCalibrator();
    calibrator.mousePressed();
    confirmButton.mousePressed();
    quitButton.mousePressed();
    
    
  }else if (scene == GameScenes.GAME){
    if (mouseButton==LEFT) {
      jugador1.shoot();
      Weapon actualWeapon = (Weapon) jugador1.weapons.get(i);
      //println("Estas usando el arma :" + actualWeapon.type);
    } else if(mouseButton==RIGHT){
      i = (i+1)%jugador1.weapons.size();
      jugador1.changeWeapon(i);
    }
  }else if (scene == GameScenes.WIN || scene == GameScenes.LOSE){
    playAgainButton.mousePressed();
    quitButton2.mousePressed();
  }
}

void mouseReleased(){
  if(scene == GameScenes.DEBUG_MODE){
  }else if(scene == GameScenes.MAIN_MENU){
    if (confirmButton.mouseReleased()) {
        scene = GameScenes.GAME;
    } else if (quitButton.mouseReleased()) {
      exit();
    }
  }else if(scene == GameScenes.WIN || scene == GameScenes.LOSE){
    if (playAgainButton.mouseReleased()) {
        scene = GameScenes.GAME;
    }
    if (quitButton2.mouseReleased()) {
      exit();
    }
    
  }
}
