import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/di/providers.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/theme/app_colors.dart';
import 'package:stokflow/core/theme/app_theme.dart';
import 'package:stokflow/core/utils/transaction_number.dart';
import 'package:stokflow/domain/entities/inputs.dart';

/// Layar 01: Masuk dan Daftar Baru (+ buat toko). FR-01 sampai FR-03.
/// Setelah sukses, navigasi dilakukan auth guard di router (sesi berubah), bukan di sini.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _Mode { login, register }

/// Email (ada `@` dan domain) atau nomor HP (9-15 digit; spasi, `-`, `+` diabaikan).
bool looksLikeEmailOrPhone(String raw) {
  final v = raw.trim();
  if (v.contains('@')) return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
  return RegExp(r'^\d{9,15}$').hasMatch(v.replaceAll(RegExp(r'[\s\-+]'), ''));
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _businessName = TextEditingController();
  final _businessCode = TextEditingController();

  _Mode _mode = _Mode.login;
  bool _showPassword = false;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};
  String? _formError;

  @override
  void dispose() {
    for (final c in [_identifier, _password, _name, _businessName, _businessCode]) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchMode(_Mode mode) => setState(() {
    _mode = mode;
    _fieldErrors = const {};
    _formError = null;
  });

  Map<String, String> _validate() => {
    if (_identifier.text.trim().isEmpty) 'identifier': 'Nomor HP atau email wajib diisi.',
    if (_password.text.isEmpty) 'password': 'PIN / kata sandi wajib diisi.',
    if (_mode == _Mode.register) ...{
      if (_name.text.trim().isEmpty) 'name': 'Nama pemilik wajib diisi.',
      if (_businessName.text.trim().isEmpty) 'businessName': 'Nama toko wajib diisi.',
      if (!isValidBusinessCode(_businessCode.text)) 'businessCode': 'Kode toko 2-10 karakter, huruf besar atau angka.',
    },
  };

  Future<void> _submit() async {
    final local = _validate();
    setState(() {
      _fieldErrors = local;
      _formError = null;
    });
    if (local.isNotEmpty) return;

    setState(() => _submitting = true);
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_mode == _Mode.login) {
        await auth.login(identifier: _identifier.text.trim(), password: _password.text);
      } else {
        await auth.register(
          RegisterInput(
            name: _name.text.trim(),
            identifier: _identifier.text.trim(),
            password: _password.text,
            businessName: _businessName.text.trim(),
            businessCode: _businessCode.text,
          ),
        );
      }
    } on ValidationException catch (e) {
      const visible = {'identifier', 'password', 'name', 'businessName', 'businessCode'};
      final onFields = {
        for (final entry in e.fieldErrors.entries)
          if (visible.contains(entry.key)) entry.key: entry.value,
      };
      if (mounted) {
        setState(() {
          _fieldErrors = onFields;
          _formError = onFields.length == e.fieldErrors.length ? null : e.message;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final register = _mode == _Mode.register;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Hero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModeTabs(mode: _mode, onChanged: _switchMode),
                  const SizedBox(height: 16),
                  if (_formError != null) ...[_FormError(message: _formError!), const SizedBox(height: 12)],
                  if (register) ...[
                    _LabeledField(
                      fieldKey: const Key('auth-name'),
                      label: 'Nama Pemilik',
                      controller: _name,
                      error: _fieldErrors['name'],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _LabeledField(
                    fieldKey: const Key('auth-identifier'),
                    label: 'Nomor HP atau Email',
                    controller: _identifier,
                    error: _fieldErrors['identifier'],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    suffix: looksLikeEmailOrPhone(_identifier.text)
                        ? const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Text(
                              'Valid',
                              style: TextStyle(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    fieldKey: const Key('auth-password'),
                    label: 'PIN / Kata Sandi',
                    controller: _password,
                    error: _fieldErrors['password'],
                    obscure: !_showPassword,
                    textInputAction: register ? TextInputAction.next : TextInputAction.done,
                    onSubmitted: register ? null : (_) => _submit(),
                    suffix: TextButton(
                      key: const Key('auth-toggle-password'),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                      child: Text(_showPassword ? 'Sembunyikan' : 'Tampilkan'),
                    ),
                  ),
                  if (register) ...[
                    const SizedBox(height: 12),
                    _LabeledField(
                      fieldKey: const Key('auth-business-name'),
                      label: 'Nama Toko',
                      controller: _businessName,
                      error: _fieldErrors['businessName'],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      fieldKey: const Key('auth-business-code'),
                      label: 'Kode Toko',
                      controller: _businessCode,
                      error: _fieldErrors['businessCode'],
                      helper: 'Contoh: TMJ01. Dipakai pada nomor transaksi dan tidak bisa diubah.',
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                        TextInputFormatter.withFunction((old, value) => value.copyWith(text: value.text.toUpperCase())),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('auth-submit'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : Text(register ? 'Buat Toko & Masuk' : 'Lanjut ke Toko Saya'),
                  ),
                  const SizedBox(height: 16),
                  const _OfflineBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 28, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'StokFlow',
                    style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text('Inventaris UMKM', style: TextStyle(color: AppColors.primaryTint, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Atur stok toko\nsecepat scan barcode!',
            style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tanpa ribet buku tulis, tetap jalan meski sinyal hilang.',
            style: TextStyle(color: AppColors.primaryTint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});

  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(Key key, String label, _Mode value) {
      final selected = mode == value;
      return Expanded(
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: kMinTouchTarget),
            decoration: BoxDecoration(
              color: selected ? AppColors.white : null,
              borderRadius: BorderRadius.circular(10),
              border: selected ? Border.all(color: AppColors.line) : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(kRadius)),
      child: Row(
        children: [
          tab(const Key('tab-login'), 'Masuk', _Mode.login),
          tab(const Key('tab-register'), 'Daftar Baru', _Mode.register),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.error,
    this.helper,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.formatters,
    this.onChanged,
    this.onSubmitted,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final String? error;
  final String? helper;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: formatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(errorText: error, helperText: helper, helperMaxLines: 2, suffixIcon: suffix),
        ),
      ],
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('auth-form-error'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.errorTint, borderRadius: BorderRadius.circular(kRadius)),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: AppColors.primaryLine),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Offline-First Ready',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Semua stok aman di HP & auto-sync.',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
