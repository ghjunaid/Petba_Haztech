import 'package:petba_new/chat/Model/ChatModel.dart';

class ChatModel {
  final String name;
  final String icon;
  final bool isGroup;
  String time;
  String currentMessage;
  final int id;
  String messageType;
  String status;
  bool select;

  int? sendDelete;
  int? receiveDelete;
  String? token;

  // New fields for pet adoption system
  final int? petId;
  final int ownerId;
  final String ownerName;
  final String? petBreed;
  final String? petType;
  final String? petImageUrl;
  final bool isPetChat;
  final String? adoptionId; // Unique ID for adoption conversations

  // Additional fields for two-way chat system
  final bool isMyPetChat; // Flag to identify if this is for user's own pet
  final int? interestedUserId; // ID of user interested in adopting
  final String? interestedUserName; // Name of user interested in adopting
  final String? petName; // Pet name
  final int? petAge; // Pet age
  final String? petGender; // Pet gender
  final String? petDescription; // Pet description
  final String? petLocation; // Pet location
  final int? conversationId;
  final int? senderId;
  final int? receiverId;
  final int? chatId;
  bool isReceivedMessage;

  ChatModel({
    required this.name,
    required this.icon,
    required this.isGroup,
    required this.time,
    required this.currentMessage,
    required this.id,
    this.messageType = "text",
    this.status = "Unread",
    this.select = false,
    this.petId,
    required this.ownerId,
    required this.ownerName,
    this.petBreed,
    this.petType,
    this.petImageUrl,
    this.isPetChat = false,
    this.adoptionId,
    // New parameters for two-way chat
    this.isMyPetChat = false,
    this.interestedUserId,
    this.interestedUserName,
    this.petName,
    this.petAge,
    this.petGender,
    this.petDescription,
    this.petLocation,


    this.sendDelete,
    this.receiveDelete,
    this.token,
    this.conversationId,
    this.senderId,
    this.receiverId,
    this.chatId,
    this.isReceivedMessage = false,
  });

  // Factory constructor for creating pet chat (when user wants to adopt other's pet)
  factory ChatModel.petChat({
    required PetModel pet,
    required String lastMessage,
    required String lastMessageTime,
    String messageType = "text",
    String? adoptionId,
  }) {
    return ChatModel(
      name: pet.name,
      icon: "pet.svg",
      isGroup: false,
      time: lastMessageTime,
      currentMessage: lastMessage,
      id: pet.id,
      messageType: messageType,
      status: "Available",
      select: false,
      petId: pet.id,
      ownerId: pet.ownerId,
      ownerName: pet.ownerName,
      petBreed: pet.breed,
      petType: pet.petType,
      petImageUrl: pet.imageUrl,
      isPetChat: true,
      adoptionId: adoptionId,
      isMyPetChat: false,
      petName: pet.name,
      petAge: pet.age,
      petGender: pet.gender,
      petDescription: pet.description,
      petLocation: pet.location,
    );
  }

  // Factory constructor for creating adoption request chat (when others want to adopt user's pet)
  factory ChatModel.adoptionRequestChat({
    required PetModel pet,
    required UserModel interestedUser,
    required String lastMessage,
    required String lastMessageTime,
    String messageType = "text",
  }) {
    return ChatModel(
      name: "${interestedUser.name} → ${pet.name}",
      icon: "person.svg",
      isGroup: false,
      time: lastMessageTime,
      currentMessage: lastMessage,
      id: interestedUser.id * 1000 + pet.id, // Unique ID combination
      messageType: messageType,
      status: "Request",
      select: false,
      petId: pet.id,
      ownerId: pet.ownerId,
      ownerName: pet.ownerName,
      petBreed: pet.breed,
      petType: pet.petType,
      petImageUrl: pet.imageUrl,
      isPetChat: true,
      isMyPetChat: true,
      interestedUserId: interestedUser.id,
      interestedUserName: interestedUser.name,
      adoptionId: "adoption_request_${pet.ownerId}_${pet.id}_${interestedUser.id}",
      petName: pet.name,
      petAge: pet.age,
      petGender: pet.gender,
      petDescription: pet.description,
      petLocation: pet.location,
    );
  }

  // Factory constructor for creating user chat (for multiple pets)
  factory ChatModel.userChat({
    required UserModel user,
    required String lastMessage,
    required String lastMessageTime,
    String messageType = "text",
  }) {
    return ChatModel(
      name: user.name,
      icon: "person.svg",
      isGroup: false,
      time: lastMessageTime,
      currentMessage: lastMessage,
      id: user.id,
      messageType: messageType,
      status: "Online",
      select: false,
      ownerId: user.id,
      ownerName: user.name,
      isPetChat: false,
      isMyPetChat: false,
    );
  }
}

class MessageModel {
  String message;
  String type;
  String time;
  String messageType;
  String? senderId;
  String? receiverId;
  String? base64Image;
  String? fileName;
  String? messageId;
  String? chatId;
  bool? delivered;
  bool? read;

  // New fields for pet adoption system
  String? senderName;
  String? receiverName;
  int? petId;
  String? petName;
  int? senderUserId;
  int? receiverUserId;
  String? adoptionId;
  bool isFromPetOwner;
  String? petOwnerName;
  final int? conversationId;

  MessageModel({
    required this.message,
    required this.type,
    required this.time,
    this.messageType = "text",
    this.senderId,
    this.receiverId,
    this.base64Image,
    this.fileName,
    this.messageId,
    this.chatId,
    this.delivered,
    this.read,
    this.senderName,
    this.receiverName,
    this.petId,
    this.petName,
    this.senderUserId,
    this.receiverUserId,
    this.adoptionId,
    this.isFromPetOwner = false,
    this.petOwnerName,
    this.conversationId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determine if this message was sent by current user
    String messageType = json['senderId'] == currentUserId ? 'source' : 'destination';

    return MessageModel(
      message: json['message'] ?? '',
      type: messageType,
      time: _formatTimestamp(json['timestamp']),
      messageType: json['messageType'] ?? 'text',
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      base64Image: json['base64Image'],
      fileName: json['fileName'],
      messageId: json['messageId'],
      chatId: json['chatId'],
      delivered: json['delivered'],
      read: json['read'],
      senderName: json['senderName'],
      receiverName: json['receiverName'],
      petId: json['petId'],
      petName: json['petName'],
      senderUserId: json['senderUserId'],
      receiverUserId: json['receiverUserId'],
      adoptionId: json['adoptionId'],
      isFromPetOwner: json['isFromPetOwner'] ?? false,
      petOwnerName: json['petOwnerName'],
    );
  }

  static String _formatTimestamp(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      String hour = dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "00:00";
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'type': type,
      'time': time,
      'messageType': messageType,
      'senderId': senderId,
      'receiverId': receiverId,
      'base64Image': base64Image,
      'fileName': fileName,
      'messageId': messageId,
      'chatId': chatId,
      'delivered': delivered,
      'read': read,
      'senderName': senderName,
      'receiverName': receiverName,
      'petId': petId,
      'petName': petName,
      'senderUserId': senderUserId,
      'receiverUserId': receiverUserId,
      'adoptionId': adoptionId,
      'isFromPetOwner': isFromPetOwner,
      'petOwnerName': petOwnerName,
    };
  }
}
