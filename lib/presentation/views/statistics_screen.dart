import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        automaticallyImplyLeading: false,
        leading:
            ModalRoute.of(context)?.isFirst == true ? null : const BackButton(),
      ),
      body: const Center(
        child: Text('통계 화면입니다22.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
