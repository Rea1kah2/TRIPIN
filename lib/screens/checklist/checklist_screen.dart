
import 'package:flutter/material.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> _items = [
    {'name': 'Pakaian ganti', 'done': true},
    {'name': 'Tiket perjalanan', 'done': true},
    {'name': 'Obat-obatan', 'done': true},
    {'name': 'Charger HP', 'done': false},
    {'name': 'Perlengkapan mandi', 'done': false},
  ];

  void _tambahBarang() {
    final nama = _controller.text.trim();

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nama barang terlebih dahulu!'),
        ),
      );
      return;
    }

    setState(() {
      _items.add({
        'name': nama,
        'done': false,
      });

      _controller.clear();
    });

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nama berhasil ditambahkan'),
      ),
    );
  }

  void _hapusBarang(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selesai = _items
        .where((item) => item['done'] == true)
        .length;

    final progres = _items.isEmpty
        ? 0.0
        : selesai / _items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Perjalanan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Persiapan Liburan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$selesai dari ${_items.length} barang sudah siap',
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progres,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _tambahBarang(),
                    decoration: const InputDecoration(
                      hintText: 'Masukkan nama barang',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _tambahBarang,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Barang yang perlu dibawa',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _items.isEmpty
                  ? const Center(
                child: Text('Belum ada barang.'),
              )
                  : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Card(
                    child: CheckboxListTile(
                      value: item['done'] as bool,
                      title: Text(
                        item['name'] as String,
                        style: TextStyle(
                          decoration:
                          item['done'] == true
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      secondary: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          _hapusBarang(index);
                        },
                      ),
                      onChanged: (value) {
                        setState(() {
                          item['done'] = value ?? false;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
