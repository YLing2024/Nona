import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/provider_share_codec.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';

/// G-02：扫码导入页——识别 Nona 服务商分享码（ai-provider:v1:...），
/// 成功后返回 [ChatProvider]；无效码提示。
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _handled = true;
    final l10n = AppLocalizations.of(context);
    try {
      final provider = ProviderShareCodec.decode(code);
      if (provider == null) {
        _showError(l10n.scanQrInvalid);
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(provider);
    } catch (_) {
      _showError(l10n.scanQrInvalid);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showAppSnack(context, message);
    _handled = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanQrTitle)),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            // 取景框
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.scanQrTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
