import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_inspector/schema/schema_learner.dart';
import 'package:flutter_api_inspector/schema/schema_registry.dart';
import 'package:flutter_api_inspector/schema/schema_validator.dart';

void main() {
  final registry = SchemaRegistry();

  setUp(() {
    registry.clear();
  });

  test('SchemaLearner should learn schema from map', () {
    final endpoint = '/users';
    final data = {'id': 1, 'name': 'John'};
    
    SchemaLearner.learn(endpoint, data);
    
    expect(registry.hasSchema(endpoint), true);
    final schema = registry.getSchema(endpoint);
    expect(schema?.fieldNames, containsAll(['id', 'name']));
    expect(schema?.fieldTypes['id'], 'int');
    expect(schema?.fieldTypes['name'], 'String');
  });

  test('SchemaValidator should detect changes', () {
    final endpoint = '/users';
    final initialData = {'id': 1, 'name': 'John'};
    SchemaLearner.learn(endpoint, initialData);
    final storedSchema = registry.getSchema(endpoint)!;

    // 1. New field
    SchemaValidator.validate(endpoint, storedSchema, {'id': 1, 'name': 'John', 'age': 30});

    // 2. Removed field
    SchemaValidator.validate(endpoint, storedSchema, {'id': 1});

    // 3. Type change (Breaking change)
    SchemaValidator.validate(endpoint, storedSchema, {'id': 'abc', 'name': 'John'});
  });
}
