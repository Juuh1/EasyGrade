import '../services/arquivos_service.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/avaliacao.dart';
import '../models/correcao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/status_badge.dart';
import 'leitura_screen.dart';

String notaLabel(double v) =>
    v.toStringAsFixed((v * 100).round() % 10 == 0 ? 1 : 2).replaceAll('.', ',');
String respostaLabel(int? resposta) => resposta == null
    ? 'Em branco'
    : resposta == -1
    ? 'Múltipla'
    : resposta == -2
    ? 'Incerta'
    : String.fromCharCode(65 + resposta);

class ResultadosScreen extends StatefulWidget {
  final String avaliacaoId;
  const ResultadosScreen({super.key, required this.avaliacaoId});
  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  String _busca = '';
  @override
  Widget build(BuildContext _) {
    final store = SessionScope.of(context), id = widget.avaliacaoId;
    final a = store.avaliacao(id),
        lista = store.correcoes(id),
        key = store.gabarito(id);
    final filtrados =
        lista
            .where(
              (s) => '${s.alunoNome} ${s.alunoId}'.toLowerCase().contains(
                _busca.toLowerCase(),
              ),
            )
            .toList()
          ..sort((a, b) => a.alunoNome.compareTo(b.alunoNome));
    final pendentes = store
        .alunos(a.turma)
        .where((aluno) => !lista.any((r) => r.alunoId == aluno.id))
        .toList();
    return AppPage(
      title: 'Resultados da turma',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PageHeading(
            title: 'Resultados da turma',
            subtitle:
                '${a.nome}\n${a.turma} · ${lista.length} ${lista.length == 1 ? 'folha corrigida' : 'folhas corrigidas'}',
          ),
          if (lista.isEmpty)
            EmptyState(
              title: 'Nenhuma correção confirmada',
              subtitle:
                  'Prepare o gabarito e leia a primeira folha de respostas.',
              icon: Icons.insights_rounded,
              action: store.gabaritoPronto(id)
                  ? ElevatedButton(
                      onPressed: () =>
                          abrir(context, CapturaScreen(avaliacaoId: id)),
                      child: const Text('Ler primeira folha'),
                    )
                  : null,
            )
          else ...[
            SurfaceCard(
              color: AppColors.primaryDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Média da turma', color: AppColors.lavender),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        notaLabel(store.media(id)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 13),
                        child: Text(
                          '/ ${formatarPontos(a.totalPontos)}',
                          style: const TextStyle(
                            color: AppColors.lavender,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${lista.length} ${lista.length == 1 ? 'resultado confirmado' : 'resultados confirmados'} · ${pendentes.length} ${pendentes.length == 1 ? 'aluno pendente' : 'alunos pendentes'}',
                    style: const TextStyle(
                      color: AppColors.onDarkSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Metric(
                  notaLabel(lista.map((r) => r.nota(key, a)).reduce(math.max)),
                  'maior nota',
                ),
                const SizedBox(width: 12),
                Metric(
                  notaLabel(lista.map((r) => r.nota(key, a)).reduce(math.min)),
                  'menor nota',
                ),
              ],
            ),
            const SectionHeading('Análise e relatório'),
            ActionTile(
              icon: Icons.stacked_bar_chart_rounded,
              title: 'Análise por questão',
              subtitle: 'Acertos, erros e alternativas mais marcadas.',
              tint: AppColors.softPurple,
              onTap: () => abrir(context, EstatisticasScreen(avaliacaoId: id)),
            ),
            ActionTile(
              icon: Icons.table_view_outlined,
              title: 'Relatório de notas',
              subtitle: 'Veja a prévia com as respostas de cada aluno.',
              onTap: () => abrir(context, RelatorioScreen(avaliacaoId: id)),
            ),
            const SectionHeading('Resultados individuais'),
            TextField(
              onChanged: (v) => setState(() => _busca = v),
              decoration: const InputDecoration(
                hintText: 'Buscar aluno ou matrícula',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (filtrados.isEmpty)
              const EmptyState(
                title: 'Aluno não encontrado',
                subtitle: 'Tente outro nome ou matrícula.',
              )
            else
              ...filtrados.map(
                (r) => _AlunoResultTile(
                  correcao: r,
                  gabarito: key,
                  nota: r.nota(key, a),
                  onTap: () => abrir(
                    context,
                    ResultadoAlunoScreen(avaliacaoId: id, alunoId: r.alunoId),
                  ),
                ),
              ),
            if (pendentes.isNotEmpty) ...[
              const SectionHeading('Ainda sem leitura'),
              ...pendentes.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${s.nome} · ${s.id}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AlunoResultTile extends StatelessWidget {
  final Correcao correcao;
  final List<int?> gabarito;
  final double nota;
  final VoidCallback onTap;
  const _AlunoResultTile({
    required this.correcao,
    required this.gabarito,
    required this.nota,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.softPurple,
                child: Text(
                  correcao.alunoNome.isEmpty ? '?' : correcao.alunoNome[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      correcao.alunoNome,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${correcao.acertos(gabarito)}/${gabarito.length} acertos',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                notaLabel(nota),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ResultadoAlunoScreen extends StatelessWidget {
  final String avaliacaoId, alunoId;
  const ResultadoAlunoScreen({
    super.key,
    required this.avaliacaoId,
    required this.alunoId,
  });
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final a = store.avaliacao(avaliacaoId),
        r = store
            .correcoes(avaliacaoId)
            .firstWhere((r) => r.alunoId == alunoId),
        key = store.gabarito(avaliacaoId);
    final naFolha = r.gabaritoNaFolha(key);
    return AppPage(
      title: 'Resultado individual',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PageHeading(
            eyebrow: 'Correção confirmada',
            title: r.alunoNome,
            subtitle:
                '${r.alunoId} · ${a.turma} · Versão ${store.rotuloVersao(a.id, r.variante)}\n${a.nome}',
          ),
          SurfaceCard(
            color: AppColors.softPurple,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Nota da avaliação'),
                      const SizedBox(height: 8),
                      Text(
                        notaLabel(r.nota(key, a)),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                        ),
                      ),
                      Text('de ${formatarPontos(a.totalPontos)} pontos'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r.acertos(key)} de ${a.numQuestoes}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'questões corretas',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeading('Respostas da folha'),
          const Row(
            children: [
              Expanded(child: Text('Questão', style: TextStyle(fontSize: 10))),
              Expanded(
                child: Text(
                  'Marcada',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10),
                ),
              ),
              Expanded(
                child: Text(
                  'Correta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10),
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (var q = 0; q < a.numQuestoes; q++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${q + 1}'.padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            respostaLabel(r.respostas[q]),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            respostaLabel(naFolha[q]),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          r.respostas[q] == naFolha[q] && naFolha[q] != null
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          size: 20,
                          color:
                              r.respostas[q] == naFolha[q] && naFolha[q] != null
                              ? AppColors.primary
                              : AppColors.dangerFg,
                        ),
                      ],
                    ),
                  ),
                  if (q != a.numQuestoes - 1) const Divider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CapturaScreen(avaliacaoId: a.id),
              ),
            ),
            icon: const Icon(Icons.document_scanner_outlined, size: 20),
            label: const Text('Ler próxima folha'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                abrir(context, RevisaoScreen(avaliacaoId: a.id, correcao: r)),
            child: const Text('Revisar respostas deste aluno'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                abrir(context, ResultadosScreen(avaliacaoId: a.id)),
            child: const Text('Ver resultados da turma'),
          ),
        ],
      ),
    );
  }
}

class EstatisticasScreen extends StatefulWidget {
  final String avaliacaoId;
  const EstatisticasScreen({super.key, required this.avaliacaoId});
  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen> {
  int _questao = 0;
  @override
  Widget build(BuildContext _) {
    final store = SessionScope.of(context), id = widget.avaliacaoId;
    final a = store.avaliacao(id),
        lista = store.correcoes(id),
        key = store.gabarito(id);
    final counts = List.generate(
      a.numAlternativas,
      (alt) => lista.where((r) => r.respostasBase[_questao] == alt).length,
    );
    final brancos = lista
        .where((r) => r.respostasBase[_questao] == null)
        .length;
    final corretos = lista
        .where(
          (r) =>
              r.respostasBase[_questao] == key[_questao] &&
              key[_questao] != null,
        )
        .length;
    final maior = counts.isEmpty ? 0 : counts.reduce(math.max);
    final populares = counts.indexed
        .where((e) => e.$2 == maior && maior > 0)
        .map((e) => String.fromCharCode(65 + e.$1))
        .join(', ');
    return AppPage(
      title: 'Análise por questão',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            title: 'Análise por questão',
            subtitle:
                'Veja as alternativas assinaladas e identifique pontos para retomar em aula.',
          ),
          DropdownButtonFormField<int>(
            initialValue: _questao,
            items: List.generate(
              a.numQuestoes,
              (q) => DropdownMenuItem(
                value: q,
                child: Text('Questão ${(q + 1).toString().padLeft(2, '0')}'),
              ),
            ),
            onChanged: (q) => setState(() => _questao = q!),
            decoration: const InputDecoration(
              labelText: 'Questão da avaliação',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Metric(
                lista.isEmpty
                    ? '0%'
                    : '${(corretos / lista.length * 100).round()}%',
                'taxa de acerto',
                color: AppColors.softPurple,
              ),
              const SizedBox(width: 12),
              Metric('$corretos/${lista.length}', 'respostas corretas'),
            ],
          ),
          const SectionHeading('Distribuição das respostas'),
          SurfaceCard(
            child: Column(
              children: [
                for (var alt = 0; alt < a.numAlternativas; alt++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              String.fromCharCode(65 + alt),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (key[_questao] == alt)
                              const Text(
                                'Resposta correta',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              '${counts[alt]} · ${lista.isEmpty ? 0 : (counts[alt] / lista.length * 100).round()}%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: lista.isEmpty
                                ? 0
                                : counts[alt] / lista.length,
                            minHeight: 9,
                            color: key[_questao] == alt
                                ? AppColors.primary
                                : AppColors.lavender,
                            backgroundColor: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    const Text('Em branco', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text(
                      '$brancos',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InfoBanner(
            populares.isEmpty
                ? 'Ainda não há respostas confirmadas para analisar.'
                : 'Mais assinalada${populares.contains(',') ? 's' : ''}: $populares. ${key[_questao] != null && counts[key[_questao]!] == maior ? 'Observe também as alternativas incorretas para planejar a devolutiva.' : 'Compare os distratores mais escolhidos com o conteúdo trabalhado em aula.'}',
            icon: Icons.lightbulb_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class RelatorioScreen extends StatefulWidget {
  final String avaliacaoId;
  const RelatorioScreen({super.key, required this.avaliacaoId});
  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  bool _respostas = true;
  bool _exportando = false;
  @override
  Widget build(BuildContext _) {
    final store = SessionScope.of(context), id = widget.avaliacaoId;
    final a = store.avaliacao(id),
        lista = store.correcoes(id),
        key = store.gabarito(id);
    final alunos = store.alunos(a.turma);
    final corrigidos = alunos
        .where((aluno) => lista.any((r) => r.alunoId == aluno.id))
        .length;
    return AppPage(
      title: 'Relatório de notas',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PageHeading(
            title: 'Relatório de notas',
            subtitle: '${a.nome}\n${a.turma}',
          ),
          SurfaceCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(status: a.status),
                Text('$corrigidos de ${alunos.length} alunos corrigidos'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            'O arquivo Excel inclui notas, acertos, versão da prova e as alternativas marcadas por cada aluno.',
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Incluir respostas por questão',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Veja a alternativa marcada, além do acerto.',
                style: TextStyle(fontSize: 11),
              ),
              value: _respostas,
              onChanged: (v) => setState(() => _respostas = v),
            ),
          ),
          const SectionHeading('Prévia da planilha'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(
                AppColors.softPurple,
              ),
              columns: [
                const DataColumn(label: Text('Aluno')),
                const DataColumn(label: Text('Matrícula')),
                const DataColumn(label: Text('Nota')),
                const DataColumn(label: Text('Acertos')),
                if (_respostas)
                  ...List.generate(
                    a.numQuestoes,
                    (q) => DataColumn(label: Text('Q${q + 1}')),
                  ),
              ],
              rows: lista
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(Text(r.alunoNome)),
                        DataCell(Text(r.alunoId)),
                        DataCell(Text(notaLabel(r.nota(key, a)))),
                        DataCell(Text('${r.acertos(key)}')),
                        if (_respostas)
                          ...r.respostas.map(
                            (v) => DataCell(Text(respostaLabel(v))),
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: lista.isEmpty || _exportando
                ? null
                : () async {
                    setState(() => _exportando = true);
                    try {
                      await ArquivosService.compartilhar(
                        ArquivosService.relatorioExcel(
                          store,
                          id,
                          respostas: _respostas,
                        ),
                        'notas-easygrade.xlsx',
                        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                      );
                    } catch (e) {
                      if (mounted) {
                        avisar(
                          context,
                          'Não foi possível exportar a planilha. Tente novamente.',
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _exportando = false);
                    }
                  },
            icon: const Icon(Icons.file_download_outlined, size: 20),
            label: Text(_exportando ? 'Preparando arquivo…' : 'Exportar Excel'),
          ),
        ],
      ),
    );
  }
}
