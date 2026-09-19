# ADR 0013 - `formz` for form validation

**Status:** Accepted · **Date:** 2026-09-03

## Context

Form validation in Flutter has two common failure modes:

**Validation in the widget.** `TextFormField`'s `validator` callback runs on submit and returns an error string. This couples validation logic to the widget tree, makes it impossible to test without building a widget, and duplicates logic when the same field type (e.g., ISBN) appears in multiple forms. It also produces an implicit validation state that lives nowhere - after `_formKey.currentState!.validate()`, the valid/invalid state is in the `Form` widget's internal state, invisible to any cubit or test.

**Validation flags in the cubit state.** A `bool isIsbnValid` field alongside the ISBN string. This is testable but verbose: every field needs a flag, every `copyWith` emits the flag alongside the value, and the "is the whole form submittable?" check is a conjunction of all the flags with no shared definition of what "valid" means for each field type.

`formz` solves both by making a validated input a first-class type. Each `FormzInput<Value, ValidationError>` carries its value and its validation state as a single object. The cubit state holds `FormzInput` instances, not bare strings. Validation logic is in the input class - a plain Dart object - and is testable with no widget involvement. The "is the form submittable?" check is `Formz.validate([titleInput, isbnInput, authorInput])`, which returns a single `FormzStatus`.

## Decision

Use **`formz`** for all form field validation. Form inputs live in `lib/core/form/inputs/`. The cubit state holds `FormzInput` instances. Validation is tested directly on the input class, not through a widget.

### Anatomy of an input

```dart
// lib/core/form/inputs/required_text.dart
enum RequiredTextValidationError { empty }

class RequiredText extends FormzInput<String, RequiredTextValidationError> {
  const RequiredText.pure([super.value = '']) : super.pure();
  const RequiredText.dirty([super.value = '']) : super.dirty();

  @override
  RequiredTextValidationError? validator(String value) {
    return value.trim().isEmpty ? RequiredTextValidationError.empty : null;
  }
}
```

`pure()` means the field has not been touched - no error shown yet even if the value is invalid. `dirty()` means the user has interacted with the field - errors are now shown. This mirrors the UX contract: a form that opens with empty fields shows no errors until the user touches each field (or submits).

### Built-in inputs

`lib/core/form/inputs/` provides:

| Class          | Validates                                     |
| -------------- | --------------------------------------------- |
| `RequiredText` | Non-empty string after trimming               |
| `Email`        | Non-empty, contains `@`, has a domain segment |
| `FullName`     | Non-empty, at least two words                 |
| `Password`     | Minimum 8 characters, at least one digit      |

Feature-specific validation (ISBN format, call number syntax, membership ID pattern) goes in the feature's own `domain/` or in a sub-folder of `lib/core/form/inputs/` if the same format appears in multiple features.

### State shape with `formz`

Form fields are `FormzInput` instances in the cubit state. They sit alongside non-form fields like the current list or the load status:

```dart
@freezed
abstract class TitleFormState with _$TitleFormState {
  const factory TitleFormState({
    @Default(RequiredText.pure()) RequiredText title,
    @Default(RequiredText.pure()) RequiredText isbn,
    @Default(RequiredText.pure()) RequiredText callNumber,
    @Default(FormzSubmissionStatus.initial) FormzSubmissionStatus status,
    AppException? error,
  }) = _TitleFormState;

  const TitleFormState._();

  bool get isValid => Formz.validate([title, isbn, callNumber]);
  bool get isSubmitting => status.isInProgress;
}
```

`Formz.validate([…])` returns `true` only when every input is in the valid state. It is the single submittability check, and it lives on the state so the submit button's `onPressed` is `state.isValid ? cubit.saveTitle : null` - no logic in the widget.

### Field change and submission flow

The cubit has one method per field change, named `<field>Changed(value)`:

```dart
// in TitleFormCubit
void titleChanged(String value) =>
    emit(state.copyWith(title: RequiredText.dirty(value)));

void isbnChanged(String value) =>
    emit(state.copyWith(isbn: RequiredText.dirty(value)));

Future<void> saveTitle() async {
  // Mark all fields dirty on submission attempt so errors appear immediately.
  emit(state.copyWith(
    title:     RequiredText.dirty(state.title.value),
    isbn:      RequiredText.dirty(state.isbn.value),
    callNumber: RequiredText.dirty(state.callNumber.value),
    status:    FormzSubmissionStatus.inProgress,
    error:     null,
  ));

  if (!state.isValid) {
    emit(state.copyWith(status: FormzSubmissionStatus.initial));
    return;
  }

  try {
    await _repository.saveTitle(state.toTitle());
    emit(state.copyWith(status: FormzSubmissionStatus.success));
  } on AppException catch (e) {
    emit(state.copyWith(status: FormzSubmissionStatus.failure, error: e));
    rethrow;
  }
}
```

The "mark all dirty on submit" step is the UX contract for a form where the user presses submit without touching every field - all errors appear at once rather than showing only after each field is individually touched.

### Displaying errors in the widget

The widget reads the error from the input's `displayError` getter, which returns `null` when the input is `pure` (untouched):

```dart
AppTextField(
  controller: _titleController,
  onChanged: cubit.titleChanged,
  errorText: switch (state.title.displayError) {
    RequiredTextValidationError.empty => context.l10n.errorFieldRequired,
    null => null,
  },
)
```

`displayError` returns the validation error only when the input is `dirty` and invalid - never when `pure`. This means the widget has no validation logic: it maps an error enum value to a localized string and passes it to the text field. The `switch` is exhaustive; the analyzer warns if a new `ValidationError` variant is added and the switch is not updated.

### `FormzInput` survives status transitions

This is why form fields live in the state as `FormzInput` instances rather than in a separate "form state" sealed union. A checkout form that transitions through `initial → loading → error → loading → success` must keep the ISBN, the member ID, and every other field value across every transition. A sealed union with an `error` variant that redeclares all the fields is mechanical duplication. A single-class `freezed` state with `FormzInput` fields carries them through every `copyWith` for free.

### `LoadStatus` vs `FormzSubmissionStatus`

States that mix a list-load and a form use both:

```dart
const factory MembersState({
  @Default(LoadStatus.initial) LoadStatus status,      // for the member list
  @Default(RequiredText.pure()) RequiredText searchQuery,
  …
}) = _MembersState;
```

A pure form state (no list, just a create/edit flow) uses `FormzSubmissionStatus` instead of `LoadStatus`, since `isLoading` / `isEmpty` / `hasError` are not meaningful for a form that has no list to display. A state that owns both a list and a form (an inline add-row pattern) uses both enums on separate fields.

## Consequences

**What this buys**

- Validation logic is in one class per input type, testable with `expect(RequiredText.dirty('').isValid, false)`. No widget tree required.
- `displayError` returns `null` for untouched fields. The widget cannot accidentally show an error before the user has interacted - the contract is enforced by the type, not by an `if` in the widget.
- `Formz.validate([…])` is the one place the form's submittability is computed. The submit button, the cubit's guard clause, and any derived state all read from the same source.
- An exhaustive `switch` on a `ValidationError` enum means adding a new validation case produces a compile-time warning at every display site.
- `FormzInput` values survive every cubit state transition without manual field forwarding.

**What this costs**

- A new field type requires a new `FormzInput` subclass, even if it is a one-line validator. For a type used in only one form, this feels like overhead. The tradeoff is testability and the `displayError` contract - a bare `String?` in the state does not give you either.
- `FormzSubmissionStatus` and `LoadStatus` coexist in some states. The naming convention (`status` for `LoadStatus`, named explicitly for `FormzSubmissionStatus`) prevents confusion, but contributors new to the codebase will encounter both.
- The `pure` / `dirty` distinction requires the "mark all dirty on submit" pattern to be written correctly in every `save` / `submit` method. A cubit that forgets to dirty the fields before checking `isValid` will pass the check on empty required fields if the user presses submit without touching anything.

## Revisiting

The trigger to replace `formz` is a Flutter-native form validation API that provides the `pure`/`dirty` distinction, exhaustive error enums, and a testable separation from the widget tree. Nothing in the current SDK comes close. The trigger to extend the built-in inputs is a validation rule that appears in three or more features - it graduates from the feature's `domain/` to `lib/core/form/inputs/`.
