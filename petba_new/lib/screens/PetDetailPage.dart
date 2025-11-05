import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:petba_new/chat/Model/ChatModel.dart';
import 'package:petba_new/chat/Model/Messagemodel.dart';
import 'package:petba_new/chat/screens/Individualpage.dart';
import 'package:petba_new/chat/socket_sevice.dart';
import 'package:petba_new/models/adoption.dart';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/services/user_data_service.dart';
import 'package:petba_new/services/owner_service.dart';
import 'package:petba_new/theme/color.dart';
import 'package:petba_new/widgets/custom_image.dart';
import 'package:petba_new/widgets/favorite_box.dart';

class PetDetailPage extends StatefulWidget {
  final AdoptionPet pet;

  PetDetailPage({required this.pet});

  @override
  _PetDetailPageState createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  Map<String, dynamic>? ownerInfo;
  bool isLoadingOwner = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    try {
      final info = await OwnerService.getOwnerInfo(widget.pet.cId);
      if (mounted) {
        setState(() {
          ownerInfo = info;
          isLoadingOwner = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingOwner = false;
        });
      }
    }
  }

  String _calculateAge(String dob) {
    try {
      final DateTime birthDate = DateTime.parse(dob);
      final DateTime now = DateTime.now();
      final int years = now.year - birthDate.year;
      final int months = now.month - birthDate.month;

      if (years > 0) {
        return '$years year${years > 1 ? 's' : ''} old';
      } else if (months > 0) {
        return '$months month${months > 1 ? 's' : ''} old';
      } else {
        return 'Less than 1 month old';
      }
    } catch (e) {
      return 'Age unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [_buildTopImage(context), _buildGlassmorphicCard(context)],
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
            widget.pet.img1.isNotEmpty ? '$apiurl/${widget.pet.img1}' : '',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.fill,
            isShadow: false,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.glassBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColor.glassBorder, width: 1),
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
              isFavorited: false, // You can implement favorite logic here
              onTap: () {
                // Add favorite functionality
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicCard(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -60),
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
              _buildOwnerInfo(context),
              SizedBox(height: 24),
              _buildDescription(),
              SizedBox(height: 32),
              _buildAdoptButton(context),
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
                widget.pet.name.toLowerCase(),
                style: TextStyle(
                  color: AppColor.glassTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FavoriteBox(
              isFavorited: false, // You can implement favorite logic here
              onTap: () {
                // Add favorite functionality
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, color: AppColor.glassLabelColor, size: 16),
            SizedBox(width: 4),
            Text(
              widget.pet.city,
              style: TextStyle(color: AppColor.glassLabelColor, fontSize: 16),
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
        _buildAttributeCard(
          Icons.transgender,
          "Sex",
          widget.pet.gender == 1 ? 'Male' : 'Female',
        ),
        _buildAttributeCard(
          Icons.color_lens_outlined,
          "Breed",
          widget.pet.breed,
        ),
        _buildAttributeCard(
          Icons.query_builder,
          "Age",
          _calculateAge(widget.pet.dob),
        ),
      ],
    );
  }

  Widget _buildAttributeCard(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.glassBorder, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColor.glassTextColor, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppColor.glassLabelColor, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColor.glassTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.glassBorder, width: 1),
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
                      isLoadingOwner
                          ? "Loading..."
                          : ownerInfo != null
                          ? "${ownerInfo!['firstname'] ?? ''} ${ownerInfo!['lastname'] ?? ''}"
                                .trim()
                          : "Pet Owner",
                      style: TextStyle(
                        color: AppColor.glassTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isLoadingOwner
                          ? "Loading owner info..."
                          : ownerInfo != null
                          ? ownerInfo!['email'] ??
                                "Customer ID: ${widget.pet.cId}"
                          : "Customer ID: ${widget.pet.cId}",
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
                    () => _handleAdoptRequest(context),
                  ),
                  SizedBox(width: 8),
                  _buildActionButton(
                    Icons.call,
                    () => _handleCallOwner(context),
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
        child: Icon(icon, color: Colors.white, size: 20),
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
          widget.pet.note.isNotEmpty
              ? widget.pet.note
              : "This is a wonderful ${widget.pet.animalName.toLowerCase()} named ${widget.pet.name.toLowerCase()}. They are ${widget.pet.gender == 1 ? 'male' : 'female'} and ${widget.pet.breed.toLowerCase()} breed. This lovely pet is looking for a caring home and would make a great companion.",
          style: TextStyle(
            color: AppColor.glassLabelColor,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Text(
              "Pet ID: ${widget.pet.adoptId}",
              style: TextStyle(color: AppColor.glassLabelColor, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdoptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleAdoptRequest(context),
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

  Future<void> _handleCallOwner(BuildContext context) async {
    if (ownerInfo != null && ownerInfo!['telephone'] != null) {
      final phoneNumber = ownerInfo!['telephone'];
      // You can implement phone calling functionality here
      // For now, show a dialog with the phone number
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColor.secondaryBackground,
          title: Text(
            "Call Owner",
            style: TextStyle(color: AppColor.glassTextColor),
          ),
          content: Text(
            "Phone: $phoneNumber",
            style: TextStyle(color: AppColor.glassLabelColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: AppColor.primaryBlue),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Owner phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAdoptRequest(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF2d2d2d),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'Creating chat...',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );

      // Get current user data
      final userData = await UserDataService.getUserData();
      if (userData == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final currentUserId = userData['customer_id'] ?? userData['id'];
      print('Current User ID: $currentUserId');
      final currentUserName =
          '${userData['firstname']} ${userData['lastname']}';
      print('Current Nameee: $currentUserName');

      // Create UserModel for current user
      final currentUser = UserModel(
        id: currentUserId,
        name: currentUserName,
        email: userData['email'],
        phoneNumber: userData['telephone'] ?? '',
        location: widget.pet.city,
        profileImageUrl: '',
        createdAt: DateTime.now(),
        token: userData['token'],
      );

      // Initialize socket service
      final socketService = SocketService.getInstance();

      // Store reference to created chat
      ChatModel? createdChatModel;
      String? conversationId;

      // Set up listeners for chat creation
      socketService.onNewChat = (chatData) {
        print('Chat creation response: $chatData');

        if (chatData.containsKey('conversationId')) {
          conversationId = chatData['conversationId'].toString();

          // Create chat model from response
          createdChatModel = ChatModel(
            name: widget.pet.name,
            icon: "pet.svg",
            isGroup: false,
            time: DateTime.now().toString(),
            currentMessage: "Chat started for ${widget.pet.name} adoption",
            id: widget.pet.adoptId,
            ownerId: widget.pet.cId,
            ownerName: chatData['ownerName'] ?? "Pet Owner",
            petName: widget.pet.name,
            petBreed: widget.pet.breed,
            petType: widget.pet.animalName,
            petImageUrl: '$apiurl/${widget.pet.img1}',
            isPetChat: true,
            adoptionId: widget.pet.adoptId.toString(),
            conversationId: int.parse(conversationId!),
            senderId: currentUserId,
            receiverId: widget.pet.cId,
            interestedUserId: currentUserId,
            interestedUserName: currentUserName,
          );
        }
      };

      // Connect to socket for chat list management
      socketService.connectForChatList(
        userId: currentUserId,
        onNewChat: socketService.onNewChat,
      );

      // Wait for socket connection
      await Future.delayed(Duration(seconds: 1));

      // Create or get chat via socket
      socketService.createOrGetChat(
        senderId: currentUserId,
        receiverId: widget.pet.cId,
        adoptionId: widget.pet.adoptId.toString(),
        petName: widget.pet.name,
        petImageUrl: '$apiurl/${widget.pet.img1}',
        petBreed: widget.pet.breed,
        petType: widget.pet.animalName,
        ownerName: ownerInfo != null
            ? "${ownerInfo!['firstname'] ?? ''} ${ownerInfo!['lastname'] ?? ''}"
                  .trim()
            : "Pet Owner",
        interestedUserName: currentUserName,
      );

      // Wait for chat creation response
      int attempts = 0;
      while (createdChatModel == null &&
          conversationId == null &&
          attempts < 10) {
        await Future.delayed(Duration(milliseconds: 500));
        attempts++;
      }

      Navigator.pop(context); // Close loading dialog

      if (createdChatModel != null && conversationId != null) {
        socketService.sendMessage(
          message:
              "Hi! I'm interested in adopting ${widget.pet.name}. Can we discuss the details?",
          sourceId: currentUserId,
          targetId: widget.pet.cId,
          senderName: currentUserName,
          receiverName: ownerInfo != null
              ? "${ownerInfo!['firstname'] ?? ''} ${ownerInfo!['lastname'] ?? ''}"
                    .trim()
              : "Pet Owner",
          adoptionId: widget.pet.adoptId.toString(),
          petName: widget.pet.name,
        );
        // Navigate to individual chat page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Individualpage(
              chatModel: createdChatModel!,
              sourchat: ChatModel(
                name: currentUser.name,
                icon: "person.svg",
                isGroup: false,
                time: DateTime.now().toString(),
                currentMessage: "",
                id: currentUser.id,
                ownerId: currentUser.id,
                ownerName: currentUser.name,
              ),
              currentUser: currentUser,
              conversationId: int.parse(conversationId!),
            ),
          ),
        );
      } else {
        // Fallback: Create chat model manually and navigate
        final fallbackChatModel = ChatModel(
          name: widget.pet.name,
          icon: "pet.svg",
          isGroup: false,
          time: DateTime.now().toString(),
          currentMessage: "Chat started for ${widget.pet.name} adoption",
          id: widget.pet.adoptId,
          ownerId: widget.pet.cId,
          ownerName: ownerInfo != null
              ? "${ownerInfo!['firstname'] ?? ''} ${ownerInfo!['lastname'] ?? ''}"
                    .trim()
              : "Pet Owner",
          petName: widget.pet.name,
          petBreed: widget.pet.breed,
          petType: widget.pet.animalName,
          petImageUrl: '$apiurl/${widget.pet.img1}',
          isPetChat: true,
          adoptionId: widget.pet.adoptId.toString(),
          conversationId: DateTime.now().millisecondsSinceEpoch,
          senderId: currentUserId,
          receiverId: widget.pet.cId,
          interestedUserId: currentUserId,
          interestedUserName: currentUserName,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Individualpage(
              chatModel: fallbackChatModel,
              sourchat: ChatModel(
                name: currentUser.name,
                icon: "person.svg",
                isGroup: false,
                time: DateTime.now().toString(),
                currentMessage: "",
                id: currentUser.id,
                ownerId: currentUser.id,
                ownerName: currentUser.name,
              ),
              currentUser: currentUser,
              conversationId: fallbackChatModel.conversationId!,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      print('Exception in _handleAdoptRequest: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
