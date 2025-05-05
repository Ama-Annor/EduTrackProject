// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for the API - you'll need to update this with your Firebase Functions URL when deployed
  static const String baseUrl = 'https://us-central1-your-project-id.cloudfunctions.net';

  // Get function for making GET requests
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      // Construct the URL with query parameters if provided
      final Uri uri = queryParams != null
          ? Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams)
          : Uri.parse('$baseUrl/$endpoint');

      // Get the current user's authentication token
      final user = FirebaseAuth.instance.currentUser;
      String? token;
      if (user != null) {
        token = await user.getIdToken();
      }

      // Set headers with auth token if available
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Make the request
      final response = await http.get(uri, headers: headers);

      // Check for success status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse the JSON response
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        // Handle error responses
        return {
          'success': false,
          'error': 'Request failed with status: ${response.statusCode}',
          'data': _tryParseJson(response.body),
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      // Handle exceptions
      return {
        'success': false,
        'error': e.toString(),
        'data': null,
        'statusCode': 500,
      };
    }
  }

  // Post function for making POST requests
  Future<Map<String, dynamic>> post(String endpoint, dynamic body) async {
    try {
      final Uri uri = Uri.parse('$baseUrl/$endpoint');

      // Get the current user's authentication token
      final user = FirebaseAuth.instance.currentUser;
      String? token;
      if (user != null) {
        token = await user.getIdToken();
      }

      // Set headers with auth token if available
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Make the request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      // Check for success status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse the JSON response
        return {
          'success': true,
          'data': _tryParseJson(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        // Handle error responses
        return {
          'success': false,
          'error': 'Request failed with status: ${response.statusCode}',
          'data': _tryParseJson(response.body),
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      // Handle exceptions
      return {
        'success': false,
        'error': e.toString(),
        'data': null,
        'statusCode': 500,
      };
    }
  }

  // Helper method to try parsing JSON, returning null if it fails
  dynamic _tryParseJson(String text) {
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } catch (e) {
      return text;
    }
  }

  // Method to cache API responses
  Future<void> cacheApiResponse(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store the data along with a timestamp
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching API response: $e');
    }
  }

  // Method to get cached API response
  Future<dynamic> getCachedApiResponse(String key, {int maxAgeMinutes = 60}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);

      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        final timestamp = data['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Check if the cache is still valid based on maxAgeMinutes
        if (now - timestamp < maxAgeMinutes * 60 * 1000) {
          return data['data'];
        }
      }

      return null;
    } catch (e) {
      print('Error getting cached API response: $e');
      return null;
    }
  }

  // Example API methods

  // Get study statistics for the current user
  Future<Map<String, dynamic>> getStudyStats({bool useCache = true}) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    const cacheKey = 'study_stats';

    // Try to get cached data first if useCache is true
    if (useCache) {
      final cachedData = await getCachedApiResponse(cacheKey);
      if (cachedData != null) {
        return {
          'success': true,
          'data': cachedData,
          'source': 'cache',
        };
      }
    }

    // If no cache or cache is expired, fetch from API
    final result = await get('getStudyStats', queryParams: {'email': userEmail});

    // Cache the response if it was successful
    if (result['success'] && result['data'] != null) {
      await cacheApiResponse(cacheKey, result['data']);
    }

    return result;
  }

  // Trigger a test notification
  Future<Map<String, dynamic>> sendTestNotification() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    return await post('send_motivational_quote', {'email': userEmail});
  }

  // Get all deadlines for the current user
  Future<Map<String, dynamic>> getDeadlines({bool useCache = true}) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    const cacheKey = 'deadlines';

    // Try to get cached data first if useCache is true
    if (useCache) {
      final cachedData = await getCachedApiResponse(cacheKey, maxAgeMinutes: 15);
      if (cachedData != null) {
        return {
          'success': true,
          'data': cachedData,
          'source': 'cache',
        };
      }
    }

    // If no cache or cache is expired, fetch from API
    final result = await get('getDeadlines', queryParams: {'email': userEmail});

    // Cache the response if it was successful
    if (result['success'] && result['data'] != null) {
      await cacheApiResponse(cacheKey, result['data']);
    }

    return result;
  }

  // Get all schedules for the current user
  Future<Map<String, dynamic>> getSchedules({bool useCache = true}) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    const cacheKey = 'schedules';

    // Try to get cached data first if useCache is true
    if (useCache) {
      final cachedData = await getCachedApiResponse(cacheKey, maxAgeMinutes: 15);
      if (cachedData != null) {
        return {
          'success': true,
          'data': cachedData,
          'source': 'cache',
        };
      }
    }

    // If no cache or cache is expired, fetch from API
    final result = await get('getSchedules', queryParams: {'email': userEmail});

    // Cache the response if it was successful
    if (result['success'] && result['data'] != null) {
      await cacheApiResponse(cacheKey, result['data']);
    }

    return result;
  }
}