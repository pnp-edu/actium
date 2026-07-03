import 'package:flutter/material.dart';

class ExportConfig {
  final bool isCarpetaFiscal;
  final String piePagina;
  final String folioInicial;

  ExportConfig({
    required this.isCarpetaFiscal,
    required this.piePagina,
    required this.folioInicial,
  });
}

class ExportConfigDialog extends StatefulWidget {
  final String format; // "PDF" o "Word"

  const ExportConfigDialog({super.key, required this.format});

  @override
  State<ExportConfigDialog> createState() => _ExportConfigDialogState();
}

class _ExportConfigDialogState extends State<ExportConfigDialog> {
  bool _isCarpetaFiscal = true;
  final _piePaginaController = TextEditingController();
  final _folioController = TextEditingController();

  @override
  void dispose() {
    _piePaginaController.dispose();
    _folioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Row(
        children: [
          Icon(
            widget.format == 'PDF' ? Icons.picture_as_pdf : Icons.description,
            color: widget.format == 'PDF' ? Colors.greenAccent : Colors.blueAccent,
          ),
          const SizedBox(width: 8),
          Text(
            'Exportar a ${widget.format}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Formato de salida:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('Carpeta Fiscal', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Genera portada inicial y agrupa actas', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: true,
                    groupValue: _isCarpetaFiscal,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      if (val != null) setState(() => _isCarpetaFiscal = val);
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Solo Actas', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Sin portada', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: false,
                    groupValue: _isCarpetaFiscal,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      if (val != null) setState(() => _isCarpetaFiscal = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Opciones adicionales:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _folioController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Folio Inicial (Opcional)',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'Ej. 1',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _piePaginaController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Pie de Página (Opcional)',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'Texto al final de cada página',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
          onPressed: () {
            Navigator.pop(
              context,
              ExportConfig(
                isCarpetaFiscal: _isCarpetaFiscal,
                piePagina: _piePaginaController.text.trim(),
                folioInicial: _folioController.text.trim(),
              ),
            );
          },
          child: const Text('Continuar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
