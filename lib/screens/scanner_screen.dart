import 'dart:async';

import 'package:flutter/foundation.dart';
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
  QRViewController? controller;
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
    this.controller = controller;

    controller.scannedDataStream.listen((scanData){

      setState(() {
        result = scanData;
        unawaited(() async {
          Future.delayed(const Duration(milliseconds: 1000), () async
          {
            await openDoor(result!);
          });
        }.call());

      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future openDoor(scanData) async{
    var url = Uri.http('mqtt.memorymee.org', 'fridge/$scanData/open-lock');
    var response = await http.get(url);
    if (response.statusCode == 200){
      Navigator.pop(context);
    }else {
      Navigator.pop(context);
    }
  }
}
