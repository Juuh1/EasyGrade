import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Status possíveis de uma avaliação dentro do fluxo do professor.
///
/// - [rascunho]: avaliação criada mas incompleta / sem data definida.
/// - [agendada]: avaliação com data futura marcada.
/// - [concluida]: avaliação já aplicada e corrigida, com resultados.
enum StatusAvaliacao { rascunho, agendada, concluida }

extension StatusAvaliacaoX on StatusAvaliacao {
  String get label {
    switch (this) {
      case StatusAvaliacao.rascunho:
        return 'Rascunho';
      case StatusAvaliacao.agendada:
        return 'Agendada';
      case StatusAvaliacao.concluida:
        return 'Concluída';
    }
  }

  /// Texto do link de ação principal exibido no card do Histórico.
  String get acaoPrincipal {
    switch (this) {
      case StatusAvaliacao.rascunho:
        return 'Continuar edição';
      case StatusAvaliacao.agendada:
        return 'Editar avaliação';
      case StatusAvaliacao.concluida:
        return 'Ver resultados';
    }
  }

  Color get bgColor {
    switch (this) {
      case StatusAvaliacao.rascunho:
        return AppColors.rascunhoBg;
      case StatusAvaliacao.agendada:
        return AppColors.agendadaBg;
      case StatusAvaliacao.concluida:
        return AppColors.concluidaBg;
    }
  }

  Color get fgColor {
    switch (this) {
      case StatusAvaliacao.rascunho:
        return AppColors.rascunhoFg;
      case StatusAvaliacao.agendada:
        return AppColors.agendadaFg;
      case StatusAvaliacao.concluida:
        return AppColors.concluidaFg;
    }
  }
}
