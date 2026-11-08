
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final notifications = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true, requestBadgePermission: true,
    requestSoundPermission: true);
  await notifications.initialize(const InitializationSettings(android: android, iOS: ios));
  runApp(const CampusCompanion());
}

class CampusCompanion extends StatelessWidget {
  const CampusCompanion({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Campus Companion', debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF101014),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDC263B), brightness: Brightness.dark)),
    home: const HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  Map<String,dynamic> data = {};
  String day = 'Monday', division = 'L';
  int batch = 3, reminderMinutes = 5;
  final tts = FlutterTts();
  bool ready = false;

  @override void initState() { super.initState(); _load(); _configureTts(); }
  Future<void> _load() async {
    final s = await rootBundle.loadString('assets/timetable.json');
    setState(() { data = jsonDecode(s); ready = true; });
  }
  Future<void> _configureTts() async {
    // Use the device's single default system voice. No voice picker or
    // dependency on the number of voices installed on the phone.
    await tts.setLanguage('en-IN');
    await tts.setSpeechRate(0.48);
    await tts.setPitch(1.0);
  }
  Future<void> previewVoice() async {
    await tts.stop();
    await tts.speak('Hello! This is your Campus Companion lecture reminder.');
  }
  List<dynamic> get entries {
    if (!ready || data[day] == null || data[day][division] == null) return [];
    return data[day][division]['$batch'] as List<dynamic>;
  }
  Future<void> scheduleReminders() async {
    // Ask Android 13+ for notification permission when the user enables reminders.
    final androidNotifications = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.requestNotificationsPermission();

    // Rebuild the complete weekly schedule for the selected division and batch.
    await notifications.cancelAll();
    const weekdayMap = {
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
    };
    var scheduled = 0;
    for (final dayName in weekdayMap.keys) {
      final dayData = data[dayName]?[division]?['$batch'];
      if (dayData == null) continue;
      for (final e in (dayData as List)) {
        if (e['kind'] != 'class') continue;
        final parts = (e['start'] as String).split(':');
        final startHour = int.parse(parts[0]);
        final startMinute = int.parse(parts[1]);
        final reminderTime = DateTime(2026, 1, 5, startHour, startMinute)
            .subtract(Duration(minutes: reminderMinutes));
        final hour = reminderTime.hour;
        final minute = reminderTime.minute;
        // Stable ID from weekday, division, batch and lecture start time.
        final id = (weekdayMap[dayName]! * 1000000 +
                division.codeUnitAt(0) * 10000 +
                batch * 1000 +
                startHour * 60 + startMinute) &
            0x7fffffff;
        await notifications.zonedSchedule(
          id,
          'Upcoming lecture · ${e['subject']}',
          '${e['subject']} starts at ${e['start']}.'
              '${(e['room'] as String).isNotEmpty && !(e['subject'] as String).contains('#') ? ' Room ${e['room']}.' : ''}',
          _nextWeeklyOccurrence(weekdayMap[dayName]!, hour, minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'lecture_reminders',
              'Lecture reminders',
              channelDescription: 'Weekly reminders before scheduled lectures',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        scheduled++;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          scheduled == 0
            ? 'No lecture reminders found for this division and batch.'
            : '$scheduled weekly lecture reminders enabled ($reminderMinutes min before each class).',
        )),
      );
    }
  }

  tz.TZDateTime _nextWeeklyOccurrence(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  @override Widget build(BuildContext context) {
    final divisions = List.generate(18,(i)=>String.fromCharCode(65+i));
    return Scaffold(
      appBar: AppBar(title: const Text('CAMPUS COMPANION'), backgroundColor: const Color(0xFF1B1B22)),
      body: !ready ? const Center(child:CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children:[
        const Text('MY TIMETABLE',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900,letterSpacing:1.2)),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:DropdownButtonFormField<String>(value:division,decoration:const InputDecoration(labelText:'Division'),
            items:divisions.map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(),onChanged:(v)=>setState(()=>division=v!))),
          const SizedBox(width:12),
          Expanded(child:DropdownButtonFormField<int>(value:batch,decoration:const InputDecoration(labelText:'Batch'),
            items:[1,2,3].map((b)=>DropdownMenuItem(value:b,child:Text('Batch $b'))).toList(),onChanged:(v)=>setState(()=>batch=v!))),
        ]),
        const SizedBox(height:12),
        Wrap(spacing:6,children:['Monday','Tuesday','Wednesday','Thursday','Friday'].map((d)=>ChoiceChip(label:Text(d.substring(0,3)),selected:day==d,onSelected:(_)=>setState(()=>day=d))).toList()),
        const SizedBox(height:12),
        ...entries.map((e) {
          final kind=e['kind'];
          final free=kind=='free', marker=kind=='lunch'||kind=='empowerment_hour';
          return Card(color:free?const Color(0xFF202027):marker?const Color(0xFF29252A):const Color(0xFF25252D),
            child:ListTile(
              leading:Text('${e['start']}\\n${e['end']}',style:const TextStyle(fontSize:12)),
              title:Text(e['subject'],style:TextStyle(fontWeight:FontWeight.bold,color:free?Colors.lightGreenAccent:null)),
              subtitle:Text(free?'No scheduled class':marker?'':[
                if ((e['faculty'] as String).isNotEmpty) 'Faculty: ${e['faculty']}',
                if ((e['room'] as String).isNotEmpty && !(e['subject'] as String).contains('#')) 'Room: ${e['room']}',
                if ((e['subject'] as String).contains('#')) 'Self-study · no classroom'
              ].join('  •  ')),
            ));
        }),
        const Divider(height:32),
        const Text('LECTURE REMINDERS',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        Text('Remind me before each lecture: $reminderMinutes minute(s)'),
        Slider(min:0,max:20,divisions:20,value:reminderMinutes.toDouble(),
          label:'$reminderMinutes min',onChanged:(v)=>setState(()=>reminderMinutes=v.round())),
        FilledButton.icon(onPressed:scheduleReminders,icon:const Icon(Icons.notifications_active),label:const Text('Enable weekly lecture reminders')),
        const SizedBox(height:18),
        const Text('VOICE PREVIEW',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        const Text('Uses your phone’s default English system voice.'),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:previewVoice,icon:const Icon(Icons.record_voice_over),label:const Text('Preview reminder voice')),
        const SizedBox(height:20),
        const Text('Batch-specific classes are shown. Un-suffixed subjects are treated as common to all batches; entries tagged -1/-2/-3 are shown only for that batch. Empty intervals are marked FREE.',
          style:TextStyle(color:Colors.white60,fontSize:12)),
      ]),
    );
  }
}
