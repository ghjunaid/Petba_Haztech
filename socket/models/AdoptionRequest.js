


// models/AdoptionRequest.js
const mongoose = require('mongoose');

const adoptionRequestSchema = new mongoose.Schema({
  adoptionId: {
    type: String,
    required: true,
    unique: true
  },
  petId: {
    type: Number,
    required: true,
    ref: 'Pet'
  },
  petName: {
    type: String,
    required: true
  },
  requesterId: {
    type: Number,
    required: true,
    ref: 'User'
  },
  requesterName: {
    type: String,
    required: true
  },
  ownerId: {
    type: Number,
    required: true,
    ref: 'User'
  },
  ownerName: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'completed', 'cancelled'],
    default: 'pending'
  },
  requestDate: {
    type: Date,
    required: true,
    default: Date.now
  },
  initialMessage: {
    type: String,
    required: true
  },
  response: {
    type: String,
    default: ''
  },
  responseDate: {
    type: Date
  },
  meetingScheduled: {
    type: Boolean,
    default: false
  },
  meetingDate: {
    type: Date
  },
  meetingLocation: {
    type: String,
    default: ''
  },
  additionalNotes: {
    type: String,
    default: ''
  },
  requesterContact: {
    email: String,
    phone: String
  },
  ownerContact: {
    email: String,
    phone: String
  }
}, {
  timestamps: true
});

// Indexes for performance
adoptionRequestSchema.index({ petId: 1, status: 1 });
adoptionRequestSchema.index({ requesterId: 1 });
adoptionRequestSchema.index({ ownerId: 1 });
adoptionRequestSchema.index({ adoptionId: 1 });

module.exports = mongoose.model('AdoptionRequest', adoptionRequestSchema);

// Sample data initialization script
// Create this as a separate file: initializeData.js

