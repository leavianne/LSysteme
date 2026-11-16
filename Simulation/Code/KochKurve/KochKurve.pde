// L-System Prototyp 5: KOCH-KURVE / KOCH-SCHNEEFLOCKE
// Axiom: F  (Schneeflocke: F--F--F)   Regel: F -> F+F--F+F   Winkel: 60°
// Steuerung:
//   LEERTASTE / Mausklick : nächste Iteration
//   S                     : Kurve <-> Schneeflocke
//   A                     : Autoplay an/aus
//   R                     : Reset

String rule = "F+F--F+F";
boolean snowflake = false;
boolean autoplay = false;
int iter = 1;
int maxIter = 6;
float angleDeg = 60;
float growth = 0;
int wait = 0;

String sentence;
ArrayList<PVector> pts;
float minX, maxX, minY, maxY;

void setup() {
  size(900, 700);
  colorMode(HSB, 360, 100, 100);
  build();
}

void build() {
  String axiom = snowflake ? "F--F--F" : "F";
  sentence = generate(axiom, iter);
  trace(sentence);
  growth = 0;
  wait = 0;
}

String generate(String axiom, int n) {
  String s = axiom;
  for (int i = 0; i < n; i++) {
    StringBuilder next = new StringBuilder();
    for (int j = 0; j < s.length(); j++) {
      char c = s.charAt(j);
      if (c == 'F') next.append(rule);
      else next.append(c);
    }
    s = next.toString();
  }
  return s;
}

// Turtle läuft den String ab und speichert alle Punkte (Einheitslänge 1)
void trace(String s) {
  pts = new ArrayList<PVector>();
  float x = 0, y = 0, h = 0, a = radians(angleDeg);
  pts.add(new PVector(x, y));
  minX = maxX = minY = maxY = 0;
  for (int i = 0; i < s.length(); i++) {
    char c = s.charAt(i);
    if (c == 'F') {
      x += cos(h);
      y += sin(h);
      pts.add(new PVector(x, y));
      minX = min(minX, x);
      maxX = max(maxX, x);
      minY = min(minY, y);
      maxY = max(maxY, y);
    } else if (c == '+') {
      h -= a;     // links drehen
    } else if (c == '-') {
      h += a;     // rechts drehen
    }
  }
}

void draw() {
  background(15);
  growth = min(1, growth + 0.02);

  if (autoplay && growth >= 1) {
    wait++;
    if (wait > 70) {
      iter = (iter < maxIter) ? iter + 1 : 1;
      build();
    }
  }

  // Automatisch auf Fenstergröße skalieren
  float w = max(maxX - minX, 0.0001);
  float h = max(maxY - minY, 0.0001);
  float sc = min((width - 80) / w, (height - 140) / h);
  float ox = width / 2 - sc * (minX + maxX) / 2;
  float oy = height / 2 + 20 - sc * (minY + maxY) / 2;

  int n = int((pts.size() - 1) * growth);
  strokeWeight(1.5);
  for (int i = 0; i < n; i++) {
    PVector p = pts.get(i), q = pts.get(i + 1);
    stroke(map(i, 0, pts.size(), 180, 320), 70, 100);
    line(ox + sc * p.x, oy + sc * p.y, ox + sc * q.x, oy + sc * q.y);
  }

  fill(0, 0, 100);
  textSize(14);
  text((snowflake ? "Koch-Schneeflocke" : "Koch-Kurve") + "   Iteration " + iter + "/" + maxIter
     + "   Segmente: " + (pts.size() - 1), 10, 20);
  text("Länge relativ zum Start: (4/3)^n = " + nf(pow(4.0 / 3.0, iter), 1, 2)
     + "   Dimension = log4/log3 ≈ 1,26", 10, 40);
  text("[Leertaste/Klick] Iteration  [S] Kurve/Schneeflocke  [A] Autoplay  [R] Reset", 10, height - 15);
}

void nextIteration() {
  if (iter < maxIter) {
    iter++;
    build();
  }
}

void keyPressed() {
  if (key == ' ') nextIteration();
  if (key == 's' || key == 'S') { snowflake = !snowflake; build(); }
  if (key == 'a' || key == 'A') autoplay = !autoplay;
  if (key == 'r' || key == 'R') { iter = 1; build(); }
}

void mousePressed() {
  nextIteration();
}
