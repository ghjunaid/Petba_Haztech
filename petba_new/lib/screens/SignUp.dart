import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petba_new/models/Validate.dart';
import 'package:petba_new/screens/HomePage.dart';
import 'package:petba_new/screens/SignIn.dart';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/services/user_data_service.dart';
import 'package:petba_new/screens/SelectCityScreen.dart';
// import 'package:petba/services/auth_services.dart'; // Commented out API service
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Updated Sign Up Method - consistent with login flow
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // if (!_acceptTerms) {
    //   _showSnackBar('Please accept the terms and conditions', isError: true);
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'fname': _firstNameController.text.trim(),
        'lname': _lastNameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'password': _passwordController.text,
        //7/-*'password_confirmation': _confirmPasswordController.text,
        'phone': _phoneController.text.trim(),
      };

      // Make the API call
      final response = await http.post(
        Uri.parse('$apiurl/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Handle the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        bool dataSaved = await UserDataService.saveSignupResponse(responseData);
        if (dataSaved) {
          _showSnackBar('Account created successfully!', isError: false);
          _clearForm();

          // IMPORTANT: Always redirect to city selection after signup
          // Don't check for existing city ID from previous sessions
          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              print('=== SIGNUP SUCCESS - REDIRECTING TO CITY SELECTION ===');
              print('User must select city after signup');

              // Always go to city selection page after signup
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CitySelectionPage(isFromLogin: true),
                ),
              );
              print('Redirected to CitySelectionPage');
            }
          });
        } else {
          _showSnackBar(
            'Account created but failed to save data locally',
            isError: true,
          );
        }
      } else {
        // Handle API errors
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Registration failed. Please try again.';

        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['errors'] != null) {
          // Handle validation errors
          Map<String, dynamic> errors = errorData['errors'];
          List<String> errorMessages = [];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.cast<String>());
            }
          });
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.first;
          }
        }

        _showSnackBar(errorMessage, isError: true);
      }
    } on http.ClientException catch (e) {
      _showSnackBar(
        'Network error. Please check your connection.',
        isError: true,
      );
    } on FormatException catch (e) {
      _showSnackBar('Invalid response from server.', isError: true);
    } catch (e) {
      _showSnackBar(
        'An unexpected error occurred. Please try again.',
        isError: true,
      );
      print('Registration error: $e'); // For debugging
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _acceptTerms = false;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: Duration(seconds: isError ? 4 : 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'images/Logo.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.pets,
                                  size: 48,
                                  color: Theme.of(context).primaryColor,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Petba',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join our pet-loving community',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    // First Name Field
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        validator: Validators.validateName,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          hintText: 'Enter your first name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ), // Changed from height: 16 to width: 12
                    // Last Name Field
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        validator: Validators.validateName,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          hintText: 'Enter your last name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  validator: Validators.validatePhoneNumber,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[\d\s\-\(\)\+]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign In",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}