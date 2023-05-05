import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_utils/qr_code_utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qr code scan',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController linkController = TextEditingController();
  String? _imagePath;
  String _decoded = 'Unknown';
  late FocusScopeNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusScopeNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _closeKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  Future<void> QrChooseFromGalary() async {
    ImagePicker imagePicker = ImagePicker();

    XFile? xfile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (xfile != null) {
      try {
        _decoded = await QrCodeUtils.decodeFrom(xfile.path) ??
            'Unknown platform version';
      } on PlatformException {
        _decoded = 'Failed to get decoded.';
      }
    }

    setState(() {
      _imagePath = xfile!.path;
    });
  }

  Future<void> QrchooseFromLink(String url) async {
    try {
      var response = await Dio()
          .get(url, options: Options(responseType: ResponseType.bytes));

      Directory? appDocDir = await getExternalStorageDirectory();
      String appDocPath = appDocDir!.path;

      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + ".jpg";
      String filePath = "$appDocPath/$fileName";

      File file = File(filePath);
      await file.writeAsBytes(response.data);

      if (filePath != null) {
        try {
          _decoded = await QrCodeUtils.decodeFrom(filePath) ??
              'Unknown platform version';
        } on PlatformException {
          _decoded = 'Failed to get decoded.';
        }
      }

      setState(() {
        _imagePath = filePath;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Qr Code Scanner'),
      ),
      body: FocusScope(
        node: _focusNode,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imagePath != null)
                Image.file(
                  File(_imagePath!),
                  width: 200,
                  height: 200,
                ),
              Text(
                _decoded,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'Please enter link',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Text('Scan Image from link'),
                    onPressed: () {
                      QrchooseFromLink(
                        linkController.text.toString(),
                      );
                      linkController.clear();
                      _closeKeyboard();
                    },
                  ),
                  ElevatedButton(
                    child: Text('choose from galary'),
                    onPressed: () {
                      QrChooseFromGalary();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
