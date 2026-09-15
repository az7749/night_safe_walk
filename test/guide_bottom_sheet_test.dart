import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:night_safe_walk/components/bottom_sheets/guide_bottom_sheet.dart';

void main() {
  testWidgets('route buttons wait for points and dispatch the chosen mode', (tester) async {
    final selected = <String>[];
    Future<void> show({bool ready = true, bool loading = false}) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
        width: 320, height: 300,
        child: GuideBottomSheet(
          startPoint: const NLatLng(36.6, 127.4),
          destinationPoint: ready ? const NLatLng(36.7, 127.5) : null,
          destinationPointName: '충청북도 청주시 서원구 긴 도로명 주소 테스트',
          isRouteLoading: loading,
          onReset: () {}, onRouteSelected: selected.add,
        ),
      ))));
    }
    await show(ready: false);
    await tester.tap(find.text('빠른길'));
    expect(selected, isEmpty);
    await show();
    expect(selected, isEmpty);
    await tester.tap(find.text('빠른길'));
    await tester.tap(find.text('안전한길'));
    expect(selected, ['fast', 'safe']);
    await show(loading: true);
    await tester.tap(find.text('빠른길'));
    expect(selected, ['fast', 'safe']);
    expect(tester.takeException(), isNull);
  });
}
