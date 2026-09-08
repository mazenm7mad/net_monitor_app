import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const NetMonitorApp());
}

class NetMonitorApp extends StatefulWidget {
  const NetMonitorApp({super.key});

  @override
  State<NetMonitorApp> createState() => _NetMonitorAppState();
}

class _NetMonitorAppState extends State<NetMonitorApp> {
  String currentLanguage = 'ar';

  void _toggleLanguage(String lang) {
    setState(() {
      currentLanguage = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Net Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      home: HomeScreen(
        currentLanguage: currentLanguage,
        onLanguageChanged: _toggleLanguage,
      ),
    );
  }
}

class AppUsageData {
  final String appName;
  final String packageName;
  bool isTracking;
  bool isPaused;
  int secondsSpent;
  double dataUsedMB;
  Timer? timer;
  bool isSaved;

  AppUsageData({
    required this.appName,
    required this.packageName,
    this.isTracking = false,
    this.isPaused = false,
    this.secondsSpent = 0,
    this.dataUsedMB = 0.0,
    this.isSaved = false,
  });
}

class HomeScreen extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User";
  List<AppUsageData> userTrackedApps = [];
  List<String> savedLogs = [];

  final List<Map<String, String>> deviceAppsList = [
    {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically'},
    {'name': 'PUBG Mobile', 'package': 'com.tencent.ig'},
    {'name': 'Google', 'package': 'com.google.android.googlequicksearchbox'},
    {'name': 'YouTube', 'package': 'com.google.android.youtube'},
    {'name': 'WhatsApp', 'package': 'com.whatsapp'},
    {'name': 'Facebook', 'package': 'com.facebook.katana'},
    {'name': 'Instagram', 'package': 'com.instagram.android'},
  ];

  bool get isAr => widget.currentLanguage == 'ar';

  void _changeUserName() {
    TextEditingController controller = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'تغيير اسم المستخدم' : 'Change Username'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isAr ? 'أدخل الاسم الجديد' : 'Enter Username',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  userName = controller.text.trim();
                });
              }
              Navigator.pop(context);
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _openSelectAppScreen() async {
    final selectedApp = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectDeviceAppScreen(
          installedApps: deviceAppsList,
          isAr: isAr,
        ),
      ),
    );

    if (selectedApp != null && selectedApp is Map<String, String>) {
      bool exists = userTrackedApps.any((app) => app.packageName == selectedApp['package']);
      if (!exists) {
        setState(() {
          userTrackedApps.add(AppUsageData(
            appName: selectedApp['name']!,
            packageName: selectedApp['package']!,
          ));
        });
      }
    }
  }

  void _startTracking(AppUsageData app) {
    setState(() {
      app.isTracking = true;
      app.isPaused = false;
      app.isSaved = false;

      app.timer?.cancel();
      app.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!app.isPaused) {
          setState(() {
            app.secondsSpent++;
            app.dataUsedMB += 0.5; // معدل استهلاك مجازي تجريبي

            if (app.secondsSpent >= 3600) {
              _stopTracking(app);
              _showLimitReachedDialog(app);
            }
          });
        }
      });
    });
  }

  void _showLimitReachedDialog(AppUsageData app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(isAr ? 'تم الوصول للحد الزمني!' : 'Time Limit Reached!'),
          ],
        ),
        content: Text(
          isAr
              ? 'تم إيقاف ${app.appName} تلقائياً بعد مرور ساعة واحدة.\n\nالاستهلاك: ${_formatData(app.dataUsedMB)}'
              : 'Tracking for ${app.appName} stopped after 1 hour.\n\nData used: ${_formatData(app.dataUsedMB)}',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveAppData(app);
            },
            child: Text(isAr ? 'حفظ السجل' : 'Save Usage Log'),
          ),
        ],
      ),
    );
  }

  void _pauseTracking(AppUsageData app) {
    setState(() {
      app.isPaused = !app.isPaused;
    });
  }

  // عند ضغط Stop: إيقاف وتصفير الأرقام فوراً
  void _stopTracking(AppUsageData app) {
    setState(() {
      app.isTracking = false;
      app.isPaused = false;
      app.timer?.cancel();
      app.secondsSpent = 0; // تصفير الوقت
      app.dataUsedMB = 0.0; // تصفير النت
      app.isSaved = false;
    });
  }

  void _removeApp(AppUsageData app) {
    setState(() {
      app.timer?.cancel();
      userTrackedApps.removeWhere((item) => item.packageName == app.packageName);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم حذف ${app.appName} من القائمة' : 'Removed ${app.appName}',
        ),
      ),
    );
  }

  void _saveAppData(AppUsageData app) {
    if (app.dataUsedMB == 0 && app.secondsSpent == 0) return;
    setState(() {
      app.isSaved = true;
      String log = "${app.appName}: ${_formatTime(app.secondsSpent)} | ${_formatData(app.dataUsedMB)}";
      if (!savedLogs.contains(log)) {
        savedLogs.add(log);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم حفظ بيانات ${app.appName} في السجل!' : 'Saved stats for ${app.appName}!',
        ),
      ),
    );
  }

  void _openAppOnDevice(AppUsageData app) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'جاري فتح ${app.appName}...' : 'Opening ${app.appName}...',
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    String hLabel = isAr ? 'س' : 'h';
    String mLabel = isAr ? 'د' : 'm';
    String sLabel = isAr ? 'ث' : 's';

    if (hours > 0) {
      return '$hours$hLabel $minutes$mLabel $seconds$sLabel';
    }
    return '$minutes$mLabel $seconds$sLabel';
  }

  // تحويل الميجابايت لـ جيجابايت لو عدى 1024 ميجا
  String _formatData(double mb) {
    if (mb >= 1024) {
      double gb = mb / 1024;
      return '${gb.toStringAsFixed(2)} ${isAr ? "جيجابايت" : "GB"}';
    }
    return '${mb.toStringAsFixed(2)} ${isAr ? "ميجابايت" : "MB"}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'مراقب الإنترنت' : 'Net Monitor'),
          actions: [
            InkWell(
              onTap: _changeUserName,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 4),
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      userName: userName,
                      trackedApps: userTrackedApps,
                      savedLogs: savedLogs,
                      currentLanguage: widget.currentLanguage,
                      onLanguageChanged: widget.onLanguageChanged,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _openSelectAppScreen,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    isAr ? 'إضافة تطبيق / لعبة' : 'Select App',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: userTrackedApps.isEmpty
                    ? Center(
                        child: Text(
                          isAr
                              ? 'لا يوجد تطبيقات مضافة.\nاضغط على "إضافة تطبيق / لعبة" بالأعلى.'
                              : 'No apps selected.\nTap "Select App" above.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: userTrackedApps.length,
                        itemBuilder: (context, index) {
                          final app = userTrackedApps[index];
                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.sports_esports, color: Colors.blueAccent, size: 30),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              app.appName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            Text(
                                              isAr
                                                  ? 'الوقت: ${_formatTime(app.secondsSpent)} | النت: ${_formatData(app.dataUsedMB)}'
                                                  : 'Time: ${_formatTime(app.secondsSpent)} | Net: ${_formatData(app.dataUsedMB)}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // قائمة الثلاث نقط
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        onSelected: (value) {
                                          if (value == 'remove') {
                                            _removeApp(app);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem(
                                            value: 'remove',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                                const SizedBox(width: 8),
                                                Text(isAr ? 'حذف التطبيق' : 'Remove App'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: app.isSaved ? Colors.grey : Colors.teal,
                                        ),
                                        onPressed: app.isSaved ? null : () => _saveAppData(app),
                                        icon: Icon(app.isSaved ? Icons.check : Icons.save, size: 14),
                                        label: Text(
                                          app.isSaved
                                              ? (isAr ? 'تم الحفظ' : 'Saved')
                                              : (isAr ? 'حفظ' : 'Save'),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _openAppOnDevice(app),
                                            icon: const Icon(Icons.open_in_new, size: 14),
                                            label: Text(isAr ? 'فتح' : 'Open', style: const TextStyle(fontSize: 12)),
                                          ),
                                          const SizedBox(width: 6),
                                          if (app.isTracking) ...[
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    app.isPaused ? Colors.orange : Colors.amber[700],
                                              ),
                                              onPressed: () => _pauseTracking(app),
                                              child: Text(
                                                app.isPaused
                                                    ? (isAr ? 'استئناف' : 'Resume')
                                                    : (isAr ? 'إيقاف مؤقت' : 'Pause'),
                                                style: const TextStyle(color: Colors.black, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                              onPressed: () => _stopTracking(app),
                                              child: Text(isAr ? 'إيقاف' : 'Stop', style: const TextStyle(fontSize: 12)),
                                            ),
                                          ] else ...[
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                              onPressed: () => _startTracking(app),
                                              child: Text(isAr ? 'بدء' : 'Start', style: const TextStyle(fontSize: 12)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectDeviceAppScreen extends StatefulWidget {
  final List<Map<String, String>> installedApps;
  final bool isAr;

  const SelectDeviceAppScreen({
    super.key,
    required this.installedApps,
    required this.isAr,
  });

  @override
  State<SelectDeviceAppScreen> createState() => _SelectDeviceAppScreenState();
}

class _SelectDeviceAppScreenState extends State<SelectDeviceAppScreen> {
  List<Map<String, String>> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = widget.installedApps;
  }

  void _search(String query) {
    setState(() {
      filtered = widget.installedApps
          .where((app) => app['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isAr ? 'اختر تطبيق أو لعبة' : 'Select App')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                onChanged: _search,
                decoration: InputDecoration(
                  labelText: widget.isAr ? 'بحث...' : 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      leading: const Icon(Icons.sports_esports, color: Colors.blueAccent),
                      title: Text(item['name']!),
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final String userName;
  final List<AppUsageData> trackedApps;
  final List<String> savedLogs;
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.userName,
    required this.trackedApps,
    required this.savedLogs,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool autoStopDataSaver = true;

  bool get isAr => widget.currentLanguage == 'ar';

  // دالة إرسال الرسالة إلى تليجرام باستخدام التوكن والـ Chat ID الخاص بك
  Future<void> _sendTelegramMessage(String userMsg) async {
    const String botToken = '8748279427:AAHrkPof6U4vqFNsOpuQAaCKoiOqlKoNUcA';
    const String chatId = '6300622077';

    final String text =
        '📩 رسالة دعم جديدة من تطبيق Net Monitor:\n\n👤 المستخدم: ${widget.userName}\n💬 النص:\n$userMsg';

    final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');

    try {
      await http.post(
        url,
        body: {
          'chat_id': chatId,
          'text': text,
        },
      );
    } catch (e) {
      print('Telegram Error: $e');
    }
  }

  void _openSupportDialog() {
    TextEditingController supportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'التواصل مع الدعم / الإدارة' : 'Contact Support / Admin'),
        content: TextField(
          controller: supportController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isAr ? 'اكتب استفسارك هنا...' : 'Type your message...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String msg = supportController.text.trim();
              if (msg.isNotEmpty) {
                Navigator.pop(context);
                
                // إرسال الرسالة لتليجرام
                await _sendTelegramMessage(msg);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تم إرسال الرسالة للإدارة بنجاح!' : 'Message sent to admin!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text(isAr ? 'إرسال' : 'Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(isAr ? 'الإعدادات' : 'Settings')),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // اختيارات اللغة
            Text(
              isAr ? 'اللغة / Language' : 'Language / اللغة',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('العربية')),
                    selected: isAr,
                    onSelected: (selected) {
                      if (selected) widget.onLanguageChanged('ar');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('English')),
                    selected: !isAr,
                    onSelected: (selected) {
                      if (selected) widget.onLanguageChanged('en');
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // إعدادات التنبيهات
            Text(
              isAr ? 'الإعدادات العامة' : 'General Settings',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SwitchListTile(
              title: Text(isAr ? 'تفعيل التنبيهات' : 'Enable Notifications'),
              value: notificationsEnabled,
              onChanged: (val) {
                setState(() {
                  notificationsEnabled = val;
                });
              },
            ),
            SwitchListTile(
              title: Text(isAr ? 'موفّر البيانات' : 'Data Saver Mode'),
              value: autoStopDataSaver,
              onChanged: (val) {
                setState(() {
                  autoStopDataSaver = val;
                });
              },
            ),
            const Divider(height: 30),

            // الدعم
            Text(
              isAr ? 'الدعم والتواصل' : 'Support & Contact',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.blueAccent),
              title: Text(isAr ? 'التواصل مع الدعم / الإدارة' : 'Contact Support / Admin'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _openSupportDialog,
            ),
            const Divider(height: 30),

            // سجل المحفوظات الثابت والحذف الآمن بدون أخطاء
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'سجل المحفوظات' : 'Saved Logs History',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                if (widget.savedLogs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        widget.savedLogs.clear();
                      });
                    },
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                    label: Text(
                      isAr ? 'مسح الكل' : 'Clear All',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            widget.savedLogs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      isAr ? 'لا يوجد سجلات محفوظة حتى الآن.' : 'No saved logs yet.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : Column(
                    children: List.generate(widget.savedLogs.length, (index) {
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.teal),
                          title: Text(widget.savedLogs[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                            onPressed: () {
                              setState(() {
                                widget.savedLogs.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ),
          ],
        ),
      ),
    );
  }
}
