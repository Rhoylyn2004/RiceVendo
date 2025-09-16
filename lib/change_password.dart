import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  bool _verifiedOld = false;
  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _checkOldPassword() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No authenticated user.")),
      );
      return;
    }

    final oldPw = _oldCtrl.text.trim();
    if (oldPw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your old password")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: oldPw);
      await user.reauthenticateWithCredential(cred);
      setState(() {
        _verifiedOld = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Old password verified. Please enter new password.")),
      );
    } on FirebaseAuthException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Old password is incorrect")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveNewPassword() async {
    final newPw = _newCtrl.text.trim();
    final confirmPw = _confirmCtrl.text.trim();

    if (newPw.isEmpty || confirmPw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out the new password fields.")),
      );
      return;
    }

    if (newPw.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters.")),
      );
      return;
    }

    if (newPw != confirmPw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match.")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No authenticated user.");

      await user.updatePassword(newPw);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully.")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message ?? e.code}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const headerGreen = Color.fromARGB(255, 3, 60, 34);
    const backgroundColor = Color.fromARGB(255, 239, 243, 203);
    const cardColor = Color.fromARGB(255, 224, 235, 219);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: headerGreen,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Change Password',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Card(
              color: cardColor,
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!_verifiedOld) ...[
                      TextFormField(
                        controller: _oldCtrl,
                        obscureText: !_showOld,
                        decoration: InputDecoration(
                          labelText: "Enter current password",
                          suffixIcon: IconButton(
                            icon: Icon(
                                _showOld
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: headerGreen),
                            onPressed: () =>
                                setState(() => _showOld = !_showOld),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: _loading ? null : _checkOldPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: headerGreen,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text(
                                    "Continue",
                                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)), // ✅ black
                                  ),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _newCtrl,
                        obscureText: !_showNew,
                        decoration: InputDecoration(
                          labelText: "Enter new password",
                          suffixIcon: IconButton(
                            icon: Icon(
                                _showNew
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: headerGreen),
                            onPressed: () =>
                                setState(() => _showNew = !_showNew),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: !_showConfirm,
                        decoration: InputDecoration(
                          labelText: "Re-enter new password",
                          suffixIcon: IconButton(
                            icon: Icon(
                                _showConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: headerGreen),
                            onPressed: () =>
                                setState(() => _showConfirm = !_showConfirm),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed:
                                _loading ? null : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 209, 25, 25),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)), // ✅ black
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _loading ? null : _saveNewPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: headerGreen,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text(
                                    "Save",
                                    style: TextStyle(color: Colors.white), // ✅ white
                                  ),
                          ),
                        ],
                      ),
                    ],
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
