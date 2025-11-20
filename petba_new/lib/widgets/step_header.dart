import 'package:flutter/material.dart';
import 'package:petba_new/providers/Config.dart';

class StepHeader extends StatelessWidget {
  final int activeStep; // 1 to 4

  const StepHeader({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Cart', 'Address', 'Payment', 'Order Placed'];
    final Color blue = const Color(0xFF3F51B5);

    Widget circle(int index) {
      bool isCompleted = index < activeStep - 1;
      bool isActive = index == activeStep - 1;

      if (isCompleted) {
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: blue, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
      }

      if (isActive) {
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: blue, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            "${index + 1}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      return Container(
        width: 28,
        height: 28,
        decoration:
            BoxDecoration(color: Colors.grey.shade600, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          "${index + 1}",
          style: const TextStyle(color: Colors.black),
        ),
      );
    }

    Widget line(bool active) {
      return Expanded(
        child: Container(
          height: 2,
          color: active ? Colors.grey : Colors.grey.shade800,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: AppColors.primaryDark,
      child: Column(
        children: [
          Row(
            children: [
              circle(0),
              line(activeStep >= 2),
              circle(1),
              line(activeStep >= 3),
              circle(2),
              line(activeStep >= 4),
              circle(3),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps
                .map(
                  (t) => Expanded(
                    child: Text(
                      t,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
