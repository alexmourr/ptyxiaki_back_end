import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Single source of truth for the API root
  final String _baseUrl = 'https://api.ticketin.gr/api/v1';

  Map<String, String> _headers({String? token}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ---------------------------
  // Auth
  // ---------------------------
  /// POST /api/v1/login -> { token, user }
  Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['token'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// POST /api/v1/register -> { token, user }
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: _headers(),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['token'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: _headers(token: token),
      );
    } catch (_) {
      // no-op
    }
  }

  // ---------------------------
  // Profile & Scores
  // ---------------------------
  Future<Map<String, dynamic>?> getProfile(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: _headers(token: token),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getUserScores(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/user/scores'),
        headers: _headers(token: token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  // ---------------------------
  // Live Sessions (Pusher flow)
  // ---------------------------
  /// POST /api/v1/sessions/{code}/join
  /// returns { session_id, participant_id, ... }
  Future<Map<String, dynamic>?> joinSession({
    required String code,
    required String nickname,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/sessions/$code/join'),
        headers: _headers(token: token),
        body: jsonEncode({'nickname': nickname}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'error': 'Join failed (${res.statusCode})'};
    } catch (e) {
      return {'error': 'Join error: $e'};
    }
  }

  /// POST /api/v1/sessions/{id}/submit-answer
  /// body: { participant_id, question_id, selected_answers: [] }
  /// returns { correct, points, streak, message, rationale?, fun_fact? }
  Future<Map<String, dynamic>?> submitAnswers({
    required int sessionId,
    required int participantId,
    required int questionId,
    required List<String> selectedAnswers,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/sessions/$sessionId/submit-answer'),
        headers: _headers(token: token),
        body: jsonEncode({
          'participant_id': participantId,
          'question_id': questionId,
          'selected_answers': selectedAnswers,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'error': 'Failed: ${res.statusCode}', 'body': res.body};
    } catch (e) {
      return {'error': 'Exception: $e'};
    }
  }

  /// GET /api/v1/sessions/{id}/leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard(
    int sessionId,
    String token,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/sessions/$sessionId/leaderboard'),
        headers: _headers(token: token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  /// Optional polling fallback for current question
  /// GET /api/v1/sessions/{id}/current-question
  Future<Map<String, dynamic>?> getCurrentQuestion(
    int sessionId,
    String token,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/sessions/$sessionId/current-question'),
        headers: _headers(token: token),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getAssignedChallenges(String token) async {
    try {
      final url = Uri.parse('$_baseUrl/challenges/assigned');
      final res = await http.get(url, headers: _headers(token: token));

      debugPrintApi("RAW /challenges/assigned", res.body);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        debugPrintApi("JSON /challenges/assigned", body);

        final list = (body['challenges'] ?? []) as List<dynamic>;
        return list.map((e) => e as Map<String, dynamic>).toList();
      } else {
        debugPrintApi("ERROR /challenges/assigned", res.statusCode);
      }
    } catch (e, stack) {
      debugPrintApi("EXCEPTION /challenges/assigned", "$e\n$stack");
    }
    return <Map<String, dynamic>>[];
  }

  void debugPrintApi(String label, dynamic data) {
    print("=======================================");
    print("⚡ API DEBUG [$label]");
    print(data);
    print("=======================================");
  }

  /// GET /api/v1/assignments/{assignment}/quizzes
  Future<List<Map<String, dynamic>>> getAssignmentQuizzes(
    int assignmentId,
    String token,
  ) async {
    final u = Uri.parse('$_baseUrl/assignments/$assignmentId/quizzes');
    final r = await http.get(u, headers: _headers(token: token));
    if (r.statusCode != 200) {
      throw Exception('Could not fetch assignment quizzes');
    }
    final data = jsonDecode(r.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// POST /api/v1/assignments/{assignment}/attempts  { quiz_id }
  /// returns { attempt_id, ... }
  Future<Map<String, dynamic>> startAttempt(
    int assignmentId,
    int quizId,
    String token,
  ) async {
    final u = Uri.parse('$_baseUrl/assignments/$assignmentId/attempts');
    final r = await http.post(
      u,
      headers: _headers(token: token),
      body: jsonEncode({'quiz_id': quizId}),
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw Exception('Could not start attempt (${r.statusCode})');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// GET /api/v1/attempts/{attempt}/next-question
  Future<Map<String, dynamic>> getNextQuestion(
    int attemptId,
    String token,
  ) async {
    final u = Uri.parse('$_baseUrl/attempts/$attemptId/next-question');
    final r = await http.get(u, headers: _headers(token: token));
    if (r.statusCode != 200) {
      throw Exception('Could not fetch next question');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// POST /api/v1/attempts/{attempt}/answers
  /// body supports single OR multiple answers
  Future<Map<String, dynamic>> submitAttemptAnswer({
    required int attemptId,
    required int questionId,
    String? selectedAnswer,
    List<String>? selectedAnswers,
    int? answerTimeMs,
    required String token,
  }) async {
    final u = Uri.parse('$_baseUrl/attempts/$attemptId/answers');
    final body = <String, dynamic>{
      'question_id': questionId,
      if (selectedAnswer != null) 'selected_answer': selectedAnswer,
      if (selectedAnswers != null) 'selected_answers': selectedAnswers,
      if (answerTimeMs != null) 'answer_time_ms': answerTimeMs,
    };
    final r = await http.post(
      u,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    // allow 201 Created; some backends also 200/409 for “already answered”
    if (r.statusCode != 201 && r.statusCode != 200 && r.statusCode != 409) {
      throw Exception('Could not submit answer (${r.statusCode})');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// POST /api/v1/attempts/{attempt}/finish
  Future<Map<String, dynamic>> finishAttempt(
    int attemptId,
    String token,
  ) async {
    final u = Uri.parse('$_baseUrl/attempts/$attemptId/finish');
    final r = await http.post(u, headers: _headers(token: token));
    if (r.statusCode != 200) {
      throw Exception('Could not finish attempt');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
