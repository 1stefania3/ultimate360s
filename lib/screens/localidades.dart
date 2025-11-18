import 'package:flutter/material.dart';


class LocalidadesWidget extends StatelessWidget {
  const LocalidadesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [  
          Container(
            color: Color.fromRGBO(43, 57, 73, 1)
            ),
          /// FONDO
          Positioned.fill(

            child: Image.asset(
              
              'lib/assets/Fondo.png',
              fit: BoxFit.cover,
            ),
          ),

          /// FLECHA ATRÁS
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(
                'lib/assets/Backarrow.png',
                width: 45,
              ),
            ),
          ),

          /// TÍTULO
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '¿Dónde estás hoy?',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),

          /// OPCIONES DE LOCALIDAD
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _localidadBox('Norte'),
                SizedBox(height: 30),
                _localidadBox('Sur'),
                SizedBox(height: 30),
                _localidadBox('Centro'),
                SizedBox(height: 30),
                _localidadBox('Occidente'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// WIDGET DE TARJETA DE LOCALIDAD
  Widget _localidadBox(String nombre) {
    return Container(
      width: 184,
      height: 92,
      decoration: BoxDecoration(
        color: Color.fromRGBO(43, 57, 73, 1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.fromRGBO(183, 223, 72, 1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        nombre,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}
