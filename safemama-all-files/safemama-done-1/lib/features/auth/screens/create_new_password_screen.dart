// lib/features/auth/screens/create_new_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/widgets/custom_button.dart';
// --- THIS IS THE FIX ---
import 'package:safemama/core/providers/app_providers.dart';
// --- END OF FIX ---
import 'package:safemama/navigation/providers/user_profile_provider.dart';

class CreateNewPasswordScreen extends ConsumerStatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  ConsumerState<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends ConsumerState<CreateNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final success = await ref.read(userProfileNotifierProvider.notifier)
        .updateUserPassword(_passwordController.text);
    
    if(mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Show success dialog
        await showDialog(
          context: context, 
          builder: (_) => AlertDialog(
            title: const Text("Password Updated!"), 
            content: const Text("Your password has been successfully updated."), 
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), 
                child: const Text("Continue"),
              ),
            ],
          ),
        );
        // FIXED: Go directly to home since user is already authenticated
        // Password recovery creates a session, so no need to login again
        if(mounted) context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update password.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Password"), automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("You've successfully verified your email. Please enter a new password for your account.", textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController, 
                  obscureText: true, 
                  decoration: const InputDecoration(labelText: "New Password"),
                  validator: (val) {
                    if (val == null || val.length < 8) return "Password must be at least 8 characters.";
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  isLoading: _isLoading,
                  text: "Update Password",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}