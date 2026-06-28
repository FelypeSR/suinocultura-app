import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/models/animal_model.dart';
import 'package:gspr/models/evento_model.dart';
import 'package:gspr/services/animal_service.dart';
import 'package:gspr/services/evento_service.dart';
import 'package:gspr/theme/app_theme.dart';

const _verde = Color(0xFF2E7D32);

class RegistroVacinaScreen extends StatefulWidget {
  const RegistroVacinaScreen({super.key});

  @override
  State<RegistroVacinaScreen> createState() => _RegistroVacinaScreenState();
}

class _RegistroVacinaScreenState extends State<RegistroVacinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EventoService();
  final _animalService = AnimalService();

  DateTime? _data;
  String? _via;
  String? _grupo;
  bool _salvando = false;

  // Animais escolhidos quando o grupo é "Específicos".
  List<AnimalModel> _animaisSelecionados = [];

  final _tipoVacinaCtrl = TextEditingController();
  final _dosagemCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  static const _vias = ['Intramuscular', 'Subcutânea', 'Oral', 'Intranasal'];
  static const _grupos = {
    'machos': 'Machos',
    'femeas': 'Fêmeas',
    'filhotes': 'Filhotes',
    'especificos': 'Específicos',
  };

  @override
  void dispose() {
    _tipoVacinaCtrl.dispose();
    _dosagemCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(hoje.year - 1),
      lastDate: DateTime(hoje.year + 1),
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

  Future<void> _selecionarGrupo() async {
    final selecionado = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _grupos.entries
              .map((e) => ListTile(
                    title: Text(e.value),
                    trailing: _grupo == e.key
                        ? const Icon(Icons.check, color: _verde)
                        : null,
                    onTap: () => Navigator.pop(context, e.key),
                  ))
              .toList(),
        ),
      ),
    );

    if (selecionado == null) return;

    setState(() {
      _grupo = selecionado;
      if (selecionado != 'especificos') _animaisSelecionados = [];
    });

    if (selecionado == 'especificos') {
      await _selecionarAnimais();
    }
  }

  Future<void> _selecionarAnimais() async {
    final selecionados = Set<String>.from(_animaisSelecionados.map((a) => a.id));
    final mapaAnimais = <String, AnimalModel>{};

    final confirmados = await showModalBottomSheet<List<AnimalModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Selecione os animais',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<AnimalModel>>(
                        stream: _animalService.listar(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(color: _verde),
                            );
                          }
                          final animais = snapshot.data ?? [];
                          if (animais.isEmpty) {
                            return const Center(
                              child: Text('Nenhum animal cadastrado'),
                            );
                          }
                          for (final a in animais) {
                            if (a.id != null) mapaAnimais[a.id!] = a;
                          }
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: animais.length,
                            itemBuilder: (context, i) {
                              final animal = animais[i];
                              final marcado =
                                  selecionados.contains(animal.id);
                              return CheckboxListTile(
                                activeColor: _verde,
                                value: marcado,
                                title: Text('Código ${animal.codigo}'),
                                subtitle: Text(
                                    '${animal.sexo} • ${animal.raca}'),
                                onChanged: (v) {
                                  setSheetState(() {
                                    if (v == true) {
                                      selecionados.add(animal.id!);
                                    } else {
                                      selecionados.remove(animal.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final lista = selecionados
                                .map((id) => mapaAnimais[id])
                                .whereType<AnimalModel>()
                                .toList();
                            Navigator.pop(context, lista);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _verde,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Confirmar (${selecionados.length})',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (confirmados != null) {
      setState(() => _animaisSelecionados = confirmados);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_data == null) {
      _avisar('Selecione a data');
      return;
    }
    if (_via == null) {
      _avisar('Selecione a via de aplicação');
      return;
    }
    if (_grupo == null) {
      _avisar('Selecione o grupo');
      return;
    }
    if (_grupo == 'especificos' && _animaisSelecionados.isEmpty) {
      _avisar('Selecione ao menos um animal');
      return;
    }

    setState(() => _salvando = true);
    try {
      final evento = EventoModel(
        data: _data!,
        tipoVacina: _tipoVacinaCtrl.text.trim(),
        dosagem: _dosagemCtrl.text.trim(),
        viaAplicacao: _via!,
        grupo: _grupo!,
        animaisIds: _grupo == 'especificos'
            ? _animaisSelecionados.map((a) => a.id!).toList()
            : const [],
        observacoes: _obsCtrl.text.trim(),
      );
      await _service.salvar(evento);
      if (mounted) {
        context.showSuccessSnackBar('Vacinação registrada com sucesso!');
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
      title: 'Registro',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill "ATIVIDADES" + botão fechar
              Row(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'ATIVIDADES',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Atividade selecionada (fixa: Vacina, por enquanto)
              _CaixaSelecao(
                texto: 'Vacina',
                preenchido: true,
              ),
              const SizedBox(height: 16),

              // DATA + tipo de vacina
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selecionarData,
                      child: _CaixaSelecao(
                        texto: _data != null
                            ? DateFormat('dd/MM/yyyy').format(_data!)
                            : 'DATA',
                        preenchido: _data != null,
                        comCheck: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Campo(
                      controller: _tipoVacinaCtrl,
                      hint: 'tipo de vacina',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe a vacina'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dosagem + via de aplicação
              Row(
                children: [
                  Expanded(
                    child: _Campo(
                      controller: _dosagemCtrl,
                      hint: 'Dosagem',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe a dosagem'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selecionarVia,
                      child: _CaixaSelecao(
                        texto: _via ?? 'via de aplicação',
                        preenchido: _via != null,
                        comCheck: false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grupo
              GestureDetector(
                onTap: _selecionarGrupo,
                child: _CaixaSelecao(
                  texto: _grupo != null
                      ? _grupos[_grupo]!
                      : 'selecione o grupo',
                  preenchido: _grupo != null,
                ),
              ),

              // Resumo dos animais específicos selecionados
              if (_grupo == 'especificos') ...[
                const SizedBox(height: 12),
                _ResumoAnimais(
                  animais: _animaisSelecionados,
                  onEditar: _selecionarAnimais,
                ),
              ],
              const SizedBox(height: 24),

              // Observações
              const Text(
                'Observações:',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _obsCtrl,
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

              // SALVAR
              Center(
                child: _salvando
                    ? const CircularProgressIndicator(color: _verde)
                    : ElevatedButton.icon(
                        onPressed: _salvar,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'SALVAR',
                          style:
                              TextStyle(fontSize: 18, color: Colors.white),
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

  Future<void> _selecionarVia() async {
    final selecionado = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _vias
              .map((v) => ListTile(
                    title: Text(v),
                    trailing: _via == v
                        ? const Icon(Icons.check, color: _verde)
                        : null,
                    onTap: () => Navigator.pop(context, v),
                  ))
              .toList(),
        ),
      ),
    );
    if (selecionado != null) setState(() => _via = selecionado);
  }
}

/// Caixa branca arredondada com texto e um check verde à direita.
/// Usada para os seletores (atividade, grupo, via, data).
class _CaixaSelecao extends StatelessWidget {
  final String texto;
  final bool preenchido;
  final bool comCheck;

  const _CaixaSelecao({
    required this.texto,
    this.preenchido = false,
    this.comCheck = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: preenchido ? FontWeight.w600 : FontWeight.normal,
                color: preenchido ? Colors.black87 : Colors.black38,
              ),
            ),
          ),
          if (comCheck)
            Icon(
              Icons.check,
              color: preenchido ? _verde : Colors.black26,
              size: 24,
            ),
        ],
      ),
    );
  }
}

/// Mostra os animais escolhidos quando o grupo é "Específicos".
class _ResumoAnimais extends StatelessWidget {
  final List<AnimalModel> animais;
  final VoidCallback onEditar;

  const _ResumoAnimais({required this.animais, required this.onEditar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEditar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          border: Border.all(color: _verde.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.pets, color: _verde, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                animais.isEmpty
                    ? 'Toque para selecionar animais'
                    : '${animais.length} animal(is): '
                        '${animais.map((a) => a.codigo).join(', ')}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const Icon(Icons.edit, color: _verde, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Campo de texto branco arredondado, no mesmo estilo do CadastroScreen.
class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  const _Campo({
    required this.controller,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
        errorStyle: const TextStyle(height: 0.8),
      ),
    );
  }
}