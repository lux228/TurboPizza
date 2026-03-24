# Test Suite Structure

- `test/domain/`: pure business rules and model/util tests.
- `test/data/`: service/repository/database/migration/storage tests.
- `test/ui/`: widget/UI interaction tests.

## Naming convention

- Domain tests: `*_domain_test.dart`
- Data/service tests: `*_service_test.dart`
- UI/widget tests: `*_ui_test.dart`

## Running tests

- Full suite:
  - `flutter test`
- UI only:
  - `flutter test test/ui`
- Domain only:
  - `flutter test test/domain`
- Data only:
  - `flutter test test/data`
