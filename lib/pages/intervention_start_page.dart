import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/typification.dart';
import '../models/typification_repository.dart';
import '../models/intervention_session.dart';
import '../providers/intervention_provider.dart';
import '../models/template.dart';
import '../services/template_service.dart';
import 'intervention_session_page.dart';

class InterventionStartPage extends StatefulWidget {
  const InterventionStartPage({super.key});

  @override
  State<InterventionStartPage> createState() => _InterventionStartPageState();
}

class _InterventionStartPageState extends State<InterventionStartPage> {
  Typification? _selectedTypification;
  List<Template> _allTemplates = [];
  List<Template> _selectedTemplates = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final svc = TemplateService();
    final temps = await svc.loadTemplates();
    setState(() {
      _allTemplates = temps;
    });
  }

  void _onTypificationSelected(Typification t) {
    setState(() {
      _selectedTypification = t;
      _selectedTemplates = _allTemplates
          .where((tmp) => t.recommendedTemplateNames.contains(tmp.name))
          .toList();
    });
    Navigator.of(context).pop(); // Close drawer
  }

  void _showAddExtraTemplateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14161A),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Añadir Acta Extra', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allTemplates.length,
                      itemBuilder: (ctx, i) {
                        final t = _allTemplates[i];
                        final isSelected = _selectedTemplates.any((st) => st.name == t.name);
                        return CheckboxListTile(
                          title: Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          value: isSelected,
                          activeColor: Colors.blueAccent,
                          onChanged: (val) {
                            if (val == true) {
                              setState(() => _selectedTemplates.add(t));
                              setModalState(() {});
                            } else {
                              setState(() => _selectedTemplates.removeWhere((st) => st.name == t.name));
                              setModalState(() {});
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer() {
    final allTypifications = TypificationRepository.all;
    final filtered = allTypifications.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Drawer(
      backgroundColor: const Color(0xFF1A1D24),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Seleccione Tipificación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar delito...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final t = filtered[i];
                  final isSelected = _selectedTypification == t;
                  return ListTile(
                    title: Text(t.name, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                    onTap: () => _onTypificationSelected(t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Intervención'),
      ),
      endDrawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Seleccionar Tipificación'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueGrey.shade800,
                  ),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedTypification != null) ...[
              const Text('TIPIFICACIÓN SELECCIONADA', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Text(_selectedTypification!.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ACTAS A GENERAR', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  TextButton.icon(
                    onPressed: _showAddExtraTemplateDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Añadir Extra'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedTemplates.length,
                  itemBuilder: (ctx, i) {
                    return Card(
                      color: Colors.black26,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.description, color: Colors.white54, size: 20),
                        title: Text(_selectedTemplates[i].name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => setState(() => _selectedTemplates.removeAt(i)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    final session = InterventionSession(
                      name: 'Intervención - ${_selectedTypification!.name}',
                      typificationId: _selectedTypification!.id,
                      documents: _selectedTemplates.map((t) => InterventionDocument(title: t.name, content: t.content)).toList(),
                    );
                    final provider = context.read<InterventionProvider>();
                    provider.startNewSession(session, typificationName: _selectedTypification!.name, conDetenido: true);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InterventionSessionPage(showLiveWizard: true),
                      ),
                    );
                  },
                  child: const Text('Iniciar Editor en Vivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text(
                    'Por favor, seleccione una tipificación para continuar',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
