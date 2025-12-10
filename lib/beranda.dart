import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MahasiswaService {
  static const String _prefsKey = 'mahasiswa_data';

  static Future<List<Map<String, dynamic>>> getAllMahasiswa() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? raw = prefs.getStringList(_prefsKey);
    if (raw != null) {
      return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    }
    return [];
  }

  static Future<void> saveMahasiswa(
    List<Map<String, dynamic>> mahasiswaList,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = mahasiswaList.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_prefsKey, raw);
  }

  static Future<bool> addMahasiswa(Map<String, dynamic> mahasiswa) async {
    try {
      final mahasiswaList = await getAllMahasiswa();
      mahasiswa['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      mahasiswa['createdAt'] = DateTime.now().toIso8601String();
      mahasiswaList.insert(0, mahasiswa);
      await saveMahasiswa(mahasiswaList);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateMahasiswa(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final mahasiswaList = await getAllMahasiswa();
      final index = mahasiswaList.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        updatedData['id'] = id;
        updatedData['createdAt'] =
            mahasiswaList[index]['createdAt']; // Pertahankan tgl buat
        updatedData['updatedAt'] = DateTime.now().toIso8601String();
        mahasiswaList[index] = updatedData;
        await saveMahasiswa(mahasiswaList);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteMahasiswa(String id) async {
    try {
      final mahasiswaList = await getAllMahasiswa();
      mahasiswaList.removeWhere((item) => item['id'] == id);
      await saveMahasiswa(mahasiswaList);
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool isNpmExists(
    String npm,
    List<Map<String, dynamic>> mahasiswaList, {
    String? excludeId,
  }) {
    return mahasiswaList.any(
      (item) =>
          item['npm'] == npm && (excludeId == null || item['id'] != excludeId),
    );
  }
}

class FormPage extends StatefulWidget {
  final Map<String, dynamic>? mahasiswa;
  const FormPage({super.key, this.mahasiswa});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _npmController = TextEditingController();

  final List<String> _prodiList = ['Informatika', 'Mesin', 'Sipil', 'Arsitek'];
  final List<String> _kelasList = ['A', 'B', 'C', 'D', 'E'];

  String? _selectedKelas;
  String? _selectedProdi;
  String _jenisKelamin = 'Pria';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mahasiswa != null) {
      _loadDataForEdit();
    }
  }

  void _loadDataForEdit() {
    final data = widget.mahasiswa!;
    _namaController.text = data['nama'] ?? '';
    _alamatController.text = data['alamat'] ?? '';
    _npmController.text = data['npm'] ?? '';

    final kelas = data['kelas'] as String?;
    final prodi = data['prodi'] as String?;

    if (_kelasList.contains(kelas)) _selectedKelas = kelas;
    if (_prodiList.contains(prodi)) _selectedProdi = prodi;
    _jenisKelamin = (data['jk'] as String?) ?? 'Pria';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final nama = _namaController.text.trim();
    final alamat = _alamatController.text.trim();
    final npm = _npmController.text.trim();

    final allData = await MahasiswaService.getAllMahasiswa();
    final excludeId = widget.mahasiswa?['id'];

    if (MahasiswaService.isNpmExists(npm, allData, excludeId: excludeId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NPM sudah digunakan!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final mahasiswaData = {
      'nama': nama,
      'alamat': alamat,
      'npm': npm,
      'kelas': _selectedKelas ?? '-',
      'prodi': _selectedProdi ?? '-',
      'jk': _jenisKelamin,
    };

    bool success;
    if (widget.mahasiswa != null) {
      success = await MahasiswaService.updateMahasiswa(
        widget.mahasiswa!['id'],
        mahasiswaData,
      );
    } else {
      success = await MahasiswaService.addMahasiswa(mahasiswaData);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.mahasiswa != null ? 'Data diupdate' : 'Data ditambahkan',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mahasiswa != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Mahasiswa' : 'Tambah Mahasiswa'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _npmController,
                decoration: const InputDecoration(
                  labelText: 'NPM',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'NPM wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedKelas,
                decoration: const InputDecoration(
                  labelText: 'Kelas',
                  border: OutlineInputBorder(),
                ),
                items: _kelasList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedKelas = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedProdi,
                decoration: const InputDecoration(
                  labelText: 'Program Studi',
                  border: OutlineInputBorder(),
                ),
                items: _prodiList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProdi = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Jenis Kelamin: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Radio(
                    value: 'Pria',
                    groupValue: _jenisKelamin,
                    onChanged: (v) =>
                        setState(() => _jenisKelamin = v.toString()),
                  ),
                  const Text('Pria'),
                  Radio(
                    value: 'Perempuan',
                    groupValue: _jenisKelamin,
                    onChanged: (v) =>
                        setState(() => _jenisKelamin = v.toString()),
                  ),
                  const Text('Wanita'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'UPDATE DATA' : 'SIMPAN DATA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListViewPage extends StatefulWidget {
  const ListViewPage({super.key});

  @override
  State<ListViewPage> createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {
  List<Map<String, dynamic>> _mahasiswaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await MahasiswaService.getAllMahasiswa();
    setState(() {
      _mahasiswaList = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteData(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Data'),
            content: const Text('Yakin ingin menghapus data ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await MahasiswaService.deleteMahasiswa(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data dihapus')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Mahasiswa'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mahasiswaList.isEmpty
          ? const Center(child: Text('Belum ada data mahasiswa'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _mahasiswaList.length,
              itemBuilder: (context, index) {
                final item = _mahasiswaList[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        item['nama'][0].toString().toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      item['nama'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NPM: ${item['npm']}'),
                        Text('${item['prodi']} - Kelas ${item['kelas']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FormPage(mahasiswa: item),
                              ),
                            );
                            if (result == true) _loadData();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteData(item['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormPage()),
          );
          if (result == true) _loadData();
        },
      ),
    );
  }
}

class Halaman_Utama extends StatelessWidget {
  const Halaman_Utama({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListViewPage();
  }
}
