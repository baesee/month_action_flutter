import 'package:flutter/material.dart';

class CustomLoading extends StatelessWidget {
  final String? message;
  const CustomLoading({this.message, super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6DD5FA),
            strokeWidth: 5,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class CustomError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const CustomError({required this.message, this.onRetry, super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😢', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6DD5FA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}

class CustomEmpty extends StatelessWidget {
  final String message;
  final String emoji;
  const CustomEmpty({required this.message, this.emoji = '🪐', super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
