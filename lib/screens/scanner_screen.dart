import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  late final StreamSubscription _streamSubscription;
  var client = http.Client();

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                      borderColor: Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: scanArea),
                  onPermissionSet: (ctrl, p) =>
                      _onPermissionSet(context, ctrl, p),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: (result != null)
                      ? Text('Data: ${result!.code}')
                      : const Text('Scan a code'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _streamSubscription = controller.scannedDataStream.listen((scanData) async {
      if (result?.code == scanData.code) return;
      result = scanData;
      if (result == null) return;
      await getFridge(result!);
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  Future getFridge(Barcode scanData) async {
    var url = Uri.http('mqtt.memorymee.org', 'fridge/${scanData.code}');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      _showMyDialog(scanData.code ?? "");
    } else {
      showErrorDialog();
    }

  }

  Future openDoor(String code) async {
    Uri url = Uri.http('mqtt.memorymee.org', 'fridge/$code/open-lock');
    await http.get(url);
    result = null;
    Navigator.of(context).pop();
  }

  Future<void> showErrorDialog() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Ошибка"),
            content: Text("QR code не найден."),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
  }

  Future<void> _showMyDialog(String code) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Холодильник'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Вы подключились холдильнику Smart'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Открыть холодьник'),
              onPressed: () => openDoor(code),
            ),
          ],
        );
      },
    );
  }
}
