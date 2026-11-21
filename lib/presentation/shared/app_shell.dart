import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/router/app_router.dart';
import 'package:stokflow/core/theme/app_colors.dart';
import 'package:stokflow/core/theme/app_theme.dart';

/// Kerangka dengan navigasi bawah mockup: Beranda | Scan (tombol tengah) | Riwayat.
/// Scan membuka layar penuh di atas shell, bukan tab.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomBar(
        currentIndex: navigationShell.currentIndex,
        onHome: () => navigationShell.goBranch(0),
        onHistory: () => navigationShell.goBranch(1),
        onScan: () => context.push(AppRoutes.scan),
      ),
    );
  }
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    required this.currentIndex,
    required this.onHome,
    required this.onHistory,
    required this.onScan,
    super.key,
  });

  /// 0 = Beranda, 1 = Riwayat.
  final int currentIndex;
  final VoidCallback onHome;
  final VoidCallback onHistory;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _BarItem(
                  key: const Key('nav-home'),
                  icon: Icons.home_outlined,
                  label: 'Beranda',
                  selected: currentIndex == 0,
                  onTap: onHome,
                ),
              ),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Scan',
                    child: InkResponse(
                      key: const Key('nav-scan'),
                      onTap: onScan,
                      radius: 32,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.qr_code_scanner, color: AppColors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BarItem(
                  key: const Key('nav-history'),
                  icon: Icons.receipt_long_outlined,
                  label: 'Riwayat',
                  selected: currentIndex == 1,
                  onTap: onHistory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.icon, required this.label, required this.selected, required this.onTap, super.key});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTouchTarget),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
