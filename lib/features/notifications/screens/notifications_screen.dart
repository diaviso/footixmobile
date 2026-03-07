import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/duel_provider.dart';
import '../../../navigation/app_router.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _joiningDuelId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  Future<void> _acceptDuel(Map<String, dynamic> notif) async {
    final data = notif['data'];
    if (data == null) return;

    final parsedData = data is String ? {} : data as Map<String, dynamic>;
    final code = parsedData['code'] as String?;
    if (code == null) return;

    setState(() => _joiningDuelId = notif['id'] as String);

    final duel = await ref.read(activeDuelProvider.notifier).joinDuel(code);
    await ref.read(notificationProvider.notifier).markAsRead(notif['id'] as String);

    if (!mounted) return;
    setState(() => _joiningDuelId = null);

    if (duel != null) {
      context.go(AppRoutes.duelLobby);
    }
  }

  String _formatTimeAgo(String dateStr) {
    final diff = DateTime.now().difference(DateTime.parse(dateStr));
    final mins = diff.inMinutes;
    if (mins < 1) return "À l'instant";
    if (mins < 60) return 'Il y a ${mins}min';
    final hours = diff.inHours;
    if (hours < 24) return 'Il y a ${hours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text(
                'Tout lire',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune notification',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(notificationProvider.notifier).loadNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notif = state.notifications[index];
                      final isRead = notif['isRead'] == true;
                      final type = notif['type'] as String? ?? 'GENERAL';
                      final title = notif['title'] as String? ?? '';
                      final message = notif['message'] as String? ?? '';
                      final createdAt = notif['createdAt'] as String? ?? '';
                      final id = notif['id'] as String;
                      final data = notif['data'];
                      final hasDuelCode = type == 'DUEL_INVITE' && data != null && (data is Map && data['code'] != null);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isRead
                              ? (isDark ? AppColors.cardDark : AppColors.cardLight)
                              : (isDark ? AppColors.primary.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.04)),
                          border: Border.all(
                            color: isRead
                                ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                                : AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isRead ? null : () => ref.read(notificationProvider.notifier).markAsRead(id),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: type == 'DUEL_INVITE'
                                        ? Colors.blue.withValues(alpha: 0.1)
                                        : type == 'RANK_DROP'
                                            ? Colors.orange.withValues(alpha: 0.1)
                                            : (isDark ? AppColors.neutral800 : AppColors.neutral100),
                                  ),
                                  child: Icon(
                                    type == 'DUEL_INVITE'
                                        ? Icons.sports_mma_rounded
                                        : type == 'RANK_DROP'
                                            ? Icons.trending_down_rounded
                                            : Icons.notifications_rounded,
                                    size: 18,
                                    color: type == 'DUEL_INVITE'
                                        ? Colors.blue
                                        : type == 'RANK_DROP'
                                            ? Colors.orange
                                            : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            createdAt.isNotEmpty ? _formatTimeAgo(createdAt) : '',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: (isDark ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (hasDuelCode)
                                            SizedBox(
                                              height: 30,
                                              child: ElevatedButton.icon(
                                                onPressed: _joiningDuelId == id ? null : () => _acceptDuel(notif),
                                                icon: _joiningDuelId == id
                                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                    : const Icon(Icons.sports_mma_rounded, size: 14),
                                                label: const Text('Accepter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  elevation: 0,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
