import 'package:flutter/material.dart';
import 'package:night_safe_walk/components/bottom_navbar.dart';
import 'package:night_safe_walk/features/map/map_screen.dart';
import 'package:night_safe_walk/components/bottom_sheets/guide_bottom_sheet.dart';
import 'package:night_safe_walk/components/bottom_sheets/favorite_bottom_sheet.dart';
import 'package:night_safe_walk/components/bottom_sheets/more_bottom_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? _selectedSheet;

  void _onTap(int index) {
    setState(() {
      if (_selectedSheet == index) {
        _selectedSheet = null;
      } else {
        _selectedSheet = index;
      }
    });
  }

  Widget _buildBottomSheet() {
    switch (_selectedSheet) {
      case 0:
        return const GuideBottomSheet();
      case 1:
        return const FavoriteBottomSheet();
      case 2:
        return const MoreBottomSheet();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSheetOpen = _selectedSheet != null;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MapScreen()),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: isSheetOpen ? 110 : -280,
            child: Material(
              elevation: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(height: 280, child: _buildBottomSheet()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 110,
        child: BottomNavbar(onTap: _onTap),
      ),
    );
  }
}
