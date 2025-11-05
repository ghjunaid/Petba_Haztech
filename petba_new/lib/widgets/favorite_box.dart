import 'package:flutter/material.dart';
import 'package:petba_new/theme/color.dart';

class FavoriteBox extends StatelessWidget {
  final bool isFavorited;
  final GestureTapCallback? onTap;

  const FavoriteBox({
    Key? key,
    required this.isFavorited,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColor.glassBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColor.glassBorder,
            width: 1,
          ),
        ),
        child: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          color: isFavorited ? AppColor.accentRed : AppColor.glassTextColor,
          size: 20,
        ),
      ),
    );
  }
}
