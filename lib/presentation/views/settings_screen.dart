import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정1'),
        automaticallyImplyLeading: false,
        leading:
            ModalRoute.of(context)?.isFirst == true ? null : const BackButton(),
      ),
      body: const Center(
        child: Text('설정 화면입니다.111', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
