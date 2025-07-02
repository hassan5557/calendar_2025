import 'package:flutter/material.dart';
import 'calendarpage/calendar_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Set based on your design (iPhone 11 example)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Calendar',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const CalendarPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

