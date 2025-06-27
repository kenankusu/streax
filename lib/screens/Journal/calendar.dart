import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../Home/journal.dart';
import '../Shared/navigationbar.dart';
import 'package:flutter/cupertino.dart'; 

class kalender extends StatefulWidget {
  const kalender({super.key});

  @override
  State<kalender> createState() => _KalenderState();
}

class _KalenderState extends State<kalender> {
  DateTime _focusedDay = DateTime.now();
  String _dateKey(DateTime date) =>
      "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  final CalendarController _calendarController = CalendarController();
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    DateTime tempDate = _focusedDay;
                    await showDialog(
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
                                    initialDateTime: _focusedDay.isAfter(DateTime(DateTime.now().year, DateTime.now().month + 1, 0))
                                        ? DateTime(DateTime.now().year, DateTime.now().month + 1, 0)
                                        : _focusedDay,
                                    minimumDate: DateTime(2000),
                                    maximumDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
                                    onDateTimeChanged: (DateTime newDate) {
                                      tempDate = DateTime(newDate.year, newDate.month, 1);
                                    },
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _calendarController.displayDate = tempDate; // Kalender springt sofort
                                    setState(() {
                                      _focusedDay = tempDate; // Button oben aktualisieren
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Übernehmen'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text(
                    "${_focusedDay.month.toString().padLeft(2, '0')}.${_focusedDay.year}",
                    style: TextStyle(
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
            Expanded(
              child: SfCalendar(
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
                minDate: DateTime(2000, 1, 1), // Frühestes Datum
                maxDate: DateTime(DateTime.now().year, DateTime.now().month, 31),
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
                          top: -5,
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
                initialSelectedDate: _focusedDay,
                onViewChanged: (ViewChangedDetails details) {
                  final DateTime visibleDate = details.visibleDates.first;
                  if (_focusedDay.year != visibleDate.year || _focusedDay.month != visibleDate.month) {
                    setState(() {
                      _focusedDay = DateTime(visibleDate.year, visibleDate.month, 1);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 3),
    );
  }
}