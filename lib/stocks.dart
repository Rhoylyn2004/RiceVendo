import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'update.dart';
import 'home_page.dart';
import 'package:google_fonts/google_fonts.dart';

class StocksPage extends StatefulWidget {
  const StocksPage({super.key});

  @override
  State<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksPage> {
  String riceTypeA = "N/A";
  String priceA = "N/A";
  String riceTypeB = "N/A";
  String priceB = "N/A";

  int _selectedIndex = 1;

  final _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://ricevendo-4e1fe-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('stocks');

  @override
  void initState() {
    super.initState();
    listenToStockData();
  }

  void listenToStockData() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          riceTypeA = data['containerA']?['classification']?.toString() ?? 'N/A';
          priceA = data['containerA']?['price']?.toString() ?? 'N/A';
          riceTypeB = data['containerB']?['classification']?.toString() ?? 'N/A';
          priceB = data['containerB']?['price']?.toString() ?? 'N/A';
        });
      } else {
        print("⚠️ No data found in 'stocks' node.");
      }
    }, onError: (error) {
      print("❌ Firebase listener error: $error");
    });
  }

  void navigateToUpdate(String container) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScreen(
          initialClassification: container == "A" ? riceTypeA : riceTypeB,
          initialPrice: container == "A" ? priceA : priceB,
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      final classification = result['classification']?.trim() ?? "";
      final price = result['price']?.trim() ?? "";

      if (classification.isNotEmpty && price.isNotEmpty) {
        final containerKey = container == "A" ? 'containerA' : 'containerB';

        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          final updateRef = _dbRef.child(containerKey);

          await updateRef.update({
            'classification': classification,
            'price': double.tryParse(price) ?? 0,
          });
        } catch (e) {
          print("❌ Exception during update: $e");
        }
      }
    }
  }

  void _onNavBarTap(int index) async {
    if (index == 0) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget stockCard({
    required String title,
    required String riceType,
    required String price,
    required VoidCallback onUpdate,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Color.fromARGB(255, 224, 235, 219), // Updated to match HomePage lightGreen
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const Divider(color: Colors.black54, height: 20),
            Row(
              children: [
                const Icon(Icons.rice_bowl, color: Colors.brown),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Rice Type: $riceType",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Price: $price",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpdate,
                icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                label: const Text(
                  "Update",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 3, 60, 34),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.green.shade900, width: 2),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headerGreen = Color.fromARGB(255, 3, 60, 34); // Updated header color
    const navBarDarkGreen = Color.fromARGB(255, 3, 60, 34);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 243, 203),
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
                'Inventory',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            stockCard(
              title: 'CONTAINER A',
              riceType: riceTypeA,
              price: priceA,
              onUpdate: () => navigateToUpdate("A"),
            ),
            const SizedBox(height: 20),
            stockCard(
              title: 'CONTAINER B',
              riceType: riceTypeB,
              price: priceB,
              onUpdate: () => navigateToUpdate("B"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          decoration: const BoxDecoration(
            color: navBarDarkGreen,
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: BottomNavigationBar(
            backgroundColor: navBarDarkGreen,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            currentIndex: _selectedIndex,
            onTap: _onNavBarTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.widgets),
                label: 'Inventory',
              ),
            ],
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
