import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder to handle responsiveness if needed, but sticking to Stack for design fidelity
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3C4494), Color(0xFF232859)],
          ),
        ),
        child: Stack(
          children: [
            // Registration Page Container (White Card)
            Center(
              child: Container(
                width: 1290,
                height: 800,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F6),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Stack(
                  children: [
                    // Image Section (Left)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 573,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.grey, // Placeholder for image
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(35),
                            bottomLeft: Radius.circular(35),
                          ),
                          // image: DecorationImage(image: AssetImage('assets/image.png'), fit: BoxFit.cover),
                        ),
                        child: const Center(child: Text("Image Placeholder")),
                      ),
                    ),
                    
                    // Login Form Section (Right)
                    Positioned(
                      left: 738,
                      top: 170,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Login Title
                          Text(
                            AppLocalizations.of(context)!.loginTitle,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 45,
                              color: const Color(0xFF231C1C),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Username Field
                          Text(
                            AppLocalizations.of(context)!.usernamePlaceholder,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: const Color(0x80000000), // 50% opacity black
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: 382,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFB7B7B7)),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Password Field
                          Text(
                            AppLocalizations.of(context)!.passwordPlaceholder,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: const Color(0x80000000),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: 382,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFB7B7B7)),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Remember Me
                          Row(
                            children: [
                              SizedBox(
                                width: 17,
                                height: 18,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) => setState(() => _rememberMe = val!),
                                  activeColor: const Color(0xFF231C1C),
                                  side: const BorderSide(color: Color(0xFF231C1C), width: 2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.of(context)!.rememberMe,
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 20,
                                  color: const Color(0xFF231C1C),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Don't have account
                          Padding(
                            padding: const EdgeInsets.only(left: 80), // Align roughly with design
                            child: Text(
                              AppLocalizations.of(context)!.dontHaveAccount,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: const Color(0x80231C1C),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Login Button
                          GestureDetector(
                            onTap: () async {
                              final success = await _authService.login(
                                _usernameController.text,
                                _passwordController.text,
                              );
                              if (success) {
                                // Navigate
                                // context.go('/');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Login Successful")),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Login Failed")),
                                );
                              }
                            },
                            child: Container(
                              width: 382,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9CA4CC),
                                borderRadius: BorderRadius.circular(45),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                AppLocalizations.of(context)!.loginButton,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Privacy Policy Footer
                    Positioned(
                      left: 706,
                      top: 701,
                      child: Text(
                        AppLocalizations.of(context)!.privacyPolicy,
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
