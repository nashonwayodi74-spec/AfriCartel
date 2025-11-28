import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// AfriConnect Forum - A platform for innovators, scientists, and engineers
/// to discuss rising matters concerning Africa and the globe at large.

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Forum categories for African and global discussions
  final List<ForumCategory> categories = [
    ForumCategory(
      id: 'climate',
      name: 'Climate & Environment',
      icon: Icons.eco,
      color: Colors.green,
      description: 'Discuss climate change, conservation, and environmental sustainability in Africa',
    ),
    ForumCategory(
      id: 'technology',
      name: 'Technology & Innovation',
      icon: Icons.lightbulb,
      color: Colors.blue,
      description: 'Share ideas on tech solutions, startups, and digital transformation',
    ),
    ForumCategory(
      id: 'health',
      name: 'Health & Medicine',
      icon: Icons.medical_services,
      color: Colors.red,
      description: 'Discuss healthcare challenges, medical research, and public health initiatives',
    ),
    ForumCategory(
      id: 'infrastructure',
      name: 'Infrastructure & Development',
      icon: Icons.construction,
      color: Colors.orange,
      description: 'Explore infrastructure projects, urban planning, and sustainable development',
    ),
    ForumCategory(
      id: 'agriculture',
      name: 'Agriculture & Food Security',
      icon: Icons.agriculture,
      color: Colors.brown,
      description: 'Discuss farming innovations, food systems, and agricultural technology',
    ),
    ForumCategory(
      id: 'education',
      name: 'Education & Research',
      icon: Icons.school,
      color: Colors.purple,
      description: 'Share research findings, educational initiatives, and knowledge exchange',
    ),
    ForumCategory(
      id: 'energy',
      name: 'Energy & Renewables',
      icon: Icons.bolt,
      color: Colors.amber,
      description: 'Discuss renewable energy, power solutions, and energy access in Africa',
    ),
    ForumCategory(
      id: 'global',
      name: 'Global Perspectives',
      icon: Icons.public,
      color: Colors.teal,
      description: 'Connect African innovations with global challenges and opportunities',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AfriConnect Forum'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Trending', icon: Icon(Icons.trending_up)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesView(),
          _buildTrendingView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDiscussionDialog(context),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Discussion', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCategoriesView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: category.color.withOpacity(0.2),
              radius: 28,
              child: Icon(category.icon, color: category.color, size: 28),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                category.description,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _navigateToCategory(context, category),
          ),
        );
      },
    );
  }

  Widget _buildTrendingView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forum_discussions')
          .orderBy('views', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No trending discussions yet', 'Be the first to start a conversation!');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildDiscussionCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildDiscussionCard(String id, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDiscussion(context, id, data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      (data['authorName'] ?? 'A')[0].toUpperCase(),
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['authorName'] ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _formatTimestamp(data['createdAt']),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data['category'] ?? 'General',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data['title'] ?? 'Untitled',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                data['content'] ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(Icons.visibility, '${data['views'] ?? 0}'),
                  const SizedBox(width: 16),
                  _buildStatChip(Icons.comment, '${data['replies'] ?? 0}'),
                  const SizedBox(width: 16),
                  _buildStatChip(Icons.thumb_up_outlined, '${data['likes'] ?? 0}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(count, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    final date = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Discussions'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter keywords...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement search functionality
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications coming soon!')),
    );
  }

  void _showCreateDiscussionDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateDiscussionScreen(categories: categories)),
    );
  }

  void _navigateToCategory(BuildContext context, ForumCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoryDiscussionsScreen(category: category)),
    );
  }

  void _navigateToDiscussion(BuildContext context, String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DiscussionDetailScreen(discussionId: id, data: data)),
    );
  }
}

// Forum Category Model
class ForumCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  ForumCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

// Placeholder screens - to be implemented in separate files
class CreateDiscussionScreen extends StatelessWidget {
  final List<ForumCategory> categories;
  const CreateDiscussionScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Discussion')),
      body: const Center(child: Text('Create Discussion Form')),
    );
  }
}

class CategoryDiscussionsScreen extends StatelessWidget {
  final ForumCategory category;
  const CategoryDiscussionsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Center(child: Text('Discussions in ${category.name}')),
    );
  }
}

class DiscussionDetailScreen extends StatelessWidget {
  final String discussionId;
  final Map<String, dynamic> data;
  const DiscussionDetailScreen({super.key, required this.discussionId, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data['title'] ?? 'Discussion')),
      body: const Center(child: Text('Discussion Details')),
    );
  }
}
