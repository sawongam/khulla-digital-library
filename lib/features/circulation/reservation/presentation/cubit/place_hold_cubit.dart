// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';
import 'package:khulla/features/catalog/title/domain/title_repository.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';
import 'package:khulla/features/circulation/reservation/presentation/cubit/place_hold_state.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/features/members/domain/member_repository.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Place-hold modal: resolve member and title, then queue through circulation.
@injectable
class PlaceHoldCubit extends Cubit<PlaceHoldState> {
  PlaceHoldCubit(this._circulation, this._members, this._titles)
    : super(const PlaceHoldState());

  final CirculationRepository _circulation;
  final MemberRepository _members;
  final TitleRepository _titles;

  Timer? _memberLookupTimer;
  Timer? _titleLookupTimer;

  Future<void> load({String? titleId}) async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final fixed = titleId == null ? null : await _titles.findTitle(titleId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          fixedTitle: fixed,
          selectedTitle: fixed,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  void memberSearchChanged(String value) {
    _memberLookupTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          member: null,
          memberMatches: const [],
          memberQuery: '',
          error: null,
        ),
      );
      return;
    }
    _memberLookupTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(searchMembers(trimmed));
    });
  }

  /// Searches members without selecting: an exact card-number hit selects
  /// immediately (a scan, not typing), anything else lists matches for the
  /// desk to pick from. Never auto-selects a name search, even a single hit.
  Future<void> searchMembers(String query) async {
    emit(
      state.copyWith(
        isLookingUpMember: true,
        memberQuery: query.trim(),
        error: null,
      ),
    );
    try {
      final trimmed = query.trim();
      final exact = await _members.findMemberByBarcode(trimmed);
      if (isClosed) return;
      if (exact != null) {
        emit(
          state.copyWith(
            member: exact,
            memberMatches: const [],
            isLookingUpMember: false,
            error: null,
          ),
        );
        return;
      }
      final results = await _members.findMembers(MemberQuery(search: trimmed));
      if (isClosed) return;
      emit(
        state.copyWith(
          member: null,
          memberMatches: results.items,
          isLookingUpMember: false,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          member: null,
          memberMatches: const [],
          isLookingUpMember: false,
          error: error,
        ),
      );
    }
  }

  /// Picks one member from the search matches.
  void memberSelected(Member member) {
    emit(
      state.copyWith(
        member: member,
        memberMatches: const [],
        memberQuery: '',
        error: null,
      ),
    );
  }

  void clearMember() {
    _memberLookupTimer?.cancel();
    emit(
      state.copyWith(
        member: null,
        memberMatches: const [],
        memberQuery: '',
        error: null,
      ),
    );
  }

  void titleSearchChanged(String value) {
    if (state.fixedTitle != null) return;
    _titleLookupTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          titleMatches: const [],
          selectedTitle: null,
          error: null,
        ),
      );
      return;
    }
    _titleLookupTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_searchTitles(trimmed));
    });
  }

  void titleSelected(Title? title) {
    emit(state.copyWith(selectedTitle: title, error: null));
  }

  Future<void> _searchTitles(String query) async {
    try {
      final result = await _titles.findTitles(TitleQuery(search: query));
      if (isClosed) return;
      emit(
        state.copyWith(
          titleMatches: result.items,
          selectedTitle: result.items.length == 1 ? result.items.first : null,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(error: error));
    }
  }

  Future<Reservation> placeHold() async {
    final member = state.member;
    final title = state.selectedTitle ?? state.fixedTitle;
    if (member == null) {
      throw const InvalidInputException('Choose a member first.');
    }
    if (title == null) {
      throw const InvalidInputException('Choose a title first.');
    }

    emit(state.copyWith(isSaving: true, error: null));
    try {
      final hold = await _circulation.placeHold(
        memberId: member.id,
        titleId: title.id,
      );
      if (isClosed) return hold;
      emit(state.copyWith(isSaving: false));
      return hold;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(isSaving: false, error: error));
      rethrow;
    }
  }
}
