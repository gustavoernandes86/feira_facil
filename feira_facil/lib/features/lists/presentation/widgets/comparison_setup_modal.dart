import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/features/markets/presentation/markets_controller.dart';
import 'package:feira_facil/features/markets/domain/market.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

/// Resultado da seleção do modal de configuração da comparação
class ComparisonSetup {
  final FairList selectedList;
  final List<Market> selectedMarkets;

  ComparisonSetup({required this.selectedList, required this.selectedMarkets});
}

/// Modal para selecionar lista e mercado(s) antes de gerar a comparação
class ComparisonSetupModal extends ConsumerStatefulWidget {
  const ComparisonSetupModal({super.key});

  @override
  ConsumerState<ComparisonSetupModal> createState() => _ComparisonSetupModalState();
}

class _ComparisonSetupModalState extends ConsumerState<ComparisonSetupModal> {
  FairList? _selectedList;
  final Set<String> _selectedMarketIds = {};

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    final listsAsync = groupId != null
        ? ref.watch(fairListsStreamProvider(groupId))
        : const AsyncValue<List<FairList>>.loading();
    final marketsAsync = groupId != null
        ? ref.watch(marketsStreamProvider(groupId))
        : const AsyncValue<List<Market>>.loading();

    return Container(
      decoration: BoxDecoration(
        color: context.colorBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colorOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics_outlined, color: context.colorOrange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nova Comparação',
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Escolha a lista e os mercados para comparar',
                        style: TextStyle(fontSize: 12, color: context.colorTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Seleção de Lista
            Text(
              'LISTA DE COMPRAS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: context.colorTextTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            listsAsync.when(
              data: (lists) {
                if (lists.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colorBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nenhuma lista encontrada. Crie uma lista primeiro.',
                      style: TextStyle(color: context.colorTextSecondary),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedList?.id,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.list_alt_rounded, size: 20, color: context.colorGreen),
                    filled: true,
                    fillColor: context.colorBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Selecione uma lista',
                  ),
                  items: lists.map((list) {
                    return DropdownMenuItem<String>(
                      value: list.id,
                      child: Text(list.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedList = lists.firstWhere((l) => l.id == val);
                      });
                    }
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erro ao carregar listas'),
            ),

            const SizedBox(height: 24),

            // Seleção de Mercados
            Text(
              'MERCADOS PARA COMPARAR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: context.colorTextTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecione os mercados que deseja incluir na comparação',
              style: TextStyle(fontSize: 12, color: context.colorTextSecondary),
            ),
            const SizedBox(height: 10),
            marketsAsync.when(
              data: (markets) {
                if (markets.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colorBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nenhum mercado cadastrado. Cadastre mercados primeiro.',
                      style: TextStyle(color: context.colorTextSecondary),
                    ),
                  );
                }
                return Column(
                  children: [
                    // Selecionar todos
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_selectedMarketIds.length == markets.length) {
                            _selectedMarketIds.clear();
                          } else {
                            _selectedMarketIds.clear();
                            _selectedMarketIds.addAll(markets.map((m) => m.id));
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedMarketIds.length == markets.length && markets.isNotEmpty,
                              tristate: true,
                              activeColor: context.colorOrange,
                              onChanged: (_) {
                                setState(() {
                                  if (_selectedMarketIds.length == markets.length) {
                                    _selectedMarketIds.clear();
                                  } else {
                                    _selectedMarketIds.clear();
                                    _selectedMarketIds.addAll(markets.map((m) => m.id));
                                  }
                                });
                              },
                            ),
                            Text(
                              'Selecionar Todos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: context.colorTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ...markets.map((market) {
                      final isSelected = _selectedMarketIds.contains(market.id);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMarketIds.remove(market.id);
                            } else {
                              _selectedMarketIds.add(market.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: context.colorOrange,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedMarketIds.add(market.id);
                                    } else {
                                      _selectedMarketIds.remove(market.id);
                                    }
                                  });
                                },
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? context.colorOrange.withValues(alpha: 0.1) : context.colorBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.storefront,
                                  size: 18,
                                  color: isSelected ? context.colorOrange : context.colorTextTertiary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      market.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected ? context.colorTextBody : context.colorTextSecondary,
                                      ),
                                    ),
                                    if (market.address.isNotEmpty)
                                      Text(
                                        market.address,
                                        style: TextStyle(fontSize: 11, color: context.colorTextTertiary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erro ao carregar mercados'),
            ),

            const SizedBox(height: 28),

            // Botão de confirmar
            ElevatedButton(
              onPressed: _canProceed(marketsAsync)
                  ? () {
                      final markets = marketsAsync.value ?? [];
                      final selectedMarkets = markets
                          .where((m) => _selectedMarketIds.contains(m.id))
                          .toList();
                      Navigator.pop(
                        context,
                        ComparisonSetup(
                          selectedList: _selectedList!,
                          selectedMarkets: selectedMarkets,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDark ? context.colorGreenDark : context.colorGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: context.colorBorder,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'COMPARAR PREÇOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Resumo da seleção
            if (_selectedList != null || _selectedMarketIds.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  _buildSummaryText(marketsAsync),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: context.colorTextTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canProceed(AsyncValue<List<Market>> marketsAsync) {
    return _selectedList != null && _selectedMarketIds.isNotEmpty;
  }

  String _buildSummaryText(AsyncValue<List<Market>> marketsAsync) {
    final parts = <String>[];
    if (_selectedList != null) {
      parts.add('"${_selectedList!.name}"');
    }
    if (_selectedMarketIds.isNotEmpty) {
      final count = _selectedMarketIds.length;
      parts.add('$count mercado${count > 1 ? 's' : ''}');
    }
    return parts.join(' · ');
  }
}
