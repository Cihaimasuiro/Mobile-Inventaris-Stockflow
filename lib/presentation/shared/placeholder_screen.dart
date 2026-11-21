import 'package:material_ui/material_ui.dart';

/// Placeholder untuk layar yang belum dikerjakan. Dipasang di `app_router.dart`;
/// pemilik layar (A/B) menggantinya dengan layar asli tanpa mengubah path.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, required this.screenNumber, required this.owner, super.key});

  final String title;

  /// Nomor layar di mockup (01-08).
  final String screenNumber;

  /// Pemilik pengerjaan (A atau B).
  final String owner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Layar $screenNumber ($title) belum dikerjakan.\nPemilik: $owner.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
