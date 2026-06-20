import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Volume parameters (0.0 to 1.0)
  double _masterVolume = 1.0;
  double _musicVolume = 0.8;
  double _sfxVolume = 1.0;

  // Active Music Player & State
  AudioPlayer? _musicPlayer;
  String? _currentMusicAsset;

  // Dedicated Preloaded SFX Players (Using Low Latency Mode)
  AudioPlayer? _correctPlayer;
  AudioPlayer? _wrongPlayer;
  AudioPlayer? _completedPlayer;
  AudioPlayer? _completedLosePlayer;
  AudioPlayer? _timeRunningOutPlayer;

  // Getters
  double get masterVolume => _masterVolume;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  // Keys for SharedPreferences
  static const String _keyMasterVolume = 'audio_master_volume';
  static const String _keyMusicVolume = 'audio_music_volume';
  static const String _keySfxVolume = 'audio_sfx_volume';

  /// Initialize and load volumes from SharedPreferences, preloading sound effects
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _masterVolume = prefs.getDouble(_keyMasterVolume) ?? 1.0;
    _musicVolume = prefs.getDouble(_keyMusicVolume) ?? 0.8;
    _sfxVolume = prefs.getDouble(_keySfxVolume) ?? 1.0;

    // Instantiate players
    _musicPlayer = AudioPlayer();
    _correctPlayer = AudioPlayer();
    _wrongPlayer = AudioPlayer();
    _completedPlayer = AudioPlayer();
    _completedLosePlayer = AudioPlayer();
    _timeRunningOutPlayer = AudioPlayer();

    // Set player modes
    await _musicPlayer!.setPlayerMode(PlayerMode.mediaPlayer);
    await _correctPlayer!.setPlayerMode(PlayerMode.lowLatency);
    await _wrongPlayer!.setPlayerMode(PlayerMode.lowLatency);
    await _completedPlayer!.setPlayerMode(PlayerMode.lowLatency);
    await _completedLosePlayer!.setPlayerMode(PlayerMode.lowLatency);
    await _timeRunningOutPlayer!.setPlayerMode(PlayerMode.lowLatency);

    // Configure the background music player context (gain focus, playback category)
    try {
      await _musicPlayer!.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print("AudioService: Failed to configure music player context: $e");
    }

    // Configure SFX players context (no focus, ambient/mix category)
    final sfxContext = AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: const {},
      ),
    );

    // Apply SFX context and set sources to preload audio into memory
    final List<Future<void>> preloads = [
      _correctPlayer!.setAudioContext(sfxContext).then((_) => _correctPlayer!.setSource(AssetSource('Audio/Correct.mp3'))),
      _wrongPlayer!.setAudioContext(sfxContext).then((_) => _wrongPlayer!.setSource(AssetSource('Audio/Wrong.mp3'))),
      _completedPlayer!.setAudioContext(sfxContext).then((_) => _completedPlayer!.setSource(AssetSource('Audio/Completed.mp3'))),
      _completedLosePlayer!.setAudioContext(sfxContext).then((_) => _completedLosePlayer!.setSource(AssetSource('Audio/CompletedLose.mp3'))),
      _timeRunningOutPlayer!.setAudioContext(sfxContext).then((_) => _timeRunningOutPlayer!.setSource(AssetSource('Audio/TimeRunningOut.mp3'))),
    ];

    try {
      await Future.wait(preloads);
      // ignore: avoid_print
      print("AudioService: Successfully preloaded all sound effects in low-latency mode.");
    } catch (e) {
      // ignore: avoid_print
      print("AudioService Error: Failed during preloading audio assets: $e");
    }

    // Set initial volumes
    _updateMusicPlayerVolume();
    _updateSfxPlayersVolume();
  }

  /// Update Master Volume
  Future<void> setMasterVolume(double value) async {
    _masterVolume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMasterVolume, _masterVolume);
    _updateMusicPlayerVolume();
    _updateSfxPlayersVolume();
  }

  /// Update Music Volume
  Future<void> setMusicVolume(double value) async {
    _musicVolume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMusicVolume, _musicVolume);
    _updateMusicPlayerVolume();
  }

  /// Update SFX Volume
  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySfxVolume, _sfxVolume);
    _updateSfxPlayersVolume();
  }

  /// Calculate effective music volume
  double get _effectiveMusicVolume => _masterVolume * _musicVolume;

  /// Calculate effective SFX volume
  double get _effectiveSfxVolume => _masterVolume * _sfxVolume;

  /// Update volume of active music player
  void _updateMusicPlayerVolume() {
    if (_musicPlayer != null) {
      _musicPlayer!.setVolume(_effectiveMusicVolume);
    }
  }

  /// Update volume of all SFX players
  void _updateSfxPlayersVolume() {
    final sfxVol = _effectiveSfxVolume;
    _correctPlayer?.setVolume(sfxVol);
    _wrongPlayer?.setVolume(sfxVol);
    _completedPlayer?.setVolume(sfxVol);
    _completedLosePlayer?.setVolume(sfxVol);
    _timeRunningOutPlayer?.setVolume(sfxVol);
  }

  /// Play background music (loops indefinitely)
  Future<void> playMusic(String assetPath) async {
    // If it's already playing the same music, do nothing
    if (_musicPlayer != null && _currentMusicAsset == assetPath) {
      return;
    }

    try {
      await stopMusic();

      _currentMusicAsset = assetPath;
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer!.setVolume(_effectiveMusicVolume);
      // ignore: avoid_print
      print("AudioService: Attempting to play background music: $assetPath (Volume: $_effectiveMusicVolume)");
      await _musicPlayer!.play(AssetSource(assetPath));
    } catch (e, stack) {
      // ignore: avoid_print
      print("AudioService Error: Failed to play music $assetPath: $e");
      // ignore: avoid_print
      print(stack);
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    if (_musicPlayer != null) {
      try {
        await _musicPlayer!.stop();
      } catch (e) {
        // Safe catch
      }
      _currentMusicAsset = null;
    }
  }

  /// Play a one-shot Sound Effect (SFX)
  Future<void> playSfx(String assetPath) async {
    AudioPlayer? player;
    if (assetPath == 'Audio/Correct.mp3') {
      player = _correctPlayer;
    } else if (assetPath == 'Audio/Wrong.mp3') {
      player = _wrongPlayer;
    } else if (assetPath == 'Audio/Completed.mp3') {
      player = _completedPlayer;
    } else if (assetPath == 'Audio/CompletedLose.mp3') {
      player = _completedLosePlayer;
    }

    if (player != null) {
      try {
        // Play directly - this handles resetting and playing for low latency player
        await player.play(AssetSource(assetPath));
        // ignore: avoid_print
        print("AudioService: Instantly playing preloaded SFX: $assetPath");
      } catch (e) {
        // ignore: avoid_print
        print("AudioService Error: Failed to play preloaded SFX $assetPath: $e");
      }
    } else {
      // Fallback for other audio files not in the preloaded set
      try {
        final fallbackPlayer = AudioPlayer();
        await fallbackPlayer.setVolume(_effectiveSfxVolume);
        // ignore: avoid_print
        print("AudioService: Playing fallback SFX: $assetPath");
        await fallbackPlayer.play(AssetSource(assetPath));
        fallbackPlayer.onPlayerComplete.listen((_) => fallbackPlayer.dispose());
      } catch (e) {
        // ignore: avoid_print
        print("AudioService Error: Failed to play fallback SFX $assetPath: $e");
      }
    }
  }

  /// Play the time running out ticking warning
  Future<void> playTimeRunningOut() async {
    if (_timeRunningOutPlayer != null) {
      try {
        await _timeRunningOutPlayer!.play(AssetSource('Audio/TimeRunningOut.mp3'));
        // ignore: avoid_print
        print("AudioService: Instantly playing TimeRunningOut ticking warning");
      } catch (e, stack) {
        // ignore: avoid_print
        print("AudioService Error: Failed to play TimeRunningOut warning: $e");
        // ignore: avoid_print
        print(stack);
      }
    }
  }

  /// Stop the time running out warning
  Future<void> stopTimeRunningOut() async {
    if (_timeRunningOutPlayer != null) {
      try {
        await _timeRunningOutPlayer!.stop();
      } catch (e) {
        // Safe catch
      }
    }
  }
}
