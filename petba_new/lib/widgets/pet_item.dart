import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:petba_new/theme/color.dart';
import 'package:petba_new/widgets/favorite_box.dart';
import 'package:petba_new/widgets/custom_image.dart';

class PetItem extends StatelessWidget {
  const PetItem({
    Key? key,
    required this.data,
    this.width = 350,
    this.height = 400,
    this.radius = 40,
    this.onTap,
    this.onFavoriteTap,
  }) : super(key: key);

  final data;
  final double width;
  final double height;
  final double radius;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Stack(
          children: [
            _buildImage(),
            Positioned(
              bottom: 0,
              child: _buildInfoGlass(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGlass() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(25),
      blur: 10,
      opacity: 0.15,
      child: Container(
        width: width,
        height: 110,
        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColor.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo(),
            SizedBox(height: 5),
            _buildLocation(),
            SizedBox(height: 15),
            _buildAttributes(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocation() {
    return Text(
      data["location"],
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColor.glassLabelColor,
        fontSize: 13,
      ),
    );
  }

  Widget _buildInfo() {
    return Row(
      children: [
        Expanded(
          child: Text(
            data["name"],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColor.glassTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FavoriteBox(
          isFavorited: data["is_favorited"],
          onTap: onFavoriteTap,
        ),
      ],
    );
  }

  Widget _buildImage() {
    return CustomImage(
      data["image"],
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(radius),
        bottom: Radius.zero,
      ),
      isShadow: false,
      width: width,
      height: 350,
    );
  }

  Widget _buildAttributes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _getAttribute(
          Icons.transgender,
          data["sex"],
        ),
        _getAttribute(
          Icons.color_lens_outlined,
          data["color"],
        ),
        _getAttribute(
          Icons.query_builder,
          data["age"],
        ),
      ],
    );
  }

  Widget _getAttribute(IconData icon, String info) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColor.glassTextColor,
        ),
        SizedBox(width: 3),
        Text(
          info,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColor.textColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// Full-screen Pet Detail Widget
class PetDetailFullScreen extends StatelessWidget {
  final data;
  final GestureTapCallback? onBackTap;
  final GestureTapCallback? onFavoriteTap;
  final GestureTapCallback? onMessageTap;
  final GestureTapCallback? onCallTap;
  final GestureTapCallback? onAdoptTap;

  const PetDetailFullScreen({
    Key? key,
    required this.data,
    this.onBackTap,
    this.onFavoriteTap,
    this.onMessageTap,
    this.onCallTap,
    this.onAdoptTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopImage(context),
            _buildGlassmorphicCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4,
      child: Stack(
        children: [
          CustomImage(
            data["image"],
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            isShadow: false,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: onBackTap,
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
                  Icons.arrow_back,
                  color: AppColor.glassTextColor,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: FavoriteBox(
              isFavorited: data["is_favorited"],
              onTap: onFavoriteTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicCard() {
    return Container(
      margin: EdgeInsets.only(top: -30),
      child: GlassContainer(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        blur: 15,
        opacity: 0.2,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPetInfo(),
              SizedBox(height: 24),
              _buildOwnerInfo(),
              SizedBox(height: 24),
              _buildDescription(),
              SizedBox(height: 32),
              _buildAdoptButton(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                data["name"],
                style: TextStyle(
                  color: AppColor.glassTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FavoriteBox(
              isFavorited: data["is_favorited"],
              onTap: onFavoriteTap,
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppColor.glassLabelColor,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              data["location"],
              style: TextStyle(
                color: AppColor.glassLabelColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildPetAttributes(),
      ],
    );
  }

  Widget _buildPetAttributes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAttributeCard(Icons.transgender, "Sex", data["sex"]),
        _buildAttributeCard(Icons.color_lens_outlined, "Color", data["color"]),
        _buildAttributeCard(Icons.query_builder, "Age", data["age"]),
      ],
    );
  }

  Widget _buildAttributeCard(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColor.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColor.glassTextColor,
            size: 20,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColor.glassLabelColor,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColor.glassTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Owner",
            style: TextStyle(
              color: AppColor.glassTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColor.glassBorder,
                child: Icon(
                  Icons.person,
                  color: AppColor.glassTextColor,
                  size: 30,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["owner_name"] ?? "Pet Owner",
                      style: TextStyle(
                        color: AppColor.glassTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Pet Owner",
                      style: TextStyle(
                        color: AppColor.glassLabelColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildActionButton(
                    Icons.message,
                    onMessageTap,
                  ),
                  SizedBox(width: 8),
                  _buildActionButton(
                    Icons.call,
                    onCallTap,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, GestureTapCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColor.primaryBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Description",
          style: TextStyle(
            color: AppColor.glassTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          data["description"] ?? "This is a wonderful pet looking for a loving home. They are friendly, well-behaved, and ready to become part of your family.",
          style: TextStyle(
            color: AppColor.glassLabelColor,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAdoptButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onAdoptTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryBlue,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          "Adopt Me",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
