import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
