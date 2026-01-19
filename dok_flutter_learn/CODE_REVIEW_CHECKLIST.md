# Code Review Checklist

> Checklist untuk memastikan setiap fitur sesuai dengan arsitektur dan standar kode

---

## Table of Contents

1. [Pre-Implementation Checklist](#pre-implementation-checklist)
2. [Domain Layer Checklist](#domain-layer-checklist)
3. [Data Layer Checklist](#data-layer-checklist)
4. [Presentation Layer Checklist](#presentation-layer-checklist)
5. [Testing Checklist](#testing-checklist)
6. [Documentation Checklist](#documentation-checklist)
7. [Common Violations](#common-violations)

---

## Pre-Implementation Checklist

Sebelum memulai implementasi fitur:

### Planning
- [ ] Fitur sudah didefinisikan dengan jelas (apa yang dilakukan)
- [ ] Entities sudah diidentifikasi
- [ ] UseCases sudah diidentifikasi
- [ ] API endpoints sudah diketahui (jika ada)
- [ ] UI flow sudah disketsakan

### Structure Setup
- [ ] Folder structure sudah dibuat sesuai template
- [ ] File sudah diberi nama dengan convention yang benar

---

## Domain Layer Checklist

### Entities
- [ ] Menggunakan `Equatable` untuk equality comparison
- [ ] Semua properties adalah `final`
- [ ] Memiliki `copyWith` method
- [ ] Memiliki `props` getter untuk Equatable
- [ ] **TIDAK** ada import Flutter (`package:flutter/`)
- [ ] **TIDAK** ada import dari package lain selain Dart SDK
- [ ] Constructor menggunakan `const` jika memungkinkan

```dart
// ✅ GOOD
class User extends Equatable {
  final String id;
  final String name;

  const User({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];

  User copyWith({String? id, String? name}) {
    return User(id: id ?? this.id, name: name ?? this.name);
  }
}

// ❌ BAD
import 'package:flutter/material.dart'; // No Flutter in Domain!
```

### Repository Interfaces
- [ ] Berupa **abstract class**
- [ ] Method documentation lengkap dengan `///`
- [ ] Mendefinisikan exceptions yang mungkin dilempar
- [ ] Return type menggunakan Future untuk async operations
- [ ] Method parameters menggunakan named parameters dengan `required`

```dart
// ✅ GOOD
abstract class AuthRepository {
  /// Login user with email and password
  ///
  /// Throws [UnauthorizedException] on invalid credentials
  /// Throws [NetworkException] on no internet connection
  Future<User> login({
    required String email,
    required String password,
  });
}
```

### UseCases
- [ ] Meng-extend `UseCase` atau `CompletableUseCase`
- [ ] Memiliki Params class jika perlu parameters
- [ **TIDAK** ada `ThrottleHelper` (gunakan DIO Interceptor)
- [ ] Error handling dengan try-catch
- [ ] Logger digunakan untuk tracking (finest, severe, warning)
- [ ] StreamController ditutup dengan `close()`
- [ ] **TIDAK** ada import Flutter

```dart
// ✅ GOOD
class LoginUseCase extends UseCase<User, LoginUseCaseParams> {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  @override
  Future<Stream<User>> buildUseCaseStream(params) async {
    final controller = StreamController<User>();
    try {
      final user = await _authRepository.login(...);
      controller.add(user);
      controller.close();
      logger.finest('LoginUseCase successful');
    } catch (e) {
      logger.severe('LoginUseCase failed: $e');
      controller.addError(e);
    }
    return controller.stream;
  }
}

// ❌ BAD
import 'package:flutter/material.dart'; // No Flutter!
final ThrottleHelper _throttle; // Use DIO Interceptor instead
```

---

## Data Layer Checklist

### Repository Implementation
- [ ] Meng-implement Repository interface dari Domain
- [ ] Constructor menggunakan dependency injection
- [ ] Error handling dengan try-catch
- [ ] Re-throw exceptions yang appropriate
- [ ] Mapping Model ↔ Entity jika menggunakan Model

```dart
// ✅ GOOD
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final model = await _remoteDataSource.login(email: email, password: password);
      return model.toEntity();
    } on ServerException {
      rethrow; // Re-throw known exceptions
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
}
```

### Models
- [ ] Meng-extend Entity jika mapping 1-1
- [ ] Memiliki `fromJson` factory constructor
- [ ] Memiliki `toJson` method
- [ ] Memiliki `toEntity` method
- [ ] Nullable fields ditangani dengan benar

```dart
// ✅ GOOD
class UserModel extends User {
  const UserModel({required String id, required String name}) : super(id: id, name: name);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  User toEntity() => User(id: id, name: name);
}
```

### Remote DataSource
- [ ] Constructor menggunakan dependency injection (ApiClient)
- [ ] Error handling dengan try-catch
- [ ] Melempar exception yang tepat (ServerException, NetworkException, etc)
- [ ] HTTP status code ditangani dengan benar (200, 401, 404, 500, etc)

```dart
// ✅ GOOD
@override
Future<UserModel> login({required String email, required String password}) async {
  try {
    final response = await _apiClient.post('/auth/login', data: {...});

    if (response.statusCode == 200) {
      return UserModel.fromJson(response.data['data']);
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Invalid credentials');
    } else {
      throw ServerException(response.data['message']);
    }
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      throw NetworkException('Connection timeout');
    }
    throw ServerException(e.message ?? 'Network error');
  }
}
```

---

## Presentation Layer Checklist

### Controller
- [ ] Meng-extend `Controller`
- [ ] Constructor menggunakan dependency injection
- [ ] **TIDAK** ada hardcoded dependencies
- [ ] State variables ditangani dengan benar
- [ ] `initListeners()` diimplement
- [ ] `onDisposed()` dispose Presenter dan UseCase
- [ ] `refreshUI()` dipanggil saat state berubah
- [ ] Input validation dilakukan sebelum memanggil Presenter

```dart
// ✅ GOOD
class LoginController extends Controller {
  final LoginPresenter _presenter;

  String email = '';
  String password = '';
  bool isLoading = false;
  String? errorMessage;

  LoginController(AuthRepository authRepo)
      : _presenter = LoginPresenter(authRepo),
        super();

  void onEmailChanged(String value) {
    email = value;
    refreshUI();
  }

  @override
  void initListeners() {
    _presenter.loginOnNext = (user) {
      isLoading = false;
      errorMessage = null;
      refreshUI();
    };
    _presenter.loginOnError = (error) { /* ... */ };
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}

// ❌ BAD
final LoginPresenter _presenter = LoginPresenter(AuthRepositoryImpl()); // Hardcoded!
```

### Presenter
- [ ] Meng-extend `Presenter`
- [ ] Constructor menggunakan dependency injection
- [ ] Memiliki UseCase sebagai member
- [ ] Callback functions di-definisikan (OnNext, OnError, OnComplete)
- [ ] `dispose()` dispose UseCase
- [ ] Observer class inner atau terpisah

```dart
// ✅ GOOD
class LoginPresenter extends Presenter {
  final LoginUseCase _loginUseCase;

  Function(User)? loginOnNext;
  Function(dynamic)? loginOnError;

  LoginPresenter(AuthRepository authRepo)
      : _loginUseCase = LoginUseCase(authRepo);

  void login(String email, String password) {
    _loginUseCase.execute(_LoginObserver(this), LoginUseCaseParams(email, password));
  }

  @override
  void dispose() {
    _loginUseCase.dispose();
  }
}
```

### View
- [ ] Meng-extend `CleanView`
- [ ] State meng-extend `CleanViewState<View, Controller>`
- [ ] Constructor memanggil `super(Controller(...))`
- [ ] `get view` mengembalikan Widget
- [ ] Menggunakan `ControlledWidgetBuilder` untuk akses controller state
- [ ] `globalKey` digunakan di Scaffold jika perlu akses dari controller

```dart
// ✅ GOOD
class LoginPage extends CleanView {
  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends CleanViewState<LoginPage, LoginController> {
  _LoginState() : super(LoginController(authRepository));

  @override
  Widget get view {
    return Scaffold(
      key: globalKey, // For controller access
      body: ControlledWidgetBuilder<LoginController>(
        builder: (context, controller) {
          return Column(
            children: [
              if (controller.isLoading) CircularProgressIndicator(),
              // ...
            ],
          );
        },
      ),
    );
  }
}
```

---

## Testing Checklist

### Unit Tests
- [ ] Domain UseCases memiliki test
- [ ] Data Repositories memiliki test
- [ ] Mock digunakan untuk dependencies
- [ ] Test meng-cover success scenario
- [ ] Test meng-cover error scenarios
- [ ] Arrange-Act-Assert pattern digunakan

### Widget Tests
- [ ] View utama memiliki widget test
- [ ] User interactions di-test (tap, input, etc)
- [ ] State changes terverifikasi
- [ ] Error states di-test

### Test Coverage
- [ ] Domain layer: minimal 100%
- [ ] Data layer: minimal 90%
- [ ] Presentation layer: minimal 80%

---

## Documentation Checklist

### Code Documentation
- [ ] Public API memiliki documentation comments (`///`)
- [ ] Complex logic memiliki inline comments
- [ ] TODO/FIXME comments ditangani atau dicatat

### README (per fitur jika perlu)
- [ ] Fitur didokumentasikan
- [ ] Cara penggunaan dijelaskan
- [ ] Contoh kode disertakan

---

## File & Naming Checklist

### File Structure
- [ ] Feature folder structure sesuai template
- [ ] File naming menggunakan `snake_case.dart`
- [ ] Folder naming menggunakan `lowercase`

### Class Naming
- [ ] Class menggunakan `PascalCase`
- [ ] Variable menggunakan `camelCase`
- [ ] Private member menggunakan `_underscorePrefix`
- [ ] Constants menggunakan `kPrefix` (optional) atau UPPER_CASE

### Import Order
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. Package dependencies
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

// 4. Core imports
import '../../../../core/utils/validators.dart';

// 5. Feature imports
import '../../domain/entities/user.dart';

// 6. Relative imports
import '../widgets/custom_button.dart';
```

---

## Common Violations

### ❌ CRITICAL Violations (MUST FIX)

| Violation | Why Wrong | Fix |
|-----------|-----------|-----|
| Import Flutter in Domain | Domain must be framework-agnostic | Move to Data/Presentation |
| Hardcoded dependencies | Cannot test, violates DI | Use constructor injection |
| Skip error handling | App may crash | Wrap in try-catch |
| Skip dispose | Memory leak | Dispose in onDisposed |
| God classes (>500 lines) | Hard to maintain | Split into smaller classes |
| Direct View → UseCase | Skips layers | Use Controller → Presenter |

### ⚠️ WARNING Violations (SHOULD FIX)

| Violation | Why Wrong | Fix |
|-----------|-----------|-----|
| No `const` constructor | Performance | Add `const` |
| No Equatable | Cannot compare objects | Implement `Equatable` |
| Hardcoded strings | Cannot localize | Move to constants |
| No documentation | Hard to understand | Add comments |
| Large methods (>50 lines) | Hard to read | Extract methods |

### ℹ️ INFO Violations (NICE TO FIX)

| Violation | Why Wrong | Fix |
|-----------|-----------|-----|
| Inconsistent naming | Confusing | Follow convention |
| Long lines (>120 chars) | Hard to read | Break into multiple lines |
| Missing trailing comma | Hard to format | Add trailing comma |

---

## Quick Checklist (One-Line)

### Domain Layer
```
[ ] No Flutter imports
[ ] Entities use Equatable
[ ] Repositories are abstract
[ ] UseCases handle errors
[ ] No ThrottleHelper (use DIO)
```

### Data Layer
```
[ ] Implements Domain interface
[ ] DataSource throws proper exceptions
[ ] Model has fromJson/toJson/toEntity
[ ] Repository handles errors
```

### Presentation Layer
```
[ ] Controller uses DI
[ ] initListeners implemented
[ ] onDisposed cleanup
[ ] View uses ControlledWidgetBuilder
```

### General
```
[ ] File naming: snake_case
[ ] Class naming: PascalCase
[ ] Imports in correct order
[ ] No hardcoded values
[ ] Error handling present
```

---

## Automated Checks (Recommended)

### Dart Analyze
```bash
# Run analyzer
dart analyze

# Fix issues automatically
dart fix --apply
```

### Format Check
```bash
# Format code
dart format .

# Check formatting
dart format --output=none --set-exit-if-changed .
```

### Linter Rules

Tambahkan di `analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml

analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

  errors:
    # Treat missing required parameters as error
    missing_required_param: error
    # Treat missing return as error
    missing_return: error
    # Treat deprecated annotations as error
    deprecated_member_use_from_same_package: error

linter:
  rules:
    # Error prevention
    - avoid_dynamic_calls
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_slow_async_io
    - avoid_type_to_string
    - avoid_types_as_parameter_names
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - literal_only_boolean_expressions
    - no_adjacent_strings_in_list
    - prefer_void_to_null
    - test_types_in_equals
    - throw_in_finally
    - unnecessary_statements
    - unrelated_type_equality_checks
    - unsafe_html
    - valid_regexps

    # Style
    - always_declare_return_types
    - always_put_control_body_on_new_line
    - always_put_required_named_parameters_first
    - always_require_non_null_named_parameters
    - annotate_overrides
    - avoid_bool_literals_in_conditional_expressions
    - avoid_catches_without_on_clauses
    - avoid_double_and_int_checks
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_escaping_inner_quotes
    - avoid_function_literals_in_foreach_calls
    - avoid_init_to_null
    - avoid_null_checks_in_equality_operators
    - avoid_positional_boolean_parameters
    - avoid_redundant_argument_values
    - avoid_return_types_on_setters
    - avoid_single_cascade_in_expression_statements
    - avoid_unnecessary_containers
    - avoid_unused_constructor_parameters
    - avoid_void_async
    - await_only_futures
    - camel_case_extensions
    - camel_case_types
    - cascade_invocations
    - cast_nullable_to_non_nullable
    - constant_identifier_names
    - curly_braces_in_flow_control_structures
    - depend_on_referenced_packages
    - deprecated_consistency
    - directives_ordering
    - empty_catches
    - empty_constructor_bodies
    - eol_at_end_of_file
    - exhaustive_cases
    - file_names
    - flutter_style_todos
    - implementation_imports
    - join_return_with_assignment
    - leading_newlines_in_multiline_strings
    - library_names
    - library_prefixes
    - library_private_types_in_public_api
    - lines_longer_than_80_chars
    - missing_whitespace_between_adjacent_strings
    - no_default_cases
    - no_duplicate_case_values
    - no_leading_underscores_for_library_prefixes
    - no_literal_bool_comparisons
    - no_logic_in_create_state
    - no_runtimeType_toString
    - non_constant_identifier_names
    - noop_primitive_operations
    - null_check_on_nullable_type_parameter
    - null_closures
    - omit_local_variable_types
    - one_member_abstracts
    - only_throw_errors
    - overridden_fields
    - package_names
    - parameter_assignments
    - prefer_adjacent_string_concatenation
    - prefer_asserts_in_initializer_lists
    - prefer_asserts_with_message
    - prefer_collection_literals
    - prefer_conditional_assignment
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_constructors_over_static_methods
    - prefer_contains
    - prefer_equal_for_default_values
    - prefer_expression_function_bodies
    - prefer_final_fields
    - prefer_final_locals
    - prefer_for_elements_to_map_fromIterable
    - prefer_function_declarations_over_variables
    - prefer_generic_function_type_aliases
    - prefer_if_elements_to_conditional_expressions
    - prefer_if_null_operators
    - prefer_initializing_formals
    - prefer_inlined_adds
    - prefer_int_literals
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_is_not_operator
    - prefer_iterable_whereType
    - prefer_null_aware_method_calls
    - prefer_null_aware_operators
    - prefer_relative_imports
    - prefer_single_quotes
    - prefer_spread_collections
    - prefer_typing_uninitialized_variables
    - provide_deprecation_message
    - public_member_api_docs
    - recursive_getters
    - require_trailing_commas
    - sized_box_for_whitespace
    - sized_box_shrink_expand
    - slash_for_doc_comments
    - sort_child_properties_last
    - sort_constructors_first
    - sort_pub_dependencies
    - type_annotate_public_apis
    - type_init_formals
    - unawaited_futures
    - unnecessary_await_in_return
    - unnecessary_brace_in_string_interps
    - unnecessary_const
    - unnecessary_constructor_name
    - unnecessary_getters_setters
    - unnecessary_lambdas
    - unnecessary_late
    - unnecessary_new
    - unnecessary_null_aware_assignments
    - unnecessary_null_checks
    - unnecessary_null_in_if_null_operators
    - unnecessary_nullable_for_final_variable_declarations
    - unnecessary_overrides
    - unnecessary_parenthesis
    - unnecessary_raw_strings
    - unnecessary_string_escapes
    - unnecessary_string_interpolations
    - unnecessary_this
    - unnecessary_to_list_in_spreads
    - unreachable_from_main
    - unrelated_type_equality_checks
    - use_build_context_synchronously
    - use_colored_box
    - use_decorated_box
    - use_enums
    - use_full_hex_values_for_flutter_colors
    - use_function_type_syntax_for_parameters
    - use_if_null_to_convert_nulls_to_bools
    - use_is_even_rather_than_modulo
    - use_key_in_widget_constructors
    - use_late_for_private_fields_and_variables
    - use_named_constants
    - use_raw_strings
    - use_rethrow_when_possible
    - use_setters_to_change_properties
    - use_string_buffers
    - use_super_parameters
    - use_test_throws_matchers
    - use_to_and_as_if_applicable
    - valid_regexps
    - void_checks
```

---

## Pre-Pull Request Checklist

Sebelum membuat PR, pastikan:

- [ ] Semua checklist di atas sudah terpenuhi
- [ ] `dart analyze` tidak ada error
- [ ] `dart format` sudah dijalankan
- [ ] Tests pass (`flutter test`)
- [ ] Integration tests pass (jika ada)
- [ ] Documentation sudah di-update
- [ ] PR description menjelaskan perubahan
- [ ] Reviewer sudah ditag

---

*Version: 1.0.0*
*Last Updated: 7 Januari 2025*
