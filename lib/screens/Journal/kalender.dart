import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../Home/journal.dart';
import '../shared/navigationsleiste.dart'; // Import hinzufügen

class kalender extends StatefulWidget {
  const kalender({super.key});

  @override
  State<kalender> createState() => _KalenderState();
}

class _KalenderState extends State<kalender> {
  DateTime _focusedDay = DateTime.now();
String _dateKey(DateTime date) =>
    "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Kalender', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Color.fromARGB(255, 0, 68, 255),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: Colors.white70),
            defaultTextStyle: TextStyle(color: Colors.white),
            outsideTextStyle: TextStyle(color: Colors.grey),
          ),
          headerStyle: HeaderStyle(
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
            formatButtonVisible: false,
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            decoration: BoxDecoration(
              color: Colors.grey[850],
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final eintrag = eintraege[_dateKey(day)];
              final isToday = _isSameDay(day, DateTime.now());
              if (eintrag != null && eintrag['option'] != null && eintrag['option'] != '') {
                return Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? Color.fromARGB(255, 0, 40, 150) // dunkler blau für heute mit Eintrag
                        : Color.fromARGB(255, 0, 68, 255), // blau für andere Tage mit Eintrag
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              return null;
            },
            todayBuilder: (context, day, focusedDay) {
              final eintrag = eintraege[_dateKey(day)];
              if (eintrag != null && eintrag['option'] != null && eintrag['option'] != '') {
                return Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 0, 40, 150),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              // Standard-heute-Dekoration
              return Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 0, 68, 255),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            String key = _dateKey(selectedDay);
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
              _focusedDay = focusedDay;
            });
          },
        ),
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 3), // Navigationsleiste hinzufügen (currentPage: 3 = Kalender)
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}