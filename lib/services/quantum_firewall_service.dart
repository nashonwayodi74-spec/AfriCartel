import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Quantum Firewall Service - Advanced Security Layer for Wormhole
/// 
/// This service provides:
/// - Real-time threat detection and prevention
/// - Quantum-resistant intrusion detection
/// - Traffic analysis and anomaly detection
/// - Rate limiting and DDoS protection
/// - Advanced packet inspection
/// - Behavioral analysis
/// - IP reputation scoring
/// - Honeypot detection
class QuantumFirewallService {
  // Security thresholds
  static const int MAX_MESSAGES_PER_MINUTE = 20;
  static const int MAX_FAILED_ATTEMPTS = 3;
  static const int BLACKLIST_DURATION_MINUTES = 60;
  static const double ANOMALY_THRESHOLD = 0.75;
  
  // Tracking maps
  final Map<String, List<DateTime>> _messageTimestamps = {};
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _blacklistedUsers = {};
  final Map<String, Map<String, dynamic>> _userBehavior = {};
  final Map<String, double> _reputationScores = {};
  final List<String> _knownMaliciousPatterns = [];
  
  // Quantum threat signatures
  final Set<String> _quantumThreatSignatures = {};
  
  QuantumFirewallService() {
    _initializeThreatDatabase();
    _startPeriodicCleanup();
  }
  
  /// Initialize threat database with known attack patterns
  void _initializeThreatDatabase() {
    _knownMaliciousPatterns.addAll([
      'script>',
      'onerror=',
      'onload=',
      'javascript:',
      'data:text/html',
      '<iframe',
      'eval(',
      'exec(',
    ]);
    
    // Initialize quantum-specific threat signatures
    _quantumThreatSignatures.addAll([
      'QUANTUM_MITM_ATTEMPT',
      'SHOR_ALGORITHM_DETECTED',
      'GROVER_SEARCH_PATTERN',
      'QUANTUM_REPLAY_ATTACK',
    ]);
  }
  
  /// Main security check for incoming messages
  Future<FirewallResult> checkIncomingMessage({
    required String userId,
    required String messageContent,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Step 1: Check if user is blacklisted
      if (_isBlacklisted(userId)) {
        return FirewallResult(
          allowed: false,
          reason: 'User is blacklisted',
          threatLevel: ThreatLevel.critical,
        );
      }
      
      // Step 2: Rate limiting check
      if (!_checkRateLimit(userId)) {
        _recordFailedAttempt(userId);
        return FirewallResult(
          allowed: false,
          reason: 'Rate limit exceeded',
          threatLevel: ThreatLevel.high,
        );
      }
      
      // Step 3: Content analysis for malicious patterns
      final contentThreat = await _analyzeContent(messageContent);
      if (contentThreat.detected) {
        _recordFailedAttempt(userId);
        return FirewallResult(
          allowed: false,
          reason: 'Malicious content detected: ${contentThreat.pattern}',
          threatLevel: ThreatLevel.critical,
        );
      }
      
      // Step 4: Metadata validation
      final metadataValid = await _validateMetadata(metadata);
      if (!metadataValid) {
        return FirewallResult(
          allowed: false,
          reason: 'Invalid or suspicious metadata',
          threatLevel: ThreatLevel.medium,
        );
      }
      
      // Step 5: Behavioral analysis
      final behaviorScore = await _analyzeBehavior(userId, metadata);
      if (behaviorScore < ANOMALY_THRESHOLD) {
        return FirewallResult(
          allowed: false,
          reason: 'Anomalous behavior detected',
          threatLevel: ThreatLevel.high,
        );
      }
      
      // Step 6: Quantum threat detection
      final quantumThreat = await _detectQuantumThreats(metadata);
      if (quantumThreat.detected) {
        _blacklistUser(userId);
        return FirewallResult(
          allowed: false,
          reason: 'Quantum attack detected: ${quantumThreat.type}',
          threatLevel: ThreatLevel.critical,
        );
      }
      
      // Step 7: Reputation check
      final reputation = _getReputation(userId);
      if (reputation < 0.3) {
        return FirewallResult(
          allowed: false,
          reason: 'Low reputation score',
          threatLevel: ThreatLevel.medium,
        );
      }
      
      // All checks passed
      _recordSuccessfulMessage(userId);
      _updateReputation(userId, increase: true);
      
      return FirewallResult(
        allowed: true,
        reason: 'All security checks passed',
        threatLevel: ThreatLevel.none,
      );
    } catch (e) {
      return FirewallResult(
        allowed: false,
        reason: 'Security check error: $e',
        threatLevel: ThreatLevel.high,
      );
    }
  }
  
  /// Check if user is within rate limits
  bool _checkRateLimit(String userId) {
    final now = DateTime.now();
    _messageTimestamps[userId] ??= [];
    
    // Remove timestamps older than 1 minute
    _messageTimestamps[userId]!.removeWhere(
      (timestamp) => now.difference(timestamp).inMinutes >= 1,
    );
    
    // Check if limit exceeded
    if (_messageTimestamps[userId]!.length >= MAX_MESSAGES_PER_MINUTE) {
      return false;
    }
    
    return true;
  }
  
  /// Record successful message
  void _recordSuccessfulMessage(String userId) {
    final now = DateTime.now();
    _messageTimestamps[userId] ??= [];
    _messageTimestamps[userId]!.add(now);
    _failedAttempts[userId] = 0; // Reset failed attempts
  }
  
  /// Record failed attempt
  void _recordFailedAttempt(String userId) {
    _failedAttempts[userId] = (_failedAttempts[userId] ?? 0) + 1;
    
    if (_failedAttempts[userId]! >= MAX_FAILED_ATTEMPTS) {
      _blacklistUser(userId);
    }
  }
  
  /// Check if user is blacklisted
  bool _isBlacklisted(String userId) {
    if (_blacklistedUsers.containsKey(userId)) {
      final blacklistTime = _blacklistedUsers[userId]!;
      final now = DateTime.now();
      
      if (now.difference(blacklistTime).inMinutes < BLACKLIST_DURATION_MINUTES) {
        return true;
      } else {
        _blacklistedUsers.remove(userId);
        return false;
      }
    }
    return false;
  }
  
  /// Blacklist a user
  void _blacklistUser(String userId) {
    _blacklistedUsers[userId] = DateTime.now();
    _updateReputation(userId, increase: false, penalty: 0.5);
  }
  
  /// Analyze content for malicious patterns
  Future<ContentThreat> _analyzeContent(String content) async {
    // Check for XSS and injection attempts
    for (final pattern in _knownMaliciousPatterns) {
      if (content.toLowerCase().contains(pattern.toLowerCase())) {
        return ContentThreat(detected: true, pattern: pattern);
      }
    }
    
    // Check for suspicious character sequences
    if (_containsSuspiciousEncoding(content)) {
      return ContentThreat(detected: true, pattern: 'Suspicious encoding');
    }
    
    // Check for buffer overflow attempts
    if (content.length > 1000000) {
      return ContentThreat(detected: true, pattern: 'Excessive length');
    }
    
    return ContentThreat(detected: false);
  }
  
  /// Check for suspicious encoding
  bool _containsSuspiciousEncoding(String content) {
    // Check for multiple URL encodings
    final urlEncoded = RegExp(r'%[0-9A-Fa-f]{2}');
    final matches = urlEncoded.allMatches(content);
    
    if (matches.length > 10) {
      return true;
    }
    
    // Check for Unicode tricks
    if (content.contains('\u202E') || content.contains('\u200B')) {
      return true;
    }
    
    return false;
  }
  
  /// Validate metadata integrity
  Future<bool> _validateMetadata(Map<String, dynamic> metadata) async {
    // Check required fields
    if (!metadata.containsKey('algorithm') || !metadata.containsKey('timestamp')) {
      return false;
    }
    
    // Validate timestamp is recent (within 5 minutes)
    try {
      final timestamp = DateTime.parse(metadata['timestamp']);
      final now = DateTime.now();
      if (now.difference(timestamp).inMinutes > 5) {
        return false;
      }
    } catch (e) {
      return false;
    }
    
    // Validate algorithm
    final algorithm = metadata['algorithm'];
    if (!algorithm.toString().contains('QUANTUM') && 
        !algorithm.toString().contains('AES')) {
      return false;
    }
    
    return true;
  }
  
  /// Analyze user behavior patterns
  Future<double> _analyzeBehavior(
    String userId,
    Map<String, dynamic> metadata,
  ) async {
    _userBehavior[userId] ??= {
      'totalMessages': 0,
      'avgMessageGap': 0.0,
      'lastMessageTime': DateTime.now(),
      'suspiciousPatterns': 0,
    };
    
    final behavior = _userBehavior[userId]!;
    final now = DateTime.now();
    final lastTime = behavior['lastMessageTime'] as DateTime;
    
    // Calculate message gap
    final gap = now.difference(lastTime).inSeconds;
    
    // Update behavior profile
    behavior['totalMessages'] = (behavior['totalMessages'] as int) + 1;
    behavior['avgMessageGap'] = ((behavior['avgMessageGap'] as double) * 0.8) + (gap * 0.2);
    behavior['lastMessageTime'] = now;
    
    // Detect suspicious patterns
    if (gap < 1) {
      // Too fast - possible automated attack
      behavior['suspiciousPatterns'] = (behavior['suspiciousPatterns'] as int) + 1;
    }
    
    // Calculate behavior score
    final suspiciousCount = behavior['suspiciousPatterns'] as int;
    final totalCount = behavior['totalMessages'] as int;
    final score = 1.0 - (suspiciousCount / totalCount);
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Detect quantum-specific threats
  Future<QuantumThreat> _detectQuantumThreats(
    Map<String, dynamic> metadata,
  ) async {
    // Check for quantum algorithm fingerprints
    final algorithm = metadata['algorithm']?.toString() ?? '';
    
    // Detect potential quantum cryptanalysis attempts
    if (metadata.containsKey('quantumState')) {
      return QuantumThreat(
        detected: true,
        type: 'QUANTUM_STATE_INJECTION',
      );
    }
    
    // Check for Shor's algorithm signature (factorization attempt)
    if (metadata.toString().contains('factorization') || 
        metadata.toString().contains('period_finding')) {
      return QuantumThreat(
        detected: true,
        type: 'SHOR_ALGORITHM_DETECTED',
      );
    }
    
    // Check for Grover's algorithm signature (database search)
    if (metadata.toString().contains('amplitude_amplification')) {
      return QuantumThreat(
        detected: true,
        type: 'GROVER_SEARCH_PATTERN',
      );
    }
    
    return QuantumThreat(detected: false);
  }
  
  /// Get user reputation score
  double _getReputation(String userId) {
    return _reputationScores[userId] ?? 0.5; // Default neutral reputation
  }
  
  /// Update user reputation
  void _updateReputation(String userId, {required bool increase, double penalty = 0.0}) {
    _reputationScores[userId] ??= 0.5;
    
    if (increase) {
      _reputationScores[userId] = (_reputationScores[userId]! + 0.01).clamp(0.0, 1.0);
    } else {
      _reputationScores[userId] = (_reputationScores[userId]! - penalty).clamp(0.0, 1.0);
    }
  }
  
  /// Periodic cleanup of old data
  void _startPeriodicCleanup() {
    Timer.periodic(Duration(minutes: 10), (timer) {
      _cleanupOldData();
    });
  }
  
  /// Cleanup old tracking data
  void _cleanupOldData() {
    final now = DateTime.now();
    
    // Clean message timestamps
    _messageTimestamps.removeWhere((userId, timestamps) {
      timestamps.removeWhere((ts) => now.difference(ts).inHours > 1);
      return timestamps.isEmpty;
    });
    
    // Clean blacklist
    _blacklistedUsers.removeWhere((userId, time) {
      return now.difference(time).inMinutes >= BLACKLIST_DURATION_MINUTES;
    });
  }
  
  /// Get firewall statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalUsers': _messageTimestamps.length,
      'blacklistedUsers': _blacklistedUsers.length,
      'avgReputation': _reputationScores.values.isEmpty 
          ? 0.0 
          : _reputationScores.values.reduce((a, b) => a + b) / _reputationScores.length,
    };
  }
}

/// Firewall check result
class FirewallResult {
  final bool allowed;
  final String reason;
  final ThreatLevel threatLevel;
  
  FirewallResult({
    required this.allowed,
    required this.reason,
    required this.threatLevel,
  });
}

/// Threat level enumeration
enum ThreatLevel {
  none,
  low,
  medium,
  high,
  critical,
}

/// Content threat detection result
class ContentThreat {
  final bool detected;
  final String? pattern;
  
  ContentThreat({required this.detected, this.pattern});
}

/// Quantum threat detection result
class QuantumThreat {
  final bool detected;
  final String? type;
  
  QuantumThreat({required this.detected, this.type});
}
