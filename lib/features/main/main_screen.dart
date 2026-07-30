import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../components/bottom_navbar.dart';
import '../../components/bottom_sheets/favorite_bottom_sheet.dart';
import '../../components/bottom_sheets/guide_bottom_sheet.dart';
import '../../components/bottom_sheets/more_bottom_sheet.dart';
import '../../components/map_search_bar.dart';
import '../auth/screen/login_screen.dart';
import '../auth/screen/profile_edit_screen.dart';
import '../map/map_screen.dart';
import '../map/service/place_search_service.dart';
import '../map/service/route_api_service.dart';
import '../map/widgets/search_panel.dart';

class MainScreen extends StatefulWidget {
  final int? userId;

  const MainScreen({super.key, this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  int selectedIndex = 0;
  bool showSheet = false;
  bool showSearchPanel = false;
  bool hasSearched = false;
  NLatLng? startPoint;
  NLatLng? destinationPoint;
  NLatLng? cameraTarget;
  List<NLatLng> routePath = [];
  bool isRouteLoading = false;
  bool isSearchLoading = false;
  bool isInRiskZone = false;
  List<Map<String, dynamic>> searchResults = [];

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

  void onRiskZoneChanged(bool value) {
    if (!mounted || isInRiskZone == value) return;

    setState(() {
      isInRiskZone = value;
    });
  }

  Widget buildRiskZoneOverlay() {
    final alertBottom = showSheet
        ? navBarHeight + sheetHeight + 4
        : navBarHeight + 12;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isInRiskZone ? 1 : 0,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: alertBottom,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.65),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE53935),
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '위험구역입니다',
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      return MoreBottomSheet(
        onProfileTap: openProfileEdit,
        onLogoutTap: logout,
      );
    }
  }

  void openProfileEdit() {
    final userId = widget.userId;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(userId: userId),
      ),
    );
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void selectRoutePoint(NLatLng point) {
    setState(() {
      selectedIndex = 0;
      showSheet = true;
      showSearchPanel = false;

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

  Future<void> searchPlaces() async {
    final query = searchController.text.trim();

    if (query.isEmpty || isSearchLoading) return;

    setState(() {
      isSearchLoading = true;
      showSearchPanel = true;
      hasSearched = true;
      searchResults = [];
    });

    try {
      final places = await PlaceSearchService.searchPlaces(query);

      if (!mounted) return;

      setState(() {
        searchResults = places;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (!mounted) return;

      setState(() {
        isSearchLoading = false;
      });
    }
  }

  void selectSearchResult(Map<String, dynamic> place) {
    final lat = place['lat'];
    final lng = place['lng'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('좌표가 없는 검색 결과입니다.')));
      return;
    }

    final point = NLatLng((lat as num).toDouble(), (lng as num).toDouble());

    setState(() {
      cameraTarget = point;
      searchController.text = place['title']?.toString() ?? '';
      showSearchPanel = false;
      hasSearched = false;
    });

    searchFocusNode.unfocus();
    selectRoutePoint(point);
  }

  void resetRoutePoints() {
    setState(() {
      startPoint = null;
      destinationPoint = null;
      routePath = [];
    });
  }

  Future<void> loadRoute(String mode) async {
    final start = startPoint;
    final destination = destinationPoint;

    if (start == null || destination == null || isRouteLoading) return;

    setState(() {
      isRouteLoading = true;
    });

    try {
      final path = await RouteApiService.loadRoute(
        start: start,
        destination: destination,
        mode: mode,
      );

      if (!mounted) return;

      setState(() {
        routePath = path;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (!mounted) return;

      setState(() {
        isRouteLoading = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
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
              cameraTarget: cameraTarget,
              onRoutePointSelected: selectRoutePoint,
              onRiskZoneChanged: onRiskZoneChanged,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MapSearchBar(
              controller: searchController,
              focusNode: searchFocusNode,
              onTap: () {
                setState(() {
                  showSearchPanel = true;
                });
              },
              onSearch: searchPlaces,
              onSubmitted: (_) => searchPlaces(),
            ),
          ),

          if (showSearchPanel && (isSearchLoading || hasSearched))
            Positioned(
              top: 88,
              left: 16,
              right: 16,
              child: SearchPanel(
                isLoading: isSearchLoading,
                results: searchResults,
                onSelect: selectSearchResult,
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
          buildRiskZoneOverlay(),
        ],
      ),
    );
  }
}
