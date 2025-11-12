import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MiPerfilPage extends StatefulWidget {
  const MiPerfilPage({Key? key}) : super(key: key);

  @override
  State<MiPerfilPage> createState() => _MiPerfilPageState();
}

class _MiPerfilPageState extends State<MiPerfilPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a1a2e),
        body: Center(
          child: Text('No hay usuario', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Perfil
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final profileImage = userData['imageBase64'] != null
                    ? MemoryImage(base64Decode(userData['imageBase64']))
                    : null;
                final userName = userData['name'] ?? 'Usuario';
                final location = userData['location'] ?? 'Desconocida';
                final level = userData['level'] ?? 'Principiante';
                final following = userData['following'] ?? 0;

                return Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profileImage,
                          child: profileImage == null
                              ? Text(userName[0].toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 40, color: Colors.white))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Stats
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                final postCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(userId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox();
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    final level = userData['level'] ?? 'Principiante';
                    final following = userData['following'] ?? 0;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Posts', postCount.toString()),
                        _buildStat('Nivel', level, color: Colors.greenAccent),
                        _buildStat('Following', following.toString()),
                      ],
                    );
                  },
                );
              },
            ),
            const Divider(color: Colors.white30, height: 30),

            // Grid de posts
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .where('userId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var posts = snapshot.data!.docs;

                  // Ordenar localmente por timestamp descendente
                  posts.sort((a, b) {
                    final aTime = (a['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime(2000);
                    final bTime = (b['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime(2000);
                    return bTime.compareTo(aTime);
                  });

                  if (posts.isEmpty) {
                    return const Center(
                      child: Text('No tienes publicaciones',
                          style: TextStyle(color: Colors.white)),
                    );
                  }

                  return GridView.builder(
                    itemCount: posts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final data = posts[index].data() as Map<String, dynamic>;
                      final hasImage = data['imageBase64'] != null;
                      final likes = List<String>.from(data['likes'] ?? []);

                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: hasImage
                                ? Image.memory(
                                    base64Decode(data['imageBase64']),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Container(
                                    color: Colors.purple[800],
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        data['text'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                          ),
                          // Número de likes
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.favorite,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    likes.length.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
