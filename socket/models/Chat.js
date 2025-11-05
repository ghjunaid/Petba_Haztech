// models/Chat.js (Enhanced for pet adoption)
const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
  chatId: {
    type: String,
    required: true,
    unique: true
  },
  participants: [{
    type: String,
    required: true
  }],
  lastMessage: {
    type: String,
    required: true
  },
  lastMessageTime: {
    type: Date,
    required: true,
    default: Date.now
  },
  lastMessageType: {
    type: String,
    enum: ['text', 'image', 'video', 'audio', 'document', 'adoption_request', 'adoption_response'],
    default: 'text'
  },
  isGroup: {
    type: Boolean,
    default: false
  },
  
  // Pet adoption specific fields
  petId: {
    type: Number,
    ref: 'Pet'
  },
  petName: {
    type: String
  },
  adoptionId: {
    type: String,
    index: true
  },
  petOwnerUserId: {
    type: Number,
    ref: 'User'
  },
  interestedUserId: {
    type: Number,
    ref: 'User'
  },
  chatType: {
    type: String,
    enum: ['regular', 'pet_adoption', 'group'],
    default: 'pet_adoption'
  }
}, {
  timestamps: true
});

chatSchema.index(
  { petId: 1, petOwnerUserId: 1, interestedUserId: 1 }, 
  { unique: true }
);

// Index for performance
chatSchema.index({ participants: 1, lastMessageTime: -1 });
chatSchema.index({ adoptionId: 1 });
chatSchema.index({ petId: 1 });

module.exports = mongoose.model('Chat', chatSchema);