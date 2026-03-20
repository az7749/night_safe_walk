import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('안심 지도'), centerTitle: true),
      body: Column(
        children: [
          // 지도 자리
          Expanded(
            child: Container(
              // margin: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                // borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '여기에 지도 API 화면이 들어갈 예정',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
