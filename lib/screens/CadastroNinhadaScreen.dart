import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/models/animal_model.dart';
import 'package:gspr/models/ninhada_model.dart';
import 'package:gspr/services/animal_service.dart';
import 'package:gspr/services/ninhada_service.dart';
import 'package:gspr/theme/app_theme.dart';

const _verde = Color(0xFF2E7D32);

/// Cadastro de uma ninhada (leitegada): mãe, data do parto, nascidos,
/// mortos e desmamados. Alimenta o relatório em PDF e o resumo da home.
class CadastroNinhadaScreen extends StatefulWidget {
  /// Quando a tela é aberta a partir do cadastro de uma fêmea, a mãe já vem
  /// pré-selecionada (id + código), evitando escolhê-la de novo.
  final String? maeId;
  final String? maeCodigo;

  const CadastroNinhadaScreen({super.key, this.maeId, this.maeCodigo});

  @override
  State<CadastroNinhadaScreen> createState() => _CadastroNinhadaScreenState();
}

class _CadastroNinhadaScreenState extends State<CadastroNinhadaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = NinhadaService();
  final _animalService = AnimalService();

  DateTime? _data;
  String? _maeId; // preenchido quando a mãe é escolhida do rebanho
  bool _salvando = false;

  final _maeCodigoCtrl = TextEditingController();
  final _nascidosCtrl = TextEditingController();
  final _mortosCtrl = TextEditingController();
  final _desmamadosCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mãe vinda do cadastro da fêmea, se houver.
    _maeId = widget.maeId;
    if (widget.maeCodigo != null) _maeCodigoCtrl.text = widget.maeCodigo!;
  }

  @override
  void dispose() {
    _maeCodigoCtrl.dispose();
    _nascidosCtrl.dispose();
    _mortosCtrl.dispose();
    _desmamadosCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(hoje.year - 5),
      lastDate: hoje,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _verde,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _data = picked);
  }

  /// Abre um seletor com as fêmeas do rebanho para escolher a mãe.
  /// Preenche o código e guarda o id do animal.
  Future<void> _selecionarMae() async {
    final escolhida = await showModalBottomSheet<AnimalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Selecione a mãe (fêmeas)',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<AnimalModel>>(
                    stream: _animalService.listarPorSexo('femea'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _verde),
                        );
                      }
                      final femeas = snapshot.data ?? [];
                      if (femeas.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Nenhuma fêmea cadastrada.\n'
                              'Você pode digitar o código da mãe manualmente.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: femeas.length,
                        itemBuilder: (context, i) {
                          final a = femeas[i];
                          return ListTile(
                            leading: const Icon(Icons.pets, color: _verde),
                            title: Text('Código ${a.codigo}'),
                            subtitle: Text('${a.raca} • ${a.idadeEmMeses} meses'),
                            onTap: () => Navigator.pop(context, a),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (escolhida != null) {
      setState(() {
        _maeId = escolhida.id;
        _maeCodigoCtrl.text = escolhida.codigo;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      _avisar('Selecione a data do parto');
      return;
    }

    final nascidos = int.parse(_nascidosCtrl.text.trim());
    final mortos = int.tryParse(_mortosCtrl.text.trim()) ?? 0;
    final desmamados = int.tryParse(_desmamadosCtrl.text.trim()) ?? 0;

    if (mortos > nascidos) {
      _avisar('Mortos não pode ser maior que nascidos');
      return;
    }
    if (desmamados > nascidos) {
      _avisar('Desmamados não pode ser maior que nascidos');
      return;
    }

    setState(() => _salvando = true);
    try {
      final ninhada = NinhadaModel(
        maeId: _maeId,
        maeCodigo: _maeCodigoCtrl.text.trim(),
        data: _data!,
        nascidos: nascidos,
        mortos: mortos,
        desmamados: desmamados,
        observacao: _obsCtrl.text.trim(),
      );
      await _service.salvar(ninhada);
      if (mounted) {
        context.showSuccessSnackBar('Ninhada registrada com sucesso!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _avisar('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _avisar(String msg) {
    context.showErrorSnackBar(msg);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Ninhada',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Nova ninhada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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

              // MÃE (código) + botão de escolher do rebanho
              _Campo(
                controller: _maeCodigoCtrl,
                hint: 'código da mãe',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe a mãe'
                    : null,
                onChanged: (_) {
                  // Se o usuário digitar manualmente, desvincula do animal.
                  if (_maeId != null) setState(() => _maeId = null);
                },
                suffix: IconButton(
                  icon: const Icon(Icons.pets, color: _verde),
                  tooltip: 'Selecionar do rebanho',
                  onPressed: _selecionarMae,
                ),
              ),
              const SizedBox(height: 16),

              // DATA DO PARTO
              GestureDetector(
                onTap: _selecionarData,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _data != null
                              ? DateFormat('dd/MM/yyyy').format(_data!)
                              : 'data do parto',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: _data != null
                                ? Colors.black87
                                : Colors.black38,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today,
                          color: _verde, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // NASCIDOS + MORTOS
              Row(
                children: [
                  Expanded(
                    child: _Campo(
                      controller: _nascidosCtrl,
                      hint: 'nascidos',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Campo(
                      controller: _mortosCtrl,
                      hint: 'mortos',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return int.tryParse(v.trim()) == null
                            ? 'Inválido'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // DESMAMADOS
              _Campo(
                controller: _desmamadosCtrl,
                hint: 'desmamados',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return int.tryParse(v.trim()) == null ? 'Inválido' : null;
                },
              ),
              const SizedBox(height: 16),

              // OBSERVAÇÕES
              const Text(
                'Observações:',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _obsCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Intercorrências, peso médio...',
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

              Center(
                child: _salvando
                    ? const CircularProgressIndicator(color: _verde)
                    : ElevatedButton.icon(
                        onPressed: _salvar,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'SALVAR',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _verde,
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

/// Campo de texto branco arredondado, no mesmo estilo das demais telas.
class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffix;

  const _Campo({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
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
        errorStyle: const TextStyle(height: 0.8),
      ),
    );
  }
}
