import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({Key? key}) : super(key: key);

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userLevel;
  String? _userLocation;
  String? _userImage;
  int _postCount = 0;
  int _following = 0;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      _userId = args['userId'];
      _userName = args['userName'];
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Cargar datos del usuario
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      final userData = userDoc.data();

      // Contar posts del usuario
      final postsQuery = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: _userId)
          .get();

      setState(() {
        _userName = userData?['name'] ?? 'Usuario';
        _userEmail = userData?['email'] ?? '';
        _userLevel = userData?['level'] ?? '1';
        _userLocation = userData?['location'] ?? 'Desconocida';
        _userImage = userData?['imageBase64'];
        _following = userData?['following'] ?? 0;
        _postCount = postsQuery.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Navegar a la página de detalle del post
  void _navigateToPost(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailView(postId: postId),
      ),
    );
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
                                    Navigator.pop(context);
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
                                    Navigator.pop(context);
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
                        final commentUserId = data['userId'];
                        
                        return ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                '/perfil',
                                arguments: {
                                  'userId': commentUserId,
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
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                '/perfil',
                                arguments: {
                                  'userId': commentUserId,
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
    final currentUserId = _auth.currentUser?.uid;
    final isOwnProfile = currentUserId == _userId;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Header del perfil
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: _userImage != null
                                ? MemoryImage(base64Decode(_userImage!))
                                : null,
                            child: _userImage == null
                                ? Text(
                                    (_userName ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                    ),
                                  )
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName ?? 'Usuario',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _userLocation ?? 'Desconocida',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Estadísticas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Posts', _postCount.toString()),
                      _buildStat('Nivel', _userLevel ?? '1', color: Colors.greenAccent),
                      _buildStat('Following', _following.toString()),
                    ],
                  ),
                  const Divider(color: Colors.white30, height: 30),

                  // Grid de publicaciones
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('posts')
                          .where('userId', isEqualTo: _userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.cyan),
                          );
                        }

                        var posts = snapshot.data!.docs;

                        // Ordenar localmente por timestamp descendente
                        posts.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aTime = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
                          final bTime = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
                          return bTime.compareTo(aTime);
                        });

                        if (posts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isOwnProfile
                                      ? 'No tienes publicaciones'
                                      : 'Este usuario no tiene publicaciones',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          itemCount: posts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            final data = posts[index].data() as Map<String, dynamic>;
                            final postId = posts[index].id;
                            final hasImage = data['imageBase64'] != null;
                            final likes = List<String>.from(data['likes'] ?? []);

                            return GestureDetector(
                              onTap: () => _navigateToPost(postId),
                              child: Stack(
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
                                            alignment: Alignment.center,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                data['text'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                  ),
                                  // Overlay con gradiente para mejorar legibilidad
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.3),
                                          ],
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
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            likes.length.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
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
            ),
    );
  }

  Widget _buildStat(String label, String value, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
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

// ========================================
// Vista de Detalle del Post
// ========================================

class PostDetailView extends StatefulWidget {
  final String postId;
  
  const PostDetailView({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

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
                              if (!snapshot.hasData) return const SizedBox();
                              final userData = snapshot.data?.data() as Map<String, dynamic>?;
                              final userName = userData?['name'] ?? 'Usuario';
                              final userImage = userData?['imageBase64'];
                              
                              return ListTile(
                                leading: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PerfilPage(),
                                        settings: RouteSettings(
                                          arguments: {
                                            'userId': userId,
                                            'userName': userName,
                                          },
                                        ),
                                      ),
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
                                title: Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final user = _auth.currentUser!;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final username = userData?['name'] ?? user.email;
    final userImage = userData?['imageBase64'];

    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'username': username,
      'userImageBase64': userImage,
      'text': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

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
          'Publicación',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Publicación no encontrada',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final likes = List<String>.from(data['likes'] ?? []);
          final isLiked = likes.contains(currentUserId);
          final userName = data['username'] ?? 'Usuario';
          final userImage = data['userImageBase64'];
          final userId = data['userId'];
          final hasImage = data['imageBase64'] != null;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Post card
                Container(
                  margin: const EdgeInsets.all(16),
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
                      // Header del post
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PerfilPage(),
                                    settings: RouteSettings(
                                      arguments: {
                                        'userId': userId,
                                        'userName': userName,
                                      },
                                    ),
                                  ),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PerfilPage(),
                                      settings: RouteSettings(
                                        arguments: {
                                          'userId': userId,
                                          'userName': userName,
                                        },
                                      ),
                                    ),
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
                          ],
                        ),
                      ),

                      // Contenido del post
                      if (hasImage)
                        ClipRRect(
                          child: Image.memory(
                            base64Decode(data['imageBase64']),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (data['text'] != null && data['text'].toString().isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(minHeight: 300),
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
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                data['text'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                      // Texto debajo de la imagen
                      if (hasImage && data['text'] != null && data['text'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            data['text'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
                                    onPressed: () => _toggleLike(widget.postId, likes),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sección de comentarios
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2d2d44),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.comment, color: Colors.cyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Comentarios',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo para agregar comentario
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _sendComment(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.cyan),
                            onPressed: _sendComment,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lista de comentarios
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('posts')
                            .doc(widget.postId)
                            .collection('comments')
                            .orderBy('timestamp', descending: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Colors.cyan),
                              ),
                            );
                          }

                          final comments = snapshot.data!.docs;

                          if (comments.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'Sé el primero en comentar',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            separatorBuilder: (context, index) => const Divider(
                              color: Colors.white12,
                              height: 16,
                            ),
                            itemBuilder: (context, index) {
                              final commentData = comments[index].data() as Map<String, dynamic>;
                              final commentUserImage = commentData['userImageBase64'];
                              final commentUserName = commentData['username'] ?? 'Usuario';
                              final commentUserId = commentData['userId'];
                              final timestamp = commentData['timestamp'] as Timestamp?;
                              final dateStr = timestamp != null 
                                  ? _formatDate(timestamp.toDate())
                                  : '';

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PerfilPage(),
                                        settings: RouteSettings(
                                          arguments: {
                                            'userId': commentUserId,
                                            'userName': commentUserName,
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.grey[600],
                                    backgroundImage: commentUserImage != null
                                        ? MemoryImage(base64Decode(commentUserImage))
                                        : null,
                                    child: commentUserImage == null
                                        ? Text(
                                            commentUserName[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.white),
                                          )
                                        : null,
                                  ),
                                ),
                                title: Text(
                                  commentUserName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      commentData['text'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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