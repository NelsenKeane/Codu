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

  // Active Players
  AudioPlayer? _musicPlayer;
  AudioPlayer? _timeRunningOutPlayer;
  String? _currentMusicAsset;

  // Getters
  double get masterVolume => _masterVolume;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  // Keys for SharedPreferences
  static const String _keyMasterVolume = 'audio_master_volume';
  static const String _keyMusicVolume = 'audio_music_volume';
  static const String _keySfxVolume = 'audio_sfx_volume';

  /// Initialize and load volumes from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _masterVolume = prefs.getDouble(_keyMasterVolume) ?? 1.0;
    _musicVolume = prefs.getDouble(_keyMusicVolume) ?? 0.8;
    _sfxVolume = prefs.getDouble(_keySfxVolume) ?? 1.0;
  }

  /// Update Master Volume
  Future<void> setMasterVolume(double value) async {
    _masterVolume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMasterVolume, _masterVolume);
    _updateMusicPlayerVolume();
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
    
    // If time running out player is currently playing, update its volume
    if (_timeRunningOutPlayer != null) {
      await _timeRunningOutPlayer!.setVolume(_masterVolume * _sfxVolume);
    }
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

  /// Play background music (loops indefinitely)
  Future<void> playMusic(String assetPath) async {
    // If it's already playing the same music, do nothing
    if (_musicPlayer != null && _currentMusicAsset == assetPath) {
      return;
    }

    await stopMusic();

    _currentMusicAsset = assetPath;
    _musicPlayer = AudioPlayer();
    await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer!.setVolume(_effectiveMusicVolume);
    await _musicPlayer!.play(AssetSource(assetPath));
  }

  /// Stop background music
  Future<void> stopMusic() async {
    if (_musicPlayer != null) {
      await _musicPlayer!.stop();
      await _musicPlayer!.dispose();
      _musicPlayer = null;
      _currentMusicAsset = null;
    }
  }

  /// Play a one-shot Sound Effect (SFX)
  Future<void> playSfx(String assetPath) async {
    final player = AudioPlayer();
    await player.setVolume(_effectiveSfxVolume);
    await player.play(AssetSource(assetPath));
    
    // Auto-dispose player when playback completes
    player.onPlayerComplete.listen((_) {
      player.dispose();
    });
  }

  /// Play the time running out ticking warning
  Future<void> playTimeRunningOut() async {
    await stopTimeRunningOut();

    _timeRunningOutPlayer = AudioPlayer();
    await _timeRunningOutPlayer!.setVolume(_effectiveSfxVolume);
    await _timeRunningOutPlayer!.play(AssetSource('Audio/TimeRunningOut.mp3'));
    
    _timeRunningOutPlayer!.onPlayerComplete.listen((_) {
      stopTimeRunningOut();
    });
  }

  /// Stop the time running out warning
  Future<void> stopTimeRunningOut() async {
    if (_timeRunningOutPlayer != null) {
      try {
        await _timeRunningOutPlayer!.stop();
        await _timeRunningOutPlayer!.dispose();
      } catch (e) {
        // Safe catch if already disposed
      }
      _timeRunningOutPlayer = null;
    }
  }
}
