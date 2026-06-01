import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/known_persons/detections/data/known_person_detections_repository.dart';
import 'package:smartguard_flutter/features/known_persons/detections/model/known_person_detection_image.dart';

class KnownPersonDetectionsViewModel extends ChangeNotifier {
  KnownPersonDetectionsViewModel({
    required KnownPersonDetectionsRepository repository,
    required String personId,
  }) : _repository = repository,
       _personId = personId;

  final KnownPersonDetectionsRepository _repository;
  final String _personId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<KnownPersonDetectionImage> _items = const [];
  List<KnownPersonDetectionImage> get items => _items;

  int _page = 1;
  final int _pageSize = 50;
  int _totalCount = 0;
  bool _hasMore = false;

  int get page => _page;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    _page = 1;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final paged = await _repository.list(
        personId: _personId,
        page: _page,
        pageSize: _pageSize,
      );
      _items = paged.result;
      _totalCount = paged.count;
      _hasMore = _items.length < _totalCount;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();
    try {
      _page++;
      final paged = await _repository.list(
        personId: _personId,
        page: _page,
        pageSize: _pageSize,
      );
      _items = [..._items, ...paged.result];
      _totalCount = paged.count;
      _hasMore = _items.length < _totalCount;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      _page--;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

