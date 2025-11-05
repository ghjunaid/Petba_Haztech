import 'package:flutter/material.dart';
import 'package:petba_new/chat/CustomUI/ButtonCard.dart';
import 'package:petba_new/chat/Model/ChatModel.dart';
import 'package:petba_new/chat/Model/Messagemodel.dart';
import 'package:petba_new/chat/screens/HomeScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:petba_new/providers/Config.dart';

class Loginscreen extends StatefulWidget {
  final int? userId;
  final String? userToken;
  final String? userEmail;
  final String? firstName;
  final String? lastName;
  final String? telephone;
  final int? cityId;
  final String? userLocation;
  // final List<PetModel>? userPets;
   final String? profileImageUrl;

  const Loginscreen({
    Key? key,
    this.userId,
    this.userToken,
    this.userEmail,
    this.firstName,
    this.lastName,
    this.telephone,
    this.cityId,
    this.userLocation,
    // this.userPets,
     this.profileImageUrl,
  }) : super(key: key);

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  UserModel? selectedUser;
  List<UserModel> users = [];

  @override
  void initState() {
    super.initState();
    _initializeUsers();
  }

  void _initializeUsers() {
    // Create user from dynamic data if provided, otherwise use default
    if (widget.userId != null) {
      users = [
        UserModel(
          id: widget.userId!,
          name: widget.firstName != null && widget.lastName != null
              ? "${widget.firstName!} ${widget.lastName!}"
              : widget.firstName ?? "User",
          email: widget.userEmail ?? "user@gmail.com",
          phoneNumber: widget.telephone ?? "+1234567890",
          location: widget.userLocation ?? "Mumbai",
          profileImageUrl: widget.profileImageUrl ?? "assets/user.jpg",
          createdAt: DateTime.now(),
          token: widget.userToken ?? "default_token",
          //pets: widget.userPets ?? _getDefaultPets(),
        ),
      ];
    } else {
      // Fallback to default user if no dynamic data provided
      // users = [
      //   UserModel(
      //     id: 159,
      //     name: "Raju",
      //     email: "siya@gmail.com",
      //     phoneNumber: "+1234567890",
      //     location: "Mumbai",
      //     profileImageUrl: "assets/raju.jpg",
      //     createdAt: DateTime.now(),
      //     token: "STBhR1ZFVGhpYkxrUWZ0dFVyVGV3RjRzZDhjV2pmUlhLcm1FamVLZQ==",
      //     pets: _getDefaultPets(),
      //   ),
      // ];
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pet Adoption Chat"),
        backgroundColor: Colors.green.shade400,
      ),
      body: Column(
        children: [
          // Show user info at top if dynamic data is provided
          if (widget.userId != null) ...[
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.green.shade200,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade600,
                          ),
                        ),
                        Text(
                          widget.firstName != null && widget.lastName != null
                              ? "${widget.firstName!} ${widget.lastName!}"
                              : widget.firstName ?? "User",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.userEmail != null)
                          Text(
                            widget.userEmail!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) => Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    selectedUser = users[index];
                    _navigateToHomeScreen(selectedUser!);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.green.shade700,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                users[index].name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              // Text(
                              //   "${users[index].pets.length} pets available",
                              //   style: TextStyle(
                              //     color: Colors.grey[600],
                              //     fontSize: 14,
                              //   ),
                              // ),

                            ],
                          ),
                        ),
                        // Container(
                        //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //   decoration: BoxDecoration(
                        //     color: Colors.green.shade400,
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: Text(
                        //     "${users[index].pets.length}",
                        //     style: TextStyle(
                        //       color: Colors.white,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<ChatModel>> _fetchChatList(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/chatlist'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.userToken != null) 'Authorization': 'Bearer ${widget.userToken}',
        },
        body: json.encode({
          'c_id': userId,
        }),
      );

      print("🔎 Response status: ${response.statusCode}");
      print("🔎 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<ChatModel> chatList = [];

        for (var chat in data['chatlist']) {
          chatList.add(ChatModel(
            name: chat['petname'] ?? 'Unknown Pet',
            icon: "pet.svg",
            isGroup: false,
            time: _formatTime(chat['latest_message_time']),
            currentMessage: chat['latest_message'] ?? '',
            id: chat['chat_id'],
            status: chat['status'] == 1 ? "Active" : "Inactive",
            ownerId: chat['receiver_id'],
            ownerName: chat['receiver_name'] ?? 'Unknown',
            isPetChat: true,
            adoptionId: chat['adoption_id'].toString(),
            petImageUrl: chat['adoption_image'] != null
                ? '$apiurl${chat['adoption_image']}'
                : null,
            petName: chat['petname'],
            petType: "Pet",
            petBreed: "Unknown",
            interestedUserName: chat['sender_name'],
            interestedUserId: chat['sender_id'],
          ));
        }

        return chatList;
      } else {
        throw Exception('Failed to load chat list: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat list: $e');
      return [];
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "00:00";
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      String hour = dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "00:00";
    }
  }

  void _navigateToHomeScreen(UserModel user) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
        ),
      ),
    );

    try {
      // Fetch chat list from API using dynamic user ID
      List<ChatModel> apiChats = await _fetchChatList(user.id);

      // Close loading dialog
      Navigator.pop(context);

      // Create a ChatModel representing the current user
      ChatModel sourceChat = ChatModel(
        name: user.name,
        icon: "person.svg",
        isGroup: false,
        time: DateTime.now().toString(),
        currentMessage: "",
        id: user.id,
        ownerId: user.id,
        ownerName: user.name,
        isPetChat: false,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            chatmodels: apiChats,
            sourchat: sourceChat,
            currentUser: user,
            allUsers: users,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to load chats. Please try again.\nError: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}