import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class CuentaPage extends StatefulWidget {
  const CuentaPage({Key? key}) : super(key: key);

  @override
  State<CuentaPage> createState() => _CuentaPageState();
}

class _CuentaPageState extends State<CuentaPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isEditingName = false;
  bool _isEditingLevel = false;
  bool _isLoading = false;

  String? _name;
  String? _email;
  String? _level;
  String? _imageBase64;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();

    setState(() {
      _name = data?['name'] ?? 'Usuario';
      _email = user.email;
      _level = data?['level'] ?? '1';
      _imageBase64 = data?['imageBase64'];
    });

    _nameController.text = _name!;
    _levelController.text = _level!;
  }

  Future<void> _updateProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);

    final bytes = await File(picked.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'imageBase64': base64Image,
    });

    setState(() {
      _imageBase64 = base64Image;
      _isLoading = false;
    });
  }

  Future<void> _updateUserField(String field, String value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({field: value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mi cuenta",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Imagen de perfil
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _imageBase64 != null
                            ? MemoryImage(base64Decode(_imageBase64!))
                            : null,
                        child: _imageBase64 == null
                            ? const Icon(Icons.person, color: Colors.white, size: 70)
                            : null,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _updateProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.cyan,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Nombre
                  _buildEditableField(
                    label: "Nombre",
                    value: _name ?? '',
                    controller: _nameController,
                    isEditing: _isEditingName,
                    onEdit: () {
                      setState(() => _isEditingName = !_isEditingName);
                      if (!_isEditingName) {
                        _updateUserField('name', _nameController.text);
                        setState(() => _name = _nameController.text);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Correo (solo lectura)
                  _buildReadOnlyField(
                    label: "Correo",
                    value: _email ?? '',
                  ),

                  const SizedBox(height: 20),

                  // Nivel
                  _buildEditableField(
                    label: "Nivel",
                    value: _level ?? '1',
                    controller: _levelController,
                    isEditing: _isEditingLevel,
                    onEdit: () {
                      setState(() => _isEditingLevel = !_isEditingLevel);
                      if (!_isEditingLevel) {
                        _updateUserField('level', _levelController.text);
                        setState(() => _level = _levelController.text);
                      }
                    },
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        // Redirige a IndexScreen y elimina historial de navegación
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/index', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Cerrar sesión"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d44),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.cyan),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d44),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
