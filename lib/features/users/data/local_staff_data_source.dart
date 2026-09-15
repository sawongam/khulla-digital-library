// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/users/data/mappers/staff_row_mappers.dart';
import 'package:khulla/features/users/data/staff_local_data_source.dart';
import 'package:khulla/features/users/domain/models/staff_credentials.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';
import 'package:uuid/uuid.dart';

/// Drift-backed [StaffLocalDataSource].
@LazySingleton(as: StaffLocalDataSource)
class LocalStaffDataSource implements StaffLocalDataSource {
  LocalStaffDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalStaffDataSource';
  static const Uuid _uuid = Uuid();

  /// Trimmed and lower-cased, so the unique index treats one address as one
  /// account however it was typed. Applied on every read and every write —
  /// normalizing on only one side is how a lookup starts missing rows.
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  @override
  Future<bool> hasAnyStaff() => guardDatabase(
    () async {
      final count = _db.staff.id.count();
      final row = await (_db.selectOnly(
        _db.staff,
      )..addColumns([count])).getSingle();
      return (row.read(count) ?? 0) > 0;
    },
    source: '$_source.hasAnyStaff',
  );

  @override
  Future<List<StaffMember>> findAllStaff() => guardDatabase(
    () async {
      final rows =
          await (_db.select(_db.staff)..orderBy([
                (staff) => OrderingTerm(expression: staff.createdAt),
              ]))
              .get();
      return rows.map((row) => row.toDomain()).toList();
    },
    source: '$_source.findAllStaff',
  );

  @override
  Future<StaffMember?> findStaffById(String id) => guardDatabase(
    () async {
      final row = await (_db.select(
        _db.staff,
      )..where((staff) => staff.id.equals(id))).getSingleOrNull();
      return row?.toDomain();
    },
    source: '$_source.findStaffById',
  );

  @override
  Future<StaffCredentials?> findCredentialsByEmail(String email) =>
      guardDatabase(
        () async {
          final row =
              await (_db.select(_db.staff)..where(
                    (staff) => staff.email.equals(normalizeEmail(email)),
                  ))
                  .getSingleOrNull();
          return row?.toCredentials();
        },
        source: '$_source.findCredentialsByEmail',
      );

  @override
  Future<bool> hasUnusedRecoveryCodes() => guardDatabase(
    () async {
      final count = _db.staffRecoveryCodes.id.count();
      final row =
          await (_db.selectOnly(_db.staffRecoveryCodes)
                ..addColumns([count])
                ..where(_db.staffRecoveryCodes.usedAt.isNull()))
              .getSingle();
      return (row.read(count) ?? 0) > 0;
    },
    source: '$_source.hasUnusedRecoveryCodes',
  );

  @override
  Future<List<StoredRecoveryCode>> findUnusedRecoveryCodes(String staffId) =>
      guardDatabase(
        () async {
          final rows =
              await (_db.select(_db.staffRecoveryCodes)..where(
                    (code) =>
                        code.staffId.equals(staffId) & code.usedAt.isNull(),
                  ))
                  .get();
          return [
            for (final row in rows)
              StoredRecoveryCode(id: row.id, codeHash: row.codeHash),
          ];
        },
        source: '$_source.findUnusedRecoveryCodes',
      );

  @override
  Future<StaffMember> insertStaff(
    StaffMember staff, {
    required String passwordHash,
    List<String> recoveryCodeHashes = const [],
  }) => guardDatabase(
    () => _db.transaction(() async {
      var normalized = staff.copyWith(email: normalizeEmail(staff.email));
      if (normalized.barcode == null || normalized.barcode!.trim().isEmpty) {
        final settings = await (_db.select(
          _db.librarySettings,
        )..where((s) => s.id.equals(1))).getSingleOrNull();
        if (settings == null) {
          normalized = normalized.copyWith(
            barcode: 'STF-${DateTime.now().millisecondsSinceEpoch}',
          );
        } else {
          final barcode =
              '${settings.staffBarcodePrefix}${settings.staffBarcodeNextValue}';
          await (_db.update(
            _db.librarySettings,
          )..where((s) => s.id.equals(1))).write(
            LibrarySettingsCompanion(
              staffBarcodeNextValue: Value(settings.staffBarcodeNextValue + 1),
              updatedAt: Value(DateTime.now()),
            ),
          );
          normalized = normalized.copyWith(barcode: barcode);
        }
      }
      await _db
          .into(_db.staff)
          .insert(normalized.toCompanion(passwordHash: passwordHash));
      final now = DateTime.now();
      for (final hash in recoveryCodeHashes) {
        await _db
            .into(_db.staffRecoveryCodes)
            .insert(
              StaffRecoveryCodesCompanion.insert(
                id: _uuid.v4(),
                staffId: normalized.id,
                codeHash: hash,
                createdAt: now,
              ),
            );
      }
      return normalized;
    }),
    source: '$_source.insertStaff',
  );

  @override
  Future<void> resetPasswordWithRecoveryCode({
    required String staffId,
    required String passwordHash,
    required String recoveryCodeId,
  }) => guardDatabase(
    () => _db.transaction(() async {
      await (_db.update(
        _db.staff,
      )..where((staff) => staff.id.equals(staffId))).write(
        StaffCompanion(passwordHash: Value(passwordHash)),
      );
      final marked =
          await (_db.update(_db.staffRecoveryCodes)..where(
                (code) =>
                    code.id.equals(recoveryCodeId) &
                    code.staffId.equals(staffId) &
                    code.usedAt.isNull(),
              ))
              .write(
                StaffRecoveryCodesCompanion(usedAt: Value(DateTime.now())),
              );
      if (marked == 0) {
        throw const ConflictException(
          'That recovery code has already been used.',
        );
      }
    }),
    source: '$_source.resetPasswordWithRecoveryCode',
  );

  @override
  Future<int> countStaffWithRoleAndStatus({
    required UserRole role,
    required UserStatus status,
  }) => guardDatabase(
    () async {
      final count = _db.staff.id.count();
      final row =
          await (_db.selectOnly(_db.staff)
                ..addColumns([count])
                ..where(
                  _db.staff.role.equalsValue(role) &
                      _db.staff.status.equalsValue(status),
                ))
              .getSingle();
      final value = row.read(count) ?? 0;
      return value;
    },
    source: '$_source.countStaffWithRoleAndStatus',
  );

  @override
  Future<StaffMember> updateStaff(StaffMember staff) => guardDatabase(
    () async {
      final normalized = staff.copyWith(email: normalizeEmail(staff.email));
      final updated =
          await (_db.update(
            _db.staff,
          )..where((row) => row.id.equals(normalized.id))).write(
            StaffCompanion(
              name: Value(normalized.name),
              email: Value(normalized.email),
              role: Value(normalized.role),
            ),
          );
      if (updated == 0) {
        throw const NotFoundException(
          'That staff account no longer exists.',
        );
      }
      return normalized;
    },
    source: '$_source.updateStaff',
  );

  @override
  Future<StaffMember> setStaffStatus({
    required String staffId,
    required UserStatus status,
  }) => guardDatabase(
    () async {
      await (_db.update(
        _db.staff,
      )..where((row) => row.id.equals(staffId))).write(
        StaffCompanion(status: Value(status)),
      );
      final row = await (_db.select(
        _db.staff,
      )..where((row) => row.id.equals(staffId))).getSingle();
      return row.toDomain();
    },
    source: '$_source.setStaffStatus',
  );

  @override
  Future<void> setPasswordHash({
    required String staffId,
    required String passwordHash,
  }) => guardDatabase(
    () =>
        (_db.update(
          _db.staff,
        )..where((row) => row.id.equals(staffId))).write(
          StaffCompanion(passwordHash: Value(passwordHash)),
        ),
    source: '$_source.setPasswordHash',
  );
}
