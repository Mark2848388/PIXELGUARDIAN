import 'dart:math' as m;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

const double S = 3, T = 48;
const int W = 64, H = 48;
Color c(int v) => Color(0xFF000000 | v);
typedef R = void Function(num, num, num, num, Color);

Future<ui.Image> mk(int w, int h, void Function(R) f) async {
  final rec = ui.PictureRecorder();
  final cv = Canvas(rec);
  final p = Paint()..isAntiAlias = false;
  f((x, y, a, b, col) {
    p.color = col;
    cv.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), a.toDouble(), b.toDouble()), p);
  });
  return rec.endRecording().toImage(w, h);
}

void line(R r, num x, num y, num a, int L, Color col, int t) {
  final d = a * m.pi / 180;
  for (var i = 0; i < L; i++) {
    r((x + m.cos(d) * i).round(), (y + m.sin(d) * i).round(), t, t, col);
  }
}

class Pal {
  final String name; final Color armor, trim, cape, hair, pants, boot, blade, belt; final int L, t; final bool helm;
  const Pal(this.name, this.armor, this.trim, this.cape, this.hair, this.pants, this.boot, this.blade, this.belt, this.L, this.t, this.helm);
}

final pals = [
  Pal('Рыцарь', c(0xc9a227), c(0xe8d07a), c(0x1d3f8c), c(0x222222), c(0x1d3f8c), c(0x8a6a1c), c(0xddddee), c(0x5a3b1a), 13, 1, false),
  Pal('Самурай', c(0x4f9a3a), c(0xe9822b), c(0xe9822b), c(0x181818), c(0x333333), c(0x5a3b1a), c(0xeeeeff), c(0xe9822b), 11, 1, true),
  Pal('Мечник', c(0x7a1f2b), c(0xb8b8c4), c(0x3a2a22), c(0xc9902f), c(0x2a2a2a), c(0x5a3b1a), c(0x2b2b33), c(0x5a3b1a), 13, 2, false),
];
const rest = -75.0;
const atkA = [-125.0, -70.0, 5.0, 55.0];

Future<ui.Image> hero(Pal p, String st, int f) => mk(32, 30, (r) {
      final bob = (st == 'idle' && f % 2 == 1) ? 1 : 0;
      final w = st == 'walk';
      final lx = w ? [-1, 0, 1, 0][f] : 0;
      final lf = (w && f % 2 == 0) ? 1 : 0;
      r(6, 11 + bob, 12, 10, p.cape);
      r(8, 11 + bob, 8, 8, p.armor);
      r(8, 17 + bob, 8, 2, p.belt);
      r(9 + lx, 19, 3, 6 - lf, p.pants);
      r(13 - lx, 19, 3, 6 - lf, p.pants);
      r(9 + lx, 25 - lf, 3, 2, p.boot);
      r(13 - lx, 25 - lf, 3, 2, p.boot);
      r(8, 3 + bob, 8, 8, c(0xf0b27a));
      r(7, 2 + bob, 10, 4, p.hair);
      r(7, 5 + bob, 1, 5, p.hair);
      r(13, 7 + bob, 1, 2, c(0x222222));
      if (p.helm) r(7, 1 + bob, 10, 3, p.armor);
      r(6, 11 + bob, 3, 3, p.trim);
      r(15, 11 + bob, 3, 3, p.trim);
      r(15, 12 + bob, 3, 4, p.armor);
      final a = st == 'atk' ? atkA[f] : rest;
      final hx = 17, hy = 15 + bob;
      line(r, hx, hy, a, 3, c(0x5a3b1a), 2);
      final d = a * m.pi / 180;
      line(r, hx + m.cos(d) * 3, hy + m.sin(d) * 3, a, p.L, p.blade, p.t);
      if (st == 'atk' && f >= 2) {
        for (var k = -30; k < 40; k += 6) {
          final q = (a + k) * m.pi / 180;
          r((hx + m.cos(q) * (p.L + 3)).round(), (hy + m.sin(q) * (p.L + 3)).round(), 1, 1, Colors.white);
        }
      }
    });

Future<ui.Image> boss(String st, int f) => mk(80, 64, (r) {
      final bob = (st == 'idle' && f % 2 == 1) ? 1 : 0;
      final lx = st == 'walk' ? [-2, 0, 2, 0][f] : 0;
      r(18, 22 + bob, 24, 24, c(0x2a1018));
      r(20, 24 + bob, 20, 20, c(0x5c1620));
      r(20, 40 + bob, 20, 4, c(0xc9a227));
      r(20 + lx, 46, 7, 12, c(0x2a1018));
      r(33 - lx, 46, 7, 12, c(0x2a1018));
      r(18 + lx, 57, 10, 4, c(0x111111));
      r(32 - lx, 57, 10, 4, c(0x111111));
      r(16, 22 + bob, 8, 6, c(0x8a8a99));
      r(36, 22 + bob, 8, 6, c(0x8a8a99));
      r(22, 6 + bob, 16, 16, c(0x8a2020));
      r(21, 5 + bob, 18, 6, c(0x3a3a45));
      for (final h in [[16, 0, 4, 10], [40, 0, 4, 10], [14, 0, 3, 4], [43, 0, 3, 4]]) {
        r(h[0], h[1] + bob, h[2], h[3], c(0xe8e0c8));
      }
      r(25, 14 + bob, 4, 3, c(0xffd23a));
      r(32, 14 + bob, 4, 3, c(0xffd23a));
      r(27, 19 + bob, 6, 2, c(0x111111));
      if (st == 'cast') {
        r(12, 12 + bob - f, 5, 14, c(0x5c1620));
        r(43, 12 + bob - f, 5, 14, c(0x5c1620));
        final s = 2 + f * 2;
        r(28 - s / 2 + 2, 2 - s + bob, s, s, c(0xff9a1f));
        r(28 - s / 4 + 2, 2 - s * .75 + bob, s / 2, s / 2, c(0xffe28a));
        return;
      }
      r(40, 26 + bob, 5, 10, c(0x5c1620));
      r(14, 26 + bob, 5, 10, c(0x5c1620));
      const A = [-130.0, -150.0, 15.0, 70.0];
      final a = st == 'slam' ? A[f] : -60.0;
      line(r, 45, 36 + bob, a, 30, c(0xcfd3e0), 3);
      line(r, 45, 36 + bob, a + 180, 4, c(0x5a3b1a), 3);
      if (st == 'slam' && f >= 2) {
        for (var k = 0; k < 12; k++) r(50 + k * 2, 52 + (k % 3), 2, 2, c(0xffb347));
      }
    });

double hs(num x, num y) {
  final n = m.sin(x * 127.1 + y * 311.7) * 43758.5;
  return n - n.floorToDouble();
}

int tile(int x, int y) {
  if (x < 1 || y < 1 || x >= W - 1 || y >= H - 1) return 2;
  if ((x - 50).abs() < 7 && (y - 36).abs() < 6) return 0;
  if ((x - 8).abs() < 4 && (y - 8).abs() < 4) return 0;
  if (m.sin(x * .3) + m.cos(y * .35) > 1.55) return 2;
  final h = hs(x, y);
  if (h > .9) return 3;
  if (h < .1) return 4;
  return 0;
}

bool solid(double px, double py) {
  final t = tile((px / T).floor(), (py / T).floor());
  return t == 2 || t == 3;
}

class Ent { double x, y; int face = 1; Ent(this.x, this.y); }
class Mob extends Ent { double hp = 40, ts = 0, hurt = 0, cd = 0; int id; Mob(super.x, super.y, this.id); }

Future<ui.Image> slime(int f) => mk(24, 20, (r) {
      final q = f % 2;
      r(3, 8 + q, 18, 10 - q, c(0x3fbf5f));
      r(5, 6 + q, 14, 3, c(0x3fbf5f));
      r(7, 5 + q, 6, 2, c(0x8af0a0));
      r(7, 10 + q, 3, 3, c(0x111111));
      r(14, 10 + q, 3, 3, c(0x111111));
      r(8, 11 + q, 1, 1, Colors.white);
      r(15, 11 + q, 1, 1, Colors.white);
      r(3, 17, 18, 2, c(0x2a8a44));
    });

Uint8List wav(List<double> fr, double dur, {double vol = .3, bool noise = false, bool music = false}) {
  const sr = 22050;
  final n = (sr * dur).floor();
  final d = ByteData(44 + n * 2);
  void w(int o, String t) { for (var i = 0; i < 4; i++) { d.setUint8(o + i, t.codeUnitAt(i)); } }
  w(0, 'RIFF'); d.setUint32(4, 36 + n * 2, Endian.little); w(8, 'WAVE'); w(12, 'fmt ');
  d.setUint32(16, 16, Endian.little); d.setUint16(20, 1, Endian.little); d.setUint16(22, 1, Endian.little);
  d.setUint32(24, sr, Endian.little); d.setUint32(28, sr * 2, Endian.little); d.setUint16(32, 2, Endian.little);
  d.setUint16(34, 16, Endian.little); w(36, 'data'); d.setUint32(40, n * 2, Endian.little);
  final rnd = m.Random(1);
  for (var i = 0; i < n; i++) {
    final f = fr[(i * fr.length / n).floor()];
    final env = music ? 1 - ((i * fr.length / n) % 1) * .7 : 1 - i / n;
    final v = noise ? rnd.nextDouble() * 2 - 1 : (((i / sr) * f) % 1 < .5 ? 1.0 : -1.0);
    d.setInt16(44 + i * 2, (v * env * vol * 32767).round(), Endian.little);
  }
  return d.buffer.asUint8List();
}

class Sfx {
  bool on = true;
  final ps = List.generate(5, (_) => AudioPlayer());
  final mus = AudioPlayer();
  int k = 0;
  final d = <String, Uint8List>{
    'hit': wav([300, 150], .12), 'swing': wav([600, 900], .08, vol: .15),
    'hurt': wav([200, 120, 80], .25, noise: true), 'shoot': wav([500, 350, 200], .2, vol: .2),
    'slam': wav([90, 70, 50, 40], .4, noise: true, vol: .5), 'kill': wav([400, 600, 800], .2),
    'win': wav([523, 659, 784, 1047], .8),
  };
  void play(String n) { if (!on) return; try { ps[k++ % ps.length].play(BytesSource(d[n]!)); } catch (_) {} }
  void music() {
    try {
      mus.setReleaseMode(ReleaseMode.loop);
      if (on) mus.play(BytesSource(wav([262, 330, 392, 330, 262, 330, 392, 523], 2.4, vol: .08, music: true)));
    } catch (_) {}
  }
  void toggle() { on = !on; on ? music() : mus.stop(); }
}
class Proj { double x, y, vx, vy, l = 3; Proj(this.x, this.y, this.vx, this.vy); }
class Ring { double x, y, r = 0; Ring(this.x, this.y); }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: GamePage()));
}

class GamePage extends StatefulWidget { const GamePage({super.key}); @override State<GamePage> createState() => _GS(); }

class _GS extends State<GamePage> with SingleTickerProviderStateMixin {
  final n = ValueNotifier<int>(0);
  late final Ticker tk;
  Duration last = Duration.zero;
  bool ready = false;
  final hsp = <List<Map<String, List<ui.Image>>>>[];
  final heroS = <Map<String, List<ui.Image>>>[];
  final bossS = <String, List<ui.Image>>{};
  String scene = 'load';
  double prog = 0, saveT = 0;
  final mobs = <Mob>[];
  final slimeS = <ui.Image>[];
  Set<int> deadIds = {};
  int kills = 0;
  bool hasSave = false;
  SharedPreferences? sp;
  final sfx = Sfx();
  List<String> dlg = [];
  int di = 0;
  int hi = 0;
  double t = 0;
  final h = Ent(8.5 * T, 8.5 * T), b = Ent(50.5 * T, 36.5 * T);
  double hp = 100, hAt = -1, hCd = 0, bhp = 600, bTs = 0, bCast = 3, bHurt = 0;
  bool moving = false, hitDone = false, dead = false, win = false, aggro = false, bHit = false;
  String bSt = 'idle';
  final proj = <Proj>[];
  final rings = <Ring>[];
  Offset? joyO, joyV;
  final fp = Paint()..isAntiAlias = false;

  @override
  void initState() {
    super.initState();
    _load();
    tk = createTicker((e) {
      final dt = m.min(.05, (e - last).inMicroseconds / 1e6);
      last = e;
      if (ready) update(dt);
      n.value++;
    })..start();
  }

  Future<void> _load() async {
    final tot = pals.length * 10 + 16;
    var k = 0;
    void tick() { k++; prog = k / tot; if (k % 6 == 0) setState(() {}); }
    for (final p in pals) {
      final mp = <String, List<ui.Image>>{'idle': [], 'walk': [], 'atk': []};
      for (final e in {'idle': 2, 'walk': 4, 'atk': 4}.entries) {
        for (var f = 0; f < e.value; f++) { mp[e.key]!.add(await hero(p, e.key, f)); tick(); }
      }
      heroS.add(mp);
    }
    for (final st in ['idle', 'walk', 'slam', 'cast']) {
      bossS[st] = [];
      for (var f = 0; f < (st == 'idle' ? 2 : 4); f++) { bossS[st]!.add(await boss(st, f)); tick(); }
    }
    for (var f = 0; f < 2; f++) { slimeS.add(await slime(f)); tick(); }
    sp = await SharedPreferences.getInstance();
    hasSave = sp!.containsKey('hp');
    await Future.delayed(const Duration(milliseconds: 700));
    prog = 1;
    setState(() { ready = true; scene = 'menu'; });
  }

  @override
  void dispose() { tk.dispose(); super.dispose(); }

  static const intro = [
    'Королевство Эльдория. Древняя Печать веками держала Демона-рыцаря в заточении.',
    'Но Печать слабеет: слизни-стражи, питавшиеся её силой, расплодились по всем землям.',
    'Ты — один из трёх Хранителей. Уничтожь 8 слизней, чтобы ослабить связь Демона с миром.',
    'Тогда он проснётся... и настанет твой час.'
  ];
  void showDlg(List<String> l) { dlg = l; di = 0; scene = 'story'; setState(() {}); }
  void spawn() {
    mobs.clear();
    for (var y = 2; y < H - 2; y++) {
      for (var x = 2; x < W - 2; x++) {
        final id = y * W + x;
        if (hs(x * 1.7, y * 2.3) > .98 && tile(x, y) == 0 && (x - 8).abs() + (y - 8).abs() > 9 && (x - 50).abs() > 8 && !deadIds.contains(id)) {
          mobs.add(Mob(x * T + T / 2, y * T + T / 2, id));
        }
      }
    }
  }
  void resetBoss() { b.x = 50.5 * T; b.y = 36.5 * T; aggro = false; setB('idle'); proj.clear(); rings.clear(); win = false; dead = false; }
  void newGame() {
    deadIds = {}; kills = 0; hp = 100; bhp = 600; h.x = 8.5 * T; h.y = 8.5 * T; hi = 0;
    resetBoss(); spawn(); sfx.music(); showDlg(intro);
  }
  void contGame() {
    final q = sp!;
    h.x = q.getDouble('x') ?? 8.5 * T; h.y = q.getDouble('y') ?? 8.5 * T;
    hp = q.getDouble('hp') ?? 100; bhp = q.getDouble('bhp') ?? 600; hi = q.getInt('hi') ?? 0; kills = q.getInt('kills') ?? 0;
    deadIds = (q.getStringList('dead') ?? []).map(int.parse).toSet();
    resetBoss(); spawn(); sfx.music(); scene = 'game'; setState(() {});
  }
  void save() {
    final q = sp;
    if (q == null || win || dead) return;
    q.setDouble('x', h.x); q.setDouble('y', h.y); q.setDouble('hp', hp); q.setDouble('bhp', bhp);
    q.setInt('hi', hi); q.setInt('kills', kills); q.setStringList('dead', deadIds.map((e) => '$e').toList());
  }
  void hitMobs() {
    for (final o in mobs) {
      if (m.sqrt(m.pow(o.x - h.x, 2) + m.pow(o.y - h.y, 2)) < 90) { o.hp -= [22, 18, 30][hi]; o.hurt = .15; }
    }
    final k = mobs.where((o) => o.hp <= 0).toList();
    for (final o in k) { deadIds.add(o.id); kills++; hp = m.min(100, hp + 10); sfx.play('kill'); }
    mobs.removeWhere((o) => o.hp <= 0);
    if (k.isNotEmpty) {
      save();
      if (kills == 8) showDlg(['Печать треснула! На юго-востоке пробудился Демон-рыцарь.', 'Иди на арену и покончи с ним. Удачи, Хранитель.']);
    }
  }
  void atk() { if (scene == 'game' && hAt < 0 && hCd <= 0) { hAt = 0; hCd = .5; hitDone = false; sfx.play('swing'); } }
  void setB(String s) { bSt = s; bTs = 0; bHit = false; }

  void move(Ent o, double dx, double dy, double r) {
    if (!solid(o.x + dx + dx.sign * r, o.y)) o.x += dx;
    if (!solid(o.x, o.y + dy + dy.sign * r * .6)) o.y += dy;
  }

  void hurt(double v) {
    hp -= v; sfx.play('hurt');
    if (hp <= 0 && !dead) {
      dead = true;
      Future.delayed(const Duration(milliseconds: 1800), () {
        hp = 100; dead = false; h.x = 8.5 * T; h.y = 8.5 * T;
        bhp = m.max(bhp, 600); aggro = false; b.x = 50.5 * T; b.y = 36.5 * T; setB('idle'); proj.clear();
      });
    }
  }

  bool key(LogicalKeyboardKey k) => HardwareKeyboard.instance.isLogicalKeyPressed(k);

  void update(double dt) {
    t += dt;
    if (scene != 'game' || win || dead) return;
    saveT += dt;
    if (saveT > 5) { saveT = 0; save(); }
    double dx = (key(LogicalKeyboardKey.keyD) || key(LogicalKeyboardKey.arrowRight) ? 1 : 0) - (key(LogicalKeyboardKey.keyA) || key(LogicalKeyboardKey.arrowLeft) ? 1 : 0);
    double dy = (key(LogicalKeyboardKey.keyS) || key(LogicalKeyboardKey.arrowDown) ? 1 : 0) - (key(LogicalKeyboardKey.keyW) || key(LogicalKeyboardKey.arrowUp) ? 1 : 0);
    if (joyV != null && joyV!.distance > 10) { dx = joyV!.dx; dy = joyV!.dy; }
    final mg = m.sqrt(dx * dx + dy * dy);
    moving = mg > 0 && hAt < 0;
    if (mg > 0 && hAt < 0) {
      move(h, dx / mg * 170 * dt, dy / mg * 170 * dt, 12);
      if (dx.abs() > .3) h.face = dx > 0 ? 1 : -1;
    }
    hCd -= dt;
    if (hAt >= 0) {
      hAt += dt;
      if (hAt > .32) { hAt = -1; }
      else if (!hitDone && hAt > .16) {
        hitDone = true; sfx.play('hit'); hitMobs();
        final d = m.sqrt(m.pow(b.x - h.x, 2) + m.pow(b.y - h.y, 2));
        if (d < 110 && bhp > 0 && kills >= 8) {
          bhp -= [22, 18, 30][hi]; bHurt = .15; aggro = true;
          if (bhp <= 0) { bhp = 0; win = true; sfx.play('win'); sp?.clear(); hasSave = false; }
        }
      }
    }
    for (final o in mobs) {
      final dd = m.sqrt(m.pow(h.x - o.x, 2) + m.pow(h.y - o.y, 2));
      if (o.hurt > 0) o.hurt -= dt;
      o.cd -= dt;
      if (dd < 280 && dd > 26) { final a = m.atan2(h.y - o.y, h.x - o.x); move(o, m.cos(a) * 70 * dt, m.sin(a) * 70 * dt, 14); }
      if (dd < 30 && o.cd <= 0) { o.cd = 1; hurt(8); }
    }
    final d = m.sqrt(m.pow(h.x - b.x, 2) + m.pow(h.y - b.y, 2));
    if (d < 520 && kills >= 8) aggro = true;
    bTs += dt;
    if (bHurt > 0) bHurt -= dt;
    if (aggro && bhp > 0) {
      b.face = h.x > b.x ? 1 : -1;
      if (bSt == 'idle' || bSt == 'walk') {
        bCast -= dt;
        if (bCast <= 0) { setB('cast'); bCast = 5; }
        else if (d < 120) { setB('slam'); }
        else {
          bSt = 'walk';
          final a = m.atan2(h.y - b.y, h.x - b.x);
          move(b, m.cos(a) * 90 * dt, m.sin(a) * 90 * dt, 20);
        }
      } else if (bSt == 'slam') {
        if (bTs > .55 && !bHit) {
          bHit = true;
          sfx.play('slam'); rings.add(Ring(b.x + b.face * 50, b.y + 20));
          if (m.sqrt(m.pow(h.x - b.x - b.face * 50, 2) + m.pow(h.y - b.y - 20, 2)) < 110) hurt(20);
        }
        if (bTs > .8) setB('idle');
      } else if (bSt == 'cast') {
        if (bTs > .7 && !bHit) {
          bHit = true;
          final a = m.atan2(h.y - b.y, h.x - b.x);
          sfx.play('shoot');
          for (final o in [-.3, 0.0, .3]) { proj.add(Proj(b.x, b.y - 30, m.cos(a + o) * 240, m.sin(a + o) * 240)); }
        }
        if (bTs > 1) setB('idle');
      }
    }
    for (final p in proj) {
      p.x += p.vx * dt; p.y += p.vy * dt; p.l -= dt;
      if ((p.x - h.x).abs() < 20 && (p.y - h.y).abs() < 20) { p.l = 0; hurt(10); }
      if (solid(p.x, p.y)) p.l = 0;
    }
    proj.removeWhere((p) => p.l <= 0);
    for (final r in rings) { r.r += 260 * dt; }
    rings.removeWhere((r) => r.r >= 110);
  }

  void txt(Canvas cv, String s, double x, double y, double sz, {bool center = false}) {
    final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(color: Colors.white, fontSize: sz, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    tp.paint(cv, Offset(center ? x - tp.width / 2 : x, y));
  }

  void rect(Canvas cv, double x, double y, double w, double hh, Color col) { fp.color = col; cv.drawRect(Rect.fromLTWH(x, y, w, hh), fp); }

  void spr(Canvas cv, ui.Image img, Ent o, double sc, double shw, double cx, double cy, {bool flash = false}) {
    final w = img.width * sc, hh = img.height * sc;
    fp.color = const Color(0x44000000);
    cv.drawOval(Rect.fromCenter(center: Offset(o.x - cx, o.y - cy + 4), width: shw * 2, height: shw * .8), fp);
    cv.save();
    cv.translate((o.x - cx).floorToDouble(), (o.y - cy).floorToDouble());
    cv.scale(o.face.toDouble(), 1);
    final ip = Paint()..filterQuality = FilterQuality.none..color = Color.fromRGBO(255, 255, 255, flash ? .5 : 1);
    cv.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), Rect.fromLTWH(-w / 2, -hh + 6, w, hh), ip);
    cv.restore();
  }

  void paint(Canvas cv, Size sz) {
    final s = m.min(sz.width / 960, sz.height / 540);
    cv.translate((sz.width - 960 * s) / 2, (sz.height - 540 * s) / 2);
    cv.scale(s);
    cv.clipRect(const Rect.fromLTWH(0, 0, 960, 540));
    rect(cv, 0, 0, 960, 540, Colors.black);
    if (scene == 'load' || !ready) {
      txt(cv, 'PIXEL GUARDIANS', 480, 190, 40, center: true);
      rect(cv, 280, 300, 400, 18, const Color(0xff222222));
      rect(cv, 282, 302, 396 * prog, 14, c(0x55cc55));
      txt(cv, 'Загрузка... ${(prog * 100).round()}%', 480, 326, 16, center: true);
      return;
    }
    if (scene == 'menu') { rect(cv, 0, 0, 960, 540, c(0x0b1020)); return; }
    final cx = (h.x - 480).clamp(0.0, W * T - 960), cy = (h.y - 270).clamp(0.0, H * T - 540);
    final x0 = (cx / T).floor(), x1 = ((cx + 960) / T).floor(), y0 = (cy / T).floor(), y1 = ((cy + 540) / T).floor();
    final layers = <MapEntry<double, void Function()>>[];
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        if (x < 0 || y < 0 || x >= W || y >= H) continue;
        final tt = tile(x, y), hh = hs(x + 9, y + 4);
        final X = (x * T - cx).floorToDouble(), Y = (y * T - cy).floorToDouble();
        rect(cv, X, Y, T, T, tt == 2 ? (((x + y) & 1) == 1 ? c(0x2f6fb5) : c(0x3a7cc4)) : (hh > .5 ? c(0x5aa34a) : c(0x63ad52)));
        if (tt == 2) continue;
        if (hh > .7) rect(cv, X + 10, Y + 14, 3, 6, c(0x4a8d3c));
        if (hh < .3) rect(cv, X + 30, Y + 28, 3, 6, c(0x4a8d3c));
        if (tt == 4) { rect(cv, X + 14, Y + 18, 6, 6, Colors.white); rect(cv, X + 16, Y + 20, 3, 3, c(0xff5e7e)); }
        if (tt == 3) {
          layers.add(MapEntry(y * T + T, () {
            rect(cv, X + 6, Y + 36, 36, 8, const Color(0x30000000));
            rect(cv, X + 18, Y + 24, 12, 20, c(0x6b4423));
            rect(cv, X + 4, Y + 4, 40, 26, c(0x2f7d32));
            rect(cv, X + 10, Y, 28, 14, c(0x3c9a40));
          }));
        }
      }
    }
    for (final r in rings) {
      fp.style = PaintingStyle.stroke; fp.strokeWidth = 6; fp.color = c(0xffb347);
      cv.drawOval(Rect.fromCenter(center: Offset(r.x - cx, r.y - cy), width: r.r * 2, height: r.r * 1.2), fp);
      fp.style = PaintingStyle.fill;
    }
    final hs0 = heroS[hi];
    layers.add(MapEntry(h.y, () {
      List<ui.Image> a; int i;
      if (hAt >= 0) { a = hs0['atk']!; i = m.min(3, (hAt / .08).floor()); }
      else if (moving) { a = hs0['walk']!; i = (t * 9).floor() % 4; }
      else { a = hs0['idle']!; i = (t * 2).floor() % 2; }
      spr(cv, a[i], h, S, 26, cx, cy, flash: dead);
    }));
    layers.add(MapEntry(b.y, () {
      if (bhp <= 0) return;
      final a = bossS[bSt]!;
      final i = bSt == 'idle' ? (t * 2).floor() % 2 : bSt == 'walk' ? (t * 6).floor() % 4 : m.min(3, (bTs / (bSt == 'slam' ? .2 : .25)).floor());
      spr(cv, a[i], b, 4, 60, cx, cy, flash: bHurt > 0);
    }));
    for (final o in mobs) {
      if ((o.x - cx).abs() > 1000 || (o.y - cy).abs() > 600) continue;
      layers.add(MapEntry(o.y, () { o.face = h.x > o.x ? 1 : -1; spr(cv, slimeS[(t * 4 + o.id).floor() % 2], o, 3, 20, cx, cy, flash: o.hurt > 0); }));
    }
    layers.sort((a, b) => a.key.compareTo(b.key));
    for (final l in layers) { l.value(); }
    for (final p in proj) {
      rect(cv, p.x - cx - 10, p.y - cy - 10, 20, 20, c(0xff6a00));
      rect(cv, p.x - cx - 5, p.y - cy - 5, 10, 10, c(0xffe28a));
    }
    rect(cv, 10, 10, 210, 22, const Color(0xaa000000));
    rect(cv, 14, 14, m.max(0, hp) * 2, 14, c(0xdd2222));
    txt(cv, pals[hi].name, 14, 36, 14);
    txt(cv, kills < 8 ? 'Цель: слизни $kills/8' : bhp > 0 ? 'Цель: победи Демона (юго-восток)' : 'Королевство спасено!', 14, 56, 14);
    if (aggro && bhp > 0) {
      rect(cv, 280, 500, 400, 22, const Color(0xaa000000));
      rect(cv, 284, 504, bhp / 600 * 392, 14, c(0xaa22cc));
      txt(cv, 'Демон-рыцарь', 290, 502, 13);
    }
    if (win) txt(cv, 'ПОБЕДА!', 480, 250, 40, center: true);
    if (dead) txt(cv, 'Ты пал... возрождение', 480, 250, 32, center: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is KeyDownEvent) {
            if (e.logicalKey == LogicalKeyboardKey.space) atk();
            if (e.logicalKey == LogicalKeyboardKey.digit1) hi = 0;
            if (e.logicalKey == LogicalKeyboardKey.digit2) hi = 1;
            if (e.logicalKey == LogicalKeyboardKey.digit3) hi = 2;
          }
          return KeyEventResult.handled;
        },
        child: LayoutBuilder(builder: (ctx, bc) {
          return Stack(children: [
            Listener(
              onPointerDown: (e) { if (e.position.dx < bc.maxWidth / 2) { joyO = e.position; joyV = Offset.zero; } },
              onPointerMove: (e) { if (joyO != null) joyV = e.position - joyO!; },
              onPointerUp: (e) { joyO = null; joyV = null; },
              child: SizedBox.expand(child: CustomPaint(painter: _P(this, n))),
            ),
            Positioned(right: 24, bottom: 24, child: GestureDetector(onTapDown: (_) => atk(), child: Container(width: 84, height: 84, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black45, border: Border.all(color: Colors.white54, width: 2)), child: const Text('АТАКА', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
            Positioned(top: 8, right: 12, child: TextButton(onPressed: () => hi = (hi + 1) % 3, style: TextButton.styleFrom(backgroundColor: Colors.black45), child: const Text('Сменить героя', style: TextStyle(color: Colors.white)))),
            if (win) Positioned(left: 0, right: 0, bottom: 40, child: Center(child: ElevatedButton(onPressed: () => setState(() { scene = 'menu'; win = false; }), child: const Text('В главное меню')))),
            if (scene == 'story') Positioned(left: 40, right: 40, bottom: 20, child: GestureDetector(onTap: () => setState(() { di++; if (di >= dlg.length) scene = 'game'; }), child: Container(padding: const EdgeInsets.all(16), color: Colors.black87, child: Text('${dlg[di]}\n\n(тап — дальше)', style: const TextStyle(color: Colors.white, fontSize: 16))))),
            if (scene == 'menu') Container(color: const Color(0xFF0B1020), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('PIXEL GUARDIANS', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: newGame, child: const Text('Новая игра')),
              if (hasSave) ElevatedButton(onPressed: contGame, child: const Text('Продолжить')),
              ElevatedButton(onPressed: () => setState(() => sfx.toggle()), child: Text(sfx.on ? 'Звук: вкл' : 'Звук: выкл')),
            ]))),
          ]);
        }),
      ),
    );
  }
}

class _P extends CustomPainter {
  final _GS g;
  _P(this.g, ValueNotifier<int> n) : super(repaint: n);
  @override
  void paint(Canvas canvas, Size size) => g.paint(canvas, size);
  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}
