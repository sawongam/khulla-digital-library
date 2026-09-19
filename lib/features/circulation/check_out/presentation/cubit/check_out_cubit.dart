// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/features/catalog/copy/domain/copy_repository.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/circulation/check_out/presentation/cubit/check_out_state.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/features/circulation/shared/domain/models/effective_loan_rules.dart';
import 'package:khulla/features/circulation/shared/domain/resolve_loan_rules.dart';
import 'package:khulla/features/members/data/member_type_local_data_source.dart';
import 'package:khulla/features/members/domain/member_repository.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';
import 'package:khulla/features/settings/domain/loan_rules_repository.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';

/// The check-out desk: member lookup, copy basket and loan creation.
///
/// Page-scoped `@injectable` cubit coordinating [CirculationRepository],
/// [CopyRepository], [MemberRepository] and [LoanRulesRepository]. Member
/// lookup failures emit into state; barcode adds and [checkOutCopies] emit
/// and rethrow so the scanner field or confirm button can toast.
@injectable
class CheckOutCubit extends Cubit<CheckOutState> {
  CheckOutCubit(
    this._circulationRepository,
    this._copyRepository,
    this._memberRepository,
    this._loanRulesRepository,
    this._memberTypes,
    this._auth,
  ) : super(const CheckOutState());

  final CirculationRepository _circulationRepository;
  final CopyRepository _copyRepository;
  final MemberRepository _memberRepository;
  final LoanRulesRepository _loanRulesRepository;
  final MemberTypeLocalDataSource _memberTypes;
  final AuthCubit _auth;

  Timer? _memberLookupTimer;

  /// Formatted due date from the resolved [EffectiveLoanRules], or blank until a member is set.
  String dueDateLabel() {
    final rules = state.rules;
    if (rules == null) return '';
    final dueAt = addCalendarDays(
      dateOnly(DateTime.now()),
      rules.loanPeriodDays,
    );
    return AppDateFormat.format(dueAt);
  }

  void memberSearchChanged(String value) {
    _memberLookupTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          member: null,
          rules: null,
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
      final exact = await _memberRepository.findMemberByBarcode(trimmed);
      if (isClosed) return;
      if (exact != null) {
        final rules = await _loadEffectiveRules(exact.memberTypeId);
        if (isClosed) return;
        emit(
          state.copyWith(
            member: exact,
            rules: rules,
            memberMatches: const [],
            isLookingUpMember: false,
            error: null,
          ),
        );
        return;
      }
      final results = await _memberRepository.findMembers(
        MemberQuery(search: trimmed),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          member: null,
          rules: null,
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
          rules: null,
          memberMatches: const [],
          isLookingUpMember: false,
          error: error,
        ),
      );
    }
  }

  /// Picks one member from the search matches and loads their loan rules.
  Future<void> memberSelected(Member member) async {
    emit(state.copyWith(isLookingUpMember: true, error: null));
    try {
      final rules = await _loadEffectiveRules(member.memberTypeId);
      if (isClosed) return;
      emit(
        state.copyWith(
          member: member,
          rules: rules,
          memberMatches: const [],
          memberQuery: '',
          isLookingUpMember: false,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isLookingUpMember: false, error: error));
    }
  }

  /// Resolves a member by barcode or unambiguous name search.
  ///
  /// One-shot direct resolution for the `?card=` deep link. Loads
  /// [EffectiveLoanRules] for their type on success. Failures emit
  /// into state and swallow - the operator stays on the same field.
  Future<void> lookupMember(String query) async {
    emit(
      state.copyWith(
        isLookingUpMember: true,
        memberMatches: const [],
        memberQuery: query.trim(),
        error: null,
      ),
    );
    try {
      final trimmed = query.trim();
      var member = await _memberRepository.findMemberByBarcode(trimmed);
      if (member == null) {
        final results = await _memberRepository.findMembers(
          MemberQuery(search: trimmed, limit: 2),
        );
        if (results.items.length == 1) {
          member = results.items.first;
        }
      }
      if (isClosed) return;
      if (member == null) {
        emit(
          state.copyWith(
            member: null,
            rules: null,
            memberMatches: const [],
            isLookingUpMember: false,
            error: const NotFoundException('That member was not found.'),
          ),
        );
        return;
      }
      final rules = await _loadEffectiveRules(member.memberTypeId);
      if (isClosed) return;
      emit(
        state.copyWith(
          member: member,
          rules: rules,
          memberMatches: const [],
          memberQuery: '',
          isLookingUpMember: false,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          member: null,
          rules: null,
          memberMatches: const [],
          isLookingUpMember: false,
          error: error,
        ),
      );
    }
  }

  void clearMember() {
    _memberLookupTimer?.cancel();
    emit(
      state.copyWith(
        member: null,
        rules: null,
        basket: const [],
        memberMatches: const [],
        memberQuery: '',
        error: null,
      ),
    );
  }

  /// Adds a copy to the basket by barcode. Emits and rethrows on failure.
  Future<void> addCopyByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    try {
      final copy = await _copyRepository.findCopyByBarcode(trimmed);
      if (isClosed) return;
      if (copy == null) {
        throw const NotFoundException('No copy matches that barcode.');
      }
      if (state.basket.any((item) => item.id == copy.id)) {
        throw const ConflictException('That copy is already in the basket.');
      }
      emit(state.copyWith(basket: [...state.basket, copy], error: null));
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  void removeCopy(Copy copy) {
    emit(
      state.copyWith(
        basket: state.basket.where((item) => item.id != copy.id).toList(),
        error: null,
      ),
    );
  }

  /// Creates loans for every copy in the basket, then clears the desk.
  ///
  /// Emits and rethrows on failure so the confirm action can toast without
  /// losing the basket.
  Future<void> checkOutCopies() async {
    final member = state.member;
    if (member == null || state.basket.isEmpty) return;

    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      await _circulationRepository.checkOutCopies(
        memberId: member.id,
        barcodes: state.basket.map((copy) => copy.barcode).toList(),
        staffId: _auth.state.staff?.id,
      );
      if (isClosed) return;
      emit(const CheckOutState());
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false, error: error));
      rethrow;
    }
  }

  Future<EffectiveLoanRules> _loadEffectiveRules(String memberTypeId) async {
    final defaults = await _loanRulesRepository.findRules();
    if (defaults == null) {
      throw const NotFoundException('Loan rules have not been configured.');
    }
    final memberType = await _memberTypes.findMemberTypeById(memberTypeId);
    if (memberType == null) {
      throw const NotFoundException('That member type was not found.');
    }
    return resolveLoanRules(defaults, memberType);
  }

  @override
  Future<void> close() {
    _memberLookupTimer?.cancel();
    return super.close();
  }
}
