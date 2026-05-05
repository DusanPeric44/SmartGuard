import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/core/network/api_error.dart';

void main() {
  test('ApiError parsira backend validacijske poruke iz mapiranih errors', () {
    final body = jsonEncode({
      'message': 'Validation failed',
      'errors': {
        'email': ['Invalid email'],
        'password': ['Too short'],
      },
    });

    final error = ApiError.fromHttpResponse(
      statusCode: 422,
      body: body,
      headers: {'content-type': 'application/json'},
    );

    expect(error.type, ApiErrorType.http);
    expect(error.statusCode, 422);
    expect(error.message, 'Validation failed');
    expect(error.validation['email'], ['Invalid email']);
    expect(error.validation['password'], ['Too short']);
    expect(
      error.messages,
      containsAll(['Validation failed', 'Invalid email', 'Too short']),
    );
  });

  test('ApiError parsira listu poruka iz errors: []', () {
    final body = jsonEncode({
      'errors': ['A', 'B'],
    });

    final error = ApiError.fromHttpResponse(
      statusCode: 400,
      body: body,
      headers: {'content-type': 'application/json'},
    );

    expect(error.message, 'A');
    expect(error.messages, ['A', 'B']);
    expect(error.validation, isEmpty);
  });

  test('ApiError čuva plain-text tijelo kada response nije JSON', () {
    final error = ApiError.fromHttpResponse(
      statusCode: 500,
      body: 'Internal Server Error',
      headers: {'content-type': 'text/plain'},
    );

    expect(error.message, 'Internal Server Error');
    expect(error.messages, ['Internal Server Error']);
  });
}
