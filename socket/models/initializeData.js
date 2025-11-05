const mongoose = require('mongoose');
const User = require('./models/User');
const Pet = require('./models/Pet');

async function initializeSampleData() {
  try {
    // Clear existing data (use cautiously in production)
    await User.deleteMany({});
    await Pet.deleteMany({});

    // Create sample users
    const users = [
      {
        id: 1,
        name: "Raju",
        email: "raju@petadoption.com",
        phoneNumber: "+919876543210",
        location: "Mumbai",
        profileImageUrl: "assets/raju.jpg"
      },
      {
        id: 2,
        name: "Siya",
        email: "siya@petadoption.com",
        phoneNumber: "+919876543211",
        location: "Delhi",
        profileImageUrl: "assets/siya.jpg"
      },
      {
        id: 3,
        name: "Kishen",
        email: "kishen@petadoption.com",
        phoneNumber: "+919876543212",
        location: "Bangalore",
        profileImageUrl: "assets/kishen.jpg"
      },
      {
        id: 4,
        name: "Pragati",
        email: "pragati@petadoption.com",
        phoneNumber: "+919876543213",
        location: "Pune",
        profileImageUrl: "assets/pragati.jpg"
      }
    ];

    await User.insertMany(users);
    console.log('✅ Users created successfully');

    // Create sample pets
    const pets = [
      {
        id: 101,
        name: "Buddy",
        breed: "Golden Retriever",
        age: 3,
        gender: "Male",
        description: "Friendly and energetic dog, loves playing fetch! Great with kids and other pets. House trained and knows basic commands.",
        imageUrl: "assets/buddy.jpg",
        ownerId: 1,
        ownerName: "Raju",
        isAvailableForAdoption: true,
        petType: "Dog",
        vaccinations: ["Rabies", "DHPP", "Bordetella"],
        location: "Mumbai",
        adoptionFee: 5000,
        specialNeeds: "None",
        goodWithKids: true,
        goodWithPets: true,
        energyLevel: "High",
        size: "Large"
      },
      {
        id: 102,
        name: "Fluffy",
        breed: "Persian",
        age: 2,
        gender: "Female",
        description: "Calm and loving cat, perfect for apartments. Enjoys quiet environments and gentle pets.",
        imageUrl: "assets/fluffy.jpg",
        ownerId: 1,
        ownerName: "Raju",
        isAvailableForAdoption: true,
        petType: "Cat",
        vaccinations: ["FVRCP", "Rabies"],
        location: "Mumbai",
        adoptionFee: 3000,
        specialNeeds: "Indoor cat only",
        goodWithKids: true,
        goodWithPets: false,
        energyLevel: "Low",
        size: "Medium"
      },
      {
        id: 201,
        name: "Max",
        breed: "Labrador",
        age: 4,
        gender: "Male",
        description: "Well-trained and obedient dog, great with kids. Loves swimming and outdoor activities.",
        imageUrl: "assets/max.jpg",
        ownerId: 2,
        ownerName: "Siya",
        isAvailableForAdoption: true,
        petType: "Dog",
        vaccinations: ["Rabies", "DHPP", "Bordetella", "Lyme"],
        location: "Delhi",
        adoptionFee: 6000,
        specialNeeds: "Needs daily exercise",
        goodWithKids: true,
        goodWithPets: true,
        energyLevel: "High",
        size: "Large"
      },
      {
        id: 202,
        name: "Whiskers",
        breed: "Maine Coon",
        age: 1,
        gender: "Male",
        description: "Playful kitten looking for a loving home. Very social and loves attention.",
        imageUrl: "assets/whiskers.jpg",
        ownerId: 2,
        ownerName: "Siya",
        isAvailableForAdoption: true,
        petType: "Cat",
        vaccinations: ["FVRCP"],
        location: "Delhi",
        adoptionFee: 4000,
        specialNeeds: "Needs lots of playtime",
        goodWithKids: true,
        goodWithPets: true,
        energyLevel: "High",
        size: "Medium"
      },
      {
        id: 301,
        name: "Luna",
        breed: "German Shepherd",
        age: 5,
        gender: "Female",
        description: "Protective and loyal, excellent guard dog. Well-trained and intelligent.",
        imageUrl: "assets/luna.jpg",
        ownerId: 3,
        ownerName: "Kishen",
        isAvailableForAdoption: true,
        petType: "Dog",
        vaccinations: ["Rabies", "DHPP", "Bordetella"],
        location: "Bangalore",
        adoptionFee: 7000,
        specialNeeds: "Needs experienced owner",
        goodWithKids: false,
        goodWithPets: false,
        energyLevel: "Medium",
        size: "Large"
      },
      {
        id: 401,
        name: "Charlie",
        breed: "Beagle",
        age: 2,
        gender: "Male",
        description: "Energetic and friendly, loves outdoor activities. Great family dog.",
        imageUrl: "assets/charlie.jpg",
        ownerId: 4,
        ownerName: "Pragati",
        isAvailableForAdoption: true,
        petType: "Dog",
        vaccinations: ["Rabies", "DHPP"],
        location: "Pune",
        adoptionFee: 4500,
        specialNeeds: "None",
        goodWithKids: true,
        goodWithPets: true,
        energyLevel: "High",
        size: "Medium"
      },
      {
        id: 402,
        name: "Bella",
        breed: "Siamese",
        age: 3,
        gender: "Female",
        description: "Elegant and vocal cat, very social. Loves to 'talk' to her humans.",
        imageUrl: "assets/bella.jpg",
        ownerId: 4,
        ownerName: "Pragati",
        isAvailableForAdoption: true,
        petType: "Cat",
        vaccinations: ["FVRCP", "Rabies"],
        location: "Pune",
        adoptionFee: 3500,
        specialNeeds: "Vocal - may not be suitable for apartments",
        goodWithKids: true,
        goodWithPets: true,
        energyLevel: "Medium",
        size: "Medium"
      }
    ];

    await Pet.insertMany(pets);
    console.log('✅ Pets created successfully');

    console.log('🐾 Sample pet adoption data initialized successfully!');
    console.log(`📊 Created ${users.length} users and ${pets.length} pets`);
    
  } catch (error) {
    console.error('❌ Error initializing sample data:', error);
  }
}

// Run this function to initialize data
// initializeSampleData();

module.exports = { initializeSampleData };