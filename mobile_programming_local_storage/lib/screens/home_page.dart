
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../models/mahasiswa.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _prodiController = TextEditingController();
  final _noteController = TextEditingController();

  List<Mahasiswa> _items = [];

  int? _editingId;
  bool _loading = true;
  String _savedNote = '';

  @override
  void initState() {
    super.initState();
    _loadMahasiswa();
    _loadNote();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _prodiController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // READ SQLITE
  Future<void> _loadMahasiswa() async {
    try {
      final data =
          await DatabaseHelper.instance.getAllMahasiswa();

      if (!mounted) return;

      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Gagal membaca database: $e');
    }
  }

  // CREATE DAN UPDATE
  Future<void> _saveMahasiswa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mahasiswa = Mahasiswa(
      id: _editingId,
      nama: _namaController.text.trim(),
      nim: _nimController.text.trim(),
      programStudi: _prodiController.text.trim(),
    );

    try {
      if (_editingId == null) {
        await DatabaseHelper.instance
            .insertMahasiswa(mahasiswa);

        _message('Data berhasil ditambahkan.');
      } else {
        await DatabaseHelper.instance
            .updateMahasiswa(mahasiswa);

        _message('Data berhasil diperbarui.');
      }

      _clearForm();
      await _loadMahasiswa();
    } catch (e) {
      _message('Gagal menyimpan data. Periksa NIM. $e');
    }
  }

  // EDIT DATA
  void _edit(Mahasiswa item) {
    setState(() {
      _editingId = item.id;
      _namaController.text = item.nama;
      _nimController.text = item.nim;
      _prodiController.text = item.programStudi;
    });
  }

  // DELETE DATA
  Future<void> _delete(Mahasiswa item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data?'),
        content: Text('Data ${item.nama} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || item.id == null) return;

    await DatabaseHelper.instance.deleteMahasiswa(item.id!);

    if (_editingId == item.id) {
      _clearForm();
    }

    await _loadMahasiswa();
    _message('Data berhasil dihapus.');
  }

  // RESET FORM
  void _clearForm() {
    _formKey.currentState?.reset();

    _namaController.clear();
    _nimController.clear();
    _prodiController.clear();

    setState(() {
      _editingId = null;
    });
  }

  // SHARED PREFERENCES READ
  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();

    final note = prefs.getString('catatan_pengguna') ?? '';

    if (!mounted) return;

    setState(() {
      _savedNote = note;
      _noteController.text = note;
    });
  }

  // SHARED PREFERENCES SAVE
  Future<void> _saveNote() async {
    final prefs = await SharedPreferences.getInstance();

    final note = _noteController.text.trim();

    await prefs.setString('catatan_pengguna', note);

    if (!mounted) return;

    setState(() {
      _savedNote = note;
    });

    _message('Catatan berhasil disimpan.');
  }

  // SHARED PREFERENCES DELETE
  Future<void> _deleteNote() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('catatan_pengguna');

    if (!mounted) return;

    _noteController.clear();

    setState(() {
      _savedNote = '';
    });

    _message('Catatan berhasil dihapus.');
  }

  // SNACKBAR
  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // INPUT FORM
  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label wajib diisi';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Storage Mahasiswa'),
        backgroundColor:
            Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FORM MAHASISWA
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingId == null
                          ? 'Form Mahasiswa'
                          : 'Edit Mahasiswa',
                      style:
                          Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    _field(
                      _namaController,
                      'Nama',
                      Icons.person_outline,
                    ),

                    _field(
                      _nimController,
                      'NIM',
                      Icons.badge_outlined,
                    ),

                    _field(
                      _prodiController,
                      'Program Studi',
                      Icons.school_outlined,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saveMahasiswa,
                            icon: Icon(
                              _editingId == null
                                  ? Icons.add
                                  : Icons.save,
                            ),
                            label: Text(
                              _editingId == null
                                  ? 'Simpan'
                                  : 'Update',
                            ),
                          ),
                        ),
                        if (_editingId != null) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _clearForm,
                            child: const Text('Batal'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // DAFTAR MAHASISWA
          Text(
            'Data Mahasiswa - SQLite',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada data mahasiswa.'),
              ),
            )
          else
            ..._items.map(
              (item) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      item.nama.substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text(item.nama),
                  subtitle: Text(
                    'NIM: ${item.nim}\n'
                    'Program Studi: ${item.programStudi}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _edit(item);
                      }

                      if (value == 'delete') {
                        _delete(item);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 18),

          // SHARED PREFERENCES
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alternatif: SharedPreferences',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Simpan catatan sederhana secara lokal '
                    'dengan metode key-value.',
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan singkat',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _saveNote,
                        child: const Text('Simpan Catatan'),
                      ),
                      OutlinedButton(
                        onPressed: _deleteNote,
                        child: const Text('Hapus Catatan'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Tersimpan: '
                    '${_savedNote.isEmpty ? "(kosong)" : _savedNote}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
