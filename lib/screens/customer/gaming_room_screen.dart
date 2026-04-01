import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GamingRoomScreen extends StatefulWidget {
  const GamingRoomScreen({super.key});

  @override
  State<GamingRoomScreen> createState() => _GamingRoomScreenState();
}

class _GamingRoomScreenState extends State<GamingRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Gaming Room',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Book'),
            Tab(icon: Icon(Icons.history), text: 'My Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [const BookingGridTab(), const MyBookingsTab()],
      ),
    );
  }
}

// ─── Booking Grid Tab ─────────────────────────────────────────────────────────

class BookingGridTab extends StatefulWidget {
  const BookingGridTab({super.key});

  @override
  State<BookingGridTab> createState() => _BookingGridTabState();
}

class _BookingGridTabState extends State<BookingGridTab> {
  late DateTime _weekStart;
  final int _pricePerHour = 15000;

  @override
  void initState() {
    super.initState();
    // Start from current Monday
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
  }

  // Get hours for a given day (0=Mon ... 6=Sun)
  List<int> _hoursForDay(int weekdayIndex) {
    // weekdayIndex: 0=Mon, 1=Tue, ..., 4=Fri, 5=Sat, 6=Sun
    if (weekdayIndex >= 5) {
      // Weekend: 10:00 - 20:00
      return List.generate(10, (i) => i + 10);
    } else {
      // Weekday: 09:00 - 20:00
      return List.generate(11, (i) => i + 9);
    }
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  String _slotId(DateTime day, int hour) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}_$hour';
  }

  String _dayLabel(DateTime day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day.weekday - 1];
  }

  String _monthDay(DateTime day) {
    return '${day.month}/${day.day}';
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  bool _isPast(DateTime day, int hour) {
    final now = DateTime.now();
    final slotTime = DateTime(day.year, day.month, day.day, hour);
    return slotTime.isBefore(now);
  }

  void _confirmBooking(DateTime day, int hour) {
    final user = FirebaseAuth.instance.currentUser!;
    final slotId = _slotId(day, hour);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_esports, size: 50),
            const SizedBox(height: 12),
            Text(
              '${_dayLabel(day)}, ${_monthDay(day)}\n$hour:00 - ${hour + 1}:00',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '₮${_pricePerHour.toString()}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _book(user, day, hour, slotId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _book(User user, DateTime day, int hour, String slotId) async {
    try {
      // Use transaction to prevent double booking
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final slotRef = FirebaseFirestore.instance
            .collection('gaming_slots')
            .doc(slotId);

        final slotDoc = await transaction.get(slotRef);

        if (slotDoc.exists && slotDoc['status'] == 'booked') {
          throw Exception('Already booked!');
        }

        transaction.set(slotRef, {
          'slotId': slotId,
          'userId': user.uid,
          'userEmail': user.email,
          'date':
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
          'hour': hour,
          'price': _pricePerHour,
          'status': 'booked',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 70),
                const SizedBox(height: 16),
                const Text(
                  'Booked!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_dayLabel(day)} $hour:00 - ${hour + 1}:00\n₮$_pricePerHour',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Already booked')
                  ? 'Sorry, this slot was just booked!'
                  : 'Error: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gaming_slots').snapshots(),
      builder: (context, snapshot) {
        // Build a set of booked slot IDs
        final bookedSlots = <String, Map<String, dynamic>>{};
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            bookedSlots[doc.id] = doc.data() as Map<String, dynamic>;
          }
        }

        return Column(
          children: [
            // ── Price info bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'VIP Gaming Room',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₮$_pricePerHour / hour',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // ── Week navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setState(
                      () => _weekStart = _weekStart.subtract(
                        const Duration(days: 7),
                      ),
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${_weekStart.month}/${_weekStart.day} - ${_weekDays.last.month}/${_weekDays.last.day}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () =>
                          _weekStart = _weekStart.add(const Duration(days: 7)),
                    ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),

            // ── Grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Day headers
                        Row(
                          children: [
                            const SizedBox(width: 60),
                            ..._weekDays.map(
                              (day) => Container(
                                width: 72,
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isToday(day)
                                      ? Colors.black
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _dayLabel(day),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: _isToday(day)
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      _monthDay(day),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _isToday(day)
                                            ? Colors.white70
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ── Hour rows
                        ...List.generate(24, (hourIndex) {
                          final hour = hourIndex;

                          // Only show hours that appear in at least one day
                          final hasAnySlot = _weekDays.asMap().entries.any(
                            (e) => _hoursForDay(e.key).contains(hour),
                          );
                          if (!hasAnySlot) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                // Hour label
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    '$hour:00',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),

                                // Slots for each day
                                ..._weekDays.asMap().entries.map((entry) {
                                  final dayIndex = entry.key;
                                  final day = entry.value;
                                  final validHours = _hoursForDay(dayIndex);

                                  if (!validHours.contains(hour)) {
                                    return Container(
                                      width: 72,
                                      height: 44,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    );
                                  }

                                  final slotId = _slotId(day, hour);
                                  final isBooked = bookedSlots.containsKey(
                                    slotId,
                                  );
                                  final isMyBooking =
                                      isBooked &&
                                      bookedSlots[slotId]?['userId'] ==
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid;
                                  final isPast = _isPast(day, hour);

                                  Color bgColor;
                                  Color textColor;
                                  String label;

                                  if (isPast) {
                                    bgColor = Colors.grey.shade200;
                                    textColor = Colors.grey;
                                    label = '-';
                                  } else if (isMyBooking) {
                                    bgColor = Colors.black;
                                    textColor = Colors.white;
                                    label = 'Mine';
                                  } else if (isBooked) {
                                    bgColor = Colors.red.shade100;
                                    textColor = Colors.red;
                                    label = 'Full';
                                  } else {
                                    bgColor = Colors.green.shade50;
                                    textColor = Colors.green.shade700;
                                    label = 'Open';
                                  }

                                  return GestureDetector(
                                    onTap: (!isPast && !isBooked)
                                        ? () => _confirmBooking(day, hour)
                                        : null,
                                    child: Container(
                                      width: 72,
                                      height: 44,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: isMyBooking
                                            ? null
                                            : Border.all(
                                                color: isPast
                                                    ? Colors.grey.shade300
                                                    : isBooked
                                                    ? Colors.red.shade200
                                                    : Colors.green.shade200,
                                                width: 1,
                                              ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Legend
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.grey.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(
                    Colors.green.shade50,
                    Colors.green.shade700,
                    'Available',
                  ),
                  const SizedBox(width: 16),
                  _legendItem(Colors.red.shade100, Colors.red, 'Booked'),
                  const SizedBox(width: 16),
                  _legendItem(Colors.black, Colors.white, 'Mine'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _legendItem(Color bg, Color text, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ─── My Bookings Tab ──────────────────────────────────────────────────────────

class MyBookingsTab extends StatelessWidget {
  const MyBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gaming_slots')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_esports_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No bookings yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Book a slot from the Book tab',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final booking = snapshot.data!.docs[index];
            final hour = booking['hour'] as int;
            final date = booking['date'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sports_esports,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gaming Room',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$hour:00 - ${hour + 1}:00',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₮${booking['price']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
