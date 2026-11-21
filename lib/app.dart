import 'package:material_ui/material_ui.dart';

/// Placeholder root widget. MILIK B: ganti dengan MaterialApp.router (go_router),
/// tema, dan auth guard. Dipanggil oleh `main.dart` dan `dev/main_fake.dart`.
class StokflowApp extends StatelessWidget {
  const StokflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'StokFlow',
      home: Scaffold(body: Center(child: Text('StokFlow'))),
    );
  }
}
