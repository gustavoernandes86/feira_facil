import 'package:flutter/material.dart';

/// Ponto de corte: >= 850px usa layout web, abaixo usa mobile.
const double kDesktopBreakpoint = 850;

/// Envolve as telas e seleciona o widget correto conforme largura de tela.
class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget web;

  const ResponsiveWrapper({
    super.key,
    required this.mobile,
    required this.web,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= kDesktopBreakpoint ? web : mobile;
  }
}
