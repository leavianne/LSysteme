// L-System Baum-Editor (Processing 4, Java-Modus, keine Bibliotheken)
// Axiom F, Regel F -> FF+[+F-F-F]-[-F+F+F]
// Alle Parameter über Regler im Bedienfeld links. Das Bild ist statisch und wird nur
// bei Interaktion neu gezeichnet (noLoop/redraw).
//
// Farbpalette:  Stamm 7f4f24 | Blätter 4f772d | Boden 90a955 | Leiste b6ad90 | Text 582f0e | Himmel blau

String axiom = "F";
String rule = "FF+[+F-F-F]-[-F+F+F]";
String sentence = "";
int sentenceIter = -1;

float branchFactor = 0.8;        // Seitenäste starten 20 % dünner als der Mutterast
float easeAfterBranch = 0.2;     // wie schnell sich der Stamm nach einer Verzweigung verdünnt (kleiner = langsamer)

boolean leavesOn = true;          // Blätter ein/aus (Schalter neben der Überschrift "Blätter")

Plant plant;
Plant refPlant;                     // gleicher Baum ohne Zufall (bestimmt Position und Größe)
float fsc, fox, foy;             // Skalierung/Verschiebung (siehe fit)

// Layout
float panelW = 300;
float groundY;                   // Oberkante der Wiese (wird in setup gesetzt)
float baseY;                     // Fußpunkt des Baums (leicht in der Wiese)

// Farben (in setup gesetzt)
color cStem, cLeaf, cLeafDark, cLeafLight, cGround, cPanel, cText, cInk, cSkyTop, cSkyBottom;
color[] petal;

// Regler, die den Baum neu aufbauen (Indizes) und deren letzte Werte
int[] treeIdx = { 0, 1, 2, 3, 5 };
float[] lastTree = new float[5];

Slider[] sliders;
float[][] flowers;
PFont sans, sansB;

// Fenster- und Darstellungseinstellungen (müssen in settings() stehen)
void settings() {
  size(1000, 720);
  smooth(8);                           // stärkere Kantenglättung (Anti-Aliasing)
  pixelDensity(displayDensity());      // volle Auflösung auf hochauflösenden Bildschirmen
}

void setup() {
  groundY = height - 80;
  baseY = groundY + 16;

  cStem = color(127, 79, 36);                 // 7f4f24
  cLeaf = color(79, 119, 45);                 // 4f772d
  cLeafDark = color(62, 100, 35);
  cLeafLight = color(100, 142, 60);
  cGround = color(144, 169, 85);              // 90a955
  cPanel = color(182, 173, 144);              // b6ad90
  cText = color(88, 47, 14);                  // 582f0e
  cInk = color(52, 26, 6);                    // dunkleres Braun für Schrift und Regler (mehr Kontrast)
  cSkyTop = color(122, 189, 232);             // Himmel: oben kräftiger, zum Horizont heller
  cSkyBottom = color(206, 232, 247);
  petal = new color[] { color(245, 237, 214), color(233, 186, 87), color(204, 100, 74), color(222, 150, 160) };

  sans = createFont("SansSerif", 14);
  sansB = createFont("SansSerif.bold", 14);

  sliders = new Slider[] {
    new Slider("Iterationen", 134, 1, 5, 3, 0, ""),
    new Slider("Winkel", 182, 5, 60, 22.5, 1, "°"),
    new Slider("Zufall", 230, 0, 20, 0, 1, "°"),
    new Slider("Astverkürzung", 278, 0.6, 1.0, 0.85, 2, ""),
    new Slider("Stammdicke", 412, 2, 30, 12, 1, " px"),
    new Slider("Verjüngung", 460, 0, 1, 0.5, 2, "%"),
    new Slider("Blattbreite", 546, 1, 20, 10, 1, " px"),
    new Slider("Blattlänge", 594, 1, 30, 16, 1, " px"),
    new Slider("Segmentlänge", 326, 0.3, 1.0, 0.9, 2, "%")      // Index 8, steht optisch in "Struktur"
  };

  makeFlowers();
  rebuild();
  noLoop();
}

// ---------- L-System-Kern ----------

// Ersetzung (Rewriting): alle F werden pro Iteration gleichzeitig ersetzt
String generate(int n) {
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

// Interpretation (Turtle-Grafik): String -> Liniensegmente (Einheitslänge 1) und Blätter
class Plant {
  ArrayList<float[]> segs = new ArrayList<float[]>();     // x1, y1, x2, y2, Dicke Anfang, Dicke Ende
  ArrayList<float[]> leaves = new ArrayList<float[]>();   // x, y, Richtung
  float minX = 0, maxX = 0, minY = 0, maxY = 0;

  // taperTip:    Dicke am Ende des längsten Wegs relativ zum Start (kontinuierliche Verjüngung)
  // branchTip:   Dicke des Stamms nach allen Verzweigungen des längsten Wegs (Verdünnung nach Ast)
  Plant(String s, float angleDeg, float jit, float decay, float taperTip, float branchTip) {
    // 1. Durchlauf: längster Weg (Anzahl F) und meiste Verzweigungen entlang eines Wegs
    ArrayList<Integer> cstC = new ArrayList<Integer>();
    ArrayList<Integer> cstB = new ArrayList<Integer>();
    int cnt = 0, bc = 0, maxPath = 1, maxBr = 1;
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      if (c == 'F') {
        cnt++;
        maxPath = max(maxPath, cnt);
      } else if (c == '[') {
        cstC.add(cnt);
        cstB.add(bc);
      } else if (c == ']') {
        cnt = cstC.remove(cstC.size() - 1);
        bc = cstB.remove(cstB.size() - 1) + 1;        // der Stamm hat einen Ast abgegeben
        maxBr = max(maxBr, bc);
      }
    }
    float factor = pow(taperTip, 1.0 / maxPath);          // Dickenfaktor pro Segment
    float branchRatio = pow(branchTip, 1.0 / maxBr);      // Dickenfaktor pro Verzweigung

    // 2. Durchlauf: eigentliche Turtle
    randomSeed(7);                       // gleicher Zufall bei jedem Neuaufbau
    float x = 0, y = 0, h = 0, w = 1, a = radians(angleDeg);
    float pending = 1;                   // noch ausstehende Verdünnung nach Verzweigungen
    int depth = 0;
    ArrayList<float[]> st = new ArrayList<float[]>();
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      if (c == 'F') {
        float l = pow(decay, depth);     // Astverkürzung pro Verzweigungsebene
        float nx = x + sin(h) * l, ny = y - cos(h) * l;
        // Ausstehende Verdünnung wird nicht auf einmal, sondern über mehrere Segmente abgebaut
        float step = pow(pending, easeAfterBranch);
        pending /= step;
        float w2 = w * factor * step;
        segs.add(new float[] { x, y, nx, ny, w, w2 });
        x = nx;
        y = ny;
        w = w2;
        minX = min(minX, x);
        maxX = max(maxX, x);
        minY = min(minY, y);
        maxY = max(maxY, y);
      } else if (c == '+') {
        h -= a + radians(random(-jit, jit));      // links
      } else if (c == '-') {
        h += a + radians(random(-jit, jit));      // rechts
      } else if (c == '[') {
        st.add(new float[] { x, y, h, depth, w, pending * branchRatio });
        depth++;
        w *= branchFactor;               // Seitenast startet dünner
        pending = 1;
      } else if (c == ']') {
        leaves.add(new float[] { x, y, h });      // Blatt am Astende
        float[] q = st.remove(st.size() - 1);
        x = q[0];
        y = q[1];
        h = q[2];
        depth = int(q[3]);
        w = q[4];
        pending = q[5];                  // Stamm wird ab jetzt langsam dünner
      }
    }
    leaves.add(new float[] { x, y, h });
  }
}

void rebuild() {
  for (int k = 0; k < treeIdx.length; k++) lastTree[k] = sliders[treeIdx[k]].value;
  int iter = int(sliders[0].value);
  if (iter != sentenceIter) {                     // String nur bei neuer Iteration erzeugen
    sentence = generate(iter);
    sentenceIter = iter;
  }
  float thin = sliders[5].value;                  // ein Regler für beide Effekte
  float taperTip = pow(0.05, thin);               // kontinuierliche Verjüngung entlang des Asts (100 % = Spitze bei 5 %)
  float branchTip = pow(0.2, thin);               // Verdünnung nach Verzweigungen (100 % = Stamm auf 20 %)
  float jit = sliders[2].value;
  plant = new Plant(sentence, sliders[1].value, jit, sliders[3].value, taperTip, branchTip);
  // Referenz ohne Zufall: Skalierung und Stammposition hängen nur von ihr ab
  refPlant = (jit == 0) ? plant : new Plant(sentence, sliders[1].value, 0, sliders[3].value, taperTip, branchTip);
}

boolean treeChanged() {
  for (int k = 0; k < treeIdx.length; k++) {
    if (sliders[treeIdx[k]].value != lastTree[k]) return true;
  }
  return false;
}

// ---------- Szene ----------

// Skalierung und Position nur aus dem Referenzbaum (ohne Zufall) bestimmen:
// Der Stamm steht dadurch immer mittig an derselben Stelle, auch wenn "Zufall" verändert wird.
void fit(Plant ref, float x0, float y0, float x1, float y1) {
  float halfW = max(max(abs(ref.minX), abs(ref.maxX)), 0.001);
  float h = max(ref.maxY - ref.minY, 0.001);
  fsc = min(min((x1 - x0) / 2 / halfW, (y1 - y0) / h), 90) * sliders[8].value;   // Segmentlänge: 100 % = Baum füllt die Fläche
  fox = (x0 + x1) / 2;
  foy = y1 - fsc * ref.maxY;
}

float sx(float x) { return fox + fsc * x; }
float sy(float y) { return foy + fsc * y; }

// Oberkante der Wiese (leicht wellig)
float meadowTop(float x) {
  return groundY + sin(x * 0.018) * 4 + sin(x * 0.047 + 1.3) * 2.5;
}

// Himmel mit Farbverlauf
void drawSky() {
  background(cSkyBottom);
  strokeWeight(1);
  float yEnd = groundY + 10;
  for (float y = 0; y <= yEnd; y++) {
    stroke(lerpColor(cSkyTop, cSkyBottom, y / yEnd));
    line(0, y, width, y);
  }
}

void drawMeadow() {
  noStroke();
  fill(cGround);
  beginShape();
  vertex(0, height);
  for (float x = 0; x <= width; x += 8) vertex(x, meadowTop(x));
  vertex(width, meadowTop(width));
  vertex(width, height);
  endShape(CLOSE);
}

// Zufällig verteilte Blumen auf der Wiese (einmalig erzeugt)
void makeFlowers() {
  randomSeed(3);
  int n = 70;
  flowers = new float[n][6];
  for (int i = 0; i < n; i++) {
    float x = random(panelW + 16, width - 16);
    float y = meadowTop(x) + random(8, height - groundY - 22);
    flowers[i] = new float[] { x, y, random(9, 16), random(-3, 3), random(2.4, 3.8), int(random(4)) };
  }
}

void drawFlower(float[] f) {
  float hx = f[0] + f[3], hy = f[1] - f[2], r = f[4];
  stroke(cLeaf);                                     // Stiel
  strokeWeight(1.3);
  line(f[0], f[1], hx, hy);
  noStroke();
  fill(cLeaf);                                       // kleines Blatt am Stiel
  ellipse(f[0] + f[3] * 0.5 + 2, f[1] - f[2] * 0.45, 4, 2);
  fill(petal[int(f[5])]);                            // fünf Blütenblätter
  for (int k = 0; k < 5; k++) {
    float ang = TWO_PI * k / 5 + f[3];
    ellipse(hx + cos(ang) * r * 0.9, hy + sin(ang) * r * 0.9, r * 1.3, r * 1.3);
  }
  fill(cText);                                       // Mitte
  ellipse(hx, hy, r * 0.9, r * 0.9);
}

// Blumen hinter (kleineres y) oder vor (größeres y) dem Baum zeichnen
void drawFlowers(boolean front) {
  for (float[] f : flowers) {
    if ((f[1] >= baseY) == front) drawFlower(f);
  }
}

// Jedes Segment ist ein Trapez, das von der Anfangs- zur Enddicke schmaler wird
void drawTrunk() {
  float base = sliders[4].value;
  noStroke();
  fill(red(cText), green(cText), blue(cText), 45);   // weicher Schatten am Fuß
  ellipse(sx(0), sy(0) + 2, base * 3.2 + 10, 9);
  fill(cStem);
  for (float[] g : plant.segs) {
    float ax = sx(g[0]), ay = sy(g[1]), ex = sx(g[2]), ey = sy(g[3]);
    float w0 = max(1, base * g[4]), w1 = max(1, base * g[5]);
    float dx = ex - ax, dy = ey - ay;
    float d = max(0.0001, sqrt(dx * dx + dy * dy));
    float nx = -dy / d * 0.5, ny = dx / d * 0.5;      // halbe Normale
    quad(ax + nx * w0, ay + ny * w0, ax - nx * w0, ay - ny * w0,
         ex - nx * w1, ey - ny * w1, ex + nx * w1, ey + ny * w1);
    ellipse(ex, ey, w1, w1);                           // runde Verbindung zum nächsten Segment
  }
}

void drawLeaves() {
  if (!leavesOn) return;
  noStroke();
  float lw = sliders[6].value, ll = sliders[7].value;
  for (int i = 0; i < plant.leaves.size(); i++) {
    float[] lf = plant.leaves.get(i);
    float v = (i * 37 % 100) / 100.0;                  // leichte Farbvariation pro Blatt
    fill(lerpColor(cLeafDark, cLeafLight, v));
    pushMatrix();
    translate(sx(lf[0]), sy(lf[1]));
    rotate(lf[2]);
    ellipse(0, -ll / 2, lw, ll);
    popMatrix();
  }
}

void draw() {
  for (Slider s : sliders) s.update();
  if (treeChanged()) rebuild();

  fit(refPlant, panelW + 40, 70, width - 40, baseY);
  drawSky();
  drawMeadow();
  drawFlowers(false);
  drawTrunk();
  drawLeaves();
  drawFlowers(true);
  drawPanel();
}

// ---------- Bedienfeld ----------

float resetX = 28, resetY = 630, resetW = 244, resetH = 40;

boolean overReset() {
  return mouseX >= resetX && mouseX <= resetX + resetW && mouseY >= resetY && mouseY <= resetY + resetH;
}

void section(String name, float y, float xEnd) {
  textFont(sansB);
  textSize(16);
  fill(cInk);
  textAlign(LEFT, BASELINE);
  text(name, 28, y);
  stroke(cInk, 140);
  strokeWeight(1);
  line(28 + textWidth(name) + 10, y - 5, xEnd, y - 5);
}

// Schalter rechts neben der Überschrift "BLÄTTER"
float togX = 228, togY = 487, togW = 44, togH = 22;

boolean overToggle() {
  return mouseX >= togX && mouseX <= togX + togW && mouseY >= togY && mouseY <= togY + togH;
}

void drawToggle() {
  noStroke();
  fill(leavesOn ? cInk : lerpColor(cPanel, cInk, 0.45));
  rect(togX, togY, togW, togH, togH / 2);
  fill(cPanel);
  float kx = leavesOn ? togX + togW - togH / 2 : togX + togH / 2;
  ellipse(kx, togY + togH / 2, togH - 6, togH - 6);
}

void drawPanel() {
  noStroke();
  fill(cPanel);
  rect(0, 0, panelW, height);
  for (int i = 0; i < 6; i++) {                        // Schatten zur Szene hin
    stroke(red(cInk), green(cInk), blue(cInk), 28 - i * 5);
    line(panelW + i, 0, panelW + i, height);
  }

  noStroke();
  fill(cInk);
  textFont(sansB);
  textSize(22);
  textAlign(LEFT, BASELINE);
  text("L-System Baum", 28, 46);

  section("STRUKTUR", 92, 272);
  section("STAMM", 370, 272);
  section("BLÄTTER", 504, 218);
  drawToggle();
  for (Slider s : sliders) s.show();
  if (!leavesOn) {                                     // Blatt-Regler abdunkeln
    noStroke();
    fill(cPanel, 150);
    rect(0, 516, panelW, 98);
  }

  // Zurücksetzen-Button
  noStroke();
  fill(cInk);
  rect(resetX, resetY, resetW, resetH, 10);
  fill(245, 238, 220);
  textFont(sansB);
  textSize(14);
  textAlign(CENTER, CENTER);
  text("Zurücksetzen", resetX + resetW / 2, resetY + resetH / 2 - 1);
  textAlign(LEFT, BASELINE);
}

class Slider {
  String label, unit;
  float x = 28, y, w = 244, minV, maxV, value, def;
  int dec;
  boolean dragging = false;

  Slider(String label, float y, float minV, float maxV, float value, int dec, String unit) {
    this.label = label;
    this.y = y;
    this.minV = minV;
    this.maxV = maxV;
    this.value = value;
    this.def = value;
    this.dec = dec;
    this.unit = unit;
  }

  boolean over() {
    return mouseX >= x - 10 && mouseX <= x + w + 10 && mouseY >= y - 14 && mouseY <= y + 14;
  }

  void update() {
    if (dragging) {
      value = constrain(map(mouseX, x, x + w, minV, maxV), minV, maxV);
      float m = pow(10, dec);
      value = round(value * m) / m;                     // auf Anzeigegenauigkeit runden
    }
  }

  String fmt() {
    if (unit.equals("%")) return round(value * 100) + " %";
    if (dec == 0) return str(int(value)) + unit;
    return nf(value, 1, dec) + unit;
  }

  void show() {
    textFont(sans);
    textSize(13);
    fill(cInk);
    textAlign(LEFT, BASELINE);
    text(label, x, y - 18);
    textAlign(RIGHT, BASELINE);
    text(fmt(), x + w, y - 18);
    textAlign(LEFT, BASELINE);

    float kx = map(value, minV, maxV, x, x + w);
    strokeWeight(6);
    stroke(lerpColor(cPanel, cInk, 0.45));             // Schiene
    line(x, y, x + w, y);
    stroke(cInk);                                      // gefüllter Teil
    line(x, y, kx, y);
    noStroke();
    fill(cInk);
    float r = dragging ? 20 : 16;
    ellipse(kx, y, r, r);
  }
}

// ---------- Eingaben (Bild wird nur bei Interaktion neu gezeichnet) ----------

void mousePressed() {
  if (overReset()) {
    for (Slider s : sliders) s.value = s.def;
    leavesOn = true;
    redraw();
    return;
  }
  if (overToggle()) {
    leavesOn = !leavesOn;
    redraw();
    return;
  }
  for (Slider s : sliders) {
    boolean leafSlider = (s == sliders[6] || s == sliders[7]);
    if (s.over() && (leavesOn || !leafSlider)) s.dragging = true;   // Blatt-Regler sind bei ausgeschalteten Blättern gesperrt
  }
  redraw();
}

void mouseDragged() {
  redraw();
}

void mouseReleased() {
  for (Slider s : sliders) s.dragging = false;
  redraw();
}

void mouseMoved() {
  boolean hot = overReset();
  for (Slider s : sliders) hot = hot || s.over();
  hot = hot || overToggle();
  cursor(hot ? HAND : ARROW);
}
