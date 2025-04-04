import 'package:flutter/material.dart';
import 'homepage.dart';
import 'profilepage.dart';

class MainScreen extends StatefulWidget {
  final void Function(bool isDarkMode) toggleTheme;

  const MainScreen({super.key, required this.toggleTheme});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    ProfilePage(toggleTheme: (bool isDarkMode) {
      // Aksi untuk toggle tema
    }),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "CookMate",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF365E32),
          foregroundColor: Colors.white,
          centerTitle: true,
          toolbarHeight: 67,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: SizedBox(
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 1; // Mengubah halaman ke ProfilePage
                  });
                },
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/profile.jpg'),
                  radius: 18,
                ),
              ),
            ),
          ),
        ),
        body: Container(
          color: const Color(0xFFF8F5E9),
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory, // Hilangkan efek klik
            highlightColor: Colors.transparent,    // Hilangkan efek highlight
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF365E32),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
