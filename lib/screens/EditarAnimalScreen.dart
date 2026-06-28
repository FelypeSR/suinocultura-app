import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/models/animal_model.dart';
import 'package:gspr/services/animal_service.dart';
import 'package:gspr/theme/app_theme.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';

const _verde = Color(0xFF2E7D32);

/// Tela "Editar suíno" (aberta pelo botão central da navbar).
///
/// Lista os animais cadastrados e, ao tocar em um deles, abre as ações
/// disponíveis conforme o sexo:
///  - Fêmea: "Transformar em gestante" e "Registrar venda"
///  - Macho: "Registrar cobertura" e "Registrar venda"
class EditarAnimalScreen extends StatefulWidget {
  const EditarAnimalScreen({super.key});

  @override
  State<EditarAnimalScreen> createState() => _EditarAnimalScreenState();
}

class _EditarAnimalScreenState extends State<EditarAnimalScreen> {
  final _service = AnimalService();
  final _dataFmt = DateFormat('dd/MM/yyyy');

  // Filtro por sexo: null = todos.
  String? _filtroSexo;

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Editar',
      child: Column(
        children: [
          // Cabeçalho: filtros + botão fechar.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _FiltroChip(
                  label: 'Todos',
                  ativo: _filtroSexo == null,
                  onTap: () => setState(() => _filtroSexo = null),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Machos',
                  ativo: _filtroSexo == 'macho',
                  onTap: () => setState(() => _filtroSexo = 'macho'),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Fêmeas',
                  ativo: _filtroSexo == 'femea',
                  onTap: () => setState(() => _filtroSexo = 'femea'),
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
            child: StreamBuilder<List<AnimalModel>>(
              // Lista geral e filtra por sexo em memória — evita exigir
              // índice composto no Firestore (where + orderBy).
              stream: _service.listar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: LoadingBolinhas(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                final animais = (snapshot.data ?? [])
                    .where((a) => _filtroSexo == null || a.sexo == _filtroSexo)
                    .toList();
                if (animais.isEmpty) {
                  return const Center(
                    child: Text('Nenhum animal cadastrado'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: animais.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _cardAnimal(animais[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAnimal(AnimalModel animal) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _abrirAcoes(animal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              child: Icon(
                animal.isMacho ? Icons.male : Icons.female,
                color: _verde,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código ${animal.codigo}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${animal.isMacho ? 'Macho' : 'Fêmea'} • ${animal.raca}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: animal.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet com as ações disponíveis para o animal escolhido.
  void _abrirAcoes(AnimalModel animal) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Código ${animal.codigo} • '
                  '${animal.isMacho ? 'Macho' : 'Fêmea'}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (animal.vendido)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Este animal já foi vendido.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else if (animal.isFemea) ...[
              ListTile(
                leading: const Icon(Icons.pregnant_woman, color: _verde),
                title: Text(animal.gestante
                    ? 'Atualizar gestação'
                    : 'Transformar em gestante'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _dialogGestante(animal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sell, color: _verde),
                title: const Text('Registrar venda'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _dialogVenda(animal);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.favorite, color: _verde),
                title: const Text('Registrar cobertura'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _dialogCobertura(animal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sell, color: _verde),
                title: const Text('Registrar venda'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _dialogVenda(animal);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // Ação: transformar fêmea em gestante
  // ----------------------------------------------------------------------
  Future<void> _dialogGestante(AnimalModel femea) async {
    String? machoCodigo = femea.machoCobertura;
    DateTime? dataCobertura = femea.dataCobertura;
    bool salvando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            final previsao = dataCobertura
                ?.add(const Duration(days: AnimalModel.diasGestacao));
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transformar em gestante',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Seleção do macho usado (lista de machos cadastrados).
                  const Text('Macho usado'),
                  const SizedBox(height: 6),
                  StreamBuilder<List<AnimalModel>>(
                    // Lista geral e filtra machos em memória — evita exigir
                    // índice composto no Firestore (where + orderBy).
                    stream: _service.listar(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: LoadingBolinhas(dotSize: 8)),
                        );
                      }
                      if (snap.hasError) {
                        return Text('Erro ao carregar machos: ${snap.error}',
                            style: const TextStyle(color: Colors.red));
                      }
                      final machos =
                          (snap.data ?? []).where((a) => a.isMacho).toList();
                      final codigos =
                          machos.map((m) => m.codigo).toSet().toList();
                      // Garante que o valor atual exista nas opções.
                      if (machoCodigo != null &&
                          !codigos.contains(machoCodigo)) {
                        codigos.insert(0, machoCodigo!);
                      }
                      if (codigos.isEmpty) {
                        return const Text(
                          'Nenhum macho cadastrado. Cadastre um macho antes.',
                          style: TextStyle(color: Colors.black54),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: machoCodigo,
                        isExpanded: true,
                        hint: const Text('Selecione o macho'),
                        items: codigos
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('Código $c'),
                                ))
                            .toList(),
                        onChanged: (v) => setSheet(() => machoCodigo = v),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Data da cobertura
                  const Text('Data da cobertura'),
                  const SizedBox(height: 6),
                  _SeletorData(
                    data: dataCobertura,
                    placeholder: 'Selecionar data',
                    onTap: () async {
                      final d = await _escolherData(dataCobertura);
                      if (d != null) setSheet(() => dataCobertura = d);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Previsão de parto (calculada)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _verde.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: _verde, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          previsao != null
                              ? 'Previsão de parto: ${_dataFmt.format(previsao)}'
                              : 'Previsão de parto: —',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: salvando
                          ? null
                          : () async {
                              if (machoCodigo == null) {
                                sheetContext.showErrorSnackBar(
                                    'Selecione o macho usado');
                                return;
                              }
                              if (dataCobertura == null) {
                                sheetContext.showErrorSnackBar(
                                    'Selecione a data da cobertura');
                                return;
                              }
                              setSheet(() => salvando = true);
                              try {
                                await _service.marcarGestante(
                                  femea.id!,
                                  machoCodigo: machoCodigo!,
                                  dataCobertura: dataCobertura!,
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                context.showSuccessSnackBar(
                                    'Fêmea marcada como gestante!');
                              } catch (e) {
                                setSheet(() => salvando = false);
                                if (sheetContext.mounted) {
                                  sheetContext
                                      .showErrorSnackBar('Erro ao salvar: $e');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: salvando
                          ? const LoadingBolinhas(
                              dotSize: 7,
                              cores: [Colors.white, Color(0xFFF8BBD0)],
                            )
                          : const Text('Confirmar',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
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

  // ----------------------------------------------------------------------
  // Ação: registrar venda
  // ----------------------------------------------------------------------
  Future<void> _dialogVenda(AnimalModel animal) async {
    final compradorCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    DateTime? data = DateTime.now();
    bool salvando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registrar venda',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Comprador'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: compradorCtrl,
                    decoration:
                        const InputDecoration(hintText: 'Nome do comprador'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Valor'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: valorCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0,00',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Data da venda'),
                  const SizedBox(height: 6),
                  _SeletorData(
                    data: data,
                    placeholder: 'Selecionar data',
                    onTap: () async {
                      final d = await _escolherData(data);
                      if (d != null) setSheet(() => data = d);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: salvando
                          ? null
                          : () async {
                              final comprador = compradorCtrl.text.trim();
                              final valor = double.tryParse(
                                  valorCtrl.text.trim().replaceAll(',', '.'));
                              if (comprador.isEmpty) {
                                sheetContext.showErrorSnackBar(
                                    'Informe o comprador');
                                return;
                              }
                              if (valor == null || valor <= 0) {
                                sheetContext
                                    .showErrorSnackBar('Informe um valor válido');
                                return;
                              }
                              if (data == null) {
                                sheetContext
                                    .showErrorSnackBar('Selecione a data');
                                return;
                              }
                              setSheet(() => salvando = true);
                              try {
                                await _service.registrarVenda(
                                  animal.id!,
                                  comprador: comprador,
                                  valor: valor,
                                  data: data!,
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                context.showSuccessSnackBar(
                                    'Venda registrada!');
                              } catch (e) {
                                setSheet(() => salvando = false);
                                if (sheetContext.mounted) {
                                  sheetContext
                                      .showErrorSnackBar('Erro ao salvar: $e');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: salvando
                          ? const LoadingBolinhas(
                              dotSize: 7,
                              cores: [Colors.white, Color(0xFFF8BBD0)],
                            )
                          : const Text('Confirmar',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    compradorCtrl.dispose();
    valorCtrl.dispose();
  }

  // ----------------------------------------------------------------------
  // Ação: registrar cobertura (macho)
  // ----------------------------------------------------------------------
  Future<void> _dialogCobertura(AnimalModel macho) async {
    DateTime? data = DateTime.now();
    bool salvando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registrar cobertura',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Total de coberturas já registradas (tempo real).
                  StreamBuilder<int>(
                    stream: _service.contarCoberturas(macho.id!),
                    builder: (context, snap) => Text(
                      'Coberturas registradas: ${snap.data ?? 0}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Data da cobertura'),
                  const SizedBox(height: 6),
                  _SeletorData(
                    data: data,
                    placeholder: 'Selecionar data',
                    onTap: () async {
                      final d = await _escolherData(data);
                      if (d != null) setSheet(() => data = d);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: salvando
                          ? null
                          : () async {
                              if (data == null) {
                                sheetContext
                                    .showErrorSnackBar('Selecione a data');
                                return;
                              }
                              setSheet(() => salvando = true);
                              try {
                                await _service.registrarCobertura(
                                    macho.id!, data!);
                                if (!mounted) return;
                                Navigator.pop(context);
                                context.showSuccessSnackBar(
                                    'Cobertura registrada!');
                              } catch (e) {
                                setSheet(() => salvando = false);
                                if (sheetContext.mounted) {
                                  sheetContext
                                      .showErrorSnackBar('Erro ao salvar: $e');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: salvando
                          ? const LoadingBolinhas(
                              dotSize: 7,
                              cores: [Colors.white, Color(0xFFF8BBD0)],
                            )
                          : const Text('Confirmar',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
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

  Future<DateTime?> _escolherData(DateTime? atual) {
    final hoje = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: atual ?? hoje,
      firstDate: DateTime(hoje.year - 2),
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
  }
}

/// Chip de filtro por sexo.
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? _verde : Colors.white,
          border: Border.all(color: ativo ? _verde : Colors.black26),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de status (gestante / vendido). Animais ativos não exibem nada.
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'ativo') return const SizedBox.shrink();
    final bool vendido = status == 'vendido';
    final cor = vendido ? Colors.grey : const Color(0xFFEF6C00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        vendido ? 'Vendido' : 'Gestante',
        style: TextStyle(
            color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Caixa que mostra uma data escolhida (ou placeholder) e abre o date picker.
class _SeletorData extends StatelessWidget {
  final DateTime? data;
  final String placeholder;
  final VoidCallback onTap;

  const _SeletorData({
    required this.data,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: _verde, size: 18),
            const SizedBox(width: 10),
            Text(
              data != null ? fmt.format(data!) : placeholder,
              style: TextStyle(
                color: data != null ? Colors.black87 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}