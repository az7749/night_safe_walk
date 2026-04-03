import 'package:flutter/material.dart';
import '../../components/bottom_navbar.dart';
import '../../components/bottom_sheets/favorite_bottom_sheet.dart';
import '../../components/bottom_sheets/guide_bottom_sheet.dart';
import '../../components/bottom_sheets/more_bottom_sheet.dart';
import '../../components/map_search_bar.dart';
import '../map/map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  bool showSheet = false;

  final double navBarHeight = 80;
  final double sheetHeight = 320;

  void onTapBottomNav(int index) {
    setState(() {
      if (selectedIndex == index && showSheet) {
        showSheet = false;
      } else {
        selectedIndex = index;
        showSheet = true;
      }
    });
  }

  Widget getCurrentBottomSheet() {
    if (selectedIndex == 0) {
      return const GuideBottomSheet();
    } else if (selectedIndex == 1) {
      return const FavoriteBottomSheet();
    } else {
      return const MoreBottomSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MapScreen()),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MapSearchBar(
              onTap: () {
                debugPrint('검색창 클릭');
              },
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: showSheet ? navBarHeight - 10 : -sheetHeight,
            child: SizedBox(
              height: sheetHeight,
              child: getCurrentBottomSheet(),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavbar(
              selectedIndex: selectedIndex,
              onTap: onTapBottomNav,
              height: navBarHeight,
            ),
          ),
        ],
      ),
    );
  }
}
