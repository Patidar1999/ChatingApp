import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import 'setup_profile_screen.dart';
import '../home/home_screen.dart';

/// Screen where user enters the 6-digit OTP they received via SMS.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // One controller per OTP digit box
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // Collect all 6 digits into one OTP string
  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  // ──────────────────────────────────────────────
  // Verify the OTP when user taps Verify
  // ──────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      context.showSnack('Please enter the complete 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.verifyOtp(
        verificationId: widget.verificationId,
        otpCode: _otpCode,
      );

      if (userCredential == null) {
        context.showSnack('Verification failed. Try again.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final uid = userCredential.user!.uid;

      // Check if this is a new user (first time login)
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // New user → ask them to set up their profile
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => SetupProfileScreen(
              uid: uid,
              phone: widget.phoneNumber,
            ),
          ),
          (route) => false, // Remove all previous routes
        );
      } else {
        // Existing user → go to home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      context.showSnack('Invalid OTP. Please try again.', isError: true);
    }
  }

  // ──────────────────────────────────────────────
  // Build each OTP digit input box
  // ──────────────────────────────────────────────
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',  // Hide character counter
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Auto-focus next box after entering a digit
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            // Go back to previous box on delete
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.sms_rounded, size: 64, color: Color(0xFF075E54)),

            const SizedBox(height: 24),

            Text(
              'OTP Sent!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'We sent a 6-digit code to\n${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // 6 digit OTP boxes in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _buildOtpBox(i)),
            ),

            const SizedBox(height: 32),

            // Verify button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Verify OTP',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),

            const SizedBox(height: 16),

            // Resend OTP option
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Didn't receive OTP? Go back"),
            ),
          ],
        ),
      ),
    );
  }
}
