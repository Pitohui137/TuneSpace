import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/studio.dart';
import '../../services/studio_service.dart';

class AdminStudioFormScreen extends StatefulWidget {
  const AdminStudioFormScreen({super.key, this.studio});

  final Studio? studio;

  @override
  State<AdminStudioFormScreen> createState() => _AdminStudioFormScreenState();
}

class _AdminStudioFormScreenState extends State<AdminStudioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studioService = StudioService(Supabase.instance.client);

  late final TextEditingController _namaController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _fasilitasController;
  late final TextEditingController _hargaController;
  late final TextEditingController _fotoController;

  bool _isSubmitting = false;
  bool get _isEdit => widget.studio != null;

  @override
  void initState() {
    super.initState();
    final s = widget.studio;
    _namaController = TextEditingController(text: s?.namaStudio ?? '');
    _deskripsiController = TextEditingController(text: s?.deskripsi ?? '');
    _fasilitasController = TextEditingController(text: s?.fasilitas ?? '');
    _hargaController = TextEditingController(
      text: s != null ? s.hargaPerJam.toInt().toString() : '',
    );
    _fotoController = TextEditingController(text: s?.fotoUrl ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _fasilitasController.dispose();
    _hargaController.dispose();
    _fotoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final studio = Studio(
        id: widget.studio?.id ?? '',
        namaStudio: _namaController.text.trim(),
        deskripsi: _deskripsiController.text.trim().isEmpty
            ? null
            : _deskripsiController.text.trim(),
        fasilitas: _fasilitasController.text.trim().isEmpty
            ? null
            : _fasilitasController.text.trim(),
        hargaPerJam: double.parse(_hargaController.text.trim()),
        fotoUrl: _fotoController.text.trim().isEmpty
            ? null
            : _fotoController.text.trim(),
        createdAt: widget.studio?.createdAt ?? DateTime.now(),
      );

      if (_isEdit) {
        await _studioService.updateStudio(widget.studio!.id, studio);
      } else {
        await _studioService.createStudio(studio);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Studio diperbarui.' : 'Studio ditambahkan.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Studio' : 'Tambah Studio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Studio'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fasilitasController,
                decoration: const InputDecoration(labelText: 'Fasilitas'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga per Jam (Rp)',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Harga wajib diisi';
                  if (int.tryParse(v) == null) return 'Harga tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fotoController,
                decoration: const InputDecoration(
                  labelText: 'URL Foto (opsional)',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Studio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
