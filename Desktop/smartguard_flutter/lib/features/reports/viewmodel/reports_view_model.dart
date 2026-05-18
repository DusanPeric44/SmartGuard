import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';
import 'package:smartguard_flutter/features/reports/data/reports_repository.dart';
import 'package:smartguard_flutter/features/reports/model/paged_result.dart';
import 'package:smartguard_flutter/features/reports/model/report_row.dart';

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({required ReportsRepository repository})
    : _repository = repository;

  final ReportsRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PagedResult<ReportRow>? _page;
  PagedResult<ReportRow>? get page => _page;

  int _pageNum = 1;
  int _pageSize = 10;
  DateTime? _start;
  DateTime? _end;

  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  DateTime? get start => _start;
  DateTime? get end => _end;

  final Map<String, bool> _rowBusy = <String, bool>{};
  Map<String, bool> get rowBusy => Map.unmodifiable(_rowBusy);

  int _reqId = 0;

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    _reqId++;
    final current = _reqId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.list(
        page: _pageNum,
        pageSize: _pageSize,
        start: _start,
        end: _end,
      );
      if (current != _reqId) return;
      _page = res;
    } catch (e) {
      if (current != _reqId) return;
      _errorMessage = UiErrorMapper.toMessage(e);
    } finally {
      if (current == _reqId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> applyDateRange(DateTime? start, DateTime? end) async {
    _start = start;
    _end = end;
    _pageNum = 1;
    await load();
  }

  Future<void> resetFilters() async {
    _start = null;
    _end = null;
    _pageNum = 1;
    await load();
  }

  Future<void> changePage(int page) async {
    if (page < 1) return;
    _pageNum = page;
    await load();
  }

  Future<void> changePageSize(int size) async {
    _pageSize = size;
    _pageNum = 1;
    await load();
  }

  Future<bool> generate({
    required DateTime start,
    required DateTime end,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.generate(start: start, end: end);
      _pageNum = 1;
      await load();
      return true;
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> download(ReportRow row) async {
    final key = row.fileUrl;
    _rowBusy[key] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _repository.download(path: row.fileUrl);
    } catch (e) {
      _errorMessage = UiErrorMapper.toMessage(e);
      notifyListeners();
      return null;
    } finally {
      _rowBusy.remove(key);
      notifyListeners();
    }
  }
}
