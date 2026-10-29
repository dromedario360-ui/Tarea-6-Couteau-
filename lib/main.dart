import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ====== EDITA ESTOS DATOS ======
const String wpSite = 'https://techcrunch.com'; // pagina WordPress (publicala en el foro)
const String miNombre = 'Deury De La Cruz';
const String miCorreo = 'tu_correo_real@gmail.com';
const String miTelefono = '+1 809 555 1234';
const String miLinkedin = 'https://linkedin.com/in/tu_usuario_de_linkedin';
const String miGithub = 'https://github.com/tu_usuario_de_github';
// ================================

Future<dynamic> getJson(String url) async {
  final r = await http.get(Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json'});
  if (r.statusCode != 200) throw Exception('Error ${r.statusCode}');
  return jsonDecode(utf8.decode(r.bodyBytes));
}

Future<void> abrir(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Widget estado(AsyncSnapshot s, Widget Function(dynamic) ok) {
  if (s.connectionState != ConnectionState.done) {
    return const Center(child: CircularProgressIndicator());
  }
  if (s.hasError) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(16), child: Text('Error: ${s.error}')));
  }
  return ok(s.data);
}

String limpiar(String s) {
  var t = s.replaceAll(RegExp(r'<[^>]*>'), '');
  t = t.replaceAllMapped(
      RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)));
  return t
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .trim();
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Caja de Herramientas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
        home: const Home(),
      );
}

class _Item {
  final String t;
  final IconData i;
  final Widget p;
  _Item(this.t, this.i, this.p);
}

// ---------- 1. INICIO (foto caja de herramientas) ----------
class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    final items = <_Item>[
      _Item('Genero por nombre', Icons.wc, const GenderPage()),
      _Item('Persona aleatoria', Icons.person_search, const RandomUserPage()),
      _Item('Universidades', Icons.school, const UniversitiesPage()),
      _Item('Clima RD', Icons.wb_sunny, const WeatherPage()),
      _Item('Pokemon', Icons.catching_pokemon, const PokemonPage()),
      _Item('Noticias WordPress', Icons.article, const WordPressPage()),
      _Item('Acerca de', Icons.info, const AboutPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Caja de Herramientas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/caja.jpg',
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200, child: Icon(Icons.handyman, size: 120)),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: items
                .map((e) => Card(
                      child: InkWell(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => e.p)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(e.i, size: 48),
                            const SizedBox(height: 8),
                            Text(e.t, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------- 2. GENERO ----------
class GenderPage extends StatefulWidget {
  const GenderPage({super.key});
  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  final c = TextEditingController();
  String? gender;
  double prob = 0;
  bool done = false, loading = false;
  String? error;

  Future<void> predecir() async {
    final n = c.text.trim();
    if (n.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
      done = false;
    });
    try {
      final d = await getJson(
          'https://api.genderize.io/?name=${Uri.encodeQueryComponent(n)}');
      setState(() {
        gender = d['gender'];
        prob = ((d['probability'] ?? 0) as num).toDouble();
        done = true;
      });
    } catch (e) {
      setState(() => error = '$e');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final esM = gender == 'male';
    return Scaffold(
      backgroundColor:
          !done ? null : (esM ? Colors.blue.shade200 : Colors.pink.shade100),
      appBar: AppBar(title: const Text('Predecir genero')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: c,
              decoration: const InputDecoration(
                  labelText: 'Nombre', border: OutlineInputBorder()),
              onSubmitted: (_) => predecir(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: predecir, child: const Text('Predecir')),
            const SizedBox(height: 24),
            if (loading) const CircularProgressIndicator(),
            if (error != null) Text('Error: $error'),
            if (done) ...[
              Icon(esM ? Icons.male : Icons.female,
                  size: 140,
                  color: esM ? Colors.blue.shade900 : Colors.pink.shade700),
              Text(
                  esM
                      ? 'Masculino'
                      : (gender == 'female' ? 'Femenino' : 'Desconocido'),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              Text('Probabilidad: ${(prob * 100).toStringAsFixed(0)}%'),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------- 3. PERSONA ALEATORIA ----------
class RandomUserPage extends StatefulWidget {
  const RandomUserPage({super.key});
  @override
  State<RandomUserPage> createState() => _RandomUserPageState();
}

class _RandomUserPageState extends State<RandomUserPage> {
  static const url = 'https://randomuser.me/api/?results=1';
  late Future<dynamic> f;
  @override
  void initState() {
    super.initState();
    f = getJson(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persona aleatoria')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => f = getJson(url)),
        child: const Icon(Icons.refresh),
      ),
      body: FutureBuilder(
        future: f,
        builder: (context, s) => estado(s, (d) {
          final u = d['results'][0];
          final fecha = DateTime.parse(u['dob']['date']).toLocal();
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                    radius: 70,
                    backgroundImage: NetworkImage(u['picture']['large'])),
                const SizedBox(height: 16),
                Text('Nombre: ${u['name']['first']}',
                    style: const TextStyle(fontSize: 22)),
                Text('Apellido: ${u['name']['last']}',
                    style: const TextStyle(fontSize: 22)),
                Text('Nacimiento: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                    style: const TextStyle(fontSize: 18)),
                Text('Edad: ${u['dob']['age']} anos',
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------- 4. UNIVERSIDADES ----------
class UniversitiesPage extends StatefulWidget {
  const UniversitiesPage({super.key});
  @override
  State<UniversitiesPage> createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends State<UniversitiesPage> {
  final c = TextEditingController(text: 'Dominican Republic');
  List lista = [];
  bool loading = false;
  String? error;

  Future<void> buscar() async {
    final n = c.text.trim();
    if (n.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
      lista = [];
    });
    try {
      final d = await getJson(
          'https://adamix.net/proxy.php?country=${Uri.encodeQueryComponent(n)}');
      setState(() => lista = d is List ? d : []);
    } catch (e) {
      setState(() => error = '$e');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Universidades')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: c,
                  decoration: const InputDecoration(
                      labelText: 'Pais (en ingles)',
                      border: OutlineInputBorder()),
                  onSubmitted: (_) => buscar(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: buscar, child: const Text('Buscar')),
            ]),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null) Text('Error: $error'),
          Expanded(
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final u = lista[i];
                final doms = (u['domains'] as List?) ?? [];
                final webs = (u['web_pages'] as List?) ?? [];
                final web = webs.isNotEmpty ? webs[0].toString() : null;
                return Card(
                  child: ListTile(
                    title: Text('${u['name']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dominio: ${doms.join(', ')}'),
                        if (web != null)
                          InkWell(
                            onTap: () => abrir(web),
                            child: Text(web,
                                style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 5. CLIMA RD ----------
String descClima(int c) {
  if (c == 0) return 'Despejado';
  if (c <= 3) return 'Parcialmente nublado';
  if (c == 45 || c == 48) return 'Niebla';
  if (c >= 51 && c <= 57) return 'Llovizna';
  if (c >= 61 && c <= 67) return 'Lluvia';
  if (c >= 80 && c <= 82) return 'Aguaceros';
  if (c >= 95) return 'Tormenta electrica';
  return 'Variable';
}

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});
  @override
  Widget build(BuildContext context) {
    final f = getJson(
        'https://api.open-meteo.com/v1/forecast?latitude=18.4861&longitude=-69.9312'
        '&current=temperature_2m,weather_code'
        '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code'
        '&timezone=America%2FSanto_Domingo&forecast_days=1');
    return Scaffold(
      appBar: AppBar(title: const Text('Clima en RD')),
      body: FutureBuilder(
        future: f,
        builder: (context, s) => estado(s, (d) {
          final cur = d['current'];
          final day = d['daily'];
          final code = ((day['weather_code'][0] ?? 0) as num).toInt();
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Santo Domingo, Republica Dominicana',
                    style: TextStyle(fontSize: 18)),
                Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                const Icon(Icons.wb_cloudy, size: 100),
                Text('${cur['temperature_2m']} C',
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold)),
                Text(descClima(code), style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 12),
                Text(
                    'Maxima: ${day['temperature_2m_max'][0]} C   Minima: ${day['temperature_2m_min'][0]} C'),
                Text(
                    'Probabilidad de lluvia: ${day['precipitation_probability_max'][0] ?? 0}%'),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------- 6. POKEMON ----------
class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});
  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  final c = TextEditingController();
  final player = AudioPlayer();
  Map? p;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> buscar() async {
    final n = c.text.trim().toLowerCase();
    if (n.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
      p = null;
    });
    try {
      final d = await getJson('https://pokeapi.co/api/v2/pokemon/$n');
      setState(() => p = d);
    } catch (e) {
      setState(() => error = 'No se encontro el pokemon ($e)');
    }
    setState(() => loading = false);
  }

  Future<void> sonido(String url) async {
    try {
      await player.stop();
      await player.play(UrlSource(url));
    } catch (e) {
      setState(() => error = 'No se pudo reproducir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? detalle;
    if (p != null) {
      final img = p!['sprites']?['other']?['official-artwork']?['front_default'] ??
          p!['sprites']?['front_default'];
      final hab = (p!['abilities'] as List)
          .map((a) => a['ability']['name'])
          .join(', ');
      final cry = p!['cries']?['latest'];
      detalle = Column(
        children: [
          if (img != null) Image.network(img, height: 220),
          Text('${p!['name']}'.toUpperCase(),
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Experiencia base: ${p!['base_experience']}',
              style: const TextStyle(fontSize: 18)),
          Text('Habilidades: $hab', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          if (cry != null)
            ElevatedButton.icon(
              onPressed: () => sonido(cry),
              icon: const Icon(Icons.volume_up),
              label: const Text('Reproducir sonido'),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pokemon')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: c,
            decoration: const InputDecoration(
                labelText: 'Nombre del pokemon (ej: pikachu)',
                border: OutlineInputBorder()),
            onSubmitted: (_) => buscar(),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: buscar, child: const Text('Buscar')),
          const SizedBox(height: 16),
          if (loading) const Center(child: CircularProgressIndicator()),
          if (error != null) Text(error!),
          if (detalle != null) detalle,
        ],
      ),
    );
  }
}

// ---------- 7. WORDPRESS ----------
class WordPressPage extends StatelessWidget {
  const WordPressPage({super.key});
  @override
  Widget build(BuildContext context) {
    final host = Uri.parse(wpSite).host;
    final f = getJson('$wpSite/wp-json/wp/v2/posts?per_page=3');
    return Scaffold(
      appBar: AppBar(title: Text(host)),
      body: FutureBuilder(
        future: f,
        builder: (context, s) => estado(s, (d) {
          final posts = d as List;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Image.network(
                    'https://www.google.com/s2/favicons?domain=$host&sz=128',
                    height: 96,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.public, size: 96)),
              ),
              const SizedBox(height: 16),
              ...posts.map((p) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(limpiar('${p['title']['rendered']}'),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(limpiar('${p['excerpt']['rendered']}')),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => abrir('${p['link']}'),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Visitar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        }),
      ),
    );
  }
}

// ---------- 8. ACERCA DE ----------
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
              child: CircleAvatar(
                  radius: 80, backgroundImage: AssetImage('assets/yo.png'))),
          const SizedBox(height: 12),
          const Center(
              child: Text(miNombre,
                  style:
                      TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
          const Center(child: Text('Desarrollador de aplicaciones moviles')),
          const SizedBox(height: 16),
          ListTile(
              leading: const Icon(Icons.email),
              title: const Text(miCorreo),
              onTap: () => abrir('mailto:$miCorreo')),
          ListTile(
              leading: const Icon(Icons.phone),
              title: const Text(miTelefono),
              onTap: () => abrir('tel:$miTelefono')),
          ListTile(
              leading: const Icon(Icons.work),
              title: const Text('LinkedIn'),
              onTap: () => abrir(miLinkedin)),
          ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              onTap: () => abrir(miGithub)),
        ],
      ),
    );
  }
}

