class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Phone validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all spaces, dashes, and parentheses
    String cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with +91 (India country code)
    if (cleanedPhone.startsWith('+91')) {
      cleanedPhone = cleanedPhone.substring(3);
    } else if (cleanedPhone.startsWith('91') && cleanedPhone.length == 12) {
      cleanedPhone = cleanedPhone.substring(2);
    }

    // Indian mobile number should be 10 digits and start with 6, 7, 8, or 9
    if (cleanedPhone.length != 10) {
      return 'Phone number must be 10 digits';
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanedPhone)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Password validation with detailed error messages
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    List<String> errors = [];

    if (value.length < 6) {
      errors.add('At least 6 characters');
    }

    if (errors.isNotEmpty) {
      return 'Password must contain:\n• ${errors.join('\n• ')}';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    // Check if name contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    return validateName(value);
  }

  // Rescue city validation
  static String? validateRescueCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Rescue city is required';
    }
    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }
    // Check if city contains only letters, spaces, and common punctuation
    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(value.trim())) {
      return 'City name can only contain letters, spaces, hyphens, and dots';
    }
    return null;
  }

  // ============== PET PAGE VALIDATIONS ==============

  // Pet name validation
  static String? validatePetName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pet name is required';
    }
    if (value.trim().length < 2) {
      return 'Pet name must be at least 2 characters';
    }
    if (value.trim().length > 30) {
      return 'Pet name must be less than 30 characters';
    }
    // Allow letters, spaces, hyphens, and apostrophes for pet names
    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(value.trim())) {
      return 'Pet name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  // Breed validation
  static String? validateBreed(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Breed is required';
    }
    if (value.trim().length < 2) {
      return 'Breed must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Breed name must be less than 50 characters';
    }
    // Allow letters, spaces, hyphens, and parentheses for breed names
    if (!RegExp(r'^[a-zA-Z\s\-\(\)]+$').hasMatch(value.trim())) {
      return 'Breed can only contain letters, spaces, hyphens, and parentheses';
    }
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete address (minimum 10 characters)';
    }
    if (value.trim().length > 200) {
      return 'Address must be less than 200 characters';
    }
    return null;
  }

  // City validation for pet
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'City name must be less than 50 characters';
    }
    // Check if city contains only letters, spaces, and common punctuation
    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(value.trim())) {
      return 'City name can only contain letters, spaces, hyphens, and dots';
    }
    return null;
  }

  // Note validation (optional field)
  static String? validateNote(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 500) {
        return 'Note must be less than 500 characters';
      }
    }
    return null; // Optional field, so null/empty is valid
  }

  // Date validation
  static String? validateDateOfBirth(DateTime? selectedDate) {
    if (selectedDate == null) {
      return 'Date of birth is required';
    }

    // Check if date is not in the future
    if (selectedDate.isAfter(DateTime.now())) {
      return 'Date of birth cannot be in the future';
    }

    // Check if date is not too old (reasonable pet age limit - 50 years)
    DateTime fiftyYearsAgo = DateTime.now().subtract(
      const Duration(days: 365 * 50),
    );
    if (selectedDate.isBefore(fiftyYearsAgo)) {
      return 'Please enter a valid date of birth';
    }

    return null;
  }

  // Gender validation
  static String? validateGender(String? selectedGender) {
    if (selectedGender == null || selectedGender.isEmpty) {
      return 'Please select gender';
    }
    return null;
  }

  // Animal type validation
  static String? validateAnimalType(String? selectedAnimal) {
    if (selectedAnimal == null || selectedAnimal.isEmpty) {
      return 'Please select animal type';
    }
    return null;
  }

  // Image validation
  static String? validateImages(List<dynamic> images) {
    if (images.isEmpty) {
      return 'Please upload at least one image';
    }
    if (images.length > 6) {
      return 'Maximum 6 images are allowed';
    }
    return null;
  }

  // ============== UTILITY VALIDATIONS ==============

  // Age calculation from date of birth
  static int calculateAge(DateTime dateOfBirth) {
    DateTime now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Format date for display
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Clean phone number for storage
  static String cleanPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) {
      return cleaned;
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      return '+${cleaned}';
    } else if (cleaned.length == 10) {
      return '+91${cleaned}';
    }
    return cleaned;
  }

  // Capitalize first letter of each word
  static String capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
