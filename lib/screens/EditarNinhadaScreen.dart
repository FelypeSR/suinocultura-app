import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/models/animal_model.dart';
import 'package:gspr/models/ninhada_model.dart';
import 'package:gspr/services/animal_service.dart';
import 'package:gspr/services/ninhada_service.dart';
import 'package:gspr/theme/app_theme.dart';

const _verde = Color(0xFF2E7D32);

final _dataFmt = DateFormat('dd/MM/yyyy');

/// Edição de ninhadas: lista as ninhadas registradas e, ao tocar em uma,
/// abre o formulário para ajustar data, número de machos e fêmeas, mãe e pai.
class EditarNinhadaScreen extends StatelessWidget {
  EditarNinhadaScreen({super.key});

  // Stream criada uma vez: rebuilds não reabrem a consulta no Firestore.
  late final _ninhadas = NinhadaService().listar();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Ninhadas',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                const Text(
                  'Editar ninhada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 30),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NinhadaModel>>(
              stream: _ninhadas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingBolinhas());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                final ninhadas = snapshot.data ?? [];
                if (ninhadas.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma ninhada registrada',
                      style: TextStyle(color: Colors.black45),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: ninhadas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _cardNinhada(context, ninhadas[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardNinhada(BuildContext context, NinhadaModel n) {
    // Composição machos/fêmeas só aparece quando já foi informada.
    final composicao = (n.machos > 0 || n.femeas > 0)
        ? ' • ${n.machos} M / ${n.femeas} F'
        : '';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FormEditarNinhada(ninhada: n),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.child_friendly, color: _verde),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mãe ${n.maeCodigo}'
                    '${n.paiCodigo.trim().isEmpty ? '' : ' • Pai ${n.paiCodigo}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_dataFmt.format(n.data)} • ${n.nascidos} nascidos'
                    '$composicao',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_note, color: _verde),
          ],
        ),
      ),
    );
  }
}

/// Formulário de edição de uma ninhada: mãe, pai, data do parto e a
/// composição da leitegada (nº de machos e nº de fêmeas). O total de
/// nascidos passa a ser machos + fêmeas.
class _FormEditarNinhada extends StatefulWidget {
  final NinhadaModel ninhada;

  const _FormEditarNinhada({required this.ninhada});

  @override
  State<_FormEditarNinhada> createState() => _FormEditarNinhadaState();
}

class _FormEditarNinhadaState extends State<_FormEditarNinhada> {
  final _formKey = GlobalKey<FormState>();
  final _service = NinhadaService();
  final _animalService = AnimalService();

  late DateTime _data = widget.ninhada.data;
  String? _maeId;
  String? _paiId;
  bool _salvando = false;

  late final _maeCodigoCtrl =
      TextEditingController(text: widget.ninhada.maeCodigo);
  late final _paiCodigoCtrl =
      TextEditingController(text: widget.ninhada.paiCodigo);
  // Composição ainda não informada (registros antigos) começa em branco.
  late final _machosCtrl = TextEditingController(
      text: widget.ninhada.machos > 0 || widget.ninhada.femeas > 0
          ? '${widget.ninhada.machos}'
          : '');
  late final _femeasCtrl = TextEditingController(
      text: widget.ninhada.machos > 0 || widget.ninhada.femeas > 0
          ? '${widget.ninhada.femeas}'
          : '');

  @override
  void initState() {
    super.initState();
    _maeId = widget.ninhada.maeId;
    _paiId = widget.ninhada.paiId;
  }

  @override
  void dispose() {
    _maeCodigoCtrl.dispose();
    _paiCodigoCtrl.dispose();
    _machosCtrl.dispose();
    _femeasCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
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

  /// Abre um seletor com os animais do sexo pedido para escolher a mãe ou o
  /// pai. Devolve o animal escolhido (ou null se fechar sem escolher).
  Future<AnimalModel?> _selecionarAnimal(String sexo, String titulo) {
    return showModalBottomSheet<AnimalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                titulo,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<AnimalModel>>(
                stream: _animalService.listarPorSexo(sexo),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LoadingBolinhas());
                  }
                  final animais = snapshot.data ?? [];
                  if (animais.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Nenhum animal cadastrado.\n'
                          'Você pode digitar o código manualmente.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: animais.length,
                    itemBuilder: (context, i) {
                      final a = animais[i];
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
        ),
      ),
    );
  }

  Future<void> _selecionarMae() async {
    final escolhida =
        await _selecionarAnimal('femea', 'Selecione a mãe (fêmeas)');
    if (escolhida != null) {
      setState(() {
        _maeId = escolhida.id;
        _maeCodigoCtrl.text = escolhida.codigo;
      });
    }
  }

  Future<void> _selecionarPai() async {
    final escolhido =
        await _selecionarAnimal('macho', 'Selecione o pai (machos)');
    if (escolhido != null) {
      setState(() {
        _paiId = escolhido.id;
        _paiCodigoCtrl.text = escolhido.codigo;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final machos = int.parse(_machosCtrl.text.trim());
    final femeas = int.parse(_femeasCtrl.text.trim());
    final nascidos = machos + femeas;

    if (nascidos <= 0) {
      _avisar('Informe pelo menos um leitão (macho ou fêmea)');
      return;
    }
    // Mortos e desmamados não são editados aqui, mas o novo total precisa
    // continuar comportando os valores já registrados.
    if (widget.ninhada.mortos > nascidos) {
      _avisar('Total (machos + fêmeas) não pode ser menor que os '
          '${widget.ninhada.mortos} mortos já registrados');
      return;
    }
    if (widget.ninhada.desmamados > nascidos) {
      _avisar('Total (machos + fêmeas) não pode ser menor que os '
          '${widget.ninhada.desmamados} desmamados já registrados');
      return;
    }

    setState(() => _salvando = true);
    try {
      final ninhada = NinhadaModel(
        id: widget.ninhada.id,
        maeId: _maeId,
        maeCodigo: _maeCodigoCtrl.text.trim(),
        paiId: _paiId,
        paiCodigo: _paiCodigoCtrl.text.trim(),
        data: _data,
        nascidos: nascidos,
        machos: machos,
        femeas: femeas,
        mortos: widget.ninhada.mortos,
        desmamados: widget.ninhada.desmamados,
        observacao: widget.ninhada.observacao,
        criadoEm: widget.ninhada.criadoEm,
      );
      await _service.salvar(ninhada);
      if (mounted) {
        context.showSuccessSnackBar('Ninhada atualizada com sucesso!');
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

  String? _validarContagem(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe';
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return 'Inválido';
    return null;
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
                  Expanded(
                    child: Text(
                      'Editar ninhada — mãe ${widget.ninhada.maeCodigo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
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
                  icon: const Icon(Icons.female, color: _verde),
                  tooltip: 'Selecionar do rebanho',
                  onPressed: _selecionarMae,
                ),
              ),
              const SizedBox(height: 16),

              // PAI (código) + botão de escolher do rebanho
              _Campo(
                controller: _paiCodigoCtrl,
                hint: 'código do pai (opcional)',
                onChanged: (_) {
                  if (_paiId != null) setState(() => _paiId = null);
                },
                suffix: IconButton(
                  icon: const Icon(Icons.male, color: _verde),
                  tooltip: 'Selecionar do rebanho',
                  onPressed: _selecionarPai,
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
                          _dataFmt.format(_data),
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
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

              // Nº DE MACHOS + Nº DE FÊMEAS
              Row(
                children: [
                  Expanded(
                    child: _Campo(
                      controller: _machosCtrl,
                      hint: 'nº de machos',
                      keyboardType: TextInputType.number,
                      validator: _validarContagem,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Campo(
                      controller: _femeasCtrl,
                      hint: 'nº de fêmeas',
                      keyboardType: TextInputType.number,
                      validator: _validarContagem,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'O total de nascidos passa a ser machos + fêmeas.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 32),

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
