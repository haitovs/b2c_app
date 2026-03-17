import 'package:flutter_test/flutter_test.dart';
import 'package:b2c_app/features/visa/services/visa_service.dart';
import '../../../helpers/mock_api_client.dart';

void main() {
  late FakeApiClient api;
  late MockTokenProvider tokenProvider;
  late VisaService visaService;

  setUp(() {
    api = FakeApiClient();
    tokenProvider = MockTokenProvider();
    visaService = VisaService(api, tokenProvider);
  });

  final visaJson = {
    'id': 'visa-1',
    'user_id': 'user-1',
    'event_id': 10,
    'status': 'draft',
    'first_name': 'John',
    'last_name': 'Doe',
    'passport_number': 'AB1234567',
    'nationality': 'Turkmenistan',
  };

  group('VisaService.listMyVisas', () {
    test('returns list of visa applications on success', () async {
      api.stubGet('/api/v1/visas/my-visas', [visaJson]);

      final visas = await visaService.listMyVisas(eventId: 10);

      expect(visas, hasLength(1));
      expect(visas.first['id'], 'visa-1');
      expect(visas.first['status'], 'draft');
    });

    test('passes event_id as query param', () async {
      api.stubGet('/api/v1/visas/my-visas', <dynamic>[]);

      await visaService.listMyVisas(eventId: 5);

      expect(api.calls.last.queryParams?['event_id'], '5');
    });

    test('sends no query params when eventId is null', () async {
      api.stubGet('/api/v1/visas/my-visas', <dynamic>[]);

      await visaService.listMyVisas();

      expect(api.calls.last.queryParams, isNull);
    });

    test('throws on error response', () async {
      api.stubGetError('/api/v1/visas/my-visas', message: 'Unauthorized');

      expect(
        () => visaService.listMyVisas(),
        throwsA(anything),
      );
    });
  });

  group('VisaService.createMyVisa', () {
    test('returns new visa application on success', () async {
      api.stubPost('/api/v1/visas/my-visa/create', visaJson);

      final visa = await visaService.createMyVisa(eventId: 10);

      expect(visa['id'], 'visa-1');
      expect(visa['status'], 'draft');
    });

    test('throws on error response', () async {
      api.stubPostError('/api/v1/visas/my-visa/create', message: 'Limit reached');

      expect(
        () => visaService.createMyVisa(eventId: 10),
        throwsA(anything),
      );
    });
  });

  group('VisaService.getMyVisaById', () {
    test('returns visa application by ID', () async {
      api.stubGet('/api/v1/visas/my-visa/visa-1', visaJson);

      final visa = await visaService.getMyVisaById('visa-1');

      expect(visa['id'], 'visa-1');
      expect(visa['first_name'], 'John');
    });

    test('throws on not found', () async {
      api.stubGetError('/api/v1/visas/my-visa/missing', statusCode: 404, message: 'Not found');

      expect(
        () => visaService.getMyVisaById('missing'),
        throwsA(anything),
      );
    });
  });

  group('VisaService.updateMyVisaById', () {
    test('sends update data and returns updated visa', () async {
      final updatedJson = {...visaJson, 'first_name': 'Jane'};
      api.stubPut('/api/v1/visas/my-visa/visa-1', updatedJson);

      final result = await visaService.updateMyVisaById(
        visaId: 'visa-1',
        data: {'first_name': 'Jane'},
      );

      expect(result['first_name'], 'Jane');
      final body = api.calls.last.body as Map<String, dynamic>;
      expect(body['first_name'], 'Jane');
    });

    test('throws on error response', () async {
      api.stubPutError('/api/v1/visas/my-visa/visa-1', message: 'Validation error');

      expect(
        () => visaService.updateMyVisaById(visaId: 'visa-1', data: {}),
        throwsA(anything),
      );
    });
  });

  group('VisaService.submitMyVisaById', () {
    test('returns submitted visa on success', () async {
      final submittedJson = {...visaJson, 'status': 'submitted'};
      api.stubPost('/api/v1/visas/my-visa/visa-1/submit', submittedJson);

      final result = await visaService.submitMyVisaById('visa-1');

      expect(result['status'], 'submitted');
    });

    test('throws on error response', () async {
      api.stubPostError(
        '/api/v1/visas/my-visa/visa-1/submit',
        message: 'Missing required fields',
      );

      expect(
        () => visaService.submitMyVisaById('visa-1'),
        throwsA(anything),
      );
    });
  });

  group('VisaService.deleteMyVisaById', () {
    test('completes without error on success', () async {
      api.stubDelete('/api/v1/visas/my-visa/visa-1', <String, dynamic>{});

      await expectLater(visaService.deleteMyVisaById('visa-1'), completes);
    });

    test('throws on error response', () async {
      api.stubDeleteError('/api/v1/visas/my-visa/visa-1', message: 'Cannot delete submitted visa');

      expect(
        () => visaService.deleteMyVisaById('visa-1'),
        throwsA(anything),
      );
    });
  });

  group('VisaService.getMyVisa (legacy)', () {
    test('returns visa on success', () async {
      api.stubGet('/api/v1/visas/my-visa', visaJson);

      final visa = await visaService.getMyVisa(eventId: 10);

      expect(visa['id'], 'visa-1');
    });

    test('passes participant_id and event_id as query params', () async {
      api.stubGet('/api/v1/visas/my-visa', visaJson);

      await visaService.getMyVisa(participantId: 'p-1', eventId: 10);

      expect(api.calls.last.queryParams?['participant_id'], 'p-1');
      expect(api.calls.last.queryParams?['event_id'], '10');
    });
  });

  group('VisaService.updateMyVisa (legacy)', () {
    test('sends update data and returns result', () async {
      api.stubPut('/api/v1/visas/my-visa', visaJson);

      final result = await visaService.updateMyVisa(
        eventId: 10,
        data: {'nationality': 'Turkey'},
      );

      expect(result['id'], 'visa-1');
      final body = api.calls.last.body as Map<String, dynamic>;
      expect(body['nationality'], 'Turkey');
    });
  });

  group('VisaService.submitMyVisa (legacy)', () {
    test('returns submitted visa on success', () async {
      api.stubPost('/api/v1/visas/my-visa/submit', visaJson);

      final result = await visaService.submitMyVisa(eventId: 10);

      expect(result['id'], 'visa-1');
    });
  });

  group('VisaService.validateMyVisa', () {
    test('returns validation result on success', () async {
      final validationJson = {'is_valid': true, 'errors': <dynamic>[]};
      api.stubGet('/api/v1/visas/my-visa/validate', validationJson);

      final result = await visaService.validateMyVisa(eventId: 10);

      expect(result['is_valid'], true);
      expect(result['errors'], isEmpty);
    });

    test('returns validation errors', () async {
      final validationJson = {
        'is_valid': false,
        'errors': ['First name is required', 'Passport number is required'],
      };
      api.stubGet('/api/v1/visas/my-visa/validate', validationJson);

      final result = await visaService.validateMyVisa(eventId: 10);

      expect(result['is_valid'], false);
      expect((result['errors'] as List), hasLength(2));
    });
  });
}
