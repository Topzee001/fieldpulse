import 'package:flutter_test/flutter_test.dart';
import 'package:fieldpulse/src/core/utils/validators.dart';

void main() {
  group('Validators.validateField', () {
    group('required field', () {
      test('returns error when value is null and field is required', () {
        expect(
          Validators.validateField(null, required: true),
          'This field is required',
        );
      });

      test('returns error when value is empty and field is required', () {
        expect(
          Validators.validateField('', required: true),
          'This field is required',
        );
      });

      test('returns null when value is provided and field is required', () {
        expect(
          Validators.validateField('hello', required: true),
          isNull,
        );
      });

      test('returns null when value is null and field is not required', () {
        expect(
          Validators.validateField(null, required: false),
          isNull,
        );
      });

      test('returns null when value is empty and field is not required', () {
        expect(
          Validators.validateField('', required: false),
          isNull,
        );
      });
    });

    group('email validation', () {
      test('accepts valid email', () {
        expect(
          Validators.validateField('user@example.com', type: 'email'),
          isNull,
        );
      });

      test('accepts email with subdomain', () {
        expect(
          Validators.validateField('user@mail.example.com', type: 'email'),
          isNull,
        );
      });

      test('rejects email without @ symbol', () {
        expect(
          Validators.validateField('userexample.com', type: 'email'),
          'Enter a valid email',
        );
      });

      test('rejects email without domain', () {
        expect(
          Validators.validateField('user@', type: 'email'),
          'Enter a valid email',
        );
      });

      test('rejects email without TLD', () {
        expect(
          Validators.validateField('user@example', type: 'email'),
          'Enter a valid email',
        );
      });

      test('skips email validation when value is empty and not required', () {
        expect(
          Validators.validateField('', type: 'email', required: false),
          isNull,
        );
      });

      test('returns required error before email validation when both apply', () {
        expect(
          Validators.validateField('', type: 'email', required: true),
          'This field is required',
        );
      });
    });

    group('phone validation', () {
      test('accepts valid US phone number', () {
        expect(
          Validators.validateField('(555) 123-4567', type: 'phone'),
          isNull,
        );
      });

      test('accepts plain digits phone number', () {
        expect(
          Validators.validateField('5551234567', type: 'phone'),
          isNull,
        );
      });

      test('accepts international format', () {
        expect(
          Validators.validateField('+1-555-123-4567', type: 'phone'),
          isNull,
        );
      });

      test('rejects phone number with too few digits', () {
        expect(
          Validators.validateField('12345', type: 'phone'),
          'Enter a valid phone number',
        );
      });

      test('rejects phone number with only letters', () {
        expect(
          Validators.validateField('abcdefghij', type: 'phone'),
          'Enter a valid phone number',
        );
      });
    });

    group('number validation', () {
      test('accepts valid integer string', () {
        expect(
          Validators.validateField('42', type: 'number'),
          isNull,
        );
      });

      test('accepts valid decimal string', () {
        expect(
          Validators.validateField('3.14', type: 'number'),
          isNull,
        );
      });

      test('accepts negative number string', () {
        expect(
          Validators.validateField('-10', type: 'number'),
          isNull,
        );
      });

      test('rejects non-numeric string', () {
        expect(
          Validators.validateField('abc', type: 'number'),
          'Must be a number',
        );
      });

      test('rejects mixed alphanumeric string', () {
        expect(
          Validators.validateField('12abc', type: 'number'),
          'Must be a number',
        );
      });
    });

    group('no type specified', () {
      test('returns null for any non-empty value when no type is specified', () {
        expect(
          Validators.validateField('anything'),
          isNull,
        );
      });
    });
  });

  group('Validators.validateNumber', () {
    test('returns null when value is within range', () {
      expect(
        Validators.validateNumber(5, min: 1, max: 10),
        isNull,
      );
    });

    test('returns null when value equals min', () {
      expect(
        Validators.validateNumber(1, min: 1, max: 10),
        isNull,
      );
    });

    test('returns null when value equals max', () {
      expect(
        Validators.validateNumber(10, min: 1, max: 10),
        isNull,
      );
    });

    test('returns error when value is below min', () {
      expect(
        Validators.validateNumber(0, min: 1, max: 10),
        'Minimum value is 1',
      );
    });

    test('returns error when value is above max', () {
      expect(
        Validators.validateNumber(11, min: 1, max: 10),
        'Maximum value is 10',
      );
    });

    test('returns null when value is null', () {
      expect(
        Validators.validateNumber(null, min: 1, max: 10),
        isNull,
      );
    });

    test('returns null when no min/max specified', () {
      expect(
        Validators.validateNumber(999),
        isNull,
      );
    });

    test('handles decimal values', () {
      expect(
        Validators.validateNumber(3.5, min: 1.0, max: 5.0),
        isNull,
      );
    });

    test('rejects decimal below min', () {
      expect(
        Validators.validateNumber(0.5, min: 1.0),
        'Minimum value is 1.0',
      );
    });
  });
}
