import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/intervention_session.dart';
import '../models/tags.dart';
import '../providers/intervention_provider.dart';
import '../services/ai_tactical_service.dart';

class AiGrillSheet extends StatefulWidget {
  final AuditMaestroResult auditResult;
  final InterventionDocument document;

  const AiGrillSheet({
    super.key,
    required this.auditResult,
    required this.document,
  });

  @override
  State<AiGrillSheet> createState() => _AiGrillSheetState();
}

class _AiGrillSheetState extends State<AiGrillSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _inferInterventionTag(String obs) {
    final o = obs.toLowerCase();
    if (o.contains('provincia')) return '[lugar.provincia]';
    if (o.contains('distrito')) return '[lugar.distrito]';
    if (o.contains('calle') || o.contains('dirección') || o.contains('ubicación') || o.contains('lugar')) {
      if (o.contains('evidencia') || o.contains('objeto')) return '[evi.ubicacion]';
      return '[lugar.calle]';
    }
    if (o.contains('hora de inicio') || o.contains('hora inicio') || o.contains('hora del acta')) return '[tiempo.acta_hora_inicio]';
    if (o.contains('dni')) return '[imputado.dni]';
    if (o.contains('nombre') || o.contains('intervenido') || o.contains('imputado') || o.contains('identidad') || o.contains('apellidos')) return '[imputado.nombres_apellidos]';
    if (o.contains('placa') || o.contains('vehículo') || o.contains('vehiculo')) return '[vehiculo.placa_unica_nacional_rodaje]';
    if (o.contains('previos') || o.contains('precedente') || o.contains('motivo')) return '[hechos.previos]';
    if (o.contains('concomitante') || o.contains('huyo') || o.contains('fuga') || o.contains('evad')) return '[hechos.concomitantes]';
    if (o.contains('fuerza') || o.contains('resistencia') || o.contains('enrocamiento')) return '[hechos.fuerza]';
    if (o.contains('posterior') || o.contains('traslado') || o.contains('comisaría') || o.contains('derechos')) return '[hechos.posteriores]';
    if (o.contains('halló') || o.contains('incautó') || o.contains('objeto') || o.contains('evidencia') || o.contains('droga') || o.contains('arma') || o.contains('kete')) return '[evi.objetos]';
    if (o.contains('cantidad') || o.contains('cuantos') || o.contains('número de envoltorios')) return '[evi.cantidad]';
    if (o.contains('características') || o.contains('caracteristicas') || o.contains('serie') || o.contains('marca')) return '[evi.caracteristicas]';
    if (o.contains('fiscal') || o.contains('comunicación al fiscal') || o.contains('ministerio público')) {
      if (o.contains('nombre') || o.contains('grado')) return '[fiscal.grado_nombres]';
      if (o.contains('fiscalía') || o.contains('fiscalia')) return '[fiscal.fiscalia]';
      if (o.contains('hora')) return '[fiscal.hora_comunicacion]';
      if (o.contains('disposición') || o.contains('dispuso')) return '[fiscal.resultado_comunicacion]';
      if (o.contains('motivo') || o.contains('no se comunicó') || o.contains('no contestó')) return '[fiscal.motivo_no_comunicacion]';
      return '[fiscal.grado_nombres]';
    }
    return 'general';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterventionProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF3D7EFF), size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Perito IA — Auditoría Policial", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Resolución de observaciones para evitar nulidades", style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF3D7EFF),
            labelColor: const Color(0xFF3D7EFF),
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: "Grill-Me (Por Campos)", icon: Icon(Icons.list_alt, size: 20)),
              Tab(text: "Redacción IA Completa", icon: Icon(Icons.auto_awesome, size: 20)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrillTab(provider),
                _buildRedaccionTab(provider),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGrillTab(InterventionProvider provider) {
    final observations = widget.auditResult.observacionesTacticas;

    if (observations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
            const SizedBox(height: 16),
            const Text("¡Sin observaciones críticas!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text("El Perito IA no encontró fallas de objetividad ni causales de nulidad en el acta redactada.", style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: observations.length,
      itemBuilder: (context, i) {
        final obs = observations[i];
        final tag = _inferInterventionTag(obs);
        final tagDef = tag != 'general' ? TagsRepository.tagMap[tag] : null;

        if (tag != 'general' && !_controllers.containsKey(tag)) {
          final currentVal = provider.getTagValue(tag) ?? '';
          _controllers[tag] = TextEditingController(text: currentVal);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF262A35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF333A4A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      obs,
                      style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
              if (tag != 'general' && tagDef != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Campo: ${tagDef.name}",
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controllers[tag],
                        onChanged: (val) {
                          provider.updateTagValue(tag, val);
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Escriba la corrección...",
                          hintStyle: TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D7EFF),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        provider.updateTagValue(tag, _controllers[tag]!.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Campo '${tagDef.name}' actualizado in situ."),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text("Aplicar", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRedaccionTab(InterventionProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.auditResult.textoAuditado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Courier',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D7EFF),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.copy_all, color: Colors.white),
            label: const Text("Reemplazar Acta Completa con Propuesta IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              provider.updateDocumentContent(widget.document.id, widget.auditResult.textoAuditado);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("El Acta de Intervención ha sido reescrita con la redacción legal sugerida.")),
              );
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }
}
