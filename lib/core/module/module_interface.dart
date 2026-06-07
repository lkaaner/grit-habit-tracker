abstract class AppModule {
  /// Modülün benzersiz adı (örn: 'finance', 'fitness', 'productivity')
  String get moduleName;

  /// Modülün ihtiyaç duyduğu Hive Type Adapter'larını kaydeder.
  void registerHiveAdapters();

  /// Modülün ihtiyaç duyduğu Hive kutularını açar ve hazırlar.
  Future<void> initHiveBoxes();

  /// Modül kapatılırken veya uygulama sonlanırken kutuları güvenli şekilde kapatır.
  Future<void> closeHiveBoxes();
}
