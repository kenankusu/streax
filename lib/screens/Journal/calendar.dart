import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../Home/journal.dart';
import '../Shared/navigationbar.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class kalender extends StatefulWidget {
  const kalender({super.key});

  @override
  State<kalender> createState() => _KalenderState();
}

class _KalenderState extends State<kalender> {
  DateTime _focusedDay = DateTime.now();
  final CalendarController _calendarController = CalendarController();
  late final DateTime maxMonth = DateTime(DateTime.now().year, DateTime.now().month + 2, 0);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Nicht eingeloggt')),
      );
    }

    final now = _focusedDay;
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final lastDayOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.menu, color: Colors.white),
                      tooltip: "Menü",
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Dein Journal',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Align(
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('activities')
              .where('datum', isGreaterThanOrEqualTo: firstDayOfYear.toIso8601String())
              .where('datum', isLessThanOrEqualTo: lastDayOfYear.toIso8601String())
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Mappe Einträge nach Datum (ALLE Einträge, nicht nach Monat filtern!)
            final Map<String, Map<String, dynamic>> eintraege = {};
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final date = DateTime.tryParse(data['datum'] ?? '') ?? DateTime(2000);
              final dateKey = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              eintraege[dateKey] = data;
            }

            return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final DateTime now = DateTime.now();
                          final DateTime maxMonth = DateTime(now.year, now.month + 2, 0); // letzter Tag des nächsten Monats
                          final DateTime initialDate = _focusedDay.isAfter(maxMonth) ? maxMonth : _focusedDay;
                          DateTime tempDate = initialDate;

                          final DateTime? pickedDate = await showDialog<DateTime>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                contentPadding: const EdgeInsets.all(0),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: CupertinoDatePicker(
                                          mode: CupertinoDatePickerMode.monthYear,
                                          initialDateTime: initialDate,
                                          minimumDate: DateTime(2000),
                                          maximumDate: maxMonth, // <--- hier!
                                          onDateTimeChanged: (DateTime newDate) {
                                            tempDate = DateTime(newDate.year, newDate.month, 1);
                                          },
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(tempDate); // <--- gibt das Datum zurück!
                                        },
                                        child: const Text('Übernehmen'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          if (pickedDate != null) {
                            _calendarController.displayDate = pickedDate;
                            setState(() {
                              _focusedDay = pickedDate;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        label: Text(
                          "${_focusedDay.month.toString().padLeft(2, '0')}.${_focusedDay.year}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SfCalendar(
                    controller: _calendarController,
                    view: CalendarView.month,
                    viewNavigationMode: ViewNavigationMode.snap,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    todayHighlightColor: Theme.of(context).colorScheme.primary,
                    selectionDecoration: const BoxDecoration(),
                    firstDayOfWeek: 1,
                    viewHeaderHeight: 10,
                    headerHeight: 0,
                    initialDisplayDate: _focusedDay,
                    minDate: DateTime(2000, 1, 1),
                    maxDate: maxMonth,
                    monthViewSettings: MonthViewSettings(
                      showTrailingAndLeadingDates: false,
                      appointmentDisplayMode: MonthAppointmentDisplayMode.none,
                      dayFormat: 'EE',
                      numberOfWeeksInView: 6,
                      navigationDirection: MonthNavigationDirection.vertical,
                      showAgenda: false,
                    ),
                    onTap: (calendarTapDetails) {
                      final DateTime? selectedDay = calendarTapDetails.date;
                      if (selectedDay == null) return;
                      String key = "${selectedDay.year.toString().padLeft(4, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                      final eintrag = eintraege[key];
                      if (eintrag != null && eintrag['option'] != null && eintrag['option'] != '') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color.fromARGB(255, 75, 73, 73),
                            title: Text('Eintrag', style: TextStyle(color: Colors.white)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sportart: ${eintrag['option'] ?? ''}', style: TextStyle(color: Colors.white)),
                                SizedBox(height: 8),
                                Text('Text: ${eintrag['text'] ?? ''}', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('OK', style: TextStyle(color: Colors.blue)),
                              ),
                            ],
                          ),
                        );
                      }
                      setState(() {
                        _focusedDay = selectedDay;
                      });
                    },
                    monthCellBuilder: (context, details) {
                      final key = "${details.date.year.toString().padLeft(4, '0')}-${details.date.month.toString().padLeft(2, '0')}-${details.date.day.toString().padLeft(2, '0')}";
                      final eintrag = eintraege[key];
                      final theme = Theme.of(context);
                      bool isToday = details.date.year == DateTime.now().year &&
                          details.date.month == DateTime.now().month &&
                          details.date.day == DateTime.now().day;
                      return Align(
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (isToday)
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            if (eintrag != null)
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            // Datum
                            Container(
                              width: 45,
                              height: 45,
                              alignment: Alignment.center,
                              child: Text(
                                '${details.date.day}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: eintrag != null ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    initialSelectedDate: _focusedDay,
                    onViewChanged: (ViewChangedDetails details) {
                      final DateTime visibleDate = details.visibleDates.first;
                      // Nur wenn sich der Monat ODER das Jahr geändert hat
                      if (_focusedDay.year != visibleDate.year || _focusedDay.month != visibleDate.month) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _focusedDay = DateTime(visibleDate.year, visibleDate.month, 1);
                          });
                        });
                      }
                    },
                  ),
                  // Trennlinie
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: Colors.white,
                      thickness: 1,
                      height: 1,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      // Aktivitäten im aktuellen Monat zählen
                      final logsThisMonth = eintraege.values.where((eintrag) {
                        if (eintrag['datum'] == null) return false;
                        final DateTime date = DateTime.tryParse(eintrag['datum']) ?? DateTime(2000);
                        return date.year == _focusedDay.year && date.month == _focusedDay.month;
                      }).length;

                      // Aktivitäten im vorherigen Monat zählen (auch Jahreswechsel beachten)
                      int prevMonth = _focusedDay.month - 1;
                      int prevYear = _focusedDay.year;
                      if (prevMonth == 0) {
                        prevMonth = 12;
                        prevYear -= 1;
                      }
                      final logsLastMonth = eintraege.values.where((eintrag) {
                        if (eintrag['datum'] == null) return false;
                        final DateTime date = DateTime.tryParse(eintrag['datum']) ?? DateTime(2000);
                        return date.year == prevYear && date.month == prevMonth;
                      }).length;

                      Widget trendIcon;
                      if (logsThisMonth > logsLastMonth) {
                        trendIcon = Icon(Icons.arrow_upward, color: Colors.green, size: 22);
                      } else if (logsThisMonth < logsLastMonth) {
                        trendIcon = Icon(Icons.arrow_downward, color: Colors.red, size: 22);
                      } else {
                        trendIcon = Icon(Icons.remove, color: Colors.grey, size: 28, weight: 900);
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Aktivitäten dieser Monat:",
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                trendIcon,
                                const SizedBox(width: 8),
                                Text(
                                  logsThisMonth.toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Aktivitäten vorheriger Monat:",
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Text(
                                  logsLastMonth.toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
          },
        ),
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 3),
    );
  }
}