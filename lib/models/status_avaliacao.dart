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
