import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:intl/intl.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/models/animal_model.dart';
import 'package:gspr/services/animal_service.dart';
import 'package:gspr/screens/CadastroNinhadaScreen.dart';
import 'package:gspr/theme/app_theme.dart';

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

  final _random = Random();
  final _codigoCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _racaCtrl = TextEditingController();
  final _produtividadeCtrl = TextEditingController();
  final _saudeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _gerarCodigo();
  }

  /// Gera um código aleatório no formato "M-04821" / "F-04821", com o
  /// prefixo do sexo selecionado e 5 dígitos aleatórios.
  void _gerarCodigo() {
    final prefixo = _sexo == 'femea' ? 'F' : 'M';
    final numero = _random.nextInt(100000).toString().padLeft(5, '0');
    _codigoCtrl.text = '$prefixo-$numero';
  }

  /// Troca o sexo e regenera o código para refletir o novo prefixo.
  void _selecionarSexo(String sexo) {
    setState(() {
      _sexo = sexo;
      _gerarCodigo();
    });
  }

  /// Idade da fêmea em dias a partir da data de nascimento.
  bool get _disponivelCobertura {
    if (_dataNascimento == null) return false;
    return DateTime.now().difference(_dataNascimento!).inDays >= 210;
  }

  /// Dias que ainda faltam para a fêmea ficar apta à cobertura.
  int get _diasParaCobertura {
    if (_dataNascimento == null) return 210;
    final dias = DateTime.now().difference(_dataNascimento!).inDays;
    final faltam = 210 - dias;
    return faltam < 0 ? 0 : faltam;
  }

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

  /// Valida e grava o animal. Devolve o id salvo, ou null se a validação
  /// falhar ou ocorrer um erro.
  Future<String?> _persistir() async {
    if (!_formKey.currentState!.validate()) return null;
    if (_dataNascimento == null) {
      context.showErrorSnackBar('Selecione a data de nascimento');
      return null;
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
      return await _service.salvar(animal);
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Erro ao salvar: $e');
      return null;
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _salvar() async {
    final id = await _persistir();
    if (id != null && mounted) {
      context.showSuccessSnackBar('Animal cadastrado com sucesso!');
      Navigator.pop(context);
    }
  }

  /// Salva a fêmea e abre o cadastro de ninhada já vinculando-a como mãe.
  Future<void> _cadastrarFilhotes() async {
    final id = await _persistir();
    if (id == null || !mounted) return;
    final codigo = _codigoCtrl.text.trim();
    final navigator = Navigator.of(context);
    context.showSuccessSnackBar('Fêmea cadastrada! Registre a ninhada.');
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            CadastroNinhadaScreen(maeId: id, maeCodigo: codigo),
      ),
    );
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
                    onTap: () => _selecionarSexo('macho'),
                  ),
                  const SizedBox(width: 12),
                  _SexoChip(
                    label: 'Fêmea',
                    selecionado: _sexo == 'femea',
                    onTap: () => _selecionarSexo('femea'),
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

              // CÓDIGO (gerado automaticamente; editável e regenerável)
              _Campo(
                controller: _codigoCtrl,
                hint: 'código',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o código' : null,
                suffix: IconButton(
                  icon: const Icon(Icons.casino_outlined,
                      color: Color(0xFF2E7D32)),
                  tooltip: 'Gerar novo código',
                  onPressed: () => setState(_gerarCodigo),
                ),
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

              // DISPONIBILIDADE PARA COBERTURA (somente fêmeas).
              // Status automático pela idade: apta a partir de 7 meses (210 dias).
              if (_sexo == 'femea') ...[
                _IndicadorCobertura(
                  semData: _dataNascimento == null,
                  disponivel: _disponivelCobertura,
                  diasRestantes: _diasParaCobertura,
                ),
                const SizedBox(height: 16),
              ],

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

              // CADASTRO DE FILHOTES (somente fêmeas): salva a fêmea e abre a
              // tela de ninhada já vinculando-a como mãe.
              if (_sexo == 'femea') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _salvando ? null : _cadastrarFilhotes,
                    icon: const Icon(Icons.child_friendly,
                        color: Color(0xFF2E7D32)),
                    label: const Text(
                      'Cadastrar filhotes (ninhada)',
                      style: TextStyle(
                          fontSize: 16, color: Color(0xFF2E7D32)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // BOTÃO SALVAR
              Center(
                child: _salvando
                    ? const LoadingBolinhas()
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

/// Faixa que mostra, automaticamente pela idade, se a fêmea está apta à
/// cobertura (≥ 7 meses / 210 dias). Apenas informativo.
class _IndicadorCobertura extends StatelessWidget {
  final bool semData;
  final bool disponivel;
  final int diasRestantes;

  const _IndicadorCobertura({
    required this.semData,
    required this.disponivel,
    required this.diasRestantes,
  });

  @override
  Widget build(BuildContext context) {
    late final Color cor;
    late final IconData icone;
    late final String texto;

    if (semData) {
      cor = Colors.grey;
      icone = Icons.info_outline;
      texto = 'Informe o nascimento para ver a aptidão à cobertura';
    } else if (disponivel) {
      cor = const Color(0xFF2E7D32);
      icone = Icons.check_circle_outline;
      texto = 'Disponível para cobertura';
    } else {
      cor = const Color(0xFFEF6C00); // laranja
      icone = Icons.schedule;
      texto = 'Indisponível — faltam $diasRestantes dias para a cobertura';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _Campo({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.suffix,
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
        suffixIcon: suffix,
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