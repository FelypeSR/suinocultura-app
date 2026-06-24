import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'screen_base.dart';
import 'routes.dart';
import 'models/racao_model.dart';
import 'services/racao_service.dart';

const _verde = Color(0xFF2E7D32);

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Tela principal de estoque: resumo + lista de entradas de ração.
class EstoqueRacaoScreen extends StatelessWidget {
  EstoqueRacaoScreen({super.key});

  final _service = RacaoService();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Estoque',
      child: StreamBuilder<List<RacaoModel>>(
        stream: _service.listar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _verde),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final racoes = snapshot.data ?? [];
          final custoTotal =
              racoes.fold<double>(0, (soma, r) => soma + r.custo);

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _ResumoEstoque(
                  totalEntradas: racoes.length,
                  custoTotal: custoTotal,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, Rotas.cadastroRacao),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Nova entrada',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verde,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: racoes.isEmpty
                    ? const Center(
                        child: Text(
                          'Sem estoque registrado',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: racoes.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) => _CardRacao(
                          racao: racoes[i],
                          onExcluir: () => _confirmarExclusao(
                            context,
                            racoes[i],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarExclusao(
      BuildContext context, RacaoModel racao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir entrada'),
        content: Text(
            'Remover a entrada de "${racao.tipo}" do estoque?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true && racao.id != null) {
      await _service.excluir(racao.id!);
    }
  }
}

class _ResumoEstoque extends StatelessWidget {
  final int totalEntradas;
  final double custoTotal;

  const _ResumoEstoque({
    required this.totalEntradas,
    required this.custoTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5ED84F), Color(0xFF3BA135)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _resumoItem('Entradas', '$totalEntradas'),
          ),
          Container(width: 1, height: 40, color: Colors.white38),
          Expanded(
            child: _resumoItem('Investido', _moeda.format(custoTotal)),
          ),
        ],
      ),
    );
  }

  Widget _resumoItem(String label, String valor) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _CardRacao extends StatelessWidget {
  final RacaoModel racao;
  final VoidCallback onExcluir;

  const _CardRacao({required this.racao, required this.onExcluir});

  static const _rotulosClasse = {
    'todos': 'Todos',
    'femeas': 'Fêmeas',
    'machos': 'Machos',
    'filhotes': 'Filhotes',
  };

  String _fmt(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final saldo = _fmt(racao.saldoAtual);
    final dias = racao.diasRestantes;
    final acabando = dias != null && dias <= 3;
    final classe = _rotulosClasse[racao.classe] ?? racao.classe;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: _verde),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        racao.tipo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        classe,
                        style: const TextStyle(
                            fontSize: 11, color: _verde),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$saldo ${racao.unidade} em estoque'
                  '${racao.fornecedor.isNotEmpty ? ' • ${racao.fornecedor}' : ''}',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54),
                ),
                if (dias != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    acabando
                        ? '⚠ Acaba em $dias dia(s)'
                        : 'Dura ~$dias dia(s) • ${_fmt(racao.consumoPorDia)} ${racao.unidade}/dia',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          acabando ? FontWeight.bold : FontWeight.normal,
                      color: acabando ? Colors.red : Colors.black45,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _moeda.format(racao.custo),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _verde,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onExcluir,
            icon: const Icon(Icons.delete_outline, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

/// Formulário de nova entrada de ração no estoque.
class CadastroRacaoScreen extends StatefulWidget {
  const CadastroRacaoScreen({super.key});

  @override
  State<CadastroRacaoScreen> createState() => _CadastroRacaoScreenState();
}

class _CadastroRacaoScreenState extends State<CadastroRacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = RacaoService();

  String? _tipo;
  String _unidade = 'kg';
  String _classe = 'todos';
  String _modoConsumo = 'manual';
  bool _salvando = false;

  final _quantidadeCtrl = TextEditingController();
  final _fornecedorCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();
  final _consumoCtrl = TextEditingController();
  final _observacaoCtrl = TextEditingController();

  static const _tipos = [
    'Inicial',
    'Crescimento',
    'Engorda',
    'Gestação',
    'Lactação',
  ];

  // Classes de animais que consomem a ração.
  static const _classes = {
    'todos': 'Todos',
    'femeas': 'Fêmeas',
    'machos': 'Machos',
    'filhotes': 'Filhotes',
  };

  @override
  void dispose() {
    _quantidadeCtrl.dispose();
    _fornecedorCtrl.dispose();
    _custoCtrl.dispose();
    _consumoCtrl.dispose();
    _observacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarTipo() async {
    final selecionado = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _tipos
              .map((t) => ListTile(
                    title: Text(t),
                    trailing: _tipo == t
                        ? const Icon(Icons.check, color: _verde)
                        : null,
                    onTap: () => Navigator.pop(context, t),
                  ))
              .toList(),
        ),
      ),
    );
    if (selecionado != null) setState(() => _tipo = selecionado);
  }

  double? _parseNum(String v) => double.tryParse(v.trim().replaceAll(',', '.'));

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo de ração')),
      );
      return;
    }

    final automatico = _modoConsumo == 'automatico';
    if (automatico && _parseNum(_consumoCtrl.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o consumo por dia')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final racao = RacaoModel(
        tipo: _tipo!,
        classe: _classe,
        quantidade: _parseNum(_quantidadeCtrl.text)!,
        unidade: _unidade,
        fornecedor: _fornecedorCtrl.text.trim(),
        custo: _parseNum(_custoCtrl.text)!,
        observacao: _observacaoCtrl.text.trim(),
        modoConsumo: _modoConsumo,
        consumoPorDia: automatico ? _parseNum(_consumoCtrl.text)! : 0,
      );
      await _service.salvar(racao);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrada registrada no estoque!'),
            backgroundColor: _verde,
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
      title: 'Nova entrada',
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
                    'Ração',
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
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tipo de ração
              GestureDetector(
                onTap: _selecionarTipo,
                child: _CaixaSelecao(
                  texto: _tipo ?? 'tipo de ração',
                  preenchido: _tipo != null,
                ),
              ),
              const SizedBox(height: 16),

              // Classe de animal
              const Text(
                'Classe',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _classes.entries
                    .map((e) => _ChipClasse(
                          label: e.value,
                          selecionado: _classe == e.key,
                          onTap: () => setState(() => _classe = e.key),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Quantidade + unidade
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Campo(
                      controller: _quantidadeCtrl,
                      hint: 'quantidade',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe a quantidade';
                        }
                        if (_parseNum(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SeletorUnidade(
                      valor: _unidade,
                      onChanged: (u) => setState(() => _unidade = u),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fornecedor
              _Campo(
                controller: _fornecedorCtrl,
                hint: 'fornecedor',
              ),
              const SizedBox(height: 16),

              // Custo
              _Campo(
                controller: _custoCtrl,
                hint: 'custo total (R\$)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o custo';
                  }
                  if (_parseNum(v) == null) return 'Inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Consumo por dia: manual ou automático
              const Text(
                'Consumo por dia',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _modoConsumo,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'manual',
                        child: Text('Manual'),
                      ),
                      DropdownMenuItem(
                        value: 'automatico',
                        child: Text('Automático'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _modoConsumo = v ?? 'manual'),
                  ),
                ),
              ),
              // No modo automático, desconta a quantidade abaixo todo dia.
              if (_modoConsumo == 'automatico') ...[
                const SizedBox(height: 12),
                _Campo(
                  controller: _consumoCtrl,
                  hint: 'consumo por dia (kg)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o consumo por dia';
                    }
                    if (_parseNum(v) == null) return 'Inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'O estoque é descontado automaticamente a cada dia.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
              const SizedBox(height: 16),

              // Observação
              const Text(
                'Observação',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacaoCtrl,
                maxLines: 3,
                style: const TextStyle(fontStyle: FontStyle.italic),
                decoration: InputDecoration(
                  hintText: 'anotações...',
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
}

/// Alternador kg / sacos.
class _SeletorUnidade extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;

  const _SeletorUnidade({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _opcao('kg'),
          _opcao('sacos'),
        ],
      ),
    );
  }

  Widget _opcao(String u) {
    final selecionado = valor == u;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(u),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selecionado ? _verde : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            u,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              color: selecionado ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip selecionável de classe de animal (Todos / Fêmeas / Machos / Filhotes).
class _ChipClasse extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const _ChipClasse({
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? _verde : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: selecionado ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

/// Caixa branca arredondada com texto e check verde (seletor de tipo).
class _CaixaSelecao extends StatelessWidget {
  final String texto;
  final bool preenchido;

  const _CaixaSelecao({required this.texto, this.preenchido = false});

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

/// Campo de texto branco arredondado, no mesmo estilo das outras telas.
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
        errorStyle: const TextStyle(height: 0.8),
      ),
    );
  }
}