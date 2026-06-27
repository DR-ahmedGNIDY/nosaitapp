import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/staff/domain/entities/staff_attendance_entity.dart';
import 'package:basketball_academy/features/staff/domain/entities/staff_entity.dart';
import 'package:basketball_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffState {
  final List<StaffEntity> staff;
  final int total;
  final String? search;

  const StaffState({this.staff = const [], this.total = 0, this.search});

  StaffState copyWith({List<StaffEntity>? staff, int? total, String? search}) => StaffState(
        staff: staff ?? this.staff,
        total: total ?? this.total,
        search: search ?? this.search,
      );
}

class StaffNotifier extends AsyncNotifier<StaffState> {
  StaffRepository get _repo => sl<StaffRepository>();

  @override
  Future<StaffState> build() async => const StaffState();

  Future<void> load({String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getStaff(search: search, limit: 200);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (data) => StaffState(staff: data.staff, total: data.total, search: search),
      );
    });
  }

  Future<void> refresh() => load(search: state.valueOrNull?.search);

  Future<String?> createStaff({
    required String fullName,
    required String position,
    required String phone,
    String? email,
    required DateTime hireDate,
    double? baseSalary,
    required List<String> workingDays,
    required int monthlyAttendanceTarget,
    required String deductionType,
    required double deductionValue,
    String? photoPath,
  }) async {
    final result = await _repo.createStaff(
      fullName: fullName, position: position, phone: phone, email: email,
      hireDate: hireDate, baseSalary: baseSalary, workingDays: workingDays,
      monthlyAttendanceTarget: monthlyAttendanceTarget, deductionType: deductionType,
      deductionValue: deductionValue, photoPath: photoPath,
    );
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> updateStaff({
    required String id,
    String? fullName,
    String? position,
    String? phone,
    String? email,
    DateTime? hireDate,
    double? baseSalary,
    List<String>? workingDays,
    int? monthlyAttendanceTarget,
    String? deductionType,
    double? deductionValue,
    String? photoPath,
  }) async {
    final result = await _repo.updateStaff(
      id: id, fullName: fullName, position: position, phone: phone, email: email,
      hireDate: hireDate, baseSalary: baseSalary, workingDays: workingDays,
      monthlyAttendanceTarget: monthlyAttendanceTarget, deductionType: deductionType,
      deductionValue: deductionValue, photoPath: photoPath,
    );
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> deleteStaff(String id) async {
    final result = await _repo.deleteStaff(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }
}

final staffProvider = AsyncNotifierProvider<StaffNotifier, StaffState>(StaffNotifier.new);

// ---------------------------------------------------------------------------
// Staff Attendance
// ---------------------------------------------------------------------------

class StaffAttendanceNotifier extends AsyncNotifier<List<StaffAttendanceEntity>> {
  StaffRepository get _repo => sl<StaffRepository>();

  @override
  Future<List<StaffAttendanceEntity>> build() async => const [];

  Future<void> loadHistory({String? staffId, String? startDate, String? endDate}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getAttendanceHistory(staffId: staffId, startDate: startDate, endDate: endDate);
      return result.fold((failure) => throw Exception(failure.message), (data) => data);
    });
  }

  Future<String?> markAttendance({
    required String staffId,
    required String date,
    required String status,
    String? notes,
  }) async {
    final result = await _repo.markAttendance(staffId: staffId, date: date, status: status, notes: notes);
    return result.fold((failure) => failure.message, (_) => null);
  }
}

final staffAttendanceProvider =
    AsyncNotifierProvider<StaffAttendanceNotifier, List<StaffAttendanceEntity>>(StaffAttendanceNotifier.new);

class StaffAttendanceReportNotifier extends AsyncNotifier<List<StaffAttendanceReportRow>> {
  StaffRepository get _repo => sl<StaffRepository>();

  @override
  Future<List<StaffAttendanceReportRow>> build() async => const [];

  Future<void> loadReport({required String startDate, required String endDate}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getAttendanceReport(startDate: startDate, endDate: endDate);
      return result.fold((failure) => throw Exception(failure.message), (data) => data);
    });
  }
}

final staffAttendanceReportProvider =
    AsyncNotifierProvider<StaffAttendanceReportNotifier, List<StaffAttendanceReportRow>>(
        StaffAttendanceReportNotifier.new);
