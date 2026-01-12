import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

/// Dialog for importing an nsec private key.
class ImportKeyDialog extends StatefulWidget {
  const ImportKeyDialog({
    required this.onImport,
    super.key,
  });

  final void Function(String nsec) onImport;

  @override
  State<ImportKeyDialog> createState() => _ImportKeyDialogState();
}

class _ImportKeyDialogState extends State<ImportKeyDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final nsec = _controller.text.trim();

    if (nsec.isEmpty) {
      setState(() => _error = 'Please enter your nsec key');
      return;
    }

    if (!nsec.startsWith('nsec1')) {
      setState(() => _error = 'Key must start with nsec1');
      return;
    }

    Navigator.of(context).pop();
    widget.onImport(nsec);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: NesContainer(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Import Key',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your nsec private key:',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                obscureText: true,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'nsec1...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Your key is stored locally and never sent to any server.',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NesButton(
                    type: NesButtonType.normal,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  NesButton(
                    type: NesButtonType.primary,
                    onPressed: _submit,
                    child: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
