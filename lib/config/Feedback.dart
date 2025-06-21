import 'package:flutter/material.dart';

class FeedbackWidget extends StatelessWidget {
  final void Function(bool) onFeedbackGiven;
  final bool? feedbackCorrect;

  const FeedbackWidget({
    Key? key,
    required this.onFeedbackGiven,
    this.feedbackCorrect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "Is this prediction correct?",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => onFeedbackGiven(true),
              icon: const Icon(Icons.thumb_up),
              label: const Text("Yes"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: () => onFeedbackGiven(false),
              icon: const Icon(Icons.thumb_down),
              label: const Text("No"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
        if (feedbackCorrect != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              feedbackCorrect == true
                  ? "👍 You confirmed the prediction."
                  : "👎 We'll work to improve the accuracy.",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
      ],
    );
  }
}
