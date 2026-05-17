import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../core/widgets/web_sidebar.dart';
import '../../../core/widgets/premium_header.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return ResponsiveWrapper(
      mobile: Scaffold(
        backgroundColor: context.colorBackground,
        body: Column(
          children: [
            const PremiumHeader(
              title: 'Notificações',
              subtitle: 'Acompanhe as novidades do seu grupo',
            ),
            Expanded(
              child: _buildMobileBody(context, ref, notificationsAsync),
            ),
          ],
        ),
      ),
      web: Scaffold(
        backgroundColor: context.colorBackground,
        body: _buildWebBody(context, ref, notificationsAsync),
      ),
    );
  }

  // ── Mobile Body Layout ─────────────────────────────────────────────────────
  Widget _buildMobileBody(
      BuildContext context, WidgetRef ref, AsyncValue notificationsAsync) {
    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 80, color: context.colorTextSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma notificação',
                  style: TextStyle(
                    fontSize: 18,
                    color: context.colorTextSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Você será avisado quando algo importante acontecer.',
                  style: TextStyle(color: context.colorTextSecondary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENTES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: context.colorTextSecondary,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.colorGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () {
                      ref.read(notificationControllerProvider).markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Todas marcadas como lidas')),
                      );
                    },
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text(
                      'Marcar todas como lidas',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final isRead = notification.isRead;

            return InkWell(
              onTap: () {
                if (!isRead) {
                  ref.read(notificationControllerProvider).markAsRead(notification.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isRead ? Colors.transparent : context.colorGreen.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: context.colorBorder,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isRead ? context.colorCard : context.colorGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(notification.type),
                        color: isRead ? context.colorTextSecondary : context.colorGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    color: context.colorTextPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isRead ? context.colorTextTertiary : context.colorGreen,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.body,
                            style: TextStyle(
                              color: context.colorTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
},
      loading: () => Center(child: CircularProgressIndicator(color: context.colorGreen)),
      error: (error, _) => Center(child: Text('Erro ao carregar notificações: $error')),
    );
  }

  // ── Web Body Layout ────────────────────────────────────────────────────────
  Widget _buildWebBody(
      BuildContext context, WidgetRef ref, AsyncValue notificationsAsync) {
    return Row(
      children: [
        const WebSidebar(active: NavSection.notifications),
        Expanded(
          child: Column(
            children: [
              WebTopBar(
                title: 'Notificações',
                subtitle: 'Acompanhe as atualizações de listas, grupos e convites familiares.',
                actions: [
                  WebActionButton(
                    label: 'Marcar todas como lidas',
                    icon: Icons.done_all_rounded,
                    onPressed: () {
                      ref.read(notificationControllerProvider).markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Todas marcadas como lidas')),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colorCard,
                          borderRadius: BorderRadius.circular(AppColors.radiusXl),
                          border: Border.all(color: context.colorBorder),
                          boxShadow: context.shadow2,
                        ),
                        child: notificationsAsync.when(
                          data: (notifications) {
                            if (notifications.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.notifications_none_rounded,
                                      size: 72,
                                      color: context.colorTextSecondary.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Tudo limpo por aqui!',
                                      style: GoogleFonts.fraunces(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: context.colorTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Você não tem nenhuma notificação no momento.',
                                      style: TextStyle(
                                        color: context.colorTextSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: notifications.map<Widget>((notification) {
                                final isRead = notification.isRead;
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: context.colorBorder),
                                    ),
                                    color: isRead ? Colors.transparent : context.colorGreen.withValues(alpha: 0.03),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Visual read indicator bar on left side
                                        Container(
                                          width: 4,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: isRead ? Colors.transparent : context.colorGreen,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isRead ? context.colorBackground : context.colorGreen.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _getIconForType(notification.type),
                                            color: isRead ? context.colorTextSecondary : context.colorGreen,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Description details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    notification.title,
                                                    style: TextStyle(
                                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                      color: context.colorTextPrimary,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat('dd/MM - HH:mm').format(notification.createdAt),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: context.colorTextTertiary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                notification.body,
                                                style: TextStyle(
                                                  color: context.colorTextSecondary,
                                                  fontSize: 13,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Read/Unread action
                                        const SizedBox(width: 20),
                                        if (!isRead)
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: context.colorGreen,
                                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: () {
                                              ref.read(notificationControllerProvider).markAsRead(notification.id);
                                            },
                                            child: const Text('Marcar como lida'),
                                          )
                                        else
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Icon(
                                              Icons.check_circle_outline_rounded,
                                              color: context.colorTextTertiary,
                                              size: 18,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: CircularProgressIndicator(color: context.colorGreen),
                            ),
                          ),
                          error: (error, _) => Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Text('Erro ao carregar notificações: $error'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'list_created':
        return Icons.add_task_rounded;
      case 'group_invite':
        return Icons.group_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }
}
