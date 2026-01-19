# Feature Template

> Template dan pattern untuk membuat fitur baru
> Copy dan sesuaikan sesuai kebutuhan fitur

---

## Table of Contents

1. [Feature Structure](#feature-structure)
2. [Quick Start Checklist](#quick-start-checklist)
3. [Domain Layer Templates](#domain-layer-templates)
4. [Data Layer Templates](#data-layer-templates)
5. [Presentation Layer Templates](#presentation-layer-templates)
6. [Common Patterns](#common-patterns)

---

## Feature Structure

Setiap fitur baru harus mengikuti struktur berikut:

```
features/[nama_fitur]/
├── domain/
│   ├── entities/
│   │   └── [entity].dart
│   ├── repositories/
│   │   └── [fitur]_repository.dart
│   └── usecases/
│       ├── [action]_usecase.dart
│       └── [action]_usecase_params.dart
├── data/
│   ├── repositories/
│   │   └── [fitur]_repository_impl.dart
│   ├── models/
│   │   └── [model]_model.dart
│   ├── datasources/
│   │   ├── [fitur]_remote_datasource.dart
│   │   └── [fitur]_local_datasource.dart
│   └── mappers/
│       └── [mapper]_mapper.dart
└── presentation/
    ├── pages/
    │   └── [page_name]/
    │       ├── [page]_controller.dart
    │       ├── [page]_presenter.dart
    │       └── [page]_view.dart
    └── widgets/
        └── [widget].dart
```

---

## Quick Start Checklist

### Step 1: Planning

- [ ] Definisikan fitur (apa yang dilakukan)
- [ ] Identifikasi entities yang dibutuhkan
- [ ] Identifikasi use cases yang dibutuhkan
- [ ] Identifikasi API endpoints (jika ada)
- [ ] Sketsa UI flow

### Step 2: Domain Layer

- [ ] Buat entities di `domain/entities/`
- [ ] Buat repository interface di `domain/repositories/`
- [ ] Buat usecases di `domain/usecases/`

### Step 3: Data Layer

- [ ] Implement repository di `data/repositories/`
- [ ] Buat models di `data/models/` (jika perlu)
- [ ] Buat datasources di `data/datasources/`
- [ ] Buat mappers di `data/mappers/` (jika perlu)

### Step 4: Presentation Layer

- [ ] Buat controller di `presentation/pages/`
- [ ] Buat presenter di `presentation/pages/`
- [ ] Buat view di `presentation/pages/`
- [ ] Buat custom widgets di `presentation/widgets/`

### Step 5: Integration

- [ ] Register provider (jika pakai Riverpod)
- [ ] Tambahkan route di `app_router.dart`
- [ ] Test semua scenario

---

## Domain Layer Templates

### Entity Template

```dart
// features/[fitur]/domain/entities/[entity].dart
import 'package:equatable/equatable.dart';

class [EntityName] extends Equatable {
  final String id;
  final String name;
  final String description;

  const [EntityName]({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  List<Object?> get props => [id, name, description];

  [EntityName] copyWith({
    String? id,
    String? name,
    String? description,
  }) {
    return [EntityName](
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
```

**Example:**
```dart
// features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, email];

  User copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
```

---

### Repository Interface Template

```dart
// features/[fitur]/domain/repositories/[fitur]_repository.dart
import '../entities/[entity].dart';

abstract class [Fitur]Repository {
  /// Method description
  ///
  /// Throws [ServerException] on API error
  /// Throws [NetworkException] on network error
  Future<[Entity]> [methodName]({
    required String param1,
    required String param2,
  });

  /// Get list of items
  Future<List<[Entity]>> [getListMethodName]();

  /// Delete item by id
  Future<void> [deleteMethodName](String id);
}
```

**Example:**
```dart
// features/auth/domain/repositories/auth_repository.dart
import '../entities/user.dart';

abstract class AuthRepository {
  /// Login user with email and password
  ///
  /// Throws [ServerException] on API error
  /// Throws [NetworkException] on network error
  /// Throws [UnauthorizedException] on invalid credentials
  Future<User> login({
    required String email,
    required String password,
  });

  /// Logout current user
  Future<void> logout();

  /// Get currently authenticated user
  ///
  /// Returns null if no user is logged in
  Future<User?> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
```

---

### UseCase Template (Return Data)

```dart
// features/[fitur]/domain/usecases/[action]/[action]_usecase.dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../entities/[entity].dart';
import '../../repositories/[fitur]_repository.dart';

class [Action]UseCase extends UseCase<[Entity], [Action]UseCaseParams> {
  final [Fitur]Repository _[fitur]Repository;

  [Action]UseCase(this._[fitur]Repository);

  @override
  Future<Stream<[Entity]>> buildUseCaseStream(params) async {
    final StreamController<[Entity]> controller = StreamController<[Entity]>();

    try {
      // Execute business logic
      final result = await _[fitur]Repository.[methodName](
        param1: params.param1,
        param2: params.param2,
      );

      // Emit result
      controller.add(result);
      controller.close();

      logger.finest('[Action]UseCase successful.');
    } catch (e) {
      logger.severe('[Action]UseCase unsuccessful: $e');
      controller.addError(e);
    }

    return controller.stream;
  }
}

class [Action]UseCaseParams {
  final String param1;
  final String param2;

  [Action]UseCaseParams(
    this.param1,
    this.param2,
  );
}
```

**Example:**
```dart
// features/auth/domain/usecases/login/login_usecase.dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class LoginUseCase extends UseCase<User, LoginUseCaseParams> {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  @override
  Future<Stream<User>> buildUseCaseStream(params) async {
    final StreamController<User> controller = StreamController<User>();

    try {
      final user = await _authRepository.login(
        email: params.email,
        password: params.password,
      );

      controller.add(user);
      controller.close();

      logger.finest('LoginUseCase successful.');
    } catch (e) {
      logger.severe('LoginUseCase unsuccessful: $e');
      controller.addError(e);
    }

    return controller.stream;
  }
}

class LoginUseCaseParams {
  final String email;
  final String password;

  LoginUseCaseParams(this.email, this.password);
}
```

---

### UseCase Template (No Return Data)

```dart
// features/[fitur]/domain/usecases/[action]/[action]_usecase.dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../repositories/[fitur]_repository.dart';

class [Action]UseCase extends CompletableUseCase<[Action]UseCaseParams> {
  final [Fitur]Repository _[fitur]Repository;

  [Action]UseCase(this._[fitur]Repository);

  @override
  Future<Stream<void>> buildUseCaseStream(params) async {
    final StreamController<void> controller = StreamController<void>();

    try {
      await _[fitur]Repository.[methodName](
        param1: params.param1,
      );

      controller.close();
      logger.finest('[Action]UseCase successful.');
    } catch (e) {
      logger.severe('[Action]UseCase unsuccessful: $e');
      controller.addError(e);
    }

    return controller.stream;
  }
}

class [Action]UseCaseParams {
  final String param1;

  [Action]UseCaseParams(this.param1);
}
```

---

## Data Layer Templates

### Model Template

```dart
// features/[fitur]/data/models/[model]_model.dart
import '../../domain/entities/[entity].dart';

class [ModelName]Model extends [EntityName] {
  const [ModelName]Model({
    required String id,
    required String name,
    required String description,
  }) : super(
          id: id,
          name: name,
          description: description,
        );

  factory [ModelName]Model.fromJson(Map<String, dynamic> json) {
    return [ModelName]Model(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  [EntityName] toEntity() {
    return [EntityName](
      id: id,
      name: name,
      description: description,
    );
  }
}
```

---

### Remote DataSource Template

```dart
// features/[fitur]/data/datasources/[fitur]_remote_datasource.dart
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/[model]_model.dart';

abstract class [Fitur]RemoteDataSource {
  Future<[ModelName]Model> [methodName]({
    required String param1,
    required String param2,
  });

  Future<List<[ModelName]Model>> [getListMethodName]();
}

class [Fitur]RemoteDataSourceImpl implements [Fitur]RemoteDataSource {
  final ApiClient apiClient;

  [Fitur]RemoteDataSourceImpl({required this.apiClient});

  @override
  Future<[ModelName]Model> [methodName]({
    required String param1,
    required String param2,
  }) async {
    try {
      final response = await apiClient.post(
        '/[endpoint]',
        data: {
          'param1': param1,
          'param2': param2,
        },
      );

      if (response.statusCode == 200) {
        return [ModelName]Model.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message']);
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<[ModelName]Model>> [getListMethodName]() async {
    try {
      final response = await apiClient.get('/[endpoint]');

      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data['data'];
        return dataList.map((json) => [ModelName]Model.fromJson(json)).toList();
      } else {
        throw ServerException(response.data['message']);
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }
}
```

---

### Repository Implementation Template

```dart
// features/[fitur]/data/repositories/[fitur]_repository_impl.dart
import '../../domain/entities/[entity].dart';
import '../../domain/repositories/[fitur]_repository.dart';
import '../datasources/[fitur]_remote_datasource.dart';
import '../../../../core/errors/exceptions.dart';

class [Fitur]RepositoryImpl implements [Fitur]Repository {
  final [Fitur]RemoteDataSource remoteDataSource;

  [Fitur]RepositoryImpl({required this.remoteDataSource});

  @override
  Future<[Entity]> [methodName]({
    required String param1,
    required String param2,
  }) async {
    try {
      final model = await remoteDataSource.[methodName](
        param1: param1,
        param2: param2,
      );
      return model.toEntity();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<[Entity]>> [getListMethodName]() async {
    try {
      final models = await remoteDataSource.[getListMethodName]();
      return models.map((model) => model.toEntity()).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
}
```

---

## Presentation Layer Templates

### Controller Template

```dart
// features/[fitur]/presentation/pages/[page]/[page]_controller.dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '[page]_presenter.dart';

class [Page]Controller extends Controller {
  final [Page]Presenter _presenter;

  // Form state
  String field1 = '';
  String field2 = '';
  bool isLoading = false;
  String? errorMessage;

  [Page]Controller([Fitur]Repository [fitur]Repository)
      : _presenter = [Page]Presenter([fitur]Repository),
        super();

  void onField1Changed(String value) {
    field1 = value;
    refreshUI();
  }

  void onField2Changed(String value) {
    field2 = value;
    refreshUI();
  }

  Future<void> submit() async {
    if (!_validateInput()) return;

    isLoading = true;
    errorMessage = null;
    refreshUI();

    _presenter.[action](field1, field2);
  }

  bool _validateInput() {
    if (field1.isEmpty) {
      errorMessage = 'Field1 tidak boleh kosong';
      refreshUI();
      return false;
    }
    return true;
  }

  @override
  void initListeners() {
    _presenter.[action]OnNext = ([Entity] result) {
      isLoading = false;
      errorMessage = null;
      refreshUI();

      // Navigate or show success
    };

    _presenter.[action]OnError = (error) {
      isLoading = false;
      errorMessage = error.toString();
      refreshUI();
    };
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
```

---

### Presenter Template

```dart
// features/[fitur]/presentation/pages/[page]/[page]_presenter.dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart' as clean;
import '../../domain/usecases/[action]/[action]_usecase.dart';
import '../../domain/entities/[entity].dart';

class [Page]Presenter extends clean.Presenter {
  final [Action]UseCase _[action]UseCase;

  // Callbacks untuk Controller
  Function([Entity])? [action]OnNext;
  Function(dynamic)? [action]OnError;

  [Page]Presenter([Fitur]Repository [fitur]Repository)
      : _[action]UseCase = [Action]UseCase([fitur]Repository);

  void [action](String param1, String param2) {
    _[action]UseCase.execute(
      _[Action]Observer(this),
      [Action]UseCaseParams(param1, param2),
    );
  }

  @override
  void dispose() {
    _[action]UseCase.dispose();
  }
}

class _[Action]Observer extends clean.Observer<[Entity]> {
  final [Page]Presenter _presenter;

  _[Action]Observer(this._presenter);

  @override
  void onNext([Entity] result) {
    _presenter.[action]OnNext?.call(result);
  }

  @override
  void onComplete() {
    // Not used for this UseCase
  }

  @override
  void onError(error) {
    _presenter.[action]OnError?.call(error);
  }
}
```

---

### View Template

```dart
// features/[fitur]/presentation/pages/[page]/[page]_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../core/widgets/form/custom_text_field.dart';
import '../../../../core/widgets/buttons/primary_button.dart';

class [PageName] extends CleanView {
  const [PageName]({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _[PageName]State();
}

class _[PageName]State extends CleanViewState<[PageName], [PageName]Controller> {
  _[PageName]State() : super([PageName]Controller());

  @override
  Widget get view {
    return Scaffold(
      key: globalKey,
      appBar: AppBar(
        title: Text('[Page Title]'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ControlledWidgetBuilder<[PageName]Controller>(
                builder: (context, controller) {
                  return Column(
                    children: [
                      CustomTextField(
                        label: 'Field 1',
                        onChanged: controller.onField1Changed,
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Field 2',
                        onChanged: controller.onField2Changed,
                      ),

                      const SizedBox(height: 24),

                      PrimaryButton(
                        text: 'Submit',
                        isLoading: controller.isLoading,
                        onPressed: controller.submit,
                      ),

                      if (controller.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Common Patterns

### Pattern 1: List with Loading State

```dart
// Controller
class ListController extends Controller {
  final ListPresenter _presenter;

  List<[Entity]> items = [];
  bool isLoading = false;
  bool isEmpty = false;
  String? errorMessage;

  ListController([Fitur]Repository [fitur]Repository)
      : _presenter = ListPresenter([fitur]Repository),
        super();

  @override
  void initListeners() {
    _presenter.getListOnNext = (List<[Entity]> result) {
      items = result;
      isLoading = false;
      isEmpty = result.isEmpty;
      errorMessage = null;
      refreshUI();
    };

    _presenter.getListOnError = (error) {
      isLoading = false;
      errorMessage = error.toString();
      refreshUI();
    };
  }

  void loadItems() {
    isLoading = true;
    refreshUI();
    _presenter.getList();
  }

  void refresh() {
    loadItems();
  }
}
```

### Pattern 2: Form with Validation

```dart
// Controller
class FormController extends Controller {
  final FormPresenter _presenter;

  // Fields
  String email = '';
  String password = '';

  // Validation state
  String? emailError;
  String? passwordError;

  // Submit state
  bool isSubmitting = false;
  String? submitError;

  FormController([Fitur]Repository [fitur]Repository)
      : _presenter = FormPresenter([fitur]Repository),
        super();

  void onEmailChanged(String value) {
    email = value;
    emailError = _validateEmail(value);
    refreshUI();
  }

  void onPasswordChanged(String value) {
    password = value;
    passwordError = _validatePassword(value);
    refreshUI();
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email tidak boleh kosong';
    if (!isValidEmail(value)) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  bool get isFormValid => emailError == null && passwordError == null;

  void submit() {
    if (!isFormValid) return;
    isSubmitting = true;
    refreshUI();
    _presenter.submit(email, password);
  }

  @override
  void initListeners() {
    _presenter.submitOnNext = (_) {
      isSubmitting = false;
      submitError = null;
      refreshUI();
    };

    _presenter.submitOnError = (error) {
      isSubmitting = false;
      submitError = error.toString();
      refreshUI();
    };
  }
}
```

### Pattern 3: Detail Page with Refresh

```dart
// Controller
class DetailController extends Controller {
  final DetailPresenter _presenter;

  [Entity]? item;
  bool isLoading = true;
  String? errorMessage;

  DetailController([Fitur]Repository [fitur]Repository)
      : _presenter = DetailPresenter([fitur]Repository),
        super();

  void loadDetail(String id) {
    isLoading = true;
    refreshUI();
    _presenter.getDetail(id);
  }

  void refresh() {
    loadDetail(item?.id ?? '');
  }

  @override
  void initListeners() {
    _presenter.getDetailOnNext = ([Entity] result) {
      item = result;
      isLoading = false;
      errorMessage = null;
      refreshUI();
    };

    _presenter.getDetailOnError = (error) {
      isLoading = false;
      errorMessage = error.toString();
      refreshUI();
    };
  }
}

// View with RefreshIndicator
@override
Widget get view {
  return Scaffold(
    key: globalKey,
    body: RefreshIndicator(
      onRefresh: () async {
        controller.refresh();
      },
      child: ControlledWidgetBuilder<DetailController>(
        builder: (context, controller) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(child: Text(controller.errorMessage!));
          }

          if (controller.item == null) {
            return Center(child: Text('Data tidak ditemukan'));
          }

          return ListView(
            children: [
              // Detail widgets
            ],
          );
        },
      ),
    ),
  );
}
```

### Pattern 4: Delete Confirmation

```dart
// Controller
class ItemController extends Controller {
  final ItemPresenter _presenter;

  void deleteItem(String id) {
    // Show confirmation dialog
    showDialog(
      context: getContext(),
      builder: (context) => AlertDialog(
        title: Text('Hapus Item'),
        content: Text('Apakah Anda yakin ingin menghapus item ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _presenter.deleteItem(id);
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initListeners() {
    _presenter.deleteOnComplete = () {
      ScaffoldMessenger.of(getContext()).showSnackBar(
        SnackBar(content: Text('Item berhasil dihapus')),
      );
    };
  }
}
```

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Feature folder | `lowercase` | `auth`, `products`, `orders` |
| Entity | `PascalCase` | `User`, `Product`, `Order` |
| Repository interface | `[Feature]Repository` | `AuthRepository` |
| Repository impl | `[Feature]RepositoryImpl` | `AuthRepositoryImpl` |
| UseCase | `[Action]UseCase` | `LoginUseCase`, `GetProductsUseCase` |
| UseCase params | `[Action]UseCaseParams` | `LoginUseCaseParams` |
| Controller | `[Page]Controller` | `LoginController` |
| Presenter | `[Page]Presenter` | `LoginPresenter` |
| View | `[PageName]` | `LoginPage` |
| DataSource | `[Feature]RemoteDataSource` | `AuthRemoteDataSource` |
| Model | `[Entity]Model` | `UserModel`, `ProductModel` |

---

*Version: 1.0.0*
*Last Updated: 7 Januari 2025*
