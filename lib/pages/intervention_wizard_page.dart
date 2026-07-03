import 'package:provider/provider.dart';
import '../providers/intervention_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/intervention_session.dart';
import '../services/dni_service.dart';
import 'intervention_session_page.dart';

class InterventionWizardPage extends StatefulWidget {
  final InterventionSession session;

  const InterventionWizardPage({super.key, required this.session});

  @override
  State<InterventionWizardPage> createState() => _InterventionWizardPageState();
}

class _InterventionWizardPageState extends State<InterventionWizardPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Step 0: Lugar y Fecha
  final TextEditingController _lugarDistritoController = TextEditingController();
  final TextEditingController _lugarProvinciaController = TextEditingController();
  final TextEditingController _lugarViaController = TextEditingController();
  DateTime _fechaHecho = DateTime.now();
  TimeOfDay _horaHecho = TimeOfDay.now();

  // Step 1: Detenidos
  bool? _huboDetenidos;
  final TextEditingController _detaineeDniController = TextEditingController();
  
  // Step 2: Agraviados
  bool? _huboAgraviados;
  final TextEditingController _agraviadoDniController = TextEditingController();

  // Step 3: Fiscal
  bool _comunicacionFiscal = true;
  final TextEditingController _fiscalNombresController = TextEditingController();
  final TextEditingController _fiscalFiscaliaController = TextEditingController();
  TimeOfDay? _fiscalHora;

  // Step 4: Firma
  bool? _negoFirmar;
  final TextEditingController _motivoNegativaController = TextEditingController();

  // Step 5: Relato
  final TextEditingController _relatoController = TextEditingController();

  bool _isLoadingDni = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _pageController.dispose();
    _lugarDistritoController.dispose();
    _lugarProvinciaController.dispose();
    _lugarViaController.dispose();
    _detaineeDniController.dispose();
    _agraviadoDniController.dispose();
    _fiscalNombresController.dispose();
    _fiscalFiscaliaController.dispose();
    _motivoNegativaController.dispose();
    _relatoController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _finishWizard();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _addPerson(bool isDetainee) async {
    final controller = isDetainee ? _detaineeDniController : _agraviadoDniController;
    final dni = controller.text.trim();
    if (dni.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DNI inválido')));
      return;
    }
    setState(() => _isLoadingDni = true);
    final service = DniService();
    final key = await service.getApiKey() ?? '';
    final res = await service.consultarDni(dni, key);
    
    if (mounted) {
      setState(() {
        _isLoadingDni = false;
        final info = DetaineeInfo(
          dni: dni,
          names: res.success ? res.resultado?.nombres : null,
          paternalSurname: res.success ? res.resultado?.apellidoPaterno : null,
          maternalSurname: res.success ? res.resultado?.apellidoMaterno : null,
          fromApi: res.success && res.resultado != null,
        );

        if (isDetainee) {
          widget.session.detainees.add(info);
        } else {
          widget.session.agraviados.add(info);
        }
        
        if (!res.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo obtener datos de API. Agregado para llenado manual.'),
          ));
        }
        controller.clear();
      });
    }
  }

  Future<void> _finishWizard() async {
    setState(() => _isGenerating = true);
    
    // Simulate generation delay for UX
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    widget.session.comunicacionFiscal = _comunicacionFiscal;
    widget.session.negoFirmar = _negoFirmar ?? false;

    for (var doc in widget.session.documents) {
      var c = doc.content;

      c = c.replaceAll('[lugar.distrito]', _lugarDistritoController.text.trim());
      c = c.replaceAll('[lugar.provincia]', _lugarProvinciaController.text.trim());
      c = c.replaceAll('[lugar.nombre_via]', _lugarViaController.text.trim());
      c = c.replaceAll('[tiempo.fecha_hecho]', DateFormat('dd/MM/yyyy').format(_fechaHecho));
      c = c.replaceAll('[tiempo.hora_hecho]', _horaHecho.format(context));
      
      c = c.replaceAll('[narrativa.hechos]', _relatoController.text.trim());
      
      if (widget.session.comunicacionFiscal) {
        c = c.replaceAll('[fiscal.grado_nombres]', _fiscalNombresController.text.trim());
        c = c.replaceAll('[fiscal.fiscalia]', _fiscalFiscaliaController.text.trim());
        if (_fiscalHora != null) {
          c = c.replaceAll('[fiscal.hora_comunicacion]', _fiscalHora!.format(context));
        }
      }
      
      if (widget.session.negoFirmar) {
        c = c.replaceAll('[firma.motivo_negativa]', _motivoNegativaController.text.trim());
      }
      
      doc.content = c;
    }

    if (mounted) {
      context.read<InterventionProvider>().startNewSession(widget.session, conDetenido: _huboDetenidos == true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InterventionSessionPage()),
      );
    }
  }

  Widget _buildStepHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int? maxLength, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        counterText: '',
      ),
    );
  }

  Widget _buildBigButton(String text, IconData icon, bool isSelected, VoidCallback onTap, {Color? color}) {
    final activeColor = color ?? Colors.blueAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: isSelected ? activeColor : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? activeColor : Colors.white54),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(color: isSelected ? activeColor : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonList(bool isDetainee) {
    final list = isDetainee ? widget.session.detainees : widget.session.agraviados;
    return Column(
      children: list.asMap().entries.map((e) {
        final p = e.value;
        final idx = e.key;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.blueAccent),
            title: Text(p.fromApi ? '${p.names} ${p.paternalSurname}' : 'DNI: ${p.dni}', style: const TextStyle(color: Colors.white)),
            subtitle: p.fromApi ? Text('DNI: ${p.dni}', style: const TextStyle(color: Colors.white54)) : const Text('Ingreso manual en la próxima pantalla', style: TextStyle(color: Colors.orangeAccent)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  if (isDetainee) {
                    widget.session.detainees.removeAt(idx);
                  } else {
                    widget.session.agraviados.removeAt(idx);
                  }
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader('¿Dónde y cuándo ocurrió la intervención?'),
          _buildTextField('Distrito', _lugarDistritoController, Icons.map),
          const SizedBox(height: 16),
          _buildTextField('Provincia', _lugarProvinciaController, Icons.location_city),
          const SizedBox(height: 16),
          _buildTextField('Dirección / Vía', _lugarViaController, Icons.streetview),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _fechaHecho, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (d != null) setState(() => _fechaHecho = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FECHA', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(DateFormat('dd/MM/yyyy').format(_fechaHecho), style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _horaHecho);
                    if (t != null) setState(() => _horaHecho = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HORA', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(_horaHecho.format(context), style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader('¿Hubo personas detenidas en esta intervención?'),
          Row(
            children: [
              Expanded(child: _buildBigButton('Sí, hubo detenidos', Icons.front_hand, _huboDetenidos == true, () => setState(() => _huboDetenidos = true))),
              const SizedBox(width: 16),
              Expanded(child: _buildBigButton('No, sin detenidos', Icons.no_accounts, _huboDetenidos == false, () => setState(() => _huboDetenidos = false), color: Colors.grey)),
            ],
          ),
          if (_huboDetenidos == true) ...[
            const SizedBox(height: 32),
            const Text('AÑADIR DETENIDO', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('DNI (8 dígitos)', _detaineeDniController, Icons.badge, isNumber: true, maxLength: 8)),
                const SizedBox(width: 12),
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoadingDni ? null : () => _addPerson(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoadingDni ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPersonList(true),
          ]
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader('¿Hubo agraviados o víctimas?'),
          Row(
            children: [
              Expanded(child: _buildBigButton('Sí, hubo agraviados', Icons.personal_injury, _huboAgraviados == true, () => setState(() => _huboAgraviados = true))),
              const SizedBox(width: 16),
              Expanded(child: _buildBigButton('No, sin agraviados', Icons.shield, _huboAgraviados == false, () => setState(() => _huboAgraviados = false), color: Colors.grey)),
            ],
          ),
          if (_huboAgraviados == true) ...[
            const SizedBox(height: 32),
            const Text('AÑADIR AGRAVIADO', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('DNI (8 dígitos)', _agraviadoDniController, Icons.badge, isNumber: true, maxLength: 8)),
                const SizedBox(width: 12),
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoadingDni ? null : () => _addPerson(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoadingDni ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPersonList(false),
          ]
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader('Comunicación al Fiscal'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _comunicacionFiscal ? Colors.blueAccent : Colors.transparent, width: 2),
            ),
            child: SwitchListTile(
              title: const Text('¿Se notificó al Ministerio Público?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Activado por defecto', style: TextStyle(color: Colors.white54, fontSize: 12)),
              activeThumbColor: Colors.blueAccent,
              value: _comunicacionFiscal,
              onChanged: (v) => setState(() => _comunicacionFiscal = v),
            ),
          ),
          if (_comunicacionFiscal) ...[
            const SizedBox(height: 24),
            _buildTextField('Nombres y Grado del Fiscal', _fiscalNombresController, Icons.person),
            const SizedBox(height: 16),
            _buildTextField('Fiscalía (Despacho)', _fiscalFiscaliaController, Icons.account_balance),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _fiscalHora ?? TimeOfDay.now());
                if (t != null) setState(() => _fiscalHora = t);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_fiscalHora == null ? 'Hora de comunicación' : _fiscalHora!.format(context), style: TextStyle(color: _fiscalHora == null ? Colors.white54 : Colors.white, fontSize: 16))),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader('¿El intervenido se negó a firmar el acta?'),
          Row(
            children: [
              Expanded(child: _buildBigButton('Sí, se negó', Icons.cancel_presentation, _negoFirmar == true, () => setState(() => _negoFirmar = true), color: Colors.redAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildBigButton('No, firmó', Icons.draw, _negoFirmar == false, () => setState(() => _negoFirmar = false), color: Colors.green)),
            ],
          ),
          if (_negoFirmar == true) ...[
            const SizedBox(height: 32),
            _buildTextField('Motivo de la negativa', _motivoNegativaController, Icons.text_snippet, maxLines: 3),
          ]
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader('Relato de los Hechos'),
          const Text('Redacta de forma precisa las circunstancias de la intervención. Esta información se inyectará en las actas principales.', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          _buildTextField('Ej: Durante el patrullaje preventivo por la zona...', _relatoController, Icons.edit_document, maxLines: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return const Scaffold(
        backgroundColor: Color(0xFF14161A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 24),
              Text('Generando actas...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Distribuyendo información en los documentos', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    final canContinue = _checkCanContinue();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF14161A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep),
        title: Row(
          children: List.generate(_totalSteps, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 4,
                decoration: BoxDecoration(
                  color: index <= _currentStep ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep0(),
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
          _buildStep5(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                disabledBackgroundColor: Colors.blueAccent.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: canContinue ? _nextStep : null,
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Generar Actas' : 'Siguiente',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  bool _checkCanContinue() {
    if (_currentStep == 1 && _huboDetenidos == null) return false;
    if (_currentStep == 2 && _huboAgraviados == null) return false;
    if (_currentStep == 4 && _negoFirmar == null) return false;
    return true;
  }
}
