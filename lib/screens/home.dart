import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3498DB);
    const primaryRed = Color(0xFFE74C3C);
    const primaryGreen = Color(0xFF2ECC71);
    const primaryYellow = Color(0xFFF1C40F);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo
          Image.asset('lib/assets/bg1.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)), // overlay

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flecha de retroceso
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  Center(
                    child: Column(
                      children: [
                        Image.asset('lib/assets/logo.png', width: 120),
                        const SizedBox(height: 10),
                        const Text(
                          "Ultimate360",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Botones
                  Expanded(
                    child: Center(
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildHomeButton(
                            icon: Icons.explore,
                            label: "Explorar Zona",
                            color: primaryBlue,
                            onTap: () {
                              // Acción explorar
                            },
                          ),
                          _buildHomeButton(
                            icon: Icons.wifi,
                            label: "Conectar",
                            color: primaryRed,
                            onTap: () {
                              // Navega a la pantalla Welcome (Red 360)
                              Navigator.pushNamed(context, '/welcome');
                            },
                          ),
                          _buildHomeButton(
                            icon: Icons.person,
                            label: "Cuenta",
                            color: primaryGreen,
                            onTap: () {
                              // Navega a CuentaPage
                              Navigator.pushNamed(context, '/perfil');
                            },
                          ),
                          _buildHomeButton(
                            icon: Icons.menu_book,
                            label: "Instrucciones",
                            color: primaryYellow,
                            onTap: () {
                              // Acción instrucciones
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 50),
            const SizedBox(height: 15),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
