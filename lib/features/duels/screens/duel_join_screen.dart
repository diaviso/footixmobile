import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/duel_provider.dart';
import '../../../navigation/app_router.dart';

class DuelJoinScreen extends ConsumerStatefulWidget {
  const DuelJoinScreen({super.key});

  @override
  ConsumerState<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

class _DuelJoinScreenState extends ConsumerState<DuelJoinScreen> {
  final _controller = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duelState = ref.watch(activeDuelProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Rejoindre un Salon'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_soccer_rounded, size: 18, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                const SizedBox(width: 8),
                Text(
                  'Code du salon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                letterSpacing: 12,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'ABC123',
                hintStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 12,
                  color: (isDark ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
              onChanged: (v) {
                if (_error.isNotEmpty) setState(() => _error = '');
              },
              onSubmitted: (_) => _handleJoin(),
            ),

            if (_error.isNotEmpty || duelState.error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error.isNotEmpty ? _error : (duelState.error ?? ''),
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: duelState.isLoading ? null : _handleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: duelState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Rejoindre le salon', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleJoin() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Le code doit contenir 6 caractères');
      return;
    }
    final notifier = ref.read(activeDuelProvider.notifier);
    final duel = await notifier.joinDuel(code);
    if (duel != null && mounted) {
      if (duel.status == 'PLAYING') {
        context.go(AppRoutes.duelPlay);
      } else if (duel.status == 'FINISHED') {
        context.go(AppRoutes.duelResults);
      } else {
        context.go(AppRoutes.duelLobby);
      }
    }
  }
}
