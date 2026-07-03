import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intervention_session.dart';
import '../models/tags.dart';
import '../providers/intervention_provider.dart';
import '../services/dni_service.dart';

class ActaEditorView extends StatefulWidget {
  final InterventionDocument document;

  const ActaEditorView({super.key, required this.document});

  @override
  State<ActaEditorView> createState() => _ActaEditorViewState();
}

class _ActaEditorViewState extends State<ActaEditorView> {
  late TextEditingController _controller;
  bool _isEditingRaw = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.document.content);
  }
  
  @override
  void didUpdateWidget(ActaEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id) {
      _controller.text = widget.document.content;
    }
  }

  void _saveContent() {
    widget.document.content = _controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Modo Editor (Plantilla): '),
              Switch(
                value: _isEditingRaw,
                onChanged: (val) {
                  setState(() {
                    if (!val) {
                      _saveContent();
                    }
                    _isEditingRaw = val;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isEditingRaw 
                ? TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    onChanged: (val) => _saveContent(),
                  )
                : InteractiveDocumentViewer(content: widget.document.content),
          ),
        ),
      ],
    );
  }
}

class InteractiveDocumentViewer extends StatelessWidget {
  final String content;

  const InteractiveDocumentViewer({super.key, required this.content});

  // All condition keys used across Actium actas. Add new keys here as the system grows.
  static const _conditionKeys = [
    'ACOMPANANTE', 'FISCAL', 'VEHICULO', 'DETENIDO', 'COMISARIA',
    'MENOR', 'EXTRANJERO', 'HERIDO',
  ];

  // Pre-compiled RegExp patterns for performance optimization
  static final Map<String, RegExp> _ifRegexes = {
    for (final key in _conditionKeys)
      key: RegExp('<\\s*IF_$key\\s*>(.*?)<\\s*/\\s*IF_$key\\s*>', dotAll: true, caseSensitive: false),
  };

  static final Map<String, RegExp> _ifNotRegexes = {
    for (final key in _conditionKeys)
      key: RegExp('<\\s*IF_NOT_$key\\s*>(.*?)<\\s*/\\s*IF_NOT_$key\\s*>', dotAll: true, caseSensitive: false),
  };

  static final RegExp _tagRegex = RegExp(r'\[(.*?)\]');
  static final RegExp _safetyRegex = RegExp(r'<\s*/?\s*IF_[A-Z0-9_]+\s*>', caseSensitive: false);

  String _processConditions(String text, InterventionProvider provider) {
    String result = text;

    for (final key in _conditionKeys) {
      final condTrue = provider.getCondition(key);

      final ifRegex = _ifRegexes[key]!;
      result = result.replaceAllMapped(ifRegex, (m) => condTrue ? m.group(1)! : '');

      final ifNotRegex = _ifNotRegexes[key]!;
      result = result.replaceAllMapped(ifNotRegex, (m) => !condTrue ? m.group(1)! : '');
    }

    result = result.replaceAll(_safetyRegex, '');

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterventionProvider>();
    final processedContent = _processConditions(content, provider);
    print("DEBUG ACTA CONTENT INPUT: $content");
    print("DEBUG ACTA CONTENT OUTPUT: $processedContent");
    
    final matches = _tagRegex.allMatches(processedContent);
    
    if (matches.isEmpty) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Text(
            processedContent,
            style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.6),
          ),
        ),
      );
    }

    List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: processedContent.substring(lastMatchEnd, match.start)));
      }
      
      final tagString = match.group(0)!;
      
      final tagDef = TagsRepository.tagMap[tagString];

      final currentValue = provider.getTagValue(tagString);

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: InkWell(
          onTap: () => _onTagTapped(context, tagString, tagDef, currentValue),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: currentValue != null ? Colors.green.shade100 : Colors.orange.shade100,
              border: Border.all(color: currentValue != null ? Colors.green : Colors.orange),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentValue ?? (tagDef?.name ?? tagString),
              style: TextStyle(
                color: currentValue != null ? Colors.green.shade900 : Colors.orange.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < processedContent.length) {
      spans.add(TextSpan(text: processedContent.substring(lastMatchEnd)));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.6),
            children: spans,
          ),
        ),
      ),
    );
  }

  void _onTagTapped(BuildContext context, String tagString, TagDefinition? tagDef, String? currentValue) {
    final isPerson = tagString.startsWith('[imputado.') ||
                     tagString.startsWith('[testigo.') ||
                     tagString.startsWith('[agraviado.');

    if (!isPerson) {
      _showInputModal(context, tagString, tagDef, currentValue);
      return;
    }

    final dniTag = tagString.startsWith('[imputado.')
        ? '[imputado.dni]'
        : tagString.startsWith('[testigo.')
            ? '[testigo.dni]'
            : '[agraviado.dni]';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return PersonEntryMethodSheet(
          tagStr: tagString,
          tagDef: tagDef,
          currentValue: currentValue,
          dniTag: dniTag,
          onChoice: (method) {
            Navigator.pop(ctx);
            if (method == 'manual') {
              _showInputModal(context, tagString, tagDef, currentValue);
            } else {
              final dniDef = TagsRepository.tagMap[dniTag];
              final currentDniVal = context.read<InterventionProvider>().getTagValue(dniTag);
              _showInputModal(context, dniTag, dniDef, currentDniVal);
            }
          },
        );
      },
    );
  }

  void _showInputModal(BuildContext context, String tagString, TagDefinition? tagDef, String? currentValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return TagInputWidget(tagString: tagString, tagDef: tagDef, initialValue: currentValue);
      },
    );
  }
}

class TagInputWidget extends StatefulWidget {
  final String tagString;
  final TagDefinition? tagDef;
  final String? initialValue;

  const TagInputWidget({super.key, required this.tagString, this.tagDef, this.initialValue});

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  late TextEditingController _ctrl;
  String? _selectedOption;

  // DNI/CE Search state
  final DniService _dniService = DniService();
  bool _isLoadingDni = false;
  String? _dniError;
  DniResultado? _dniResultado;
  String? _apiKey;
  bool _hasApiKey = false;
  String _documentType = 'DNI'; // 'DNI' or 'CE'

  // Placa Search state
  bool _isLoadingPlaca = false;
  String? _placaError;
  PlacaResultado? _placaResultado;

  // Comisarias state
  List<String> _savedComisarias = [];
  String _operatorUnit = '';
  bool _isLoadingComisarias = false;

  // NENEOIDD state controllers
  late TextEditingController _neneNombreCtrl;
  late TextEditingController _neneEdadCtrl;
  late TextEditingController _neneNaturalCtrl;
  late TextEditingController _neneCivilCtrl;
  late TextEditingController _neneOcupacionCtrl;
  late TextEditingController _neneInstruccionCtrl;
  late TextEditingController _neneDniCtrl;
  late TextEditingController _neneDireccionCtrl;

  bool _isLoadingNeneDni = false;
  String? _neneDniError;
  String _profileCity = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    
    // Initialize NENEOIDD controllers
    _neneNombreCtrl = TextEditingController();
    _neneEdadCtrl = TextEditingController();
    _neneNaturalCtrl = TextEditingController();
    _neneCivilCtrl = TextEditingController();
    _neneOcupacionCtrl = TextEditingController();
    _neneInstruccionCtrl = TextEditingController();
    _neneDniCtrl = TextEditingController();
    _neneDireccionCtrl = TextEditingController();

    if (widget.tagString == '[neneoidd]') {
      _parseExistingNeneoidd(widget.initialValue ?? '');
      _loadApiKey();
    }
    if (widget.tagString == '[lugar.provincia]') {
      _loadProfileCity();
    }

    if (widget.tagDef?.options != null && widget.tagDef!.options!.contains(widget.initialValue)) {
      _selectedOption = widget.initialValue;
    }
    if (_isDniTag() || _isPlacaTag()) {
      _loadApiKey();
    }
    if (widget.tagString == '[acta.lugar_redaccion]') {
      _loadComisariasAndUnit();
    }
  }

  Future<void> _loadComisariasAndUnit() async {
    setState(() => _isLoadingComisarias = true);
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_comisarias') ?? [];
    final unit = prefs.getString('operator_unit') ?? '';
    setState(() {
      _savedComisarias = list;
      _operatorUnit = unit;
      _isLoadingComisarias = false;
    });
  }

  bool _isDniTag() {
    return widget.tagString == '[imputado.dni]' ||
           widget.tagString == '[testigo.dni]' ||
           widget.tagString == '[agraviado.dni]';
  }

  bool _isPlacaTag() {
    return widget.tagString == '[vehiculo.placa_unica_nacional_rodaje]' ||
           widget.tagString == '[vehiculo.placa]';
  }

  Future<void> _loadApiKey() async {
    final key = await _dniService.getApiKey();
    if (mounted) {
      setState(() {
        _apiKey = key;
        _hasApiKey = key != null && key.trim().isNotEmpty;
      });
    }
  }

  Future<void> _consultarDocumento() async {
    final doc = _ctrl.text.trim();
    if (_documentType == 'DNI') {
      if (doc.length != 8 || int.tryParse(doc) == null) {
        setState(() {
          _dniError = 'El DNI debe tener exactamente 8 dígitos.';
          _dniResultado = null;
        });
        return;
      }
    } else {
      if (doc.isEmpty) {
        setState(() {
          _dniError = 'Ingresa un Carnet de Extranjería válido.';
          _dniResultado = null;
        });
        return;
      }
    }

    final key = _apiKey ?? '';
    if (key.trim().isEmpty) {
      setState(() {
        _dniError = 'Token de Factiliza no configurado. Ve al menú principal -> Ajustes (API KEYS).';
        _dniResultado = null;
      });
      return;
    }

    setState(() {
      _isLoadingDni = true;
      _dniError = null;
      _dniResultado = null;
    });

    if (_documentType == 'DNI') {
      final response = await _dniService.consultarDni(doc, key);
      if (mounted) {
        setState(() {
          _isLoadingDni = false;
          if (response.estado && response.resultado != null) {
            _dniResultado = response.resultado;
            _dniError = null;
          } else {
            _dniError = response.mensaje;
            _dniResultado = null;
          }
        });
      }
    } else {
      final response = await _dniService.consultarCe(doc, key);
      if (mounted) {
        setState(() {
          _isLoadingDni = false;
          if (response.estado && response.resultado != null) {
            final ceData = response.resultado!;
            final nombreCompleto = "${ceData.nombres} ${ceData.apellidoPaterno} ${ceData.apellidoMaterno}".trim().replaceAll(RegExp(r'\s+'), ' ');
            _dniResultado = DniResultado(
              id: ceData.numero,
              nombres: ceData.nombres,
              apellidoPaterno: ceData.apellidoPaterno,
              apellidoMaterno: ceData.apellidoMaterno,
              nombreCompleto: nombreCompleto,
              genero: '',
              fechaNacimiento: '',
              codigoVerificacion: '',
              departamento: '',
              provincia: '',
              distrito: '',
              direccion: '',
              direccionCompleta: '',
              nacionalidad: '',
            );
            _dniError = null;
          } else {
            _dniError = response.mensaje;
            _dniResultado = null;
          }
        });
      }
    }
  }

  Future<void> _consultarPlaca() async {
    final placa = _ctrl.text.trim();
    if (placa.isEmpty) {
      setState(() {
        _placaError = 'Ingresa un número de placa válido.';
        _placaResultado = null;
      });
      return;
    }

    final key = _apiKey ?? '';
    if (key.trim().isEmpty) {
      setState(() {
        _placaError = 'Token de Factiliza no configurado. Ve al menú principal -> Ajustes (API KEYS).';
        _placaResultado = null;
      });
      return;
    }

    setState(() {
      _isLoadingPlaca = true;
      _placaError = null;
      _placaResultado = null;
    });

    final response = await _dniService.consultarPlaca(placa, key);

    if (mounted) {
      setState(() {
        _isLoadingPlaca = false;
        if (response.estado && response.resultado != null) {
          _placaResultado = response.resultado;
          _placaError = null;
        } else {
          _placaError = response.mensaje;
          _placaResultado = null;
        }
      });
    }
  }

  int _calculateAge(String birthDateStr) {
    try {
      final parts = birthDateStr.split('/');
      if (parts.length != 3) return 0;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _neneNombreCtrl.dispose();
    _neneEdadCtrl.dispose();
    _neneNaturalCtrl.dispose();
    _neneCivilCtrl.dispose();
    _neneOcupacionCtrl.dispose();
    _neneInstruccionCtrl.dispose();
    _neneDniCtrl.dispose();
    _neneDireccionCtrl.dispose();
    super.dispose();
  }

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _parseExistingNeneoidd(String text) {
    if (text.isEmpty || text == '_______________') return;
    try {
      final nameAgeRegex = RegExp(r'^([^(]+)\((\d+)\)');
      final nameAgeMatch = nameAgeRegex.firstMatch(text);
      if (nameAgeMatch != null) {
        _neneNombreCtrl.text = nameAgeMatch.group(1)!.trim();
        _neneEdadCtrl.text = nameAgeMatch.group(2)!.trim();
      }

      final naturalRegex = RegExp(r'natural de ([^,]+)', caseSensitive: false);
      final naturalMatch = naturalRegex.firstMatch(text);
      if (naturalMatch != null) {
        _neneNaturalCtrl.text = naturalMatch.group(1)!.trim();
      }

      final dniRegex = RegExp(r'identificado con DNI\s*:\s*(\w+)', caseSensitive: false);
      final dniMatch = dniRegex.firstMatch(text);
      if (dniMatch != null) {
        _neneDniCtrl.text = dniMatch.group(1)!.trim();
      }

      final dirRegex = RegExp(r'domiciliado en ([^.]+|.+)$', caseSensitive: false);
      final dirMatch = dirRegex.firstMatch(text);
      if (dirMatch != null) {
        _neneDireccionCtrl.text = dirMatch.group(1)!.trim().replaceAll(RegExp(r'\s+$'), '');
      }

      final parts = text.split(',');
      if (parts.length >= 5) {
        String civil = parts[2].trim();
        String ocup = parts[3].trim();
        String inst = parts[4].trim();

        if (!civil.toLowerCase().contains('natural') && !civil.toLowerCase().contains('identificado') && !civil.toLowerCase().contains('domiciliado')) {
          _neneCivilCtrl.text = civil;
        }
        if (!ocup.toLowerCase().contains('natural') && !ocup.toLowerCase().contains('identificado') && !ocup.toLowerCase().contains('domiciliado')) {
          _neneOcupacionCtrl.text = ocup;
        }
        if (!inst.toLowerCase().contains('natural') && !inst.toLowerCase().contains('identificado') && !inst.toLowerCase().contains('domiciliado')) {
          _neneInstruccionCtrl.text = inst;
        }
      }
    } catch (_) {}
  }

  String _compileNeneoidd() {
    final nombre = _toTitleCase(_neneNombreCtrl.text.trim());
    final edad = _neneEdadCtrl.text.trim();
    final natural = _toTitleCase(_neneNaturalCtrl.text.trim());
    final civil = _neneCivilCtrl.text.trim().toLowerCase();
    final ocupacion = _neneOcupacionCtrl.text.trim().toLowerCase();
    final instruccion = _neneInstruccionCtrl.text.trim().toLowerCase();
    final dni = _neneDniCtrl.text.trim();
    final direccion = _neneDireccionCtrl.text.trim();

    return '$nombre ($edad) , natural de $natural, $civil, $ocupacion, $instruccion, identificado con DNI : $dni, domiciliado en $direccion';
  }

  Future<void> _consultarNeneDni() async {
    final doc = _neneDniCtrl.text.trim();
    if (doc.length != 8 || int.tryParse(doc) == null) {
      setState(() {
        _neneDniError = 'El DNI debe tener exactamente 8 dígitos.';
      });
      return;
    }

    final key = _apiKey ?? '';
    if (key.trim().isEmpty) {
      setState(() {
        _neneDniError = 'Token de Factiliza no configurado. Ve al menú principal -> Ajustes (API KEYS).';
      });
      return;
    }

    setState(() {
      _isLoadingNeneDni = true;
      _neneDniError = null;
    });

    final response = await _dniService.consultarDni(doc, key);
    if (mounted) {
      setState(() {
        _isLoadingNeneDni = false;
        if (response.estado && response.resultado != null) {
          final res = response.resultado!;
          _neneNombreCtrl.text = _toTitleCase(res.nombreCompleto);
          if (res.fechaNacimiento.isNotEmpty) {
            _neneEdadCtrl.text = _calculateAge(res.fechaNacimiento).toString();
          }
          if (res.distrito.isNotEmpty) {
            _neneNaturalCtrl.text = _toTitleCase(res.distrito);
          }
          _neneDireccionCtrl.text = res.direccionCompleta.isNotEmpty 
              ? res.direccionCompleta 
              : res.direccion;
          _neneDniError = null;
        } else {
          _neneDniError = response.mensaje;
        }
      });
    }
  }

  Future<void> _loadProfileCity() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('operator_city') ?? '';
    if (mounted) {
      setState(() {
        _profileCity = city.toUpperCase();
      });
    }
  }

  Widget? _buildQuickActionsRow() {
    final tagLower = widget.tagString.toLowerCase();
    final nameLower = (widget.tagDef?.name ?? '').toLowerCase();
    final isHora = tagLower.contains('hora') || nameLower.contains('hora');
    final isFecha = tagLower.contains('fecha') || nameLower.contains('fecha');
    final isProvincia = widget.tagString == '[lugar.provincia]';

    if (!isHora && !isFecha && (!isProvincia || _profileCity.isEmpty)) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (isHora)
            ActionChip(
              avatar: const Icon(Icons.access_time, size: 14, color: Colors.white),
              backgroundColor: const Color(0xFF1E80F0),
              label: const Text('Insertar hora del sistema', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                final now = DateTime.now();
                final formatted = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                setState(() {
                  _ctrl.text = formatted;
                });
              },
            ),
          if (isFecha)
            ActionChip(
              avatar: const Icon(Icons.calendar_today, size: 14, color: Colors.white),
              backgroundColor: const Color(0xFF1E80F0),
              label: const Text('Insertar fecha del sistema', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() {
                  _ctrl.text = _formatSystemDate(DateTime.now());
                });
              },
            ),
          if (isProvincia && _profileCity.isNotEmpty)
            ActionChip(
              avatar: const Icon(Icons.location_city, size: 14, color: Colors.white),
              backgroundColor: const Color(0xFF1E80F0),
              label: Text('Usar ciudad del perfil: $_profileCity', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() {
                  _ctrl.text = _profileCity;
                });
              },
            ),
        ],
      ),
    );
  }

  String _formatSystemDate(DateTime dt) {
    const months = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SET', 'OCT', 'NOV', 'DIC'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    return '$day$month$year';
  }

  Widget _buildNeneoiddForm() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Identificación Rápida (NENEOIDD)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Completa con DNI o rellena manualmente para generar la descripción todo-en-uno.',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _neneDniCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ingresa DNI (8 dígitos)',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                      border: const OutlineInputBorder(),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E80F0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isLoadingNeneDni
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search, size: 16),
                  label: const Text('Consultar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _isLoadingNeneDni ? null : _consultarNeneDni,
                ),
              ],
            ),
            if (_neneDniError != null) ...[
              const SizedBox(height: 8),
              Text(
                '⚠ $_neneDniError',
                style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 16),
            
            _buildNeneField('Nombres y Apellidos', _neneNombreCtrl),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildNeneField('Edad', _neneEdadCtrl, keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 7,
                  child: _buildNeneField('Natural de (Ciudad)', _neneNaturalCtrl),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildNeneDropdownField(
                    'Estado Civil', 
                    _neneCivilCtrl,
                    ['Soltero(a)', 'Casado(a)', 'Viudo(a)', 'Divorciado(a)', 'Conviviente'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNeneField('Ocupación', _neneOcupacionCtrl),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildNeneDropdownField(
              'Grado de Instrucción',
              _neneInstruccionCtrl,
              [
                'Secundaria Completa',
                'Secundaria Incompleta',
                'Superior Completa',
                'Superior Incompleta',
                'Primaria Completa',
                'Primaria Incompleta',
                'Sin Instrucción'
              ],
            ),
            const SizedBox(height: 12),
            
            _buildNeneField('Dirección Domiciliaria', _neneDireccionCtrl),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final compiled = _compileNeneoidd();
                    context.read<InterventionProvider>().updateTagValue(widget.tagString, compiled);
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeneField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNeneDropdownField(String label, TextEditingController controller, List<String> options) {
    String? currentVal;
    final text = controller.text.toLowerCase().trim();
    for (final opt in options) {
      if (opt.toLowerCase().trim() == text || (opt.toLowerCase().trim().startsWith(text) && text.isNotEmpty)) {
        currentVal = opt;
        break;
      }
    }
    if (currentVal != null) {
      controller.text = currentVal;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: currentVal,
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            isDense: true,
          ),
          items: options.map((o) {
            return DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(color: Colors.white, fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              controller.text = val;
            }
          },
        ),
      ],
    );
  }

  Widget _buildFormContent(BuildContext context) {
    if (widget.tagString == '[neneoidd]') {
      return _buildNeneoiddForm();
    }
    if (widget.tagString == '[acta.lugar_redaccion]') {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lugar de Redacción / Comisaría',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (_operatorUnit.isNotEmpty) ...[
              const Text(
                'DESDE TU PERFIL (PRESIONA PARA SELECCIONAR):',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E80F0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.business_rounded),
                label: Text(
                  _operatorUnit.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  context.read<InterventionProvider>().updateTagValue(widget.tagString, _operatorUnit.toUpperCase());
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'COMISARÍAS ANTERIORES / GUARDADAS:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            _isLoadingComisarias
                ? const Center(child: CircularProgressIndicator())
                : _savedComisarias.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No hay comisarías guardadas aún.',
                          style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _savedComisarias.length,
                          itemBuilder: (context, index) {
                            final comisaria = _savedComisarias[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  comisaria,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                                  onPressed: () async {
                                    final newList = List<String>.from(_savedComisarias)..removeAt(index);
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setStringList('saved_comisarias', newList);
                                    setState(() {
                                      _savedComisarias = newList;
                                    });
                                  },
                                ),
                                onTap: () {
                                  context.read<InterventionProvider>().updateTagValue(widget.tagString, comisaria);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 16),
            const Text(
              'INGRESAR NUEVA COMISARÍA MANUALMENTE:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Ej. COMISARÍA PNP MIRAFLORES',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final text = _ctrl.text.trim().toUpperCase();
                    if (text.isEmpty) return;
                    
                    final provider = context.read<InterventionProvider>();
                    final navigator = Navigator.of(context);
                    
                    final newList = List<String>.from(_savedComisarias);
                    if (!newList.contains(text)) {
                      newList.add(text);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList('saved_comisarias', newList);
                    }
                    
                    if (mounted) {
                      provider.updateTagValue(widget.tagString, text);
                      navigator.pop();
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ));
    }

    final hasOptions = widget.tagDef?.options != null && widget.tagDef!.options!.isNotEmpty;
    final isDni = _isDniTag();
    final isPlaca = _isPlacaTag();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ingresar dato para: ${widget.tagDef?.name ?? widget.tagString}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (hasOptions) ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedOption,
              decoration: const InputDecoration(labelText: 'Opciones preconfiguradas', border: OutlineInputBorder()),
              items: widget.tagDef!.options!.map((o) {
                return DropdownMenuItem(
                  value: o,
                  child: Text(o, maxLines: 2, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedOption = val;
                  _ctrl.text = val ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('O escribir manualmente:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
          if (isDni) ...[
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('DNI'),
                    selected: _documentType == 'DNI',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _documentType = 'DNI';
                          _dniResultado = null;
                          _dniError = null;
                          _ctrl.clear();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('CE (Extranjería)'),
                    selected: _documentType == 'CE',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _documentType = 'CE';
                          _dniResultado = null;
                          _dniError = null;
                          _ctrl.clear();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_buildQuickActionsRow() != null) _buildQuickActionsRow()!,
          TextField(
            controller: _ctrl,
            keyboardType: isDni
                ? (_documentType == 'DNI' ? TextInputType.number : TextInputType.text)
                : TextInputType.text,
            textCapitalization: isPlaca ? TextCapitalization.characters : TextCapitalization.none,
            maxLines: (isDni || isPlaca) ? 1 : null,
            maxLength: isDni
                ? (_documentType == 'DNI' ? 8 : 15)
                : (isPlaca ? 10 : null),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: isDni
                  ? (_documentType == 'DNI' ? 'Ej: 12345678' : 'Ingresa Carnet de Extranjería')
                  : (isPlaca ? 'Ej: ABC123' : 'Escribe el valor aquí...'),
              counterText: '',
            ),
          ),
          if (isDni) ...[
            const SizedBox(height: 12),
            if (!_hasApiKey) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Token de Factiliza no configurado. Ve al menú principal -> Ajustes (API KEYS) para habilitar consultas.',
                        style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Token de Factiliza configurado',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ElevatedButton.icon(
              icon: _isLoadingDni
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_documentType == 'DNI' ? 'Consultar DNI Completo' : 'Consultar Carnet Extranjería'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasApiKey ? Theme.of(context).colorScheme.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: (_isLoadingDni || !_hasApiKey) ? null : _consultarDocumento,
            ),
            if (_dniError != null) ...[
              const SizedBox(height: 8),
              Text(
                '⚠ $_dniError',
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
            if (_dniResultado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Datos Encontrados',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Nombre completo: ${_dniResultado!.nombreCompleto}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    if (_dniResultado!.genero.isNotEmpty)
                      Text('Género: ${_dniResultado!.genero == "M" ? "Masculino" : "Femenino"}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    if (_dniResultado!.fechaNacimiento.isNotEmpty)
                      Text('Fecha de Nacimiento: ${_dniResultado!.fechaNacimiento}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    if (widget.tagString == '[imputado.dni]' && _dniResultado!.fechaNacimiento.isNotEmpty)
                      Text('Edad Calculada: ${_calculateAge(_dniResultado!.fechaNacimiento)} años', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          if (isPlaca) ...[
            const SizedBox(height: 12),
            if (!_hasApiKey) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Token de Factiliza no configurado. Ve al menú principal -> Ajustes (API KEYS) para habilitar consultas.',
                        style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Token de Factiliza configurado',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ElevatedButton.icon(
              icon: _isLoadingPlaca
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: const Text('Consultar Placa Completa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasApiKey ? Theme.of(context).colorScheme.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: (_isLoadingPlaca || !_hasApiKey) ? null : _consultarPlaca,
            ),
            if (_placaError != null) ...[
              const SizedBox(height: 8),
              Text(
                '⚠ $_placaError',
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
            if (_placaResultado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Datos de Vehículo Encontrados',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Placa: ${_placaResultado!.placa}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    Text('Marca: ${_placaResultado!.marca}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    Text('Modelo: ${_placaResultado!.modelo}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    Text('Color: ${_placaResultado!.color}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    Text('Motor: ${_placaResultado!.motor}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    Text('Serie: ${_placaResultado!.serie}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final val = _ctrl.text.trim();
              final cleanVal = val.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
              final cleanDniId = _dniResultado?.id.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
              final cleanPlacaVal = _placaResultado?.placa.replaceAll('-', '').replaceAll(' ', '').toUpperCase();

              if (isDni && _dniResultado != null && cleanVal == cleanDniId) {
                final type = widget.tagString == '[imputado.dni]'
                    ? 'imputado'
                    : widget.tagString == '[testigo.dni]'
                        ? 'testigo'
                        : 'agraviado';
                context.read<InterventionProvider>().populateDniData(type, _dniResultado!);
              } else if (isPlaca && _placaResultado != null && cleanVal == cleanPlacaVal) {
                context.read<InterventionProvider>().populatePlacaData(_placaResultado!);
              } else {
                context.read<InterventionProvider>().updateTagValue(widget.tagString, val);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _buildFormContent(context),
      ),
    );
  }
}

class PersonEntryMethodSheet extends StatelessWidget {
  final String tagStr;
  final TagDefinition? tagDef;
  final String? currentValue;
  final String dniTag;
  final ValueChanged<String> onChoice; // 'manual' or 'dni'

  const PersonEntryMethodSheet({
    super.key,
    required this.tagStr,
    this.tagDef,
    this.currentValue,
    required this.dniTag,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isImputado = tagStr.startsWith('[imputado.');
    final isTestigo = tagStr.startsWith('[testigo.');
    final title = isImputado
        ? 'Datos del Detenido / Imputado'
        : isTestigo
            ? 'Datos del Testigo'
            : 'Datos del Agraviado';

    final fieldName = tagDef?.name ?? tagStr;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Estás editando: $fieldName',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Option 1: DNI Quick Fill (Recomendado)
          InkWell(
            onTap: () => onChoice('dni'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Ingresar DNI (Llenado Rápido)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Autocompleta nombre, edad y nacimiento desde Reniec',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Option 2: Manual Fill
          InkWell(
            onTap: () => onChoice('manual'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_note_outlined, color: Colors.white70, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Llenar manualmente',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Escribir solo el valor de "$fieldName"',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

