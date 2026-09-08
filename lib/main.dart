import 'package:flutter/material.dart';

void main() {
  runApp(const NetMonitorApp());
}

class NetMonitorApp extends StatelessWidget {
  const NetMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Net Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NetMonitorHome(),
    );
  }
}

class NetMonitorHome extends StatelessWidget {
  const NetMonitorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Monitor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'حالة الاتصال: متصل بالإنترنت',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'الشبكة تعمل بشكل جيد وسريع',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // زر لفحص الشبكة
              },
              icon: const Icon(Icons.refresh),
              label: const Text('فحص الشبكة الآن'),
              style: ElevatedButton.style5,
            ),
          ],
        ),
      ),
    );
  }
}
