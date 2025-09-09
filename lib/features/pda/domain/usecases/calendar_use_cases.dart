import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:hushh_user_app/core/usecases/usecase.dart';
import 'package:hushh_user_app/features/pda/domain/entities/calendar_event.dart';
import 'package:hushh_user_app/features/pda/domain/repositories/calendar_repository.dart';

// Use case for getting all calendar events
class GetCalendarEventsUseCase implements UseCase<List<CalendarEvent>, String> {
  final CalendarRepository repository;

  GetCalendarEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(String userId) async {
    try {
      final events = await repository.getCalendarEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Use case for getting upcoming events
class GetUpcomingEventsUseCase implements UseCase<List<CalendarEvent>, String> {
  final CalendarRepository repository;

  GetUpcomingEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(String userId) async {
    try {
      final events = await repository.getUpcomingEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Use case for getting events in date range
class GetEventsInRangeUseCase
    implements UseCase<List<CalendarEvent>, GetEventsInRangeParams> {
  final CalendarRepository repository;

  GetEventsInRangeUseCase(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(
    GetEventsInRangeParams params,
  ) async {
    try {
      final events = await repository.getEventsInRange(
        params.userId,
        params.startDate,
        params.endDate,
      );
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class GetEventsInRangeParams extends Equatable {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const GetEventsInRangeParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

// Use case for getting today's events
class GetTodayEventsUseCase implements UseCase<List<CalendarEvent>, String> {
  final CalendarRepository repository;

  GetTodayEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(String userId) async {
    try {
      final events = await repository.getTodayEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Use case for getting events for a specific date
class GetEventsForDateUseCase
    implements UseCase<List<CalendarEvent>, GetEventsForDateParams> {
  final CalendarRepository repository;

  GetEventsForDateUseCase(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(
    GetEventsForDateParams params,
  ) async {
    try {
      final events = await repository.getEventsForDate(
        params.userId,
        params.date,
      );
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class GetEventsForDateParams extends Equatable {
  final String userId;
  final DateTime date;

  const GetEventsForDateParams({required this.userId, required this.date});

  @override
  List<Object?> get props => [userId, date];
}

// Use case for checking calendar connection status
class IsCalendarConnectedUseCase implements UseCase<bool, String> {
  final CalendarRepository repository;

  IsCalendarConnectedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String userId) async {
    try {
      final isConnected = await repository.isCalendarConnected(userId);
      return Right(isConnected);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Use case for refreshing calendar data
class RefreshCalendarDataUseCase implements UseCase<void, String> {
  final CalendarRepository repository;

  RefreshCalendarDataUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String userId) async {
    try {
      await repository.refreshCalendarData(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
