import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
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
  NLatLng? startPoint;
  NLatLng? destinationPoint;
  List<NLatLng> routePath = [];
  bool isRouteLoading = false;

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
      return GuideBottomSheet(
        startPoint: startPoint,
        destinationPoint: destinationPoint,
        isRouteLoading: isRouteLoading,
        onStartRoute: loadRoute,
        onReset: resetRoutePoints,
      );
    } else if (selectedIndex == 1) {
      return const FavoriteBottomSheet();
    } else {
      return const MoreBottomSheet();
    }
  }

  void selectRoutePoint(NLatLng point) {
    setState(() {
      selectedIndex = 0;
      showSheet = true;

      if (startPoint == null || destinationPoint != null) {
        startPoint = point;
        destinationPoint = null;
        routePath = [];
      } else {
        destinationPoint = point;
        routePath = [];
      }
    });
  }

  void resetRoutePoints() {
    setState(() {
      startPoint = null;
      destinationPoint = null;
      routePath = [];
    });
  }

  Future<void> loadRoute() async {
    final start = startPoint;
    final destination = destinationPoint;

    if (start == null || destination == null || isRouteLoading) return;

    setState(() {
      isRouteLoading = true;
    });

    try {
      final uri = Uri.parse('http://10.0.2.2:5000/route').replace(
        queryParameters: {
          's_lat': start.latitude.toString(),
          's_lng': start.longitude.toString(),
          'e_lat': destination.latitude.toString(),
          'e_lng': destination.longitude.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || data['success'] != true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']?.toString() ?? '경로를 찾을 수 없습니다.')),
        );
        return;
      }

      final path = List<Map<String, dynamic>>.from(data['path']);

      if (!mounted) return;

      setState(() {
        routePath = path
            .map(
              (point) => NLatLng(
                (point['lat'] as num).toDouble(),
                (point['lng'] as num).toDouble(),
              ),
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('경로 요청 오류: $e')));
    } finally {
      if (!mounted) return;

      setState(() {
        isRouteLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: navBarHeight,
            child: MapScreen(
              buttonBottom: showSheet
                  ? sheetHeight + navBarHeight - 70
                  : navBarHeight - 70,
              startPoint: startPoint,
              destinationPoint: destinationPoint,
              routePath: routePath,
              onRoutePointSelected: selectRoutePoint,
            ),
          ),
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
              showSheet: showSheet,
              onTap: onTapBottomNav,
              height: navBarHeight,
            ),
          ),
        ],
      ),
    );
  }
}
