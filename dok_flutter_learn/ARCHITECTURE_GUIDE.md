# Clean Architecture Guide

> Dokumentasi arsitektur Clean Architecture dengan Flutter
> Berlaku untuk semua project Flutter baru

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [The Dependency Rule](#the-dependency-rule)
3. [Architecture Layers](#architecture-layers)
4. [Technology Stack](#technology-stack)
5. [State Management Strategy](#state-management-strategy)
6. [Project Structure](#project-structure)
7. [API Throttling Strategy](#api-throttling-strategy)
8. [Error Handling Strategy](#error-handling-strategy)
9. [Dependency Injection](#dependency-injection)
10. [Routing & Navigation](#routing--navigation)
11. [Testing Strategy](#testing-strategy)
12. [Core Utilities](#core-utilities)
13. [Data Flow](#data-flow)
14. [Best Practices](#best-practices)

---

## Architecture Overview

Aplikasi menggunakan **Clean Architecture** oleh Uncle Bob yang diadaptasi untuk Flutter dengan package `flutter_clean_architecture`.

### Core Principles

1. **Separation of Concerns** - Pisahkan business logic dari implementation detail
2. **Dependency Rule** - Dependencies hanya point inward
3. **Platform Independence** - Domain layer independent dari framework
4. **Testability** - Setiap layer bisa di-test secara independent

---

## The Dependency Rule

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation (App)                      │
│                                                             │
│  View → Controller → Presenter → UseCase                    │
│                                                             │
│  Framework: Flutter Widgets                                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                        Domain                               │
│                                                             │
│  Entities + UseCases + Repository Interfaces                │
│                                                             │
│  Framework: Pure Dart (NO Flutter elements)                 │
└─────────────────────────────────────────────────────────────┘
                            ↑
┌─────────────────────────────────────────────────────────────┐
│                      Data / Device                          │
│                                                             │
│  Repository Implementation + Models + DataSources           │
│                                                             │
│  Framework: DIO, SQLite, Platform Channels                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Rule

**Source code dependencies only point inwards**

- Inner layers tidak aware dari outer layers
- Outer layers aware dan dependent pada inner layers
- Semua communication menggunakan **polymorphism** (abstract classes)

---

## Architecture Layers

### 1. Domain Layer (Inner-most)

Layer paling dalam, berisi business logic murni. **Independent dari framework** (Pure Dart).

#### Components

| Component | Description | Example |
|-----------|-------------|---------|
| **Entities** | Enterprise-wide business rules | `User`, `Product`, `Order` |
| **UseCases** | Application-specific business rules | `LoginUseCase`, `GetProductsUseCase` |
| **Repositories (Interfaces)** | Abstract definitions of data operations | `AuthRepository`, `ProductRepository` |

#### Rules

- ✅ Pure Dart only
- ✅ No Flutter imports
- ✅ No framework dependencies
- ✅ Highly reusable
- ✅ Easy to test

---

### 2. App/Presentation Layer

Layer di luar Domain, berisi UI dan event handling. **Paling framework-dependent**.

#### Components

| Component | Description | Extends |
|-----------|-------------|---------|
| **View** | UI representation | `View`, `ViewState<View, Controller>` |
| **Controller** | Event handlers, dynamic data | `Controller` |
| **Presenter** | Communicates with UseCase | `Presenter` |
| **Observer** | Observes UseCase stream | `Observer<T>` |

#### Controller Lifecycle

```dart
class MyController extends Controller {
  @override
  void onInitState() { }        // Called when state initialized

  @override
  void onDisposed() { }         // Called when controller disposed

  @override
  void initListeners() { }      // MUST implement: setup presenter listeners
}
```

---

### 3. Data Layer

Berisi implementation detail untuk data retrieval.

#### Components

| Component | Description | Example |
|-----------|-------------|---------|
| **Repositories (Impl)** | Implements domain repository interfaces | `AuthRepositoryImpl` |
| **Models** | DTOs for API/Database | `UserModel`, `ProductModel` |
| **DataSources** | API calls, Database queries | `AuthRemoteDataSource` |
| **Mappers** | Convert Entity ↔ Model | `UserMapper` |

---

### 4. Device Layer

Berisi platform-specific features yang berkomunikasi langsung dengan native platform (Android/iOS).

#### Components

| Component | Description | Example |
|-----------|-------------|---------|
| **Devices** | Native functionality wrappers | `GPSDevice`, `CameraDevice`, `StorageDevice` |
| **Permissions** | Permission handlers | `LocationPermission`, `CameraPermission` |

#### Example

```dart
// device/repositories/gps_device.dart (abstract)
abstract class GPSDevice {
  Future<Position> getCurrentPosition();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
}

// device/repositories/gps_device_impl.dart
class GPSDeviceImpl implements GPSDevice {
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  @override
  Future<Position> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw PermissionDeniedException('Location permission denied');
    }

    return await _geolocator.getCurrentPosition();
  }

  @override
  Future<bool> hasPermission() async {
    return await _geolocator.checkPermission() == LocationPermission.always;
  }

  @override
  Future<bool> requestPermission() async {
    final status = await _geolocator.requestPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }
}
```

#### Device Layer Structure

```
device/
├── repositories/             # Device repositories
│   ├── gps_device.dart       # abstract
│   └── gps_device_impl.dart  # implementation
└── utils/                    # Device-specific utilities
    └── permission_handler.dart
```

---

## Technology Stack

### Core Dependencies

```yaml
dependencies:
  # Architecture
  flutter_clean_architecture: ^6.0.2
  flutter_riverpod: ^2.4.9

  # Network
  dio: ^5.4.0
  retrofit: ^4.0.3
  pretty_dio_logger: ^1.3.1

  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Reactive
  rxdart: ^0.27.7

  # Utils
  equatable: ^2.0.5
  dartz: ^0.10.1
  intl: ^0.18.1
```

### Why flutter_clean_architecture?

| Feature | Benefit |
|---------|---------|
| Built-in Controllers | Less boilerplate than BLoC |
| Stream-based | Reactive programming with RxDart |
| Observer pattern | Clean UseCase execution |
| Lifecycle management | Built-in state management |
| Flutter-integrated | Designed specifically for Flutter |

---

## State Management Strategy

### Hybrid Approach: flutter_clean_architecture + Riverpod

| Scenario | Technology | Reason |
|----------|-----------|--------|
| UI state per page | flutter_clean_architecture Controller | Built-in, designed for pages |
| Form validation | flutter_clean_architecture Controller | Local state, lifecycle-aware |
| Auth session | Riverpod Provider | Global state, persistence |
| User profile | Riverpod Provider | Shared across pages |
| App configuration | Riverpod Provider | Global settings |

### When to Use What

#### Use flutter_clean_architecture Controller for:
- State terikat pada satu page/screen
- Form handling dan validation
- UI events (button press, input change)
- Page-specific loading/error states

#### Use Riverpod Provider for:
- Authentication session
- User profile data
- Application configuration
- Data shared antar pages
- Caching dengan auto-dispose

---

## Project Structure

Project menggunakan **Feature-First structure** untuk modularitas dan scalability.

### Overview

```
lib/
├── core/                              # Cross-cutting concerns (SHARED)
│   ├── constants/                     # API endpoints, app constants
│   ├── errors/                        # Exceptions, failures
│   ├── network/                       # API client, interceptors
│   ├── utils/                         # Validators, helpers
│   ├── widgets/                       # Shared widgets
│   └── providers/                     # Global Riverpod providers
│
├── features/                          # FITUR MODULES
│   └── [nama_fitur]/
│       ├── domain/                    # Business logic (Pure Dart)
│       │   ├── entities/              # Business entities
│       │   ├── repositories/          # Repository interfaces
│       │   └── usecases/              # Business logic
│       ├── data/                      # Data implementation
│       │   ├── repositories/          # Repository implementations
│       │   ├── models/                # DTOs
│       │   ├── datasources/           # API, database
│       │   └── mappers/               # Entity ↔ Model
│       └── presentation/              # UI implementation
│           ├── pages/                 # Screens
│           └── widgets/               # Feature-specific widgets
│
├── routes/                            # Navigation routing
└── main.dart                          # Entry point
```

### Feature Structure Detail

```
features/auth/                         # CONTOH FITUR
├── domain/
│   ├── entities/
│   │   └── user.dart
│   ├── repositories/
│   │   └── auth_repository.dart       # abstract
│   └── usecases/
│       ├── login/
│       │   └── login_usecase.dart
│       ├── logout/
│       │   └── logout_usecase.dart
│       └── get_current_user/
│           └── get_current_user_usecase.dart
│
├── data/
│   ├── repositories/
│   │   └── auth_repository_impl.dart  # implements auth_repository
│   ├── models/
│   │   └── user_model.dart
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart
│   │   └── auth_local_datasource.dart
│   └── mappers/
│       └── user_mapper.dart
│
└── presentation/
    ├── pages/
    │   ├── login/
    │   │   ├── login_controller.dart
    │   │   ├── login_presenter.dart
    │   │   └── login_view.dart
    │   └── register/
    │       ├── register_controller.dart
    │       ├── register_presenter.dart
    │       └── register_view.dart
    └── widgets/
        └── auth_form_widget.dart
```

### Benefits of Feature-First

✅ **Modular** - Setiap fitur independent dan self-contained
✅ **Easy Navigation** - Semua file terkait satu fitur dalam satu folder
✅ **Team Collaboration** - Developer bisa kerja paralel di fitur berbeda
✅ **Scalable** - Mudah menambah fitur baru
✅ **Maintainable** - Perubahan satu fitur tidak mempengaruhi fitur lain
✅ **Easy to Test** - Setiap fitur bisa di-test secara independent

---

## API Throttling Strategy

### What is Throttling?

Membatasi frekuensi request yang sama untuk mencegah spam dan overload server.

**Rule:** Request yang sama hanya boleh dieksekusi 1x dalam 2 detik.

### Implementation: DIO Interceptor (Recommended)

Gunakan **DIO Interceptor** untuk throttling secara global. Keuntungan:

✅ **Centralized** - Semua request otomatis di-throttle
✅ **Reusable** - Tidak perlu buat throttle di setiap UseCase
✅ **Transparent** - UseCase tidak perlu aware adanya throttling
✅ **Configurable** - Mudah adjust throttle duration

### ThrottleInterceptor Implementation

```dart
// core/network/interceptors/throttle_interceptor.dart
import 'package:dio/dio.dart';

class ThrottleInterceptor extends Interceptor {
  final Duration throttleDuration;
  final Map<String, DateTime> _lastRequestTime = {};

  ThrottleInterceptor({
    this.throttleDuration = const Duration(seconds: 2),
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Generate unique key untuk request
    final key = _generateRequestKey(options);

    // Check throttle
    if (_lastRequestTime.containsKey(key)) {
      final lastTime = _lastRequestTime[key]!;
      final elapsed = DateTime.now().difference(lastTime);

      if (elapsed < throttleDuration) {
        final waitTime = throttleDuration - elapsed;

        // Log throttle warning
        print('Throttling request to ${options.path}. '
              'Waiting ${waitTime.inMilliseconds}ms');

        // Tunggu sampai throttle time habis
        await Future.delayed(waitTime);
      }
    }

    // Mark request time
    _lastRequestTime[key] = DateTime.now();

    // Lanjutkan request
    handler.next(options);
  }

  /// Generate unique key untuk request
  /// Bisa dicustom sesuai kebutuhan
  String _generateRequestKey(RequestOptions options) {
    // Key berdasarkan method + path + body (untuk POST/PUT)
    if (options.method == 'GET' || options.data == null) {
      return '${options.method}_${options.path}';
    }

    // Untuk request dengan body, hash body untuk key
    final bodyHash = options.data.hashCode;
    return '${options.method}_${options.path}_$bodyHash';
  }

  /// Clear throttle history (opsional, untuk testing)
  void clear() {
    _lastRequestTime.clear();
  }

  /// Clear throttle untuk endpoint tertentu
  void clearEndpoint(String path) {
    _lastRequestTime.removeWhere((key, value) => key.contains(path));
  }
}
```

### Setup di ApiClient

```dart
// core/network/api_client.dart
import 'package:dio/dio.dart';
import 'interceptors/throttle_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/log_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({
    required String baseUrl,
    Duration throttleDuration = const Duration(seconds: 2),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      // Throttle interceptor (tambahkan pertama)
      ThrottleInterceptor(throttleDuration: throttleDuration),

      // Auth interceptor (inject token)
      AuthInterceptor(),

      // Log interceptor (debug)
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
  }) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
  }) async {
    return _dio.delete(path, data: data);
  }
}
```

### Custom Throttle per Endpoint

Jika perlu different throttle duration untuk endpoint tertentu:

```dart
// core/network/interceptors/throttle_interceptor.dart
class ThrottleInterceptor extends Interceptor {
  final Duration defaultThrottleDuration;
  final Map<String, Duration> _endpointThrottleDuration;
  final Map<String, DateTime> _lastRequestTime = {};

  ThrottleInterceptor({
    this.defaultThrottleDuration = const Duration(seconds: 2),
    Map<String, Duration>? endpointThrottleDuration,
  }) : _endpointThrottleDuration = endpointThrottleDuration ?? {
          // Custom throttle untuk endpoint tertentu
          '/auth/login': const Duration(seconds: 5), // Login lebih lama
          '/auth/refresh': const Duration(milliseconds: 500),
        };

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final key = _generateRequestKey(options);

    // Cek throttle duration untuk endpoint ini
    final throttleDuration = _getThrottleDuration(options.path);

    if (_lastRequestTime.containsKey(key)) {
      final lastTime = _lastRequestTime[key]!;
      final elapsed = DateTime.now().difference(lastTime);

      if (elapsed < throttleDuration) {
        await Future.delayed(throttleDuration - elapsed);
      }
    }

    _lastRequestTime[key] = DateTime.now();
    handler.next(options);
  }

  Duration _getThrottleDuration(String path) {
    // Cek apakah path ada custom duration
    for (final entry in _endpointThrottleDuration.entries) {
      if (path.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return defaultThrottleDuration;
  }

  String _generateRequestKey(RequestOptions options) {
    if (options.method == 'GET' || options.data == null) {
      return '${options.method}_${options.path}';
    }
    final bodyHash = options.data.hashCode;
    return '${options.method}_${options.path}_$bodyHash';
  }
}
```

### Usage

```dart
// core/network/api_client.dart
final apiClient = ApiClient(
  baseUrl: 'https://api.example.com',
  throttleDuration: const Duration(seconds: 2),
);

// Semua request otomatis di-throttle
// Tidak perlu logic tambahan di UseCase!
final response = await apiClient.post('/auth/login', data: {...});
```

### Benefits

| Tanpa Interceptor | Dengan Interceptor |
|-------------------|-------------------|
| Throttle di setiap UseCase | Throttle centralized |
| Banyak duplikasi kode | Single implementation |
| Mudah lupa implement | Otomatis untuk semua request |
| Sulit maintain | Mudah modify |

### Advanced: Queue-based Throttling

Untuk throttling yang lebih advanced dengan queue:

```dart
class QueueThrottleInterceptor extends Interceptor {
  final Duration throttleDuration;
  final Map<String, List<_Request>> _requestQueue = {};

  QueueThrottleInterceptor({
    this.throttleDuration = const Duration(seconds: 2),
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final key = _generateRequestKey(options);

    if (!_requestQueue.containsKey(key)) {
      _requestQueue[key] = [];
    }

    final queue = _requestQueue[key]!;

    if (queue.isEmpty) {
      // Tidak ada antrian, langsung eksekusi
      _lastRequestTime[key] = DateTime.now();
      handler.next(options);
    } else {
      // Tambah ke antrian
      final request = _Request(options, handler);
      queue.add(request);
      _processQueue(key);
    }
  }

  void _processQueue(String key) async {
    while (_requestQueue[key]!.isNotEmpty) {
      final lastTime = _lastRequestTime[key] ?? DateTime.now();
      final elapsed = DateTime.now().difference(lastTime);

      if (elapsed >= throttleDuration) {
        final request = _requestQueue[key]!.removeAt(0);
        _lastRequestTime[key] = DateTime.now();
        request.handler.next(request.options);
      } else {
        await Future.delayed(throttleDuration - elapsed);
      }
    }
  }
}

class _Request {
  final RequestOptions options;
  final RequestInterceptorHandler handler;

  _Request(this.options, this.handler);
}
```

---

## Error Handling Strategy

### Exception Types

Aplikasi menggunakan hierarchical exception types untuk konsistensi error handling.

#### Exception Hierarchy

```
Exception
├── AppException                    # Base exception
│   ├── ServerException             # API errors (4xx, 5xx)
│   ├── NetworkException            # No internet, timeout
│   ├── UnauthorizedException       # 401, invalid token
│   ├── NotFoundException           # 404, resource not found
│   ├── ValidationException         # 400, invalid input
│   ├── CacheException              # Cache errors
│   ├── PermissionException         # Permission denied
│   └── ThrottledException          # Request throttled
```

### Exception Definitions

```dart
// core/errors/exceptions.dart
/// Base exception untuk semua aplikasi exceptions
abstract class AppException implements Exception {
  final String message;
  final int? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Server returned error response (4xx, 5xx)
class ServerException extends AppException {
  const ServerException(
    String message, {
    int? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// No internet connection or timeout
class NetworkException extends AppException {
  const NetworkException(
    String message, {
    dynamic originalError,
  }) : super(message, originalError: originalError);
}

/// Authentication failed (401)
class UnauthorizedException extends AppException {
  const UnauthorizedException(
    String message, {
    int? code = 401,
  }) : super(message, code: code);
}

/// Resource not found (404)
class NotFoundException extends AppException {
  const NotFoundException(
    String message, {
    int? code = 404,
  }) : super(message, code: code);
}

/// Input validation failed (400)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    String message, {
    this.fieldErrors,
    int? code = 400,
  }) : super(message, code: code);
}

/// Cache operation failed
class CacheException extends AppException {
  const CacheException(
    String message, {
    dynamic originalError,
  }) : super(message, originalError: originalError);
}

/// Permission denied
class PermissionException extends AppException {
  const PermissionException(
    String message, {
    dynamic originalError,
  }) : super(message, originalError: originalError);
}

/// Request throttled
class ThrottledException extends AppException {
  const ThrottledException(
    String message, {
    int? code = 429,
  }) : super(message, code: code);
}
```

### Error Handling Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  DataSource throws Exception → Repository catches           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                           │
│  UseCase receives exception → Throws to Presenter           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Presentation Layer                        │
│  Presenter onError → Controller handles → View shows        │
└─────────────────────────────────────────────────────────────┘
```

### Implementation Examples

#### DataSource Error Handling

```dart
// data/datasources/auth_remote_datasource.dart
@override
Future<UserModel> login({
  required String email,
  required String password,
}) async {
  try {
    final response = await apiClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(response.data['data']);
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Invalid email or password');
    } else if (response.statusCode == 404) {
      throw NotFoundException('User not found');
    } else {
      throw ServerException(
        response.data['message'] ?? 'Login failed',
        code: response.statusCode,
      );
    }
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw NetworkException('Connection timeout. Check your internet.');
    }

    if (e.type == DioExceptionType.connectionError) {
      throw NetworkException('No internet connection.');
    }

    throw ServerException(e.message ?? 'Network error');
  }
}
```

#### Repository Error Handling

```dart
// data/repositories/auth_repository_impl.dart
@override
Future<User> login({
  required String email,
  required String password,
}) async {
  try {
    final model = await remoteDataSource.login(
      email: email,
      password: password,
    );

    // Cache user session
    await localDataSource.cacheUser(model);

    return model.toEntity();
  } on ServerException {
    rethrow;  // Re-throw server exceptions
  } on NetworkException {
    rethrow;  // Re-throw network exceptions
  } on UnauthorizedException {
    rethrow;
  } on CacheException {
    // Cache failed, but login successful, continue
    logger.warning('Failed to cache user session');
    rethrow;
  } catch (e) {
    throw ServerException('Unexpected error: $e');
  }
}
```

#### UseCase Error Handling

```dart
// domain/usecases/login/login_usecase.dart
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
  } on UnauthorizedException catch (e) {
    logger.warning('LoginUseCase unauthorized: $e');
    controller.addError(e);
  } on NetworkException catch (e) {
    logger.severe('LoginUseCase network error: $e');
    controller.addError(e);
  } on ServerException catch (e) {
    logger.severe('LoginUseCase server error: $e');
    controller.addError(e);
  } catch (e) {
    logger.severe('LoginUseCase unexpected error: $e');
    controller.addError(ServerException('Unexpected error: $e'));
  }

  return controller.stream;
}
```

#### Controller Error Handling

```dart
// presentation/pages/login/login_controller.dart
@override
void initListeners() {
  _presenter.loginOnNext = (user) {
    isLoading = false;
    errorMessage = null;
    refreshUI();

    // Navigate to home
    FlutterCleanArchitecture.getNavigator(getContext())
        .pushReplacementNamed('/home');
  };

  _presenter.loginOnError = (error) {
    isLoading = false;

    // Handle specific error types
    if (error is UnauthorizedException) {
      errorMessage = 'Email atau password salah';
    } else if (error is NetworkException) {
      errorMessage = 'Tidak ada koneksi internet';
    } else if (error is ThrottledException) {
      errorMessage = error.message;
    } else {
      errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
    }

    refreshUI();
  };
}
```

### Error Messages

```dart
// core/constants/error_messages.dart
class ErrorMessages {
  // Network
  static const String noInternet = 'Tidak ada koneksi internet';
  static const String connectionTimeout = 'Koneksi timeout';
  static const String serverTimeout = 'Server tidak merespons';

  // Auth
  static const String invalidCredentials = 'Email atau password salah';
  static const String sessionExpired = 'Sesi telah berakhir. Silakan login kembali';
  static const String accountNotFound = 'Akun tidak ditemukan';

  // Validation
  static const String requiredField = 'Field ini harus diisi';
  static const String invalidEmail = 'Format email tidak valid';
  static const String passwordTooShort = 'Password minimal 6 karakter';

  // General
  static const String somethingWentWrong = 'Terjadi kesalahan. Silakan coba lagi';
  static const String tryAgainLater = 'Silakan coba lagi nanti';
}
```

### User-Friendly Error Display

```dart
// presentation/widgets/error_message_widget.dart
class ErrorMessageWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;

  const ErrorMessageWidget({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    if (error is NetworkException) {
      message = error.message;
      icon = Icons.wifi_off;
      color = Colors.orange;
    } else if (error is UnauthorizedException) {
      message = error.message;
      icon = Icons.lock_outline;
      color = Colors.red;
    } else if (error is ThrottledException) {
      message = error.message;
      icon = Icons.access_time;
      color = Colors.amber;
    } else {
      message = ErrorMessages.somethingWentWrong;
      icon = Icons.error_outline;
      color = Colors.grey;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Coba Lagi'),
          ),
        ],
      ],
    );
  }
}
```

---

## Dependency Injection

### Overview

Dependency Injection (DI) adalah technique untuk memisahkan object creation dari business logic.

### Why Constructor Injection?

```dart
// ❌ BAD - Hardcoded dependency
class LoginController extends Controller {
  final LoginPresenter _presenter = LoginPresenter(AuthRepositoryImpl());

  // Tidak bisa test karena dependency hardcoded!
}

// ✅ GOOD - Constructor injection
class LoginController extends Controller {
  final LoginPresenter _presenter;

  LoginController(AuthRepository authRepo)  // Injected
      : _presenter = LoginPresenter(authRepo),
        super();

  // Bisa test dengan mock repository!
}
```

### DI with Riverpod

#### Repository Providers

```dart
// core/providers/repository_providers.dart

// Remote DataSource provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient: apiClient);
});

// Local DataSource provider
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});
```

#### UseCase Providers

```dart
// core/providers/usecase_providers.dart

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return LoginUseCase(authRepo);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return LogoutUseCase(authRepo);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(authRepo);
});
```

#### Controller Providers (Optional)

Jika ingin menggunakan Riverpod untuk Controllers:

```dart
// features/auth/presentation/providers/login_controller_provider.dart

final loginControllerProvider = StateProvider<LoginController>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return LoginController(authRepo);
});
```

### Usage in View

```dart
// presentation/pages/login/login_view.dart
class _LoginState extends CleanViewState<LoginPage, LoginController> {
  _LoginState() : super(LoginController(
    // Riverpod injects dependencies
    ref.read(authRepositoryProvider),
  ));

  @override
  Widget get view {
    return Consumer(
      builder: (context, ref, child) {
        // Access global state
        final authState = ref.watch(authStateProvider);

        return Scaffold(
          // ...
        );
      },
    );
  }
}
```

### Provider Scope

| Provider Type | Scope | Use Case |
|--------------|-------|----------|
| `Provider` | Singleton | Repository, UseCase, DataSource |
| `StateNotifierProvider` | Singleton stateful | Auth session, User profile |
| `FutureProvider` | Async, auto-dispose | One-time data fetch |
| `StreamProvider` | Stream, auto-dispose | Real-time data |

### Testing with DI

```dart
// test/login_test.dart

void main() {
  test('should login successfully', () async {
    // Mock repository
    final mockRepo = MockAuthRepository();
    when(mockRepo.login(email: any, password: any))
        .thenAnswer((_) async => User(id: '1', name: 'Test'));

    // Inject mock
    final controller = LoginController(mockRepo);

    // Test
    controller.login('test@test.com', 'password');

    verify(mockRepo.login(email: 'test@test.com', password: 'password'));
  });
}
```

---

## Routing & Navigation

### Route Structure

```dart
// routes/app_router.dart
class AppRouter {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main routes
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Feature routes
  static const String aktivitasList = '/aktivitas';
  static const String aktivitasDetail = '/aktivitas/:id';
  static const String aktivitasCreate = '/aktivitas/create';
  static const String aktivitasEdit = '/aktivitas/:id/edit';
}
```

### Route Configuration

```dart
// routes/app_router.dart
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

      case AppRouter.home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );

      case AppRouter.aktivitasDetail:
        final id = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => AktivitasDetailPage(aktivitasId: id ?? ''),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
        );
    }
  }
}
```

### Auth Guard

```dart
// routes/route_guard.dart
class RouteGuard {
  final AuthRepository _authRepository;

  const RouteGuard(this._authRepository);

  /// Check if user can access route
  Future<bool> canActivate(String route) async {
    // Public routes
    if (_isPublicRoute(route)) {
      return true;
    }

    // Check authentication
    final isAuthenticated = await _authRepository.isAuthenticated();

    if (!isAuthenticated) {
      return false;
    }

    return true;
  }

  bool _isPublicRoute(String route) {
    return route == AppRouter.login ||
        route == AppRouter.register ||
        route == AppRouter.forgotPassword;
  }

  /// Get login route if not authenticated
  String getLoginRoute(String originalRoute) {
    return '${AppRouter.login}?redirect=$originalRoute';
  }
}
```

### Navigation Service

```dart
// core/navigation/navigation_service.dart
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey;

  NavigationService() : navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get navigator => navigatorKey.currentState!;

  /// Navigate to route
  Future<T?> navigateTo<T>(String route, {Object? arguments}) {
    return navigator.pushNamed<T>(route, arguments: arguments);
  }

  /// Replace route
  Future<T?> replaceWith<T>(String route, {Object? arguments}) {
    return navigator.pushReplacementNamed<T, Object?>(
      route,
      arguments: arguments,
    );
  }

  /// Go back
  void goBack<T>([T? result]) {
    navigator.pop(result);
  }

  /// Clear all and navigate
  Future<T?> clearAndNavigate<T>(String route) {
    return navigator.pushNamedAndRemoveUntil<T>(
      route,
      (route) => false,
    );
  }

  /// Show dialog
  Future<T?> showDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return Navigator.of(
      navigatorKey.currentContext!,
    ).show<T>(
      DialogRoute<T>(
        context: navigatorKey.currentContext!,
        builder: builder,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  /// Show snackbar
  void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final scaffold = ScaffoldMessenger.of(
      navigatorKey.currentContext!,
    );

    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }
}
```

### Navigation with Controller

```dart
// presentation/pages/home/home_controller.dart
class HomeController extends Controller {
  final NavigationService _navigationService;

  HomeController(this._navigationService);

  void navigateToProfile() {
    _navigationService.navigateTo(AppRouter.profile);
  }

  void navigateToAktivitasDetail(String id) {
    _navigationService.navigateTo(
      AppRouter.aktivitasDetail,
      arguments: id,
    );
  }

  void logout() {
    // Clear all and go to login
    _navigationService.clearAndNavigate(AppRouter.login);
  }

  void showLogoutDialog() {
    _navigationService.showDialog(
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => _navigationService.goBack(),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _navigationService.goBack();
              logout();
            },
            child: Text('Ya', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

---

## Testing Strategy

### Test Pyramid

```
                ┌─────────┐
               │   E2E   │  10% - Integration tests
              └─────────┘
             ┌───────────┐
            │  Widget    │  20% - UI tests
           └───────────┘
          ┌──────────────┐
         │   Unit        │  70% - Business logic
        └──────────────┘
```

### Unit Tests

Test business logic secara isolated.

#### Domain Layer Tests

```dart
// test/domain/usecases/login/login_usecase_test.dart
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = LoginUseCase(mockRepo);
  });

  group('LoginUseCase', () {
    const tEmail = 'test@test.com';
    const tPassword = 'password123';
    const tUser = User(id: '1', name: 'Test User', email: tEmail);

    test('should return User when login successful', () async {
      // arrange
      when(mockRepo.login(email: tEmail, password: tPassword))
          .thenAnswer((_) async => tUser);

      // act
      final result = await useCase(
        LoginUseCaseParams(tEmail, tPassword),
      ).first;

      // assert
      expect(result, equals(tUser));
      verify(mockRepo.login(email: tEmail, password: tPassword));
      verifyNoMoreInteractions(mockRepo);
    });

    test('should throw UnauthorizedException when credentials invalid', () async {
      // arrange
      when(mockRepo.login(email: any, password: any))
          .thenThrow(UnauthorizedException('Invalid credentials'));

      // act & assert
      expect(
        () => useCase(LoginUseCaseParams(tEmail, tPassword)).first,
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
```

#### Data Layer Tests

```dart
// test/data/repositories/auth_repository_impl_test.dart
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('login', () {
    const tEmail = 'test@test.com';
    const tPassword = 'password123';
    const tUserModel = UserModel(id: '1', name: 'Test', email: tEmail);
    final tUser = User(id: '1', name: 'Test', email: tEmail);

    test('should return User when login successful', () async {
      // arrange
      when(mockRemoteDataSource.login(email: tEmail, password: tPassword))
          .thenAnswer((_) async => tUserModel);
      when(mockLocalDataSource.cacheUser(any))
          .thenAnswer((_) async => unit);

      // act
      final result = await repository.login(email: tEmail, password: tPassword);

      // assert
      expect(result, equals(tUser));
      verify(mockRemoteDataSource.login(email: tEmail, password: tPassword));
      verify(mockLocalDataSource.cacheUser(tUserModel));
    });

    test('should throw ServerException when remote call fails', () async {
      // arrange
      when(mockRemoteDataSource.login(email: any, password: any))
          .thenThrow(ServerException('Server error'));

      // act & assert
      expect(
        () => repository.login(email: tEmail, password: tPassword),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
```

### Widget Tests

Test UI components dan interactions.

```dart
// test/presentation/pages/login/login_view_test.dart
void main() {
  testWidgets('should show error message when login fails',
      (WidgetTester tester) async {
    // arrange
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [
            authRepositoryProvider
                .overrideWithValue(MockAuthRepository()),
          ],
          child: const LoginPage(),
        ),
      ),
    );

    // act
    await tester.enterText(
      find.byKey(Key('email_field')),
      'invalid@email.com',
    );
    await tester.enterText(
      find.byKey(Key('password_field')),
      'wrong',
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // assert
    expect(find.text('Email atau password salah'), findsOneWidget);
  });

  testWidgets('should navigate to home when login successful',
      (WidgetTester tester) async {
    // arrange
    final mockRepo = MockAuthRepository();
    when(mockRepo.login(email: any, password: any)).thenAnswer(
      (_) async => User(id: '1', name: 'Test', email: 'test@test.com'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const LoginPage(),
        ),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );

    // act
    await tester.enterText(
      find.byKey(Key('email_field')),
      'test@test.com',
    );
    await tester.enterText(
      find.byKey(Key('password_field')),
      'password123',
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // assert
    expect(find.byType(HomePage), findsOneWidget);
  });
}
```

### Integration Tests

Test full flow dengan real API (staging).

```dart
// integration_test/auth_flow_test.dart
void main() {
  group('Authentication Flow', () {
    testWidgets('login, navigate home, logout', (tester) async {
      // Start app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Should see login page
      expect(find.text('Welcome'), findsOneWidget);

      // Enter credentials
      await tester.enterText(
        find.byKey(Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'password123',
      );

      // Tap login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should see home page
      expect(find.text('Home'), findsOneWidget);

      // Logout
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Should back to login
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

### Test Coverage Goal

| Layer | Target Coverage | Priority |
|-------|----------------|----------|
| Domain | 100% | Must |
| Data | 90% | Must |
| Presentation | 80% | Should |
| Integration | Key flows only | Should |

---

## Core Utilities

### Folder Structure

```
core/
├── constants/
│   ├── api_constants.dart           # API endpoints, timeouts
│   ├── app_constants.dart           # App-wide constants
│   ├── storage_constants.dart       # Storage keys
│   └── error_messages.dart          # Error messages
├── errors/
│   ├── exceptions.dart              # Custom exceptions
│   └── failures.dart                # Failure types
├── network/
│   ├── api_client.dart              # HTTP client wrapper
│   ├── dio_client.dart              # DIO implementation
│   ├── network_info.dart            # Connectivity checker
│   └── interceptors/
│       ├── auth_interceptor.dart    # JWT injection
│       ├── log_interceptor.dart     # API logging
│       └── throttle_interceptor.dart # Request throttling
├── utils/
│   ├── validators.dart              # Input validators
│   ├── formatters.dart              # Date, currency formatters
│   ├── logger.dart                  # Logging utility
│   └── date_utils.dart              # Date utilities
└── widgets/
    ├── loading/
    │   └── loading_widget.dart
    ├── error/
    │   └── error_widget.dart
    └── form/
        ├── custom_text_field.dart
        ├── custom_password_field.dart
        └── custom_dropdown.dart
```

### API Constants

```dart
// core/constants/api_constants.dart
class ApiConstants {
  // Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  // Endpoints
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authRegister = '/auth/register';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
```

### Validators

```dart
// core/utils/validators.dart
class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{6,}$',
  );

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'Password harus mengandung huruf dan angka';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validate NIP (Nomor Induk Pegawai)
  static String? validateNIP(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIP tidak boleh kosong';
    }
    if (value.length < 16) {
      return 'NIP minimal 16 karakter';
    }
    return null;
  }

  /// Check if email is valid
  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }
}
```

### Formatters

```dart
// core/utils/formatters.dart
class Formatters {
  /// Format date to readable string
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  /// Format currency (IDR)
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  /// Format number with thousand separator
  static String formatNumber(int number) {
    return NumberFormat.decimalPattern('id_ID').format(number);
  }

  /// Format phone number
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digits
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Format: 0812-3456-7890
    if (digits.length >= 10) {
      return '${digits.substring(0, 4)}-${digits.substring(4, 8)}-${digits.substring(8)}';
    }

    return phoneNumber;
  }
}
```

### Logger

```dart
// core/utils/logger.dart
import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('AppLogger');

  static void setup() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // In production, send to logging service
      if (kDebugMode) {
        print(
          '[${record.level.name}] ${record.loggerName}: ${record.message}',
        );
      }
    });
  }

  static void info(String message) {
    _logger.info(message);
  }

  static void warning(String message) {
    _logger.warning(message);
  }

  static void severe(String message) {
    _logger.severe(message);
  }

  static void fine(String message) {
    _logger.fine(message);
  }
}
```

### Network Info

```dart
// core/network/network_info.dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectivity, this.connectionChecker);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();

    if (result == ConnectivityResult.none) {
      return false;
    }

    return await connectionChecker.hasConnection;
  }
}
```

---

## Data Flow

### Complete Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER ACTION                                 │
│                     (Button Press, Input)                            │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                              VIEW                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  ControlledWidgetBuilder<Controller>                          │  │
│  │    - Displays data from controller                            │  │
│  │    - Calls controller methods on user action                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                           CONTROLLER                                 │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  - Handles UI events                                         │  │
│  │  - Validates input                                           │  │
│  │  - Updates UI state (loading, error)                          │  │
│  │  - Calls Presenter methods                                    │  │
│  │  - Listens to Presenter callbacks                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                           PRESENTER                                  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  - Has UseCase                                               │  │
│  │  - Executes UseCase with params                              │  │
│  │  - Listens to UseCase via Observer                           │  │
│  │  - Notifies Controller of results (onNext, onError)          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                            USECASE                                   │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  - Has Repository (abstract)                                  │  │
│  │  - Contains business logic                                    │  │
│  │  - Returns Stream<Entity>                                     │  │
│  │  - Emits: data, error, or complete                            │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                          REPOSITORY                                 │
│  (Implementation in Data Layer)                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  - Has DataSource                                            │  │
│  │  - Handles data transformation (Model ↔ Entity)              │  │
│  │  - Caches data if needed                                      │  │
│  │  - Handles errors                                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         DATASOURCE                                  │
│  ┌─────────────────────┬─────────────────────────────────────┐      │
│  │  Remote DataSource  │      Local DataSource              │      │
│  │  - API calls        │      - SQLite, SharedPreferences   │      │
│  │  - DIO client       │      - Cache, Session              │      │
│  │  - Returns Models   │      - Returns Models              │      │
│  └─────────────────────┴─────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                          RESPONSE                                   │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Remote: API Response (JSON) → Model → Entity                │  │
│  │  Local: Database/File → Model → Entity                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Login Flow Example

```
┌─────────────────────────────────────────────────────────────────────┐
│  USER: Enters email & password, taps "Login"                        │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  VIEW: ControlledWidgetBuilder calls controller.login()            │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  CONTROLLER:                                                       │
│    1. Validates input                                              │
│    2. Sets isLoading = true, refreshUI()                           │
│    3. Calls presenter.login(email, password)                       │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  PRESENTER:                                                        │
│    1. Creates LoginUseCaseParams(email, password)                  │
│    2. Executes useCase.execute(observer, params)                   │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  USECASE:                                                          │
│    1. Receives params from Presenter                               │
│    2. Calls repository.login(email, password)                      │
│    3. Creates Stream, waits for result                             │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  REPOSITORY (Data Layer):                                          │
│    1. Receives login() call                                        │
│    2. Calls remoteDataSource.login(email, password)                │
│    3. Receives UserModel                                           │
│    4. Converts UserModel → User entity                             │
│    5. Caches user in localDataSource                               │
│    6. Returns User entity                                          │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  REMOTE DATASOURCE:                                                │
│    1. Receives login() call                                       │
│    2. Makes POST request to /auth/login                            │
│    3. Receives JSON response                                       │
│    4. Parses JSON → UserModel                                     │
│    5. Returns UserModel                                           │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  RESPONSE FLOW (Success):                                          │
│    1. UseCase emits User via Stream                                │
│    2. Observer.onNext(User) called                                 │
│    3. Presenter.onNext(User) called                                │
│    4. Controller.loginOnNext(User) called                          │
│    5. Controller sets isLoading = false, stores User               │
│    6. Controller.refreshUI()                                       │
│    7. View rebuilds with new data                                  │
│    8. Controller navigates to Home                                 │
└─────────────────────────────────────────────────────────────────────┘

                                  OR (Error)

┌─────────────────────────────────────────────────────────────────────┐
│  RESPONSE FLOW (Error):                                            │
│    1. DataSource throws UnauthorizedException                      │
│    2. Repository re-throws exception                               │
│    3. UseCase emits exception via Stream                           │
│    4. Observer.onError(exception) called                           │
│    5. Presenter.onError(exception) called                          │
│    6. Controller.loginOnError(exception) called                    │
│    7. Controller sets isLoading = false, errorMessage = error      │
│    8. Controller.refreshUI()                                       │
│    9. View rebuilds showing error message                          │
└─────────────────────────────────────────────────────────────────────┘
```

### Read/Query Flow Example

```
┌─────────────────────────────────────────────────────────────────────┐
│  USER: Opens page showing list of items                             │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  VIEW initState(): Calls controller.loadItems()                    │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  CONTROLLER:                                                       │
│    1. Sets isLoading = true, refreshUI()                           │
│    2. Calls presenter.getItems()                                   │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  PRESENTER:                                                         │
│    1. Executes GetItemsUseCase()                                   │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  USECASE:                                                          │
│    1. Calls repository.getItems()                                  │
│    2. Returns Stream<List<Item>>                                   │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  REPOSITORY:                                                       │
│    1. Checks cache first (optional)                                │
│    2. If cache empty, calls remoteDataSource.getItems()            │
│    3. Converts List<ItemModel> → List<Item>                         │
│    4. Caches result                                                 │
│    5. Returns List<Item>                                           │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  RESPONSE:                                                         │
│    1. UseCase emits List<Item>                                     │
│    2. Controller receives list                                     │
│    3. Controller stores list, sets isLoading = false               │
│    4. Controller.refreshUI()                                       │
│    5. View displays list of items                                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Best Practices

### DO's

- ✅ Gunakan `const` constructor untuk static widgets
- ✅ Implement `Equatable` untuk entities
- ✅ Handle semua error dengan proper exception
- ✅ Validate input sebelum kirim ke UseCase
- ✅ Dispose resources di controller
- ✅ Use proper null safety
- ✅ Document public API
- ✅ Log important events

### DON'Ts

- ❌ Jangan hardcode strings
- ❌ Jangan letakkan business logic di View
- ❌ Jangan import Flutter di Domain layer
- ❌ Jangan gunakan `print()` (gunakan logger)
- ❌ Jangan buat God classes
- ❌ Jangan skip error handling
- ❌ Jangan lupa dispose UseCase

### File Naming

| Type | Convention | Example |
|------|-----------|---------|
| Files | `snake_case.dart` | `login_usecase.dart` |
| Classes | `PascalCase` | `LoginUseCase` |
| Variables | `camelCase` | `userName` |
| Constants | `camelCase` with prefix | `kApiBaseUrl` |
| Private | `_underscorePrefix` | `_privateMethod` |

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

## Layer Communication Rules

### Domain Layer

```dart
// ✅ GOOD
domain/
├── entities/          # Pure Dart, no dependencies
├── usecases/          # Only depends on Entities + Repository interfaces
└── repositories/      # Abstract classes only

// ❌ BAD
import 'package:flutter/material.dart';  // No Flutter in Domain!
import '../../data/models/user_model.dart';  // Don't import from Data!
```

### Data Layer

```dart
// ✅ GOOD
data/
├── repositories/      # Implements Domain repository interfaces
├── models/            # Can map to Domain entities
└── datasources/       # API calls, database

// ✅ GOOD - Polymorphism
class AuthRepositoryImpl implements AuthRepository {  // Domain interface
  final AuthRemoteDataSource dataSource;
  // ...
}
```

### Presentation Layer

```dart
// ✅ GOOD
presentation/
├── pages/
│   └── login/
│       ├── login_controller.dart    # Has-a Presenter
│       ├── login_presenter.dart     # Has-a UseCase
│       └── login_view.dart          # Has-a Controller

// ✅ GOOD - Dependency flow
View → Controller → Presenter → UseCase

// ❌ BAD - Don't skip layers
View → UseCase
```

---

## Resources

### Packages

- [flutter_clean_architecture](https://pub.dev/packages/flutter_clean_architecture)
- [Riverpod](https://riverpod.dev/)
- [DIO](https://pub.dev/packages/dio)
- [RxDart](https://pub.dev/packages/rxdart)

### Documentation

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Testing](https://docs.flutter.dev/testing)

---

*Version: 1.0.0*
*Last Updated: 7 Januari 2025*
