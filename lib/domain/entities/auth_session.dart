/// Sesi pengguna aktif. Token JWT TIDAK diekspos ke UI (disimpan di secure storage oleh layer data).
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.userName,
    required this.businessId,
    required this.businessCode,
    required this.businessName,
  });

  final String userId;
  final String userName;
  final String businessId;

  /// Kode toko, mis. `TMJ01`. Dipakai sebagai prefix nomor transaksi.
  final String businessCode;
  final String businessName;

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.businessId == businessId &&
      other.businessCode == businessCode;

  @override
  int get hashCode => Object.hash(userId, businessId, businessCode);

  @override
  String toString() => 'AuthSession($userName @ $businessCode)';
}
