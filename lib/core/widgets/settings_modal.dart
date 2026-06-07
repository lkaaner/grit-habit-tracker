import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/system_provider.dart';

class SettingsModal extends ConsumerStatefulWidget {
  const SettingsModal({super.key});

  @override
  ConsumerState<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends ConsumerState<SettingsModal> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isExported = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _showAlertDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Tamam'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Tüm Verileri Temizle'),
        message: const Text('Bu işlem geri alınamaz. Tüm kayıtlarınız kalıcı olarak silinecektir.'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(systemProvider.notifier).clearAllData();
              _showAlertDialog('Sıfırlandı', 'Tüm yerel veriler başarıyla temizlendi.');
            },
            child: const Text('Evet, Hepsini Sil'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('İptal'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemState = ref.watch(systemProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Ayarlar & Yedekleme'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w600)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // YEDEKLEME BÖLÜMÜ
            const Text(
              'YEREL YEDEKLEME',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Yedek Dosyası Oluştur',
                    subtitle: 'Verileri JSON formatında kaydeder.',
                    trailing: const Icon(CupertinoIcons.square_arrow_up, color: CupertinoColors.activeBlue),
                    onTap: () async {
                      await ref.read(systemProvider.notifier).createBackup();
                      setState(() {
                        _isExported = true;
                      });
                      _showAlertDialog(
                        'Başarılı',
                        'Yedekleme dosyası oluşturuldu:\n${ref.read(systemProvider).lastBackupPath}',
                      );
                    },
                  ),
                  Container(height: 0.5, margin: const EdgeInsets.only(left: 16, right: 16), color: CupertinoColors.separator),
                  _buildListTile(
                    title: 'Yedek Dosyasından Geri Yükle',
                    subtitle: 'Kayıtlı yedek dosyasını geri yükler.',
                    trailing: const Icon(CupertinoIcons.square_arrow_down, color: CupertinoColors.activeBlue),
                    onTap: () async {
                      final success = await ref.read(systemProvider.notifier).restoreBackupFromFile();
                      if (success) {
                        _showAlertDialog('Başarılı', 'Yedek dosyasından veriler başarıyla geri yüklendi.');
                      } else {
                        _showAlertDialog('Hata', 'Yedek dosyası bulunamadı veya hasar görmüş.');
                      }
                    },
                  ),
                ],
              ),
            ),

            if (_isExported && systemState.backupJsonText != null) ...[
              const SizedBox(height: 16),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text('Yedek JSON Kodunu Kopyala'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: systemState.backupJsonText!));
                  _showAlertDialog('Kopyalandı', 'Yedek kod panoya kopyalandı. Notlarınıza yapıştırıp saklayabilirsiniz.');
                },
              ),
            ],

            const SizedBox(height: 32),

            // MANUEL KOPYALA-YAPIŞTIR
            const Text(
              'METİN TABANLI YEDEK TRANSFERİ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Başka bir cihazdan aldığınız yedek metnini buraya yapıştırıp geri yükleyebilirsiniz:',
                    style: TextStyle(fontSize: 14, color: CupertinoColors.label),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _jsonController,
                    maxLines: 5,
                    placeholder: 'Yedek JSON kodunu buraya yapıştırın...',
                    placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    color: CupertinoColors.activeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onPressed: () async {
                      if (_jsonController.text.trim().isEmpty) return;
                      final success = await ref
                          .read(systemProvider.notifier)
                          .restoreBackupFromText(_jsonController.text.trim());
                      if (success) {
                        _jsonController.clear();
                        _showAlertDialog('Başarılı', 'Yedek metninden tüm veriler başarıyla geri yüklendi.');
                      } else {
                        _showAlertDialog('Hata', 'Geçersiz yedek kodu. Lütfen kodu kontrol edin.');
                      }
                    },
                    child: const Text('Metinden Geri Yükle'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // SIFIRLAMA BÖLÜMÜ
            const Text(
              'TEHLİKELİ ALAN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.destructiveRed,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildListTile(
                title: 'Tüm Verileri Sıfırla',
                subtitle: 'Finans, fitness, yapılacaklar ve notları temizler.',
                textColor: CupertinoColors.destructiveRed,
                trailing: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                onTap: _confirmDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    Color textColor = CupertinoColors.label,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
