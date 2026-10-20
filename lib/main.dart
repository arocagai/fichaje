import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const FichajeApp());

class FichajeApp extends StatelessWidget {
  const FichajeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fichaje',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF167D72),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        fontFamily: 'Arial',
      ),
      home: const FichajeHome(),
    );
  }
}

enum FichajeTipo { entrada, salida }

class Fichaje {
  const Fichaje(this.tipo, this.hora);
  final FichajeTipo tipo;
  final DateTime hora;
}

class FichajeHome extends StatefulWidget {
  const FichajeHome({super.key});

  @override
  State<FichajeHome> createState() => _FichajeHomeState();
}

class _FichajeHomeState extends State<FichajeHome> {
  static const jornada = Duration(hours: 8);
  static const pausaMinima = Duration(minutes: 30);
  final List<Fichaje> _fichajes = [];
  int _jornadaMinutos = jornada.inMinutes;
  int _pausaMinutos = pausaMinima.inMinutes;
  DateTime _ahora = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _ahora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _tiempoTrabajado {
    var total = Duration.zero;
    for (var i = 0; i + 1 < _fichajes.length; i += 2) {
      total += _fichajes[i + 1].hora.difference(_fichajes[i].hora);
    }
    if (_fichajes.length.isOdd && _fichajes.last.tipo == FichajeTipo.entrada) {
      total += _ahora.difference(_fichajes.last.hora);
    }
    return total;
  }

  bool get _enJornada => _fichajes.isNotEmpty &&
      _fichajes.last.tipo == FichajeTipo.entrada;

  Duration get _pausaPendiente {
    if (_fichajes.length >= 3) return Duration.zero;
    var transcurrido = Duration.zero;
    if (_fichajes.length == 2) {
      transcurrido = _ahora.difference(_fichajes[1].hora);
    }
    final restante = Duration(minutes: _pausaMinutos) - transcurrido;
    return restante.isNegative ? Duration.zero : restante;
  }

  Duration get _restante =>
      Duration(minutes: _jornadaMinutos) - _tiempoTrabajado + _pausaPendiente;

  String get _estado {
    if (_fichajes.isEmpty) return 'Aún no has empezado';
    if (_enJornada && _fichajes.length >= 3) return 'Trabajando por la tarde';
    if (_enJornada) return 'Trabajando por la mañana';
    if (_fichajes.length == 2) return 'Pausa de mediodía';
    return 'Jornada completada';
  }

  String get _siguienteAccion {
    if (_fichajes.isEmpty) return 'Fichar entrada';
    if (_enJornada) {
      return _fichajes.length >= 3 ? 'Fichar salida' : 'Empezar pausa';
    }
    if (_fichajes.length == 2) return 'Fichar entrada';
    return 'Jornada completada';
  }

  void _fichar() {
    if (_siguienteAccion == 'Jornada completada') return;
    setState(() {
      final tipo = _enJornada ? FichajeTipo.salida : FichajeTipo.entrada;
      _fichajes.add(Fichaje(tipo, DateTime.now()));
      _ahora = DateTime.now();
    });
  }

  Future<void> _configurar() async {
    final jornadaCtl = TextEditingController(text: (_jornadaMinutos ~/ 60).toString());
    final minutosCtl = TextEditingController(text: (_jornadaMinutos % 60).toString());
    final pausaCtl = TextEditingController(text: _pausaMinutos.toString());
    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de jornada'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: TextField(controller: jornadaCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Horas de trabajo'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: minutosCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutos'))),
          ]),
          TextField(controller: pausaCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pausa mínima (minutos)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (guardar == true && mounted) {
      final horas = int.tryParse(jornadaCtl.text) ?? 8;
      final minutos = int.tryParse(minutosCtl.text) ?? 0;
      final pausa = int.tryParse(pausaCtl.text) ?? 30;
      if (horas >= 0 && minutos >= 0 && minutos < 60 && pausa >= 0 && horas + minutos > 0) {
        setState(() {
          _jornadaMinutos = horas * 60 + minutos;
          _pausaMinutos = pausa;
        });
      }
    }
    jornadaCtl.dispose();
    minutosCtl.dispose();
    pausaCtl.dispose();
  }

  Future<void> _anadirHora() async {
    final tipo = _enJornada ? FichajeTipo.salida : FichajeTipo.entrada;
    final fecha = DateTime.now();
    final seleccion = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fecha),
      helpText: tipo == FichajeTipo.entrada ? 'Hora de entrada' : 'Hora de salida',
    );
    if (seleccion == null || !mounted) return;
    setState(() {
      _fichajes.add(Fichaje(
        tipo,
        DateTime(fecha.year, fecha.month, fecha.day, seleccion.hour, seleccion.minute),
      ));
    });
  }

  String _formato(Duration d) {
    final mins = d.inMinutes.abs();
    return '${d.isNegative ? '−' : ''}${(mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}';
  }

  String _hora(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final fecha = MaterialLocalizations.of(context).formatMediumDate(_ahora);
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.schedule_rounded, color: Color(0xFF167D72)),
          SizedBox(width: 9),
          Text('Fichaje', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        centerTitle: false,
        backgroundColor: const Color(0xFFF5F7F6),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: _configurar,
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(fecha, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
              const SizedBox(height: 14),
              _ResumenCard(
                estado: _estado,
                restante: _restante.isNegative ? Duration.zero : _restante,
                trabajado: _tiempoTrabajado,
                formato: _formato,
                enJornada: _enJornada,
                jornada: Duration(minutes: _jornadaMinutos),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _siguienteAccion == 'Jornada completada' ? null : _fichar,
                icon: Icon(_enJornada ? Icons.logout_rounded : Icons.login_rounded),
                label: Text(_siguienteAccion),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _anadirHora,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Añadir fichaje manual'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 28),
              Row(children: [
                Text('Fichajes de hoy', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${_fichajes.length} ${_fichajes.length == 1 ? 'registro' : 'registros'}', style: const TextStyle(color: Colors.black54)),
              ]),
              const SizedBox(height: 10),
              if (_fichajes.isEmpty)
                const _EmptyCard()
              else
                ..._fichajes.map((f) => _FichajeRow(fichaje: f, hora: _hora(f.hora))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.estado, required this.restante, required this.trabajado, required this.formato, required this.enJornada, required this.jornada});
  final String estado;
  final Duration restante;
  final Duration trabajado;
  final String Function(Duration) formato;
  final bool enJornada;
  final Duration jornada;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: const Color(0xFFE5F2EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: enJornada ? const Color(0xFF167D72) : Colors.orange, shape: BoxShape.circle)),
              const SizedBox(width: 9),
              Text(estado, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),
            const Text('Te falta para terminar', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 3),
            Text(formato(restante), style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.5)),
            const SizedBox(height: 17),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: (trabajado.inSeconds / jornada.inSeconds).clamp(0.0, 1.0), minHeight: 8, backgroundColor: Colors.white, color: const Color(0xFF167D72)),
            ),
            const SizedBox(height: 9),
            Text('${formato(trabajado)} trabajadas de ${formato(jornada)}', style: const TextStyle(color: Colors.black54)),
          ]),
        ),
      );
}

class _FichajeRow extends StatelessWidget {
  const _FichajeRow({required this.fichaje, required this.hora});
  final Fichaje fichaje;
  final String hora;

  @override
  Widget build(BuildContext context) {
    final entrada = fichaje.tipo == FichajeTipo.entrada;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entrada ? const Color(0xFFE5F2EF) : const Color(0xFFFFF1E3),
          child: Icon(entrada ? Icons.login_rounded : Icons.logout_rounded, color: entrada ? const Color(0xFF167D72) : Colors.deepOrange),
        ),
        title: Text(entrada ? 'Entrada' : 'Salida'),
        trailing: Text(hora, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(children: const [
            Icon(Icons.event_available_outlined, size: 34, color: Colors.black38),
            SizedBox(height: 9),
            Text('Tus fichajes aparecerán aquí', style: TextStyle(color: Colors.black54)),
          ]),
        ),
      );
}
