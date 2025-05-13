using UnityEngine;

namespace CienPodroznika.Core.Settings
{
    [CreateAssetMenu(fileName = "GameSettings", menuName = "Cien Podroznika/Game Settings")]
    public class GameSettings : ScriptableObject
    {
        [Header("Graphics")]
        public int qualityLevel = 1;
        public bool fullscreen = true;
        public Resolution resolution;
        public bool vsync = true;
        public int targetFrameRate = 60;
        
        [Header("Audio")]
        [Range(0f, 1f)]
        public float masterVolume = 1f;
        [Range(0f, 1f)]
        public float musicVolume = 0.8f;
        [Range(0f, 1f)]
        public float sfxVolume = 1f;
        [Range(0f, 1f)]
        public float voiceVolume = 1f;
        
        [Header("Controls")]
        [Range(0.1f, 10f)]
        public float mouseSensitivity = 1f;
        public bool invertYAxis = false;
        
        [Header("Gameplay")]
        public string language = "en";
        public bool enableSubtitles = true;
        public bool enableHints = true;
        public bool enableAutosave = true;
        [Range(1f, 30f)]
        public float autosaveInterval = 5f; // in minutes
        
        [Header("Accessibility")]
        public bool colorBlindMode = false;
        public bool highContrast = false;
        [Range(0.8f, 1.2f)]
        public float uiScale = 1f;
    }
}