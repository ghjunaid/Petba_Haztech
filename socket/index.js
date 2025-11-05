const http = require("http");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const mongoose = require("mongoose");

// Import models
const Message = require("./models/Message");
const Chat = require("./models/Chat");
const Pet = require("./models/Pet");
const User = require("./models/User");
const AdoptionRequest = require("./models/AdoptionRequest");
const QueuedNotification = require("./models/QueuedNotification");

const app = express();
const port = process.env.PORT || 8000;

// MongoDB connection
mongoose.connect('mongodb://localhost:27017/petadoptionchat', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to Pet Adoption Chat MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));

// Initialize Firebase Admin SDK
const serviceAccount = require("./firebase-service-account-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

var server = http.createServer(app);
var { Server } = require("socket.io");

var io = new Server(server, {
  cors: {
    origin: "*",           // allow all origins (for testing)
    methods: ["GET", "POST"]
  }
});

app.use(express.json());
app.use(cors());

// Store connected clients with their FCM tokens
var clients = {};
var userTokens = {};
var messageQueue = {};
var offlineNotifications = {};

// Helper functions
function generateMessageId() {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
}

function generateChatId(userId1, userId2, petId = null) {
  if (petId) {
    // Create consistent room ID with sorted user IDs
    const sortedIds = [userId1.toString(), userId2.toString()].sort();
    return `adoption_${sortedIds[0]}_${sortedIds[1]}_${petId}`;
  }
  const sortedIds = [userId1, userId2].sort();
  return `${sortedIds[0]}_${sortedIds[1]}`;
}

function generateAdoptionId(userId, petId) {
  return `adoption_${userId}_${petId}_${Date.now()}`;
}

// Store message in database
// Updated storeMessageInDB function
async function storeMessageInDB(messageData) {
  try {
    const message = new Message({
      ...messageData,
      petId: messageData.petId,
      petName: messageData.petName,
      senderUserId: messageData.senderId,
      receiverUserId: messageData.receiverId,
      receiverName: messageData.receiverName,
      adoptionId: messageData.adoptionId,
      isFromPetOwner: messageData.isFromPetOwner || false,
      petOwnerName: messageData.petOwnerName,
    });
    await message.save();
    
    const chatId = messageData.chatId;
    let lastMessageText = messageData.message;
    
    // Handle different message types
    if (messageData.messageType === 'image') {
      lastMessageText = '📷 Photo';
    } else if (messageData.messageType === 'video') {
      lastMessageText = '🎥 Video';
    } else if (messageData.messageType === 'adoption_request') {
      lastMessageText = '❤️ Adoption request';
    }
    
    // Update or create chat record with correct sender/receiver info
    await Chat.findOneAndUpdate(
      { chatId: chatId },
      {
        participants: [messageData.senderId, messageData.receiverId],
        lastMessage: lastMessageText,
        lastMessageTime: messageData.timestamp,
        lastMessageType: messageData.messageType,
        isGroup: false,
        petId: messageData.petId,
        petName: messageData.petName,
        adoptionId: messageData.adoptionId,
        // Don't change these - they should remain constant
        // petOwnerUserId: messageData.receiverId, 
        // interestedUserId: messageData.senderId,
      },
      { upsert: true, new: true }
    );
    
    console.log(`Pet adoption message stored: ${messageData.messageId} for pet ${messageData.petName}`);
    return message;
  } catch (error) {
    console.error('Error storing pet adoption message:', error);
    throw error;
  }
}

// Get chat list for a user
// In your getChatListForUser function, replace the existing logic with:
async function getChatListForUser(userId) {
  try {
    const chats = await Chat.find({
      participants: userId.toString()
    }).sort({ lastMessageTime: -1 });
    
    const chatPromises = chats.map(async (chat) => {
      // Get the last message to determine actual sender/receiver
      const lastMessage = await Message.findOne({ chatId: chat.chatId })
        .sort({ timestamp: -1 });
      
      const senderId = lastMessage ? lastMessage.senderId : chat.interestedUserId;
      const receiverId = lastMessage ? lastMessage.receiverId : chat.petOwnerUserId;
      
      return {
        chatId: chat.chatId,
        conversationId: chat._id,
        petName: chat.petName,
        petId: chat.petId,
        adoptionId: chat.adoptionId,
        lastMessage: chat.lastMessage,
        lastMessageTime: chat.lastMessageTime,
        lastMessageType: chat.lastMessageType,
        ownerId: chat.petOwnerUserId,
        ownerName: chat.petOwnerName || 'Pet Owner',
        interestedUserId: chat.interestedUserId,
        interestedUserName: chat.interestedUserName || 'Interested User',
        senderId: senderId,
        receiverId: receiverId,
        status: 1,
        petImageUrl: chat.petImageUrl,
        petType: chat.petType,
        petBreed: chat.petBreed,
        participants: chat.participants, // ADD this line
      };
    });
    
    return Promise.all(chatPromises);
    
  } catch (error) {
    console.error('Error fetching chat list:', error);
    return [];
  }
}

// Create or get existing chat
async function createOrGetChat(senderId, receiverId, petId, petName, additionalData = {}) {
  try {
    const chatId = generateChatId(senderId.toString(), receiverId.toString(), petId);
    
    // Check if chat already exists using multiple criteria
    let existingChat = await Chat.findOne({ 
      $or: [
        { chatId: chatId },
        { 
          participants: { $all: [senderId.toString(), receiverId.toString()] },
          petId: petId 
        }
      ]
    });
    
    if (existingChat) {
      console.log(`Chat already exists: ${chatId}`);
      return {
        exists: true,
        chat: existingChat,
        conversationId: existingChat._id,
      };
    }
    
    // Create new chat with unique adoptionId
    const adoptionId = generateAdoptionId(senderId, petId);
    
    const newChat = new Chat({
      chatId: chatId,
      participants: [senderId.toString(), receiverId.toString()],
      lastMessage: 'Chat started',
      lastMessageTime: new Date(),
      lastMessageType: 'text',
      isGroup: false,
      petId: petId,
      petName: petName,
      adoptionId: adoptionId,
      petOwnerUserId: receiverId.toString(),
      interestedUserId: senderId.toString(),
      petOwnerName: additionalData.ownerName || 'Pet Owner',
      interestedUserName: additionalData.interestedUserName || 'Interested User',
      petImageUrl: additionalData.petImageUrl,
      petType: additionalData.petType,
      petBreed: additionalData.petBreed,
    });
    
    const savedChat = await newChat.save();
    console.log(`New chat created: ${chatId} with adoptionId: ${adoptionId}`);
    
    return {
      exists: false,
      chat: savedChat,
      conversationId: savedChat._id,
    };
  } catch (error) {
    console.error('Error creating/getting chat:', error);
    throw error;
  }
}

// // Enhanced Firebase notification function
// async function sendFirebaseNotification(token, senderName, messageText, data = {}, messageType = 'text') {
//   let notificationBody = messageText;
//   let notificationTitle = senderName;
  
//   if (data.petName && data.isFromPetOwner) {
//     notificationTitle = `${senderName} (${data.petName}'s owner)`;
//   } else if (data.petName && !data.isFromPetOwner) {
//     notificationTitle = `${senderName} about ${data.petName}`;
//   }
  
//   if (messageType === 'image') {
//     notificationBody = '📷 Sent a photo';
//   } else if (messageType === 'video') {
//     notificationBody = '🎥 Sent a video';
//   } else if (messageType === 'adoption_request') {
//     notificationBody = `❤️ Interested in adopting ${data.petName}`;
//   }

//   const message = {
//     notification: {
//       title: notificationTitle,
//       body: notificationBody,
//     },
//     data: {
//       senderId: data.senderId?.toString() || '',
//       chatId: data.chatId?.toString() || '',
//       timestamp: data.timestamp?.toString() || Date.now().toString(),
//       messageType: messageType || 'text',
//       messageId: data.messageId?.toString() || '',
//       senderName: senderName || 'Unknown',
//       message: messageText || '',
//       petId: data.petId?.toString() || '',
//       petName: data.petName || '',
//       adoptionId: data.adoptionId || '',
//       isFromPetOwner: data.isFromPetOwner?.toString() || 'false',
//       petOwnerName: data.petOwnerName || '',
//       click_action: 'FLUTTER_NOTIFICATION_CLICK',
//     },
//     token: token,
//   };

//   try {
//     const response = await admin.messaging().send(message);
//     console.log(`✅ FCM notification sent successfully:`, response);
//     return response;
//   } catch (error) {
//     console.error(`❌ Error sending FCM notification:`, error);
//     throw error;
//   }
// }



// Socket.IO connection handling
io.on("connection", (socket) => {
  console.log("Pet adoption chat connected:", socket.id);

  // User signin
  socket.on("signin", async (data) => {
    let userId, fcmToken;
    
    if (typeof data === 'object') {
      userId = data.userId;
      fcmToken = data.fcmToken;
    } else {
      userId = data;
      fcmToken = null;
    }

    console.log(`🔍 User signin debug:`);
  console.log(`  - userId: ${userId} (type: ${typeof userId})`);
  console.log(`  - fcmToken provided: ${!!fcmToken}`);
    console.log(`Pet adoption user ${userId} signed in`);
    clients[userId] = socket;
    
    if (fcmToken) {
      userTokens[userId] = fcmToken;
      console.log(`✅ FCM token stored for user ${userId}`);
    }
    await sendQueuedNotifications(userId);
  });

  // Join chat list room
  socket.on("joinChatList", (data) => {
    const { userId } = data;
    socket.join(`user_${userId}`);
    console.log(`User ${userId} joined chat list room`);
  });

  // Get chat list for user
  socket.on("getChatList", async (data) => {
    console.log("Backend: getChatList - Received data:", data);
  console.log("Backend: getChatList - User ID type:", typeof data.userId);
  console.log("Backend: getChatList - User ID value:", data.userId);
    try {
      const { userId } = data;
      const chatList = await getChatListForUser(userId);
      
      socket.emit("chatListUpdate", {
        chats: chatList
      });
      
      console.log(`Chat list sent to user ${userId}: ${chatList.length} chats`);
    } catch (error) {
      console.error('Error getting chat list:', error);
      socket.emit("error", { message: "Failed to load chat list" });
    }
  });

  // Create or get existing chat
  socket.on("createOrGetChat", async (data) => {
    try {
      const { senderId, receiverId, adoptionId, petName, petImageUrl, petBreed, petType, ownerName, interestedUserName } = data;
      
      const result = await createOrGetChat(senderId, receiverId, adoptionId, petName, {
        ownerName,
        interestedUserName,
        petImageUrl,
        petType,
        petBreed,
      });
      
      const chatData = {
  chatId: result.chat.chatId,
  conversationId: result.chat._id,
  petName: result.chat.petName,
  petId: result.chat.petId,
  adoptionId: result.chat.adoptionId,  // generated separately
  lastMessage: result.chat.lastMessage,
  lastMessageTime: new Date(result.chat.lastMessageTime), // ensure Date
  lastMessageType: result.chat.lastMessageType,
  ownerId: result.chat.petOwnerUserId,   // ✅ map correctly
  ownerName: result.chat.petOwnerName,
  interestedUserId: result.chat.interestedUserId,
  interestedUserName: result.chat.interestedUserName,
  senderId: senderId,
  receiverId: receiverId,
  // remove status if your schema doesn’t allow it
};

      
      // Send to both users
      socket.emit("chatCreated", chatData);
      if (clients[receiverId]) {
        clients[receiverId].emit("newChatCreated", chatData);
      }
      
      // Update chat lists for both users
      const senderChats = await getChatListForUser(senderId);
      const receiverChats = await getChatListForUser(receiverId);
      
      socket.emit("chatListUpdate", { chats: senderChats });
      if (clients[receiverId]) {
        clients[receiverId].emit("chatListUpdate", { chats: receiverChats });
      }
      
    } catch (error) {
      console.error('Error creating/getting chat:', error);
      socket.emit("error", { message: "Failed to create chat" });
    }
  });

  // Join specific chat room
  socket.on("joinChat", (data) => {
    const { userId, targetUserId, adoptionId, petId } = data;
     const roomId = data.roomId;
  socket.join(roomId);
  console.log(`User ${data.userId} joined room ${roomId}`);
  });

  // Handle text messages
 // Handle text messages
socket.on("message", async (msg) => {
  console.log("📨 Received message:", msg);
  
  try {
    const messageId = generateMessageId();
    const timestamp = new Date(msg.timestamp || Date.now());
    const chatId = generateChatId(msg.senderId.toString(), msg.receiverId.toString(), msg.adoptionId);

    const messageData = {
      messageId: messageId,
      senderId: msg.senderId.toString(),
      receiverId: msg.receiverId.toString(),
      receiverName: msg.receiverName,
      chatId: chatId,
      message: msg.message,
      messageType: 'text',
      timestamp: timestamp,
      delivered: false,
      read: false,
      senderName: msg.senderName,
      petId: msg.adoptionId,
      petName: msg.petName,
      adoptionId: msg.adoptionId,
      isFromPetOwner: msg.isFromPetOwner || false,
      petOwnerName: msg.petOwnerName,
    };

    // Store message in database
    await storeMessageInDB(messageData);

    // CREATE the messageToSend object that was missing
    const messageToSend = {
      ...messageData,
      timestamp: timestamp.getTime(),
    };

    // Send to room participants
    const roomId = generateChatId(msg.senderId.toString(), msg.receiverId.toString(), msg.adoptionId);
    socket.to(roomId).emit("message", messageToSend);
    
    // Also send to sender for confirmation
    socket.emit("message", messageToSend);
    
    // Update delivery status if receiver is connected
    if (clients[msg.receiverId]) {
      await Message.findOneAndUpdate(
        { messageId: messageId },
        { delivered: true, deliveredAt: new Date() }
      );
    }

    // Send FCM notification
  if (userTokens[msg.receiverId] && msg.senderId.toString() !== msg.receiverId.toString()) {
    
  try {
    console.log(`🔥 Sending FCM to user ${msg.receiverId} with token: ${userTokens[msg.receiverId].substring(0, 20)}...`);
    await sendFirebaseNotification(
      userTokens[msg.receiverId],
      msg.senderName,
      msg.message,
      {
        senderId: msg.senderId.toString(),
        chatId: chatId,
        timestamp: timestamp.getTime(),
        messageId: messageId,
        petId: msg.adoptionId,
        petName: msg.petName,
        adoptionId: msg.adoptionId,
        isFromPetOwner: msg.isFromPetOwner || false,
        petOwnerName: msg.petOwnerName,
        receiverId: msg.receiverId.toString(),
        receiverName: msg.receiverName || '',
      },
      'text'
    );
    console.log(`✅ Notification sent to user ${msg.receiverId}`);
  } catch (error) {
    console.log(`❌ Notification failed, queuing for user ${msg.receiverId}: ${error.message}`);
    
    // Queue notification for offline user
    await queueNotificationForOfflineUser(msg.receiverId, {
      title: msg.senderName,
      body: msg.message,
      data: {
        senderId: msg.senderId.toString(),
        chatId: chatId,
        adoptionId: msg.adoptionId,
        timestamp: timestamp.getTime().toString(),
        messageType: 'text',
        messageId: messageId,
        senderName: msg.senderName,
        message: msg.message,
        petId: msg.adoptionId.toString(),
        petName: msg.petName || '',
        isFromPetOwner: (msg.isFromPetOwner || false).toString(),
        petOwnerName: msg.petOwnerName || '',
        receiverId: msg.receiverId.toString(),
        receiverName: msg.receiverName || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      messageType: 'text'
    });
  }
} else if (msg.senderId.toString() !== msg.receiverId.toString()) {
  // No FCM token available, queue notification for when user comes online
  console.log(`📦 No FCM token for user ${msg.receiverId}, queuing notification`);
  
  await queueNotificationForOfflineUser(msg.receiverId, {
    title: msg.senderName,
    body: msg.message,
    data: {
      senderId: msg.senderId.toString(),
      chatId: chatId,
      adoptionId: msg.adoptionId,
      timestamp: timestamp.getTime().toString(),
      messageType: 'text',
      messageId: messageId,
      senderName: msg.senderName,
      message: msg.message,
      petId: msg.adoptionId.toString(),
      petName: msg.petName || '',
      isFromPetOwner: (msg.isFromPetOwner || false).toString(),
      petOwnerName: msg.petOwnerName || '',
      receiverId: msg.receiverId.toString(),
      receiverName: msg.receiverName || '',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    messageType: 'text'
  });
}
   

    // Update chat lists for both users
    const senderChats = await getChatListForUser(msg.senderId);
    const receiverChats = await getChatListForUser(msg.receiverId);
    
    if (clients[msg.senderId]) {
      clients[msg.senderId].emit("chatListUpdate", { chats: senderChats });
    }
    if (clients[msg.receiverId]) {
      clients[msg.receiverId].emit("chatListUpdate", { chats: receiverChats });
    }
    io.to(`user_${msg.senderId}`).emit("chatListUpdate", { chats: senderChats });
io.to(`user_${msg.receiverId}`).emit("chatListUpdate", { chats: receiverChats });
  } catch (error) {
    console.error('Error processing message:', error);
  }
});

  // Handle image messages
  socket.on("image_message", async (msg) => {
    console.log("🖼️ Received image message");
    
    try {
      const messageId = generateMessageId();
      const timestamp = new Date(msg.timestamp || Date.now());
      const chatId = generateChatId(msg.senderId.toString(), msg.receiverId.toString(), msg.adoptionId);

      const messageData = {
        messageId: messageId,
        senderId: msg.senderId.toString(),
        receiverId: msg.receiverId.toString(),
        chatId: chatId,
        message: msg.fileName || 'Photo',
        messageType: 'image',
        base64Image: msg.base64Image,
        fileName: msg.fileName,
        imagePath: msg.imagePath,
        timestamp: timestamp,
        delivered: false,
        read: false,
        senderName: msg.senderName,
        petId: msg.adoptionId,
        petName: msg.petName,
        adoptionId: msg.adoptionId,
        isFromPetOwner: msg.isFromPetOwner || false,
        petOwnerName: msg.petOwnerName,
      };

      await storeMessageInDB(messageData);

      if (clients[msg.receiverId]) {
        clients[msg.receiverId].emit("image_message", {
          ...messageData,
          timestamp: timestamp.getTime()
        });
        
        await Message.findOneAndUpdate(
          { messageId: messageId },
          { delivered: true, deliveredAt: new Date() }
        );
      }

      if (userTokens[msg.receiverId]) {
        await sendFirebaseNotification(
          userTokens[msg.receiverId],
          msg.senderName,
          'Photo',
          {
            senderId: msg.senderId.toString(),
            chatId: chatId,
            timestamp: timestamp.getTime(),
            messageId: messageId,
            petId: msg.adoptionId,
            petName: msg.petName,
            adoptionId: msg.adoptionId,
          },
          'image'
        );
      }

      // Update chat lists
      const senderChats = await getChatListForUser(msg.senderId);
      const receiverChats = await getChatListForUser(msg.receiverId);
      
      if (clients[msg.senderId]) {
        clients[msg.senderId].emit("chatListUpdate", { chats: senderChats });
      }
      if (clients[msg.receiverId]) {
        clients[msg.receiverId].emit("chatListUpdate", { chats: receiverChats });
      }
      
    } catch (error) {
      console.error('Error processing image message:', error);
    }
  });

  // Handle video messages
  socket.on("video_message", async (msg) => {
    console.log("🎥 Received video message");
    
    try {
      const messageId = generateMessageId();
      const timestamp = new Date(msg.timestamp || Date.now());
      const chatId = generateChatId(msg.senderId.toString(), msg.receiverId.toString(), msg.adoptionId);

      const messageData = {
        messageId: messageId,
        senderId: msg.senderId.toString(),
        receiverId: msg.receiverId.toString(),
        chatId: chatId,
        message: msg.fileName || 'Video',
        messageType: 'video',
        base64Image: msg.base64Video,
        fileName: msg.fileName,
        videoPath: msg.videoPath,
        timestamp: timestamp,
        delivered: false,
        read: false,
        senderName: msg.senderName,
        petId: msg.adoptionId,
        petName: msg.petName,
        adoptionId: msg.adoptionId,
        isFromPetOwner: msg.isFromPetOwner || false,
        petOwnerName: msg.petOwnerName,
      };

      await storeMessageInDB(messageData);

      if (clients[msg.receiverId]) {
        clients[msg.receiverId].emit("video_message", {
          ...messageData,
          timestamp: timestamp.getTime()
        });
        
        await Message.findOneAndUpdate(
          { messageId: messageId },
          { delivered: true, deliveredAt: new Date() }
        );
      }

      if (userTokens[msg.receiverId]) {
        await sendFirebaseNotification(
          userTokens[msg.receiverId],
          msg.senderName,
          'Video',
          {
            senderId: msg.senderId.toString(),
            chatId: chatId,
            timestamp: timestamp.getTime(),
            messageId: messageId,
            petId: msg.adoptionId,
            petName: msg.petName,
            adoptionId: msg.adoptionId,
          },
          'video'
        );
      }

      // Update chat lists
      const senderChats = await getChatListForUser(msg.senderId);
      const receiverChats = await getChatListForUser(msg.receiverId);
      
      if (clients[msg.senderId]) {
        clients[msg.senderId].emit("chatListUpdate", { chats: senderChats });
      }
      if (clients[msg.receiverId]) {
        clients[msg.receiverId].emit("chatListUpdate", { chats: receiverChats });
      }
      
    } catch (error) {
      console.error('Error processing video message:', error);
    }
  });

  // Handle typing indicators
  socket.on("typing", (data) => {
    const { senderId, receiverId } = data;
    if (clients[receiverId]) {
      clients[receiverId].emit("typing", {
        userId: senderId,
        isTyping: true,
      });
    }
  });

  socket.on("stopTyping", (data) => {
    const { senderId, receiverId } = data;
    if (clients[receiverId]) {
      clients[receiverId].emit("stopTyping", {
        userId: senderId,
        isTyping: false,
      });
    }
  });

  socket.on("getQueuedNotifications", async (data) => {
  const { userId } = data;
  
  if (offlineNotifications[userId] && offlineNotifications[userId].length > 0) {
    socket.emit("queuedNotifications", {
      notifications: offlineNotifications[userId]
    });
    
    // Clear notifications after sending
    delete offlineNotifications[userId];
    console.log(`Sent ${offlineNotifications[userId]?.length || 0} queued notifications to user ${userId}`);
  }
});

  socket.on("disconnect", () => {
    console.log("User disconnected:", socket.id);
    
    for (let userId in clients) {
      if (clients[userId].id === socket.id) {
        delete clients[userId];
        console.log(`User ${userId} removed from clients`);
        break;
      }
    }
  });
});

// REST API Endpoints

// Get chat history
app.get("/chat-history/:userId1/:userId2", async (req, res) => {
  try {
    const { userId1, userId2 } = req.params;
    const { page = 1, limit = 50, adoptionId } = req.query;
    
    let chatId;
    if (adoptionId) {
      chatId = generateChatId(userId1, userId2, adoptionId);
    } else {
      chatId = generateChatId(userId1, userId2);
    }
    
    const messages = await Message.find({ chatId: chatId })
      .sort({ timestamp: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();
    
    messages.reverse();
    
    res.json({
      success: true,
      messages: messages,
      page: parseInt(page),
      totalPages: Math.ceil(await Message.countDocuments({ chatId: chatId }) / limit)
    });
  } catch (error) {
    console.error('Error fetching chat history:', error);
    res.status(500).json({ error: 'Failed to fetch chat history' });
  }
});

// Mark messages as read
app.post("/mark-read", async (req, res) => {
  try {
    const { chatId, userId } = req.body;
    
    await Message.updateMany(
      { 
        chatId: chatId, 
        receiverId: userId.toString(),
        read: false 
      },
      { 
        read: true, 
        readAt: new Date() 
      }
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error marking messages as read:', error);
    res.status(500).json({ error: 'Failed to mark messages as read' });
  }
});

// Update FCM token
app.post("/update-token", (req, res) => {
  const { userId, token } = req.body;
  
  if (!userId || !token) {
    return res.status(400).json({ error: "userId and token are required" });
  }

  userTokens[userId] = token;
  console.log(`✅ FCM token updated for user ${userId}`);
  
  res.json({ success: true, message: "Token updated successfully" });
});

// Health check
app.get("/health", async (req, res) => {
  try {
    const totalMessages = await Message.countDocuments();
    const totalChats = await Chat.countDocuments();
    
    res.json({ 
      status: "OK", 
      service: "Pet Adoption Chat System",
      connectedUsers: Object.keys(clients).length,
      registeredTokens: Object.keys(userTokens).length,
      totalStoredMessages: totalMessages,
      totalChats: totalChats,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ error: "Health check failed" });
  }
});

// Enhanced Firebase notification function - REPLACE the duplicate function
async function sendFirebaseNotification(token, senderName, messageText, data = {}, messageType = 'text') {
  let notificationBody = messageText;
  let notificationTitle = senderName;
  
  if (data.petName && data.isFromPetOwner) {
    notificationTitle = `${senderName} (${data.petName}'s owner)`;
  } else if (data.petName && !data.isFromPetOwner) {
    notificationTitle = `${senderName} about ${data.petName}`;
  }
  
  if (messageType === 'image') {
    notificationBody = '📷 Sent a photo';
  } else if (messageType === 'video') {
    notificationBody = '🎥 Sent a video';
  } else if (messageType === 'adoption_request') {
    notificationBody = `❤️ Interested in adopting ${data.petName}`;
  }

  // FIXED: Properly construct the message object
  const message = {
    notification: {
      title: notificationTitle,
      body: notificationBody,
    },
    data: {
      senderId: data.senderId?.toString() || '',
      chatId: data.chatId?.toString() || '',
      timestamp: data.timestamp?.toString() || Date.now().toString(),
      messageType: messageType || 'text',
      messageId: data.messageId?.toString() || '',
      senderName: senderName || 'Unknown',
      message: messageText || '',
      petId: data.petId?.toString() || '',
      petName: data.petName || '',
      adoptionId: data.adoptionId || '',
      isFromPetOwner: data.isFromPetOwner?.toString() || 'false',
      petOwnerName: data.petOwnerName || '',
      receiverId: data.receiverId?.toString() || '',
      receiverName: data.receiverName || '',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`✅ FCM notification sent successfully:`, response);
    return response;
  } catch (error) {
    console.error(`❌ Error sending FCM notification:`, error);
    
    // If FCM fails, queue the notification for when user comes online
    const userId = data.receiverId;
    if (userId) {
      if (!offlineNotifications[userId]) {
        offlineNotifications[userId] = [];
      }
      offlineNotifications[userId].push({
        title: notificationTitle,
        body: notificationBody,
        data: {
          senderId: data.senderId?.toString() || '',
          chatId: data.chatId?.toString() || '',
          adoptionId: data.adoptionId || '',
          timestamp: data.timestamp?.toString() || Date.now().toString(),
          messageType: messageType,
          messageId: data.messageId?.toString() || '',
          senderName: senderName || 'Unknown',
          message: messageText || '',
          petId: data.petId?.toString() || '',
          petName: data.petName || '',
          isFromPetOwner: data.isFromPetOwner?.toString() || 'false',
          petOwnerName: data.petOwnerName || '',
          receiverId: data.receiverId?.toString() || '',
          receiverName: data.receiverName || '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        timestamp: Date.now(),
        messageType: messageType
      });
      console.log(`📦 Notification queued for offline user: ${userId}`);
    }
    throw error;
  }
}
async function queueNotificationForOfflineUser(userId, notificationData) {
  try {
    // Store in memory queue (existing logic)
    if (!offlineNotifications[userId]) {
      offlineNotifications[userId] = [];
    }
    offlineNotifications[userId].push({
      ...notificationData,
      timestamp: Date.now()
    });

    // Also store in database for persistence
    await queueNotificationInDB(userId, notificationData);
    
    console.log(`📦 Notification queued for offline user: ${userId}`);
  } catch (error) {
    console.error(`Error queuing notification for user ${userId}:`, error);
  }
}

// Update the existing queueNotificationInDB function
async function queueNotificationInDB(userId, notificationData) {
  try {
    const queuedNotification = new QueuedNotification({
      userId: userId.toString(),
      title: notificationData.title,
      body: notificationData.body,
      data: notificationData.data,
      messageType: notificationData.messageType || 'text',
      isDelivered: false,
      attempts: 0,
      createdAt: new Date()
    });
    
    await queuedNotification.save();
    console.log(`✅ Notification stored in database for user ${userId}`);
  } catch (error) {
    console.error('Error storing queued notification in DB:', error);
  }
}

// Update the sendQueuedNotifications function
async function sendQueuedNotifications(userId) {
  try {
    // Send from memory queue first
    if (offlineNotifications[userId] && offlineNotifications[userId].length > 0) {
      const notifications = offlineNotifications[userId];
      console.log(`📨 Sending ${notifications.length} queued notifications from memory to user ${userId}`);
      
      for (const notification of notifications) {
        if (userTokens[userId]) {
          try {
            await admin.messaging().send({
              notification: {
                title: notification.title,
                body: notification.body,
              },
              data: notification.data,
              token: userTokens[userId],
            });
            console.log(`✅ Queued notification delivered to user ${userId}`);
          } catch (error) {
            console.error(`❌ Failed to send queued notification:`, error);
          }
        }
      }
      
      // Clear memory queue after sending
      delete offlineNotifications[userId];
    }

    // Send from database queue
    const queuedNotifications = await QueuedNotification.find({
      userId: userId.toString(),
      isDelivered: false
    }).sort({ createdAt: 1 }).limit(10); // Limit to prevent overwhelming

    console.log(`📨 Found ${queuedNotifications.length} queued notifications in DB for user ${userId}`);

    for (const notification of queuedNotifications) {
      if (userTokens[userId]) {
        try {
          await admin.messaging().send({
            notification: {
              title: notification.title,
              body: notification.body,
            },
            data: notification.data,
            token: userTokens[userId],
          });

          // Mark as delivered in database
          notification.isDelivered = true;
          notification.deliveredAt = new Date();
          notification.attempts += 1;
          await notification.save();

          console.log(`✅ DB queued notification delivered to user ${userId}`);
        } catch (error) {
          // Increment attempt count
          notification.attempts += 1;
          notification.lastAttempt = new Date();
          await notification.save();
          
          console.error(`❌ Failed to send DB queued notification (attempt ${notification.attempts}):`, error);
          
          // Remove notification if too many failed attempts
          if (notification.attempts >= 3) {
            await QueuedNotification.findByIdAndDelete(notification._id);
            console.log(`🗑️ Removed notification after ${notification.attempts} failed attempts`);
          }
        }
      }
    }
  } catch (error) {
    console.error(`Error sending queued notifications to user ${userId}:`, error);
  }
}



server.listen(port, "0.0.0.0", () => {
  console.log("🐾 Pet Adoption Chat Server Started on port", port);
  console.log("🔥 Firebase Admin SDK initialized");
  console.log("🗄️ MongoDB integration ready");
  console.log("🔔 FCM notifications configured");
  console.log("❤️ Pet adoption system ready");
    console.log(`🚀 Server running on http://0.0.0.0:${port}`);
});

