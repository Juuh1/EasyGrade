import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'detalhes_avaliacao_screen.dart';
import 'leitura_screen.dart';

class GabaritoScreen extends StatefulWidget {
  final String avaliacaoId;
  final bool abrirDetalhesAoSalvar;
  const GabaritoScreen(
      {super.key,
      required this.avaliacaoId,
      this.abrirDetalhesAoSalvar = false});
  @override
  State<GabaritoScreen> createState() => _GabaritoScreenState();
}

class _GabaritoScreenState extends State<GabaritoScreen> {
  List<int?>? _respostas;
  bool _alterado = false;
  Future<void> _salvar() async {
    final store = SessionScope.of(context);
    if (_respostas!.any((r) => r == null)) {
      avisar(context, 'Marque uma resposta correta em cada questão.');
      return;
    }
    if (store.correcoes(widget.avaliacaoId).isNotEmpty && _alterado) {
      if (!await confirmar(context, 'Atualizar o gabarito?',
          'As notas desta sessão serão recalculadas com as novas respostas.',
          action: 'Atualizar notas')) {
        return;
      }
      if (!mounted) return;
    }
    store.salvarGabarito(widget.avaliacaoId, _respostas!);
    if (!widget.abrirDetalhesAoSalvar) {
      Navigator.pop(context);
      avisar(context, 'Gabarito atualizado nesta sessão.');
      return;
    }
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                DetalhesAvaliacaoScreen(avaliacaoId: widget.avaliacaoId)));
  }

  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final a = store.avaliacao(widget.avaliacaoId);
    _respostas ??= [...store.gabarito(a.id)];
    final preenchidas = _respostas!.where((r) => r != null).length;
    return AppPage(
        title: 'Gabarito de referência',
        bottom: ElevatedButton(
            onPressed: _salvar,
            child: Text('Salvar gabarito · $preenchidas/${a.numQuestoes}')),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          PageHeading(
              title: 'Gabarito de referência',
              subtitle:
                  '${a.nome}\nMarque a alternativa correta de cada questão.'),
          ActionTile(
              icon: Icons.document_scanner_outlined,
              title: 'Ler gabarito pela câmera',
              subtitle: 'Experimente a leitura simulada de uma folha.',
              onTap: () async {
                final result = await Navigator.push<List<int?>>(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CapturaScreen(avaliacaoId: a.id, gabarito: true)));
                if (mounted && result != null) {
                  setState(() {
                    _respostas = result;
                    _alterado = true;
                  });
                }
              }),
          const SizedBox(height: 10),
          const InfoBanner(
              'O gabarito pertence à versão A. Folhas e leitura usam a mesma ordem nesta demonstração. Questões têm peso igual; a nota vai de 0 a 10.'),
          const SizedBox(height: 20),
          SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(children: [
                for (var q = 0; q < a.numQuestoes; q++) ...[
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        SizedBox(
                            width: 40,
                            child: Text((q + 1).toString().padLeft(2, '0'),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary))),
                        Expanded(
                            child:
                                Wrap(alignment: WrapAlignment.end, children: [
                          for (var alt = 0; alt < a.numAlternativas; alt++)
                            AnswerBubble(
                                index: alt,
                                selected: _respostas![q] == alt,
                                onTap: () => setState(() {
                                      _respostas![q] = alt;
                                      _alterado = true;
                                    }))
                        ]))
                      ])),
                  if (q != a.numQuestoes - 1) const Divider(),
                ]
              ])),
        ]));
  }
}
