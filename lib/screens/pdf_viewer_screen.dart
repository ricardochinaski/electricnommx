import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nom_electrica_mx/app_state.dart';
import 'package:nom_electrica_mx/services/user_service.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:path_provider/path_provider.dart';
class PDFViewerPage extends StatefulWidget {
  final String title;
  final String assetPath;
  final int? initialPage;

  const PDFViewerPage({
    super.key,
    required this.title,
    required this.assetPath,
    this.initialPage,
  });

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();
  late PdfTextSearchResult _searchResult;

  bool _showSearch = false;
  bool _isDarkModePdf = false;
  late int _currentPage;

  final TextEditingController _searchTextController = TextEditingController();
  String _lastSearchText = '';

  // Variables para persistencia de subrayados/resaltados
  File? _localPdfFile;
  bool _isLoadingPdf = true;

  // Entrada de overlay para menú flotante de selección
  OverlayEntry? _selectionOverlayEntry;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ?? 1;
    _searchResult = PdfTextSearchResult();
    _checkLocalPdf();
  }

  @override
  void dispose() {
    _selectionOverlayEntry?.remove();
    _selectionOverlayEntry = null;
    _searchResult.clear();
    _searchResult.removeListener(_onSearchResultUpdated);
    _searchTextController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<File> _getLocalPdfFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final cleanName = widget.assetPath.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    return File('${directory.path}/$cleanName');
  }

  Future<void> _checkLocalPdf() async {
    try {
      final file = await _getLocalPdfFile();
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localPdfFile = file;
            _isLoadingPdf = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _localPdfFile = null;
            _isLoadingPdf = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking local pdf: $e");
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
        });
      }
    }
  }

  Future<void> _saveDocument() async {
    try {
      final localFile = await _getLocalPdfFile();
      final bytes = await _pdfViewerController.saveDocument();
      await localFile.writeAsBytes(bytes);
      if (_localPdfFile == null) {
        setState(() {
          _localPdfFile = localFile;
        });
      }
    } catch (e) {
      debugPrint("Error saving pdf with annotations: $e");
    }
  }

  void _handleTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    if (_selectionOverlayEntry != null) {
      _selectionOverlayEntry!.remove();
      _selectionOverlayEntry = null;
    }

    if (details.selectedText != null && details.globalSelectedRegion != null) {
      final OverlayState overlayState = Overlay.of(context);
      _selectionOverlayEntry = OverlayEntry(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final double screenWidth = MediaQuery.of(context).size.width;
          const double menuWidth = 260.0;
          const double menuHeight = 50.0;
          
          double left = details.globalSelectedRegion!.left + (details.globalSelectedRegion!.width - menuWidth) / 2;
          if (left < 10) left = 10;
          if (left + menuWidth > screenWidth - 10) {
            left = screenWidth - menuWidth - 10;
          }
          
          double top = details.globalSelectedRegion!.top - menuHeight - 10;
          if (top < MediaQuery.of(context).padding.top + 60) {
            top = details.globalSelectedRegion!.bottom + 10;
          }

          return Positioned(
            left: left,
            top: top,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(30),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Container(
                width: menuWidth,
                height: menuHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.border_color, color: Colors.amber, size: 20),
                      tooltip: 'Resaltar',
                      onPressed: () {
                        _aplicarResaltado();
                        _clearSelectionAndOverlay();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underlined, color: Colors.blueAccent, size: 20),
                      tooltip: 'Subrayar',
                      onPressed: () {
                        _aplicarSubrayado();
                        _clearSelectionAndOverlay();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 20),
                      tooltip: 'Copiar',
                      onPressed: () {
                        if (details.selectedText != null) {
                          Clipboard.setData(ClipboardData(text: details.selectedText!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Texto copiado al portapapeles.'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                        _clearSelectionAndOverlay();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                      tooltip: 'Cerrar',
                      onPressed: () {
                        _clearSelectionAndOverlay();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      overlayState.insert(_selectionOverlayEntry!);
    }
  }

  void _clearSelectionAndOverlay() {
    _pdfViewerController.clearSelection();
    if (_selectionOverlayEntry != null) {
      _selectionOverlayEntry!.remove();
      _selectionOverlayEntry = null;
    }
  }

  void _aplicarResaltado() {
    final List<PdfTextLine>? textLines = _pdfViewerKey.currentState?.getSelectedTextLines();
    if (textLines != null && textLines.isNotEmpty) {
      final highlight = HighlightAnnotation(
        textBoundsCollection: textLines,
      );
      highlight.color = Colors.yellow.withAlpha(100);
      _pdfViewerController.addAnnotation(highlight);
      _saveDocument();
    }
  }

  void _aplicarSubrayado() {
    final List<PdfTextLine>? textLines = _pdfViewerKey.currentState?.getSelectedTextLines();
    if (textLines != null && textLines.isNotEmpty) {
      final underline = UnderlineAnnotation(
        textBoundsCollection: textLines,
      );
      underline.color = Colors.blue.withAlpha(150);
      _pdfViewerController.addAnnotation(underline);
      _saveDocument();
    }
  }

  void _handleAnnotationSelected(Annotation annotation) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Eliminar Subrayado',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            '¿Deseas eliminar este subrayado o resaltado de texto?',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                _pdfViewerController.removeAnnotation(annotation);
                await _saveDocument();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Marcación eliminada con éxito.'),
                      backgroundColor: Colors.red.shade900,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: const Text('ELIMINAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _onSearchResultUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleNightMode() {
    setState(() => _isDarkModePdf = !_isDarkModePdf);
  }

  Future<void> _intentarGuardarMarcador(BuildContext context) async {
    final isPremium = context.read<PremiumProvider>().isPremium;
    final lista = globalBookmarksNotifier.value;

    if (isPremium || lista.isEmpty) {
      _mostrarDialogoGuardarMarcador(context);
    } else {
      _mostrarDialogoRecompensa(context);
    }
  }

  void _mostrarDialogoRecompensa(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(180),
      builder: (ctx) {
        bool isLoadingAd = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2035).withAlpha(245),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B82F6).withAlpha(80), width: 1.2),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 30, spreadRadius: 4)],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Límite de Marcadores Gratuito',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Has alcanzado el límite de 1 marcador en la versión gratuita. ¿Deseas ver un video corto para desbloquear un espacio de marcador adicional y guardar este elemento?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoadingAd ? null : () => Navigator.pop(ctx),
                          child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isLoadingAd
                              ? null
                              : () {
                                  setState(() {
                                    isLoadingAd = true;
                                  });
                                  AdService.instance.showRewardedAd(
                                    onRewardEarned: () {
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _guardarMarcadorInmediato(context);
                                    },
                                    onAdClosed: () {
                                      if (ctx.mounted && Navigator.canPop(ctx)) {
                                        Navigator.pop(ctx);
                                      }
                                    },
                                    onAdNotReady: () {
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('El anuncio no estaba listo. Marcador guardado de todos modos.'),
                                            backgroundColor: Colors.orange,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                        _guardarMarcadorInmediato(context);
                                      }
                                    },
                                  );
                                },
                          child: isLoadingAd
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('VER VIDEO', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _guardarMarcadorInmediato(BuildContext context) async {
    final pageForBookmark = _currentPage;
    final nombre = 'Página $pageForBookmark en ${widget.title}';
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('bookmarks') ?? [];
    final entry = '$nombre|$pageForBookmark|${widget.assetPath}';
    
    if (!lista.contains(entry)) {
      lista.add(entry);
      await prefs.setStringList('bookmarks', lista);
      globalBookmarksNotifier.value = List.from(lista);
      bool isOffline = false;
      try {
        await UserService().syncBookmarks(lista);
      } catch (e) {
        if (e is TimeoutException) {
          isOffline = true;
        } else {
          debugPrint('Error syncing bookmarks: $e');
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOffline ? 'Guardado localmente.' : 'Marcador guardado con éxito.'),
            backgroundColor: const Color(0xFF1E3A5F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Este marcador ya estaba guardado.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _mostrarDialogoGuardarMarcador(BuildContext context) {
    final pageForBookmark = _currentPage;
    final nameController = TextEditingController(
      text: 'Página $pageForBookmark en ${widget.title}',
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (ctx) => Theme(
        data: ThemeData.dark().copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF0F172A),
          ),
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2035).withAlpha(245),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3B82F6).withAlpha(80),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bookmark_add_rounded,
                          color: Color(0xFF60A5FA),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Guardar Marcador',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Página actual: $pageForBookmark',
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 1,
                    decoration: InputDecoration(
                      labelText: 'Nombre del marcador',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      hintText: 'Escribe un nombre...',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF3B82F6).withAlpha(80),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF3B82F6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final nombre = nameController.text.trim();
                          if (nombre.isEmpty) return;
                          final prefs = await SharedPreferences.getInstance();
                          final lista = prefs.getStringList('bookmarks') ?? [];
                          final entry = '$nombre|$pageForBookmark|${widget.assetPath}';
                          if (!lista.contains(entry)) {
                            lista.add(entry);
                            await prefs.setStringList('bookmarks', lista);
                            globalBookmarksNotifier.value = List.from(lista);
                            bool isOffline = false;
                            try {
                              await UserService().syncBookmarks(lista);
                            } catch (e) {
                              if (e is TimeoutException) {
                                isOffline = true;
                              } else {
                                debugPrint('Error syncing bookmarks: $e');
                              }
                            }
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isOffline ? 'Guardado localmente.' : 'Marcador guardado.'),
                                  backgroundColor: const Color(0xFF1E3A5F),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          } else {
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          elevation: 4,
                          shadowColor: const Color(0xFF3B82F6).withAlpha(120),
                        ),
                        child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() => nameController.dispose());
  }

  void _onSearch() {
    final text = _searchTextController.text.trim();
    if (text.isEmpty) {
      _searchResult.clear();
      setState(() {});
      return;
    }
    
    // Ocultar teclado al buscar para que el usuario pueda ver los resultados
    FocusScope.of(context).unfocus();
    
    // Si es la misma búsqueda, saltar a la siguiente coincidencia
    if (text == _lastSearchText && _searchResult.hasResult) {
      _searchResult.nextInstance();
      return;
    }

    // Iniciar nueva búsqueda
    _lastSearchText = text;
    _searchResult.removeListener(_onSearchResultUpdated);
    
    // El método searchText de Syncfusion inicia la búsqueda asíncrona
    _searchResult = _pdfViewerController.searchText(text);
    _searchResult.addListener(_onSearchResultUpdated);
  }

  Future<void> _eliminarMarcador(BuildContext context, String entry) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('bookmarks') ?? [];
    final index = lista.indexOf(entry);
    if (index != -1) {
      lista.removeAt(index);
      await prefs.setStringList('bookmarks', lista);
      globalBookmarksNotifier.value = List.from(lista);
      try {
        await UserService().syncBookmarks(lista);
      } catch (e) {
        debugPrint('Error syncing bookmarks: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Marcador eliminado.'),
            action: SnackBarAction(
              label: 'DESHACER',
              textColor: Colors.amber,
              onPressed: () async {
                final newLista = prefs.getStringList('bookmarks') ?? [];
                if (!newLista.contains(entry)) {
                  newLista.insert(index < newLista.length ? index : newLista.length, entry);
                  await prefs.setStringList('bookmarks', newLista);
                  globalBookmarksNotifier.value = List.from(newLista);
                  try {
                    await UserService().syncBookmarks(newLista);
                  } catch (e) {
                    debugPrint('Error syncing bookmarks: $e');
                  }
                }
              },
            ),
            backgroundColor: const Color(0xFF1E3A5F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _mostrarListaMarcadores(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2035).withAlpha(245),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: const Color(0xFF3B82F6).withAlpha(80)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Mis Marcadores',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: globalBookmarksNotifier,
                builder: (context, bookmarks, _) {
                  final localBookmarks = bookmarks
                      .where((b) => b.contains(widget.assetPath))
                      .toList();
                      
                  if (localBookmarks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay marcadores en este documento',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: localBookmarks.length,
                    itemBuilder: (ctx, i) {
                      final parts = localBookmarks[i].split('|');
                      if (parts.length < 3) return const SizedBox.shrink();
                      final nombre = parts[0];
                      final page = int.tryParse(parts[1]) ?? 1;
                      return ListTile(
                        leading: const Icon(
                          Icons.bookmark_rounded,
                          color: Color(0xFF3B82F6),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Página $page',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx); // Cierra el bottom sheet antes de mostrar el SnackBar
                            _eliminarMarcador(context, localBookmarks[i]);
                          },
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pdfViewerController.jumpToPage(page);
                        },
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

  /// Muestra un intersticial y después ejecuta Navigator.pop.
  void _exitWithAd() {
    AdService.instance.showInterstitial(
      context,
      onDismissed: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exitWithAd();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchTextController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar en el pliego...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white70),
                    onPressed: _onSearch,
                  ),
                ),
                onSubmitted: (_) => _onSearch(),
              )
            : Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          if (_showSearch)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              onPressed: () {
                if (_searchResult.hasResult) {
                  _searchResult.previousInstance();
                  setState(() {});
                }
              },
            ),
          if (_showSearch)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onPressed: () {
                if (_searchResult.hasResult) {
                  _searchResult.nextInstance();
                  setState(() {});
                }
              },
            ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchTextController.clear();
                  _searchResult.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_isDarkModePdf ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleNightMode,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: () => _intentarGuardarMarcador(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () => _mostrarListaMarcadores(context),
          ),
        ],
      ),
      body: _isLoadingPdf
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
              ),
            )
          : ColorFiltered(
              colorFilter: _isDarkModePdf
                  ? const ColorFilter.matrix([
                      -1.0, 0.0, 0.0, 0.0, 255.0,
                      0.0, -1.0, 0.0, 0.0, 255.0,
                      0.0, 0.0, -1.0, 0.0, 255.0,
                      0.0, 0.0, 0.0, 1.0, 0.0,
                    ])
                  : const ColorFilter.matrix([
                      1.0, 0.0, 0.0, 0.0, 0.0,
                      0.0, 1.0, 0.0, 0.0, 0.0,
                      0.0, 0.0, 1.0, 0.0, 0.0,
                      0.0, 0.0, 0.0, 1.0, 0.0,
                    ]),
              child: _localPdfFile != null
                  ? SfPdfViewer.file(
                      _localPdfFile!,
                      key: _pdfViewerKey,
                      controller: _pdfViewerController,
                      initialPageNumber: _currentPage,
                      canShowTextSelectionMenu: false,
                      onTextSelectionChanged: _handleTextSelectionChanged,
                      onAnnotationSelected: _handleAnnotationSelected,
                      onPageChanged: (details) {
                        _currentPage = details.newPageNumber;
                      },
                      currentSearchTextHighlightColor: Colors.yellow.withAlpha(150),
                      otherSearchTextHighlightColor: Colors.yellow.withAlpha(80),
                    )
                  : SfPdfViewer.asset(
                      widget.assetPath,
                      key: _pdfViewerKey,
                      controller: _pdfViewerController,
                      initialPageNumber: _currentPage,
                      canShowTextSelectionMenu: false,
                      onTextSelectionChanged: _handleTextSelectionChanged,
                      onAnnotationSelected: _handleAnnotationSelected,
                      onPageChanged: (details) {
                        _currentPage = details.newPageNumber;
                      },
                      currentSearchTextHighlightColor: Colors.yellow.withAlpha(150),
                      otherSearchTextHighlightColor: Colors.yellow.withAlpha(80),
                    ),
            ),
    ),
    );
  }
}
