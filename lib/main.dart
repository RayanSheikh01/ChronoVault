// Removed incorrect import
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chrono Vault',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Chrono Vault'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final passwordController = TextEditingController();
  late encrypt.Key passwordKey;
  late encrypt.IV passwordIv;
  late encrypt.Key fileKey;
  late encrypt.IV fileIv;

  void encryptPassword() {
    final string = passwordController.text;
    passwordKey = encrypt.Key.fromSecureRandom(32);
    passwordIv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(passwordKey));
    final encrypted = encrypter.encrypt(string, iv: passwordIv);
    print("Encrypted: ${encrypted.base64}");
    decryptPassword(encrypted.base64);
  }

  void decryptPassword(String encrypted) {
    final encrypter = encrypt.Encrypter(encrypt.AES(passwordKey));
    final decrypted = encrypter.decrypt64(encrypted, iv: passwordIv);
    print("Decrypted: $decrypted");
  }

  void encryptFile(File file, Uint8List inputBytes) async {
    // Implement file encryption logic here
    fileKey = encrypt.Key.fromSecureRandom(32);
    fileIv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(fileKey));
    final encrypted = encrypter.encryptBytes(inputBytes, iv: fileIv);
    final encryptedFile = File('${file.path}.enc');
    await encryptedFile.writeAsBytes(encrypted.bytes);
    final keyFile = File('${file.path}.key');
    await keyFile.writeAsString('${fileKey.base64}:${fileIv.base64}');
  }

  void decryptFile(File file) async {
    // Implement file decryption logic here
    final keyFile = File(file.path.replaceAll('.enc', '.key'));
    final keyData = await keyFile.readAsString();
    final parts = keyData.split(':');
    fileKey = encrypt.Key.fromBase64(parts[0]);
    fileIv = encrypt.IV.fromBase64(parts[1]);
    final encryptedBytes = await file.readAsBytes();
    final encrypter = encrypt.Encrypter(encrypt.AES(fileKey));
    final decrypted =
        encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: fileIv);
    final decryptedFile = File(file.path.replaceAll('.enc', '.dec'));
    await decryptedFile.writeAsBytes(decrypted);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result != null) {
                  File file = File(result.files.single.path!);
                  final inputBytes = await file.readAsBytes();
                  encryptFile(file, inputBytes);
                } else {
                  // User canceled the picker
                }
              },
              child: const Text('Encrypt File'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                encryptPassword();
                // Handle button press
              },
              child: const Text('Submit'),
            ),
            ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  if (result != null) {
                    File file = File(result.files.single.path!);
                    decryptFile(file);
                  } else {
                    // User canceled the picker
                  }
                },
                child: const Text('Decrypt File'))
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
