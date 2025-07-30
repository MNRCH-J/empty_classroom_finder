import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  await initializeNotifications();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: MyApp(),
      ),
    );
  });
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await FlutterLocalNotificationsPlugin().initialize(initializationSettings);
}

// Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Should be overridden');
});

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(sharedPreferencesProvider));
});

final csvServiceProvider = Provider<CsvService>((ref) => CsvService());

class BookingService {
  final SharedPreferences _prefs;
  static const _bookingsKey = 'classroom_bookings';

  BookingService(this._prefs);

  Future<Map<String, dynamic>> getBookings() async {
    final json = _prefs.getString(_bookingsKey);
    return json != null ? jsonDecode(json) : {};
  }

  Future<void> saveBooking(String day, String classroom, int period, String username) async {
    final bookings = await getBookings();
    if (!bookings.containsKey(day)) bookings[day] = {};
    if (!bookings[day]!.containsKey(classroom)) bookings[day]![classroom] = {};
    bookings[day]![classroom]![period.toString()] = username;
    await _prefs.setString(_bookingsKey, jsonEncode(bookings));
  }

  Future<void> cancelBooking(String day, String classroom, int period) async {
    final bookings = await getBookings();
    bookings[day]?[classroom]?.remove(period.toString());
    await _prefs.setString(_bookingsKey, jsonEncode(bookings));
  }

  String? getBooking(String day, String classroom, int period) {
    final bookings = _prefs.getString(_bookingsKey);
    if (bookings == null) return null;
    final map = jsonDecode(bookings) as Map<String, dynamic>;
    return map[day]?[classroom]?[period.toString()]?.toString();
  }

  bool isBooked(String day, String classroom, int period) {
    return getBooking(day, classroom, period) != null;
  }
}

class CsvService {
  Future<List<List<String>>> loadTimetable(String day) async {
    try {
      final raw = await rootBundle.loadString('assets/${day}_timetable.csv');
      final csvTable = const CsvToListConverter().convert(raw);
      return csvTable.map((row) => row.map((e) => e.toString()).toList()).toList();
    } catch (e) {
      throw Exception('Failed to load timetable for $day');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Empty Classroom Finder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        primaryColor: Colors.blueAccent,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: SplashScreen(),
    );
  }

}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 1400),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Hero(
            tag: 'logo',
            child: Image.asset('assets/srm_logo.png', width: 300),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_usernameController.text == 'admin' && _passwordController.text == '1234') {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => DaySelectorScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid username or password")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.blueGrey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                  tag: 'logo',
                  child: Image.asset('assets/srm_logo.png', width: 120)),
              const SizedBox(height: 30),
              const Text("Admin Login",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 20),
              _textField(_usernameController, 'Username'),
              const SizedBox(height: 12),
              _textField(_passwordController, 'Password', isPassword: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("LOGIN"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint,
      {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(color: Colors.white),
        onSubmitted: (val) {
          if (isPassword) _login();
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.white54,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          )
              : null,
        ),
      ),
    );
  }
}

class DaySelectorScreen extends ConsumerWidget {
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  final TextEditingController searchController = TextEditingController();

  void _search(BuildContext context, String classroom) {
    if (classroom.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassroomTimetableScreen(classroom: classroom),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select a Day or Class")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => _search(context, value),
                    decoration: InputDecoration(
                      hintText: "Enter Classroom (e.g. 301)",
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _search(context, searchController.text),
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2,
                ),
                itemBuilder: (context, index) {
                  final dayLabel = days[index];
                  final csvDay = "Day${index + 1}";
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              TimetableScreen(day: csvDay, displayDay: dayLabel),
                          transitionsBuilder: (_, anim, __, child) {
                            return FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.95, end: 1.0)
                                    .animate(anim),
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.lightBlueAccent, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          dayLabel,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimetableScreen extends ConsumerStatefulWidget {
  final String day;
  final String displayDay;
  const TimetableScreen({required this.day, required this.displayDay, Key? key}) : super(key: key);

  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  late Future<List<List<String>>> _timetableFuture;
  final List<String> periodLabels = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"];
  final List<String> periodTimes = [
    "08:00–08:50", "08:50–09:40", "09:50–10:40", "10:40–11:30",
    "12:20–01:10", "01:10–02:00", "02:00–02:50", "02:50–03:40"
  ];

  @override
  void initState() {
    super.initState();
    _timetableFuture = ref.read(csvServiceProvider).loadTimetable(widget.day);
  }

  bool isFree(String value) {
    final lower = value.toLowerCase();
    return lower == 'no period' ||
        lower.contains('lib') ||
        lower.contains('counselling') ||
        lower.contains('mentoring') ||
        lower.contains('seminar');
  }

  Future<void> _handlePeriodTap(String room, int periodIndex, String currentValue) async {
    final bookingManager = ref.read(bookingServiceProvider);
    final isBooked = bookingManager.isBooked(widget.day, room, periodIndex);
    final bookedBy = bookingManager.getBooking(widget.day, room, periodIndex);

    if (isBooked) {
      if (bookedBy != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This period is already booked by $bookedBy')),
        );
        return;
      }

      final shouldUnbook = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Booking?'),
          content: Text('Do you want to cancel your booking for $room (${periodLabels[periodIndex]} period)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      ) ?? false;

      if (shouldUnbook) {
        await bookingManager.cancelBooking(widget.day, room, periodIndex);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking canceled!')),
        );
      }
      return;
    }

    if (!isFree(currentValue)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This period is not free')),
      );
      return;
    }

    final shouldBook = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Classroom?'),
        content: Text('Do you want to book $room for ${periodLabels[periodIndex]} period?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldBook) {
      await bookingManager.saveBooking(widget.day, room, periodIndex, 'admin');
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully booked!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.displayDay} Timetable")),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _timetableFuture = ref.read(csvServiceProvider).loadTimetable(widget.day);
          });
        },
        child: FutureBuilder<List<List<String>>>(
          future: _timetableFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No timetable available"));
            }

            final timetable = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: periodTimes.map((time) {
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          time,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(),
                ...timetable.map((row) {
                  final room = row[0];
                  final periods = row.sublist(1, 9);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(room,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(periods.length, (i) {
                          final value = periods[i];
                          final isPeriodFree = isFree(value);
                          final bookingManager = ref.read(bookingServiceProvider);
                          final isBooked = bookingManager.isBooked(widget.day, room, i);
                          final bookedBy = isBooked
                              ? bookingManager.getBooking(widget.day, room, i)
                              : null;

                          Color color = isBooked
                              ? Colors.yellow
                              : isPeriodFree
                              ? Colors.green
                              : Colors.red;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _handlePeriodTap(room, i, value),
                              child: Tooltip(
                                message: isBooked
                                    ? 'Booked by $bookedBy\nClick to cancel'
                                    : isPeriodFree
                                    ? 'Click to book'
                                    : 'Not available',
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade700),
                                  ),
                                  child: Center(
                                    child: Text(
                                      periodLabels[i],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ClassroomTimetableScreen extends ConsumerWidget {
  final String classroom;
  const ClassroomTimetableScreen({required this.classroom, Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> loadAllDays(WidgetRef ref) async {
    List<Map<String, dynamic>> data = [];
    for (int i = 1; i <= 5; i++) {
      try {
        final day = "Day$i";
        final timetable = await ref.read(csvServiceProvider).loadTimetable(day);
        for (var row in timetable) {
          if (row[0].toString().toLowerCase().replaceAll(' ', '') ==
              classroom.toLowerCase().replaceAll(' ', '')) {
            data.add({
              "day": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"][i - 1],
              "periods": row.sublist(1, 9),
            });
          }
        }
      } catch (_) {}
    }
    return data;
  }

  Future<void> _handlePeriodTap(BuildContext context, WidgetRef ref, String day, int periodIndex, String currentValue) async {
    final bookingManager = ref.read(bookingServiceProvider);
    final dayKey = "Day${["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"].indexOf(day) + 1}";
    final isBooked = bookingManager.isBooked(dayKey, classroom, periodIndex);
    final bookedBy = bookingManager.getBooking(dayKey, classroom, periodIndex);

    if (isBooked) {
      if (bookedBy != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This period is already booked by $bookedBy')),
        );
        return;
      }

      final shouldUnbook = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Booking?'),
          content: Text('Do you want to cancel your booking for $classroom (${["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"][periodIndex]} period on $day)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      ) ?? false;

      if (shouldUnbook) {
        await bookingManager.cancelBooking(dayKey, classroom, periodIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking canceled!')),
        );
      }
      return;
    }

    if (!(currentValue.toLowerCase() == 'no period' ||
        currentValue.toLowerCase().contains('lib') ||
        currentValue.toLowerCase().contains('mentoring') ||
        currentValue.toLowerCase().contains('counselling') ||
        currentValue.toLowerCase().contains('seminar'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This period is not free')),
      );
      return;
    }

    final shouldBook = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Classroom?'),
        content: Text('Do you want to book $classroom for ${["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"][periodIndex]} period on $day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldBook) {
      await bookingManager.saveBooking(dayKey, classroom, periodIndex, 'admin');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully booked!')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodLabels = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"];

    return Scaffold(
      appBar: AppBar(title: Text("Classroom: $classroom")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadAllDays(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return Center(child: Text("No data found for $classroom"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final day = results[index]['day'];
              final periods = results[index]['periods'];
              final dayKey = "Day${["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"].indexOf(day) + 1}";
              final bookingManager = ref.read(bookingServiceProvider);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(day,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: List.generate(periods.length, (i) {
                      final val = periods[i].toString();
                      final isPeriodFree = val.toLowerCase() == 'no period' ||
                          val.toLowerCase().contains('lib') ||
                          val.toLowerCase().contains('mentoring') ||
                          val.toLowerCase().contains('counselling') ||
                          val.toLowerCase().contains('seminar');
                      final isBooked = bookingManager.isBooked(dayKey, classroom, i);
                      final bookedBy = isBooked
                          ? bookingManager.getBooking(dayKey, classroom, i)
                          : null;

                      Color color = isBooked
                          ? Colors.yellow
                          : isPeriodFree
                          ? Colors.green
                          : Colors.red;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _handlePeriodTap(context, ref, day, i, val),
                          child: Tooltip(
                            message: isBooked
                                ? 'Booked by $bookedBy\nClick to cancel'
                                : isPeriodFree
                                ? 'Click to book'
                                : 'Not available',
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  periodLabels[i],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}