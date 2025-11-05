// models/Message.js (Enhanced for pet adoption)
const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  messageId: {
    type: String,
    required: true,
    unique: true
  },
  senderId: {
    type: String,
    required: true
  },
  receiverId: {
    type: String,
    required: true
  },
  chatId: {
    type: String,
    required: true,
    index: true
  },
  message: {
    type: String,
    required: true
  },
  messageType: {
    type: String,
    enum: ['text', 'image', 'video', 'audio', 'document', 'adoption_request', 'adoption_response'],
    default: 'text'
  },
  timestamp: {
    type: Date,
    required: true,
    default: Date.now
  },
  delivered: {
    type: Boolean,
    default: false
  },
  deliveredAt: {
    type: Date
  },
  read: {
    type: Boolean,
    default: false
  },
  readAt: {
    type: Date
  },
  
  // File attachments
  base64Image: {
    type: String
  },
  fileName: {
    type: String
  },
  
  // Pet adoption specific fields
  petId: {
    type: Number,
    ref: 'Pet'
  },
  petName: {
    type: String
  },
  senderUserId: {
    type: Number,
    ref: 'User'
  },
  receiverUserId: {
    type: Number,
    ref: 'User'
  },
  senderName: {
    type: String
  },
  receiverName: {
    type: String
  },
  adoptionId: {
    type: String,
    index: true
  },
  isFromPetOwner: {
    type: Boolean,
    default: false
  },
  petOwnerName: {
    type: String
  }
}, {
  timestamps: true
});

// Indexes for performance
messageSchema.index({ chatId: 1, timestamp: -1 });
messageSchema.index({ adoptionId: 1 });
messageSchema.index({ petId: 1 });

module.exports = mongoose.model('Message', messageSchema);

