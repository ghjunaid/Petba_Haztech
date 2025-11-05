const mongoose = require('mongoose');

const queuedNotificationSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true // Index for faster queries
  },
  title: {
    type: String,
    required: true
  },
  body: {
    type: String,
    required: true
  },
  data: {
    senderId: String,
    chatId: String,
    adoptionId: String,
    timestamp: String,
    messageType: String,
    messageId: String,
    senderName: String,
    message: String,
    petId: String,
    petName: String,
    isFromPetOwner: String,
    petOwnerName: String,
    receiverId: String,
    receiverName: String,
    fileName: String,
    click_action: String
  },
  messageType: {
    type: String,
    enum: ['text', 'image', 'video', 'adoption_request'],
    default: 'text'
  },
  isDelivered: {
    type: Boolean,
    default: false
  },
  deliveredAt: {
    type: Date
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 604800 // Auto-delete after 7 days (604800 seconds)
  },
  attempts: {
    type: Number,
    default: 0
  },
  lastAttempt: {
    type: Date
  }
});

// Compound index for efficient queries
queuedNotificationSchema.index({ userId: 1, isDelivered: 1, createdAt: -1 });

module.exports = mongoose.model('QueuedNotification', queuedNotificationSchema);