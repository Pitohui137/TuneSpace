import 'package:file_picker/file_picker.dart';
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
  Uint8List? _pickedPhotoBytes;
  String? _pickedPhotoName;
  final List<_GalleryPhotoDraft> _galleryDrafts = [];
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
    if (s != null) {
      for (final photo in s.gallery) {
        _galleryDrafts.add(
          _GalleryPhotoDraft(
            fileName: 'existing-${photo.id}',
            existingUrl: photo.photoUrl,
          ),
        );
      }
    }
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
      var photoUrl = _fotoController.text.trim().isEmpty
          ? null
          : _fotoController.text.trim();

      if (_pickedPhotoBytes != null && _pickedPhotoName != null) {
        photoUrl = await _studioService.uploadStudioPhoto(
          fileName: _pickedPhotoName!,
          bytes: _pickedPhotoBytes!,
        );
      }

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
        fotoUrl: photoUrl,
        createdAt: widget.studio?.createdAt ?? DateTime.now(),
      );

      final savedStudio = _isEdit
          ? studio
          : await _studioService.createStudio(studio);

      if (_isEdit) {
        await _studioService.updateStudio(widget.studio!.id, studio);
      }

      final targetStudioId = _isEdit ? widget.studio!.id : savedStudio.id;
      final galleryUrls = <String>[];
      for (final draft in _galleryDrafts) {
        if (draft.existingUrl != null) {
          galleryUrls.add(draft.existingUrl!);
          continue;
        }
        if (draft.bytes != null) {
          final uploadedUrl = await _studioService.uploadStudioPhoto(
            fileName: draft.fileName,
            bytes: draft.bytes!,
          );
          galleryUrls.add(uploadedUrl);
        }
      }
      await _studioService.replaceStudioGallery(
        studioId: targetStudioId,
        photoUrls: galleryUrls,
      );

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

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _pickedPhotoBytes = result.files.single.bytes;
      _pickedPhotoName = result.files.single.name;
      _fotoController.text = '';
    });
  }

  Future<void> _pickGalleryPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );

    if (result == null) return;

    final newDrafts = result.files
        .where((file) => file.bytes != null)
        .map(
          (file) => _GalleryPhotoDraft(
            fileName: file.name,
            bytes: file.bytes,
          ),
        )
        .toList();

    if (newDrafts.isEmpty) return;

    setState(() {
      _galleryDrafts.addAll(newDrafts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _fotoController.text.trim().isEmpty
        ? widget.studio?.fotoUrl
        : _fotoController.text.trim();

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
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.grey.shade100,
                  image: _pickedPhotoBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_pickedPhotoBytes!),
                          fit: BoxFit.cover,
                        )
                      : (previewUrl != null && previewUrl.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(previewUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _pickedPhotoBytes == null &&
                        (previewUrl == null || previewUrl.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera_back_outlined,
                              size: 42,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada foto ruangan studio',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickPhoto,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        _pickedPhotoName == null ? 'Upload Foto' : 'Ganti Foto',
                      ),
                    ),
                  ),
                ],
              ),
              if (_pickedPhotoName != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'File dipilih: $_pickedPhotoName',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Galeri Ruangan Studio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickGalleryPhotos,
                      icon: const Icon(Icons.collections_outlined),
                      label: const Text('Tambah Beberapa Foto'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_galleryDrafts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'Belum ada foto galeri tambahan.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _galleryDrafts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final draft = _galleryDrafts[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              width: 140,
                              height: 110,
                              child: draft.bytes != null
                                  ? Image.memory(draft.bytes!, fit: BoxFit.cover)
                                  : Image.network(
                                      draft.existingUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image_outlined),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => setState(() => _galleryDrafts.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
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
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'URL Foto (opsional, jika tidak upload file)',
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

class _GalleryPhotoDraft {
  const _GalleryPhotoDraft({
    required this.fileName,
    this.bytes,
    this.existingUrl,
  });

  final String fileName;
  final Uint8List? bytes;
  final String? existingUrl;
}
