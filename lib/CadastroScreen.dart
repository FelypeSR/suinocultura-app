import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'screen_base.dart';
import 'models/animal_model.dart';
import 'services/animal_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AnimalService();

  String _sexo = 'macho';
  DateTime? _dataNascimento;
  bool _salvando = false;

  final _codigoCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _racaCtrl = TextEditingController();
  final _produtividadeCtrl = TextEditingController();
  final _saudeCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _pesoCtrl.dispose();
    _racaCtrl.dispose();
    _produtividadeCtrl.dispose();
    _saudeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: DateTime(hoje.year - 10),
      lastDate: hoje,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2E7D32),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataNascimento = picked);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataNascimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data de nascimento')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final animal = AnimalModel(
        codigo: _codigoCtrl.text.trim(),
        sexo: _sexo,
        dataNascimento: _dataNascimento!,
        peso: double.parse(_pesoCtrl.text.trim().replaceAll(',', '.')),
        raca: _racaCtrl.text.trim(),
        produtividade: _produtividadeCtrl.text.trim(),
        saude: _saudeCtrl.text.trim(),
      );
      await _service.salvar(animal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal cadastrado com sucesso!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'cadastro',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Macho / Fêmea + botão fechar
              Row(
                children: [
                  _SexoChip(
                    label: 'Macho',
                    selecionado: _sexo == 'macho',
                    onTap: () => setState(() => _sexo = 'macho'),
                  ),
                  const SizedBox(width: 12),
                  _SexoChip(
                    label: 'Fêmea',
                    selecionado: _sexo == 'femea',
                    onTap: () => setState(() => _sexo = 'femea'),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.red,
                      size: 34,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // CÓDIGO
              _Campo(
                controller: _codigoCtrl,
                hint: 'código',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o código' : null,
              ),
              const SizedBox(height: 16),

              // DATA DE NASCIMENTO + PESO
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selecionarData,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _dataNascimento != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(_dataNascimento!)
                              : 'nascimento',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: _dataNascimento != null
                                ? Colors.black87
                                : Colors.black38,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Campo(
                      controller: _pesoCtrl,
                      hint: 'peso(kg)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o peso';
                        }
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // RAÇA
              _Campo(
                controller: _racaCtrl,
                hint: 'Raça',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a raça' : null,
              ),
              const SizedBox(height: 16),

              // PRODUTIVIDADE
              _Campo(
                controller: _produtividadeCtrl,
                hint: 'produtividade',
              ),
              const SizedBox(height: 16),

              // OBSERVAÇÕES
              const Text(
                'Observações:',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _saudeCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Status de saúde, alertas...',
                  hintStyle: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black38,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // BOTÃO SALVAR
              Center(
                child: _salvando
                    ? const CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      )
                    : ElevatedButton.icon(
                        onPressed: _salvar,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'SALVAR',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SexoChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const _SexoChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
          boxShadow: selecionado
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                selecionado ? FontWeight.bold : FontWeight.normal,
            color: selecionado ? Colors.black87 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Campo({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontStyle: FontStyle.italic),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.black38,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
      ),
    );
  }
}