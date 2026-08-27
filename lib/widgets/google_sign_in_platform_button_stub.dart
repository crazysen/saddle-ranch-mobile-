import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mobile / desktop: custom branded button.
Widget buildGoogleSignInButton({
  required BuildContext context,
  required Future<void> Function() onMobilePressed,
}) {
  const darkText = Color(0xFF1F2937);
  const cardBorder = Color(0xFFE5E7EB);

  return SizedBox(
    height: 50,
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onMobilePressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: cardBorder, width: 1.2),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/google_logo.png',
            height: 20,
            width: 20,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.network(
              'https://pngimg.com/uploads/google/google_PNG19635.png',
              height: 20,
              width: 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata,
                size: 26,
                color: darkText,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Continue with Google',
            style: GoogleFonts.inter(
              color: darkText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );
}
