import 'package:flutter/material.dart';
import 'package:solar_sky_mobile_app/screens/drone_screen.dart';
import 'package:solar_sky_mobile_app/screens/farm_screen.dart';
import 'package:solar_sky_mobile_app/screens/reports_screen.dart';
import 'package:solar_sky_mobile_app/screens/start_inspection_timer.dart';

/*
this is the home screen of the app which contains the bottom navigation bar
to navigate between the farm, report and drone screens, and also to 
display the selected screen
 */
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      const FarmScreen(),
      const ReportScreen(),
      const DroneScreen(),
      StartInspectionTimer(), // Add your start_inspection_timer screen here
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0XFF2F004F),
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                icon: Icons.solar_power,
                // iconSize: 30,
                index: 0,
                text: 'Farm',
              ),
              _buildTabItem(
                icon: Icons.analytics,
                index: 1,
                text: 'Reports',
              ),
              _buildTabItem(
                icon: Icons.wifi_tethering,
                index: 2,
                text: 'Drone',
              ),
              _buildTabItem(
                icon: Icons.timelapse,
                index: 3,
                text: 'Inspection',
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required int index,
    required String text,
  }) {
    return InkWell(
      onTap: () => _selectTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: _selectedIndex == index ? Colors.deepPurple : Colors.grey),
          Text(
            text,
            style: TextStyle(
              color: _selectedIndex == index ? Colors.deepPurple : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      // Pop to first route if user taps the current active tab
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}
