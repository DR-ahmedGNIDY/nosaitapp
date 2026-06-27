import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/expenses/domain/entities/expense_entity.dart';
import 'package:basketball_academy/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesState {
  final List<ExpenseEntity> expenses;
  final int total;
  final String? categoryFilter;
  final String? startDate;
  final String? endDate;

  const ExpensesState({this.expenses = const [], this.total = 0, this.categoryFilter, this.startDate, this.endDate});
}

class ExpensesNotifier extends AsyncNotifier<ExpensesState> {
  ExpenseRepository get _repo => sl<ExpenseRepository>();

  @override
  Future<ExpensesState> build() async => const ExpensesState();

  Future<void> load({String? category, String? startDate, String? endDate}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getExpenses(category: category, startDate: startDate, endDate: endDate, limit: 200);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (data) => ExpensesState(expenses: data.expenses, total: data.total, categoryFilter: category, startDate: startDate, endDate: endDate),
      );
    });
  }

  Future<void> refresh() async {
    final s = state.valueOrNull;
    await load(category: s?.categoryFilter, startDate: s?.startDate, endDate: s?.endDate);
  }

  Future<String?> createExpense({required String name, String? description, required double amount, required String date, required String category}) async {
    final result = await _repo.createExpense(name: name, description: description, amount: amount, date: date, category: category);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> updateExpense({required String id, String? name, String? description, double? amount, String? date, String? category}) async {
    final result = await _repo.updateExpense(id: id, name: name, description: description, amount: amount, date: date, category: category);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> deleteExpense(String id) async {
    final result = await _repo.deleteExpense(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, ExpensesState>(ExpensesNotifier.new);

class ExpenseReportNotifier extends AsyncNotifier<ExpenseReportData?> {
  ExpenseRepository get _repo => sl<ExpenseRepository>();

  @override
  Future<ExpenseReportData?> build() async => null;

  Future<void> load({required String startDate, required String endDate}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getReport(startDate: startDate, endDate: endDate);
      return result.fold((failure) => throw Exception(failure.message), (data) => data);
    });
  }
}

final expenseReportProvider = AsyncNotifierProvider<ExpenseReportNotifier, ExpenseReportData?>(ExpenseReportNotifier.new);
