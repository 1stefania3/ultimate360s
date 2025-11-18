import 'package:flutter/material.dart';

class LsurWidget extends StatefulWidget {
  @override
  _LsurWidgetState createState() => _LsurWidgetState();
}

class _LsurWidgetState extends State<LsurWidget> {
  // Elementos de la lista
  final List<String> localidades = [
    'Rafael Uribe Uribe',
    'San Cristóbal',
    'Tunjuelito',
    'Bosa',
    'Ciudad Bolívar',
    'Usme',
    'Sumapaz',
  ];

  // Estado de selección
  List<bool> seleccionado = List.filled(5, false);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 428,
      height: 926,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color.fromRGBO(44, 49, 62, 1),
      ),
      child: Stack(
        children: [
          // Fondo
          Positioned(
            top: 0,
            left: -23,
            child: SizedBox(
              width: 462,
              height: 921,
              child: Image.asset(
                'lib/assets/fondo.png',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),

          // Título
          const Positioned(
            top: 120,
            left: 40,
            right: 40,
            child: Text(
              'Localidades del Norte de Bogotá',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.81),
                fontFamily: 'Montserrat',
                fontSize: 30,
              ),
            ),
          ),

          // Flecha de regreso
          Positioned(
            top: 45,
            left: 21,
            child: SizedBox(
              width: 45,
              height: 75,
              child: Image.asset(
                'lib/assets/Backarrow.png',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),

          // Lista tipo checklist
          Positioned(
            top: 300,
            left: 40,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(localidades.length, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      seleccionado[index] = !seleccionado[index];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Texto de la localidad
                        Expanded(
                          child: Text(
                            localidades[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                              fontSize: 28,
                              
                            ),
                          ),
                        ),

                        // Checkbox circular estilo maqueta
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: seleccionado[index]
                              ? Center(
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
