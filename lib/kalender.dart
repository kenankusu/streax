import 'package:flutter/material.dart';
// TableCalendar entfernen
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'widgets/journal.dart';
import 'widgets/navigationsleiste.dart'; // Import hinzufügen

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
        padding: const EdgeInsets.all(8.0),
        child: SfCalendar(
          view: CalendarView.month,
          allowedViews: const [CalendarView.month],
          viewNavigationMode: ViewNavigationMode.snap,
          backgroundColor: Colors.grey[900],
          todayHighlightColor: Color.fromARGB(255, 0, 68, 255),
          selectionDecoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6),
          ),
          monthViewSettings: MonthViewSettings(
            showTrailingAndLeadingDates: true,
            appointmentDisplayMode: MonthAppointmentDisplayMode.none,
            dayFormat: 'EEE',
            numberOfWeeksInView: 6, // Standard, aber "unendlich" durch ScrollDirection
            navigationDirection: MonthNavigationDirection.vertical,
          ),
          onTap: (calendarTapDetails) {
            final DateTime? selectedDay = calendarTapDetails.date;
            if (selectedDay == null) return;
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
              _focusedDay = selectedDay;
            });
          },
          monthCellBuilder: (context, details) {
            final eintrag = eintraege[_dateKey(details.date)];
            final theme = Theme.of(context);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: eintrag != null ? theme.colorScheme.primary : null,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${details.date.day}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: eintrag != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (eintrag != null && eintrag['icon'] != null && eintrag['icon'] != '')
                  Positioned(
                    top: -2, // leicht außerhalb des Kreises
                    right: 12,
                    child: Image.asset(
                      eintrag['icon'],
                      width: 18,
                      height: 18,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 3),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}