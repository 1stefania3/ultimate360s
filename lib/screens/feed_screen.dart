import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

// Alias para mantener compatibilidad
class FeedScreen extends FeedPage {
  const FeedScreen({Key? key}) : super(key: key);
}

class _FeedPageState extends State<FeedPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isUploading = false;
  String? _imageBase64;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 📷 Seleccionar imagen
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _isUploading = true);

    final bytes = await File(picked.path).readAsBytes();
    _imageBase64 = base64Encode(bytes);

    setState(() => _isUploading = false);
  }

  // 📝 Crear publicación
  Future<void> _createPost() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final username = userData?['name'] ?? user.email;
    final userImage = userData?['imageBase64'];

    if (_textController.text.isEmpty && _imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo o agrega una imagen')),
      );
      return;
    }

    await _firestore.collection('posts').add({
      'userId': user.uid,
      'username': username,
      'userImageBase64': userImage,
      'text': _textController.text.trim(),
      'imageBase64': _imageBase64,
      'likes': [],
      'timestamp': FieldValue.serverTimestamp(),
    });

    _textController.clear();
    setState(() => _imageBase64 = null);
    Navigator.pop(context);
  }

  // ❤️ Like o unlike
  Future<void> _toggleLike(String postId, List likes) async {
    final userId = _auth.currentUser!.uid;
    final postRef = _firestore.collection('posts').doc(postId);
    final updatedLikes = List<String>.from(likes);
    if (updatedLikes.contains(userId)) {
      updatedLikes.remove(userId);
    } else {
      updatedLikes.add(userId);
    }
    await postRef.update({'likes': updatedLikes});
  }

  // 👥 Mostrar quiénes dieron like
  void _showLikes(BuildContext context, List<String> likeUserIds) async {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF2d2d44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Les gusta",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: likeUserIds.isEmpty
                    ? const Center(
                        child: Text(
                          "Aún no hay likes",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: likeUserIds.length,
                        itemBuilder: (context, index) {
                          final userId = likeUserIds[index];
                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('users').doc(userId).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox();
                              }
                              final userData = snapshot.data?.data() as Map<String, dynamic>?;
                              final userName = userData?['name'] ?? 'Usuario';
                              final userImage = userData?['imageBase64'];
                              
                              return ListTile(
                                leading: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/perfil',
                                      arguments: {
                                        'userId': userId,
                                        'userName': userName,
                                      },
                                    );
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.grey[600],
                                    backgroundImage: userImage != null
                                        ? MemoryImage(base64Decode(userImage))
                                        : null,
                                    child: userImage == null
                                        ? Text(
                                            userName[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.white),
                                          )
                                        : null,
                                  ),
                                ),
                                title: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/perfil',
                                      arguments: {
                                        'userId': userId,
                                        'userName': userName,
                                      },
                                    );
                                  },
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 💬 Mostrar comentarios
  void _showComments(BuildContext context, String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      backgroundColor: const Color(0xFF2d2d44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      context: context,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Comentarios",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.cyan),
                      );
                    }
                    final comments = snapshot.data!.docs;
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          "Aún no hay comentarios",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final data = comments[index].data() as Map<String, dynamic>;
                        final timestamp = data['timestamp'] as Timestamp?;
                        final dateStr = timestamp != null 
                            ? _formatDate(timestamp.toDate())
                            : '';
                        final userImage = data['userImageBase64'];
                        final username = data['username'] ?? 'Usuario';
                        
                        return ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/perfil',
                                arguments: {
                                  'userId': data['userId'],
                                  'userName': username,
                                },
                              );
                            },
                            child: CircleAvatar(
                              backgroundColor: Colors.grey[600],
                              backgroundImage: userImage != null
                                  ? MemoryImage(base64Decode(userImage))
                                  : null,
                              child: userImage == null
                                  ? Text(
                                      username[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                          ),
                          title: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/perfil',
                                arguments: {
                                  'userId': data['userId'],
                                  'userName': username,
                                },
                              );
                            },
                            child: Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            data['text'] ?? '',
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                          trailing: Text(
                            dateStr,
                            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Agrega un comentario...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.cyan),
                    onPressed: () async {
                      final user = _auth.currentUser!;
                      final userDoc = await _firestore
                          .collection('users')
                          .doc(user.uid)
                          .get();
                      final userData = userDoc.data();
                      final username = userData?['name'] ?? user.email;
                      final userImage = userData?['imageBase64'];

                      if (commentController.text.trim().isEmpty) return;

                      await _firestore
                          .collection('posts')
                          .doc(postId)
                          .collection('comments')
                          .add({
                        'userId': user.uid,
                        'username': username,
                        'userImageBase64': userImage,
                        'text': commentController.text.trim(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      commentController.clear();
                    },
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

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
          'Red 360',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2d2d44),
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white, size: 30),
              onPressed: () {
                // Ya estamos en home, no hacer nada o refrescar
              },
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pushNamed(context, '/cuenta');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[400],
        shape: const CircleBorder(),
        elevation: 5,
        onPressed: () => _showCreatePost(context),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Barra horizontal de usuarios
          Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 16),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').limit(10).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.green[400],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.cyan,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final user = users[index - 1].data() as Map<String, dynamic>;
                    final userName = user['name'] ?? 'Usuario';
                    final userImage = user['imageBase64'];
                    final userId = users[index - 1].id;
                    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/perfil',
                            arguments: {
                              'userId': userId,
                              'userName': userName,
                            },
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.cyan,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.grey[700],
                                backgroundImage: userImage != null
                                    ? MemoryImage(base64Decode(userImage))
                                    : null,
                                child: userImage == null
                                    ? Text(
                                        firstLetter,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Título Timeline
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Lista de posts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                }

                // Filtrar posts según búsqueda por nombre de usuario
                final allPosts = snapshot.data!.docs;
                final filteredPosts = _searchQuery.isEmpty
                    ? allPosts
                    : allPosts.where((post) {
                        final data = post.data() as Map<String, dynamic>;
                        final username = (data['username'] ?? '').toString().toLowerCase();
                        return username.contains(_searchQuery);
                      }).toList();

                if (filteredPosts.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty 
                          ? "Sin publicaciones"
                          : "No se encontraron publicaciones de usuarios con '$_searchQuery'",
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final data = filteredPosts[index].data() as Map<String, dynamic>;
                    final postId = filteredPosts[index].id;
                    final likes = List<String>.from(data['likes'] ?? []);
                    final isLiked = likes.contains(userId);
                    final userName = data['username'] ?? 'Usuario';
                    final userImage = data['userImageBase64'];
                    final hasImage = data['imageBase64'] != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2d2d44),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header del post con fondo blanco
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/perfil',
                                      arguments: {
                                        'userId': data['userId'],
                                        'userName': userName,
                                      },
                                    );
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                    radius: 20,
                                    backgroundImage: userImage != null
                                        ? MemoryImage(base64Decode(userImage))
                                        : null,
                                    child: userImage == null
                                        ? Text(
                                            userName[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/perfil',
                                        arguments: {
                                          'userId': data['userId'],
                                          'userName': userName,
                                        },
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Hace ${_getTimeAgo(data['timestamp'])}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_horiz,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),

                          // Contenido del post
                          if (hasImage)
                            ClipRRect(
                              child: Image.memory(
                                base64Decode(data['imageBase64']),
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (data['text'] != null && data['text'].toString().isNotEmpty)
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                  colors: [
                                    Colors.purple[900]!,
                                    Colors.blue[600]!,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    data['text'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                          // Texto debajo de la imagen
                          if (hasImage && data['text'] != null && data['text'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                data['text'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          // Botones de acción
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? Colors.red : Colors.white,
                                        ),
                                        onPressed: () => _toggleLike(postId, likes),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showLikes(context, likes),
                                        child: Text(
                                          '${likes.length}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[600],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextButton(
                                    onPressed: () => _showComments(context, postId),
                                    child: const Text(
                                      'Comentar',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ➕ Pop-up para crear publicación
  void _showCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2d2d44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Crear publicación",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (_imageBase64 != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          base64Decode(_imageBase64!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageBase64 = null;
                            });
                            setModalState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "¿Qué estás pensando?",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _pickImage();
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.image, color: Colors.cyan),
                        label: Text(
                          "Imagen",
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[600]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createPost,
                        icon: const Icon(Icons.send),
                        label: const Text("Publicar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'ahora';
    
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'ahora';
      }
    } catch (e) {
      return 'ahora';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}