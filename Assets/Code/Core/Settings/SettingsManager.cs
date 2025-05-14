using UnityEngine;
using UnityEngine.Audio;
using CienPodroznika.Core.Events;

namespace CienPodroznika.Core.Settings
{
    public class SettingsManager : MonoBehaviour
    {
        [Header("Settings")]
        [SerializeField] private GameSettings _defaultSettings;
        [SerializeField] private AudioMixer _audioMixer;
        
        private static SettingsManager _instance;
        public static SettingsManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = FindObjectOfType<SettingsManager>();
                }
                return _instance;
            }
        }
        
        private GameSettings _currentSettings;
        public GameSettings CurrentSettings => _currentSettings;
        
        private const string SETTINGS_FILE = "settings.json";
        
        private void Awake()
        {
            if (_instance == null)
            {
                _instance = this;
                DontDestroyOnLoad(gameObject);
                LoadSettings();
            }
            else if (_instance != this)
            {
                Destroy(gameObject);
            }
        }
        
        private void Start()
        {
            ApplySettings();
        }

        public void LoadSettings()
        {
            try
            {
                string filePath = System.IO.Path.Combine(Application.persistentDataPath, SETTINGS_FILE);

                if (_currentSettings == null)
                {
                    _currentSettings = Instantiate(_defaultSettings);
                }

                if (System.IO.File.Exists(filePath))
                {
                    string json = System.IO.File.ReadAllText(filePath);
                    GameSettingsData settingsData = JsonUtility.FromJson<GameSettingsData>(json);

                    if (settingsData != null)
                    {
                        settingsData.ApplyTo(_currentSettings);
                    }
                }
                else
                {
                    SaveSettings();
                }
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"Failed to load settings: {ex.Message}");
                _currentSettings = Instantiate(_defaultSettings);
            }
        }

        public void SaveSettings()
        {
            try
            {
                GameSettingsData settingsData = new GameSettingsData(_currentSettings);
                string json = JsonUtility.ToJson(settingsData, true);
                string filePath = System.IO.Path.Combine(Application.persistentDataPath, SETTINGS_FILE);
                System.IO.File.WriteAllText(filePath, json);

                Debug.Log("Settings saved successfully");
                EventBus.Instance.Publish(new SettingsChangedEvent(_currentSettings));
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"Failed to save settings: {ex.Message}");
            }
        }

        public void ApplySettings()
        {
            if (_currentSettings == null) return;
            
            // Apply graphics settings
            QualitySettings.SetQualityLevel(_currentSettings.qualityLevel);
            Screen.SetResolution(_currentSettings.resolution.width, _currentSettings.resolution.height, _currentSettings.fullscreen);
            QualitySettings.vSyncCount = _currentSettings.vsync ? 1 : 0;
            Application.targetFrameRate = _currentSettings.targetFrameRate;
            
            // Apply audio settings
            if (_audioMixer != null)
            {
                _audioMixer.SetFloat("MasterVolume", Mathf.Log10(_currentSettings.masterVolume) * 20);
                _audioMixer.SetFloat("MusicVolume", Mathf.Log10(_currentSettings.musicVolume) * 20);
                _audioMixer.SetFloat("SFXVolume", Mathf.Log10(_currentSettings.sfxVolume) * 20);
                _audioMixer.SetFloat("VoiceVolume", Mathf.Log10(_currentSettings.voiceVolume) * 20);
            }
            
            // Publish settings changed event
            EventBus.Instance.Publish(new SettingsChangedEvent(_currentSettings));
        }
        
        // Individual setting update methods
        public void SetQualityLevel(int level)
        {
            _currentSettings.qualityLevel = level;
            QualitySettings.SetQualityLevel(level);
            SaveSettings();
        }
        
        public void SetMasterVolume(float volume)
        {
            _currentSettings.masterVolume = volume;
            if (_audioMixer != null)
                _audioMixer.SetFloat("MasterVolume", Mathf.Log10(volume) * 20);
            SaveSettings();
        }
        
        public void SetMouseSensitivity(float sensitivity)
        {
            _currentSettings.mouseSensitivity = sensitivity;
            SaveSettings();
        }
        
        public void ResetToDefaults()
        {
            _currentSettings = Instantiate(_defaultSettings);
            ApplySettings();
            SaveSettings();
        }
        
        private void OnDestroy()
        {
            if (_instance == this)
            {
                _instance = null;
            }
        }
    }
}