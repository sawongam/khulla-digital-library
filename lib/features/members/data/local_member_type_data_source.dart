// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/members/data/mappers/member_type_row_mappers.dart';
import 'package:khulla/features/members/data/member_type_local_data_source.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';

/// Drift-backed [MemberTypeLocalDataSource].
@LazySingleton(as: MemberTypeLocalDataSource)
class LocalMemberTypeDataSource implements MemberTypeLocalDataSource {
  LocalMemberTypeDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalMemberTypeDataSource';

  @override
  Future<int> countMemberTypes() => guardDatabase(
    () {
      final count = _db.memberTypes.id.count();
      return (_db.selectOnly(
        _db.memberTypes,
      )..addColumns([count])).getSingle().then((row) => row.read(count) ?? 0);
    },
    source: '$_source.countMemberTypes',
  );

  @override
  Future<List<MemberType>> findActiveMemberTypes() => guardDatabase(
    () async {
      final rows =
          await (_db.select(_db.memberTypes)
                ..where((type) => type.archivedAt.isNull())
                ..orderBy([
                  (type) => OrderingTerm(expression: type.sortOrder),
                ]))
              .get();
      return rows.map((row) => row.toDomain()).toList();
    },
    source: '$_source.findActiveMemberTypes',
  );

  @override
  Future<List<MemberType>> findAllMemberTypes() => guardDatabase(
    () async {
      final rows = await (_db.select(
        _db.memberTypes,
      )..orderBy([(type) => OrderingTerm(expression: type.sortOrder)])).get();
      return rows.map((row) => row.toDomain()).toList();
    },
    source: '$_source.findAllMemberTypes',
  );

  @override
  Future<MemberType?> findMemberTypeById(String id) => guardDatabase(
    () async {
      final row = await (_db.select(
        _db.memberTypes,
      )..where((type) => type.id.equals(id))).getSingleOrNull();
      return row?.toDomain();
    },
    source: '$_source.findMemberTypeById',
  );

  @override
  Future<MemberType> insertMemberType(MemberType type) => guardDatabase(
    () async {
      await _db.into(_db.memberTypes).insert(type.toCompanion());
      return type;
    },
    source: '$_source.insertMemberType',
  );

  @override
  Future<MemberType> updateMemberType(MemberType type) => guardDatabase(
    () async {
      await _db.update(_db.memberTypes).replace(type.toCompanion());
      return type;
    },
    source: '$_source.updateMemberType',
  );

  @override
  Future<void> archiveMemberType(String id) => guardDatabase(
    () =>
        (_db.update(
          _db.memberTypes,
        )..where((type) => type.id.equals(id))).write(
          MemberTypesCompanion(archivedAt: Value(DateTime.now())),
        ),
    source: '$_source.archiveMemberType',
  );

  @override
  Future<void> unarchiveMemberType(String id) => guardDatabase(
    () =>
        (_db.update(
          _db.memberTypes,
        )..where((type) => type.id.equals(id))).write(
          const MemberTypesCompanion(archivedAt: Value(null)),
        ),
    source: '$_source.unarchiveMemberType',
  );
}
