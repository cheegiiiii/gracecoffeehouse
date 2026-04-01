import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_screen.dart';
import 'post_offer.dart';
import 'gaming_room_orders.dart';

class BaristaHome extends StatefulWidget {
  const BaristaHome({super.key});

  @override
  State<BaristaHome> createState() => _BaristaHomeState();
}

class _BaristaHomeState extends State<BaristaHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OrdersDashboard(),
    const GamingRoomOrders(),
    const PostOfferScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'Game Room',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Post Offer',
          ),
        ],
      ),
    );
  }
}

// ─── Orders Dashboard ────────────────────────────────────────────────────────

class OrdersDashboard extends StatefulWidget {
  const OrdersDashboard({super.key});

  @override
  State<OrdersDashboard> createState() => _OrdersDashboardState();
}

class _OrdersDashboardState extends State<OrdersDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  void _signOut() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showManualOrderDialog() {
    showDialog(context: context, builder: (_) => const ManualOrderDialog());
  }

  Widget _buildOrderCard(DocumentSnapshot order) {
    final items = List<Map<String, dynamic>>.from(order['items']);
    final status = order['status'] as String;
    final total = order['totalPrice'];
    final email = order['userEmail'] ?? 'Walk-in Customer';
    final createdAt = order['createdAt'] as Timestamp?;
    final orderType = order['orderType'] ?? 'dine-in';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor(status).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        if (orderType == 'manual')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'WALK-IN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (createdAt != null)
                          Text(
                            _formatTime(createdAt.toDate()),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['quantity']}x  ${item['name']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '₮${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₮${(total as num).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Action buttons
                if (status == 'pending')
                  _actionButton(
                    label: 'Start Preparing',
                    icon: Icons.coffee_maker,
                    color: Colors.blue,
                    onTap: () => _updateStatus(order.id, 'preparing'),
                  ),
                if (status == 'preparing')
                  _actionButton(
                    label: 'Mark as Ready ✅',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onTap: () => _updateStatus(order.id, 'ready'),
                  ),
                if (status == 'ready')
                  _actionButton(
                    label: 'Complete Order',
                    icon: Icons.done_all,
                    color: Colors.grey,
                    onTap: () => _updateStatus(order.id, 'completed'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (!snapshot.hasData) return const SizedBox();

        var docs = snapshot.data!.docs;

        if (statusFilter == 'active') {
          docs = docs
              .where(
                (d) =>
                    d['status'] == 'pending' ||
                    d['status'] == 'preparing' ||
                    d['status'] == 'ready',
              )
              .toList();
        } else {
          docs = docs.where((d) => d['status'] == 'completed').toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statusFilter == 'active'
                      ? Icons.coffee_outlined
                      : Icons.done_all,
                  size: 70,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  statusFilter == 'active'
                      ? 'No active orders right now'
                      : 'No completed orders yet',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildOrderCard(docs[index]),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Barista Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Active'),
            Tab(icon: Icon(Icons.done_all), text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualOrderDialog,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Manual Order'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOrderList('active'), _buildOrderList('completed')],
      ),
    );
  }
}

// ─── Manual Order Dialog ─────────────────────────────────────────────────────

class ManualOrderDialog extends StatefulWidget {
  const ManualOrderDialog({super.key});

  @override
  State<ManualOrderDialog> createState() => _ManualOrderDialogState();
}

class _ManualOrderDialogState extends State<ManualOrderDialog> {
  final _nameController = TextEditingController();
  final List<_ManualItem> _items = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    final snapshot = await FirebaseFirestore.instance.collection('menu').get();
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select Item'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: snapshot.docs.map((doc) {
                return ListTile(
                  leading: const Icon(Icons.coffee),
                  title: Text(doc['name']),
                  subtitle: Text('₮${doc['price']}'),
                  onTap: () {
                    setState(() {
                      final existing = _items
                          .where((e) => e.itemId == doc.id)
                          .toList();
                      if (existing.isNotEmpty) {
                        existing.first.quantity++;
                      } else {
                        _items.add(
                          _ManualItem(
                            itemId: doc.id,
                            name: doc['name'],
                            price: (doc['price'] as num).toDouble(),
                          ),
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      );
    }
  }

  double get _total => _items.fold(0, (sum, e) => sum + (e.price * e.quantity));

  Future<void> _submitOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': 'manual',
        'userEmail': _nameController.text.trim().isEmpty
            ? 'Walk-in Customer'
            : _nameController.text.trim(),
        'items': _items
            .map(
              (e) => {
                'itemId': e.itemId,
                'name': e.name,
                'price': e.price,
                'quantity': e.quantity,
              },
            )
            .toList(),
        'totalPrice': _total,
        'status': 'preparing',
        'orderType': 'manual',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual order added! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'New Manual Order',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name (optional)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              if (_items.isNotEmpty) ...[
                ..._items.map(
                  (item) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.quantity}x ${item.name}')),
                      Text(
                        '₮${(item.price * item.quantity).toStringAsFixed(0)}',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => setState(() {
                          if (item.quantity > 1) {
                            item.quantity--;
                          } else {
                            _items.remove(item);
                          }
                        }),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₮${_total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              OutlinedButton.icon(
                onPressed: _loadMenu,
                icon: const Icon(Icons.add),
                label: const Text('Add Item from Menu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Place Order'),
        ),
      ],
    );
  }
}

class _ManualItem {
  final String itemId;
  final String name;
  final double price;
  int quantity;

  _ManualItem({
    required this.itemId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}
