import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database.dart';

class WillkommensSeite extends StatefulWidget {
  final String uid;

  const WillkommensSeite({required this.uid, super.key});

  @override
  State<WillkommensSeite> createState() => _WillkommensSeiteState();
}

class _WillkommensSeiteState extends State<WillkommensSeite> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope( // ✅ Verhindert Zurück-Navigation
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Willkommen bei Streax!',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Erstelle dein Profil um zu beginnen',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 60),
                
                // Form
                Text(
                  'Profil erstellen',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                
                SizedBox(height: 32),
                
                // Name Input
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Dein Name',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: 'z.B. Max Mustermann',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Username Input
                TextFormField(
                  controller: usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: 'z.B. max_mustermann',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                
                Spacer(),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _createProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Profil erstellen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Hinweis
                Center(
                  child: Text(
                    'Du kannst dein Profil später in den Einstellungen ändern',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    // Validation
    String name = nameController.text.trim();
    String username = usernameController.text.trim();
    
    if (name.isEmpty || username.isEmpty) {
      _showError('Bitte alle Felder ausfüllen');
      return;
    }
    
    if (username.length < 3) {
      _showError('Username muss mindestens 3 Zeichen haben');
      return;
    }
    
    if (username.contains(' ')) {
      _showError('Username darf keine Leerzeichen enthalten');
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      // Profil in Firestore erstellen
      await DatabaseService(uid: widget.uid).updateUserData(
        name,
        username,
        freundeAnzahl: 0,
        laengsterStreak: 0,
      );
      
      // Zurück zur App - Wrapper wird automatisch zur startseite wechseln
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showError('Fehler beim Erstellen des Profils');
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }
}