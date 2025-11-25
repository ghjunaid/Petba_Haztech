import 'package:flutter/material.dart';
import 'package:petba_new/providers/Config.dart';

class StepHeader extends StatelessWidget {
  final int activeStep; // 1 to 4

  const StepHeader({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Cart', 'Address', 'Payment', 'Order Placed'];
    final theme = Theme.of(context);
    final Color blue = theme.colorScheme.primary;
    final Color onBlue = theme.colorScheme.onPrimary;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color inactiveCircle = theme.dividerColor;

    Widget circle(int index) {
      bool isCompleted = index < activeStep - 1;
      bool isActive = index == activeStep - 1;

      if (isCompleted) {
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: blue, shape: BoxShape.circle),
          child: Icon(Icons.check, color: onBlue, size: 16),
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
            style: TextStyle(color: onBlue, fontWeight: FontWeight.bold),
          ),
        );
      }

      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: inactiveCircle,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text("${index + 1}", style: TextStyle(color: onSurface)),
      );
    }

    Widget line(bool active) {
      return Expanded(
        child: Container(height: 2, color: active ? blue : theme.dividerColor),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: Theme.of(context).scaffoldBackgroundColor,
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
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface,
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
