import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../Home/journal.dart';
import '../shared/navigationsleiste.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface, 
        title: Text('Kalender', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Platzhalter für linke Seite, damit die Mitte stimmt
                Expanded(
                  child: Center(
                    child: TextButton.icon(
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
                                        _calendarController.displayDate = tempDate;
                                        setState(() {
                                          _focusedDay = tempDate;
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
                  ),
                ),
                // "Heute"-Button oben rechts
                ElevatedButton(
                  onPressed: () {
                    final DateTime today = DateTime.now();
                    final DateTime thisMonth = DateTime(today.year, today.month, 1);
                    _calendarController.displayDate = thisMonth;
                    setState(() {
                      _focusedDay = thisMonth;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.transparent, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Heute'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: SfCalendar(
                controller: _calendarController,
                view: CalendarView.month,
                viewNavigationMode: ViewNavigationMode.snap,
                backgroundColor: Theme.of(context).colorScheme.surface,                
                abtodayHighlightColor: Theme.of(context).colorScheme.primary,
                selectionDecoration: const BoxDecoration(),
                firstDayOfWeek: 1,
                viewHeaderHeight: 10,
                headerHeight: 0,
                initialDisplayDate: _focusedDay,
                minDate: DateTime(2000, 1, 1),
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

                  return Align(
                    alignment: Alignment.center,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
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