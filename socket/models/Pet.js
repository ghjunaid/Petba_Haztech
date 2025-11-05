// models/Pet.js
const mongoose = require('mongoose');

const petSchema = new mongoose.Schema({
  id: {
    type: Number,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  breed: {
    type: String,
    required: true
  },
  age: {
    type: Number,
    required: true,
    min: 0,
    max: 30
  },
  gender: {
    type: String,
    enum: ['Male', 'Female'],
    required: true
  },
  description: {
    type: String,
    required: true,
    maxLength: 1000
  },
  imageUrl: {
    type: String,
    default: ''
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
  isAvailableForAdoption: {
    type: Boolean,
    default: true
  },
  petType: {
    type: String,
    enum: ['Dog', 'Cat', 'Bird', 'Rabbit', 'Fish', 'Hamster', 'Guinea Pig', 'Other'],
    required: true
  },
  vaccinations: [{
    type: String
  }],
  location: {
    type: String,
    required: true
  },
  adoptionFee: {
    type: Number,
    default: 0,
    min: 0
  },
  specialNeeds: {
    type: String,
    default: ''
  },
  goodWithKids: {
    type: Boolean,
    default: true
  },
  goodWithPets: {
    type: Boolean,
    default: true
  },
  energyLevel: {
    type: String,
    enum: ['Low', 'Medium', 'High'],
    default: 'Medium'
  },
  size: {
    type: String,
    enum: ['Small', 'Medium', 'Large'],
    default: 'Medium'
  }
}, {
  timestamps: true
});

// Index for search optimization
petSchema.index({ 
  petType: 1, 
  location: 1, 
  isAvailableForAdoption: 1 
});

module.exports = mongoose.model('Pet', petSchema);