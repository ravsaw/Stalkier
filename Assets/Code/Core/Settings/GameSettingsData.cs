using System;
using UnityEngine;

namespace CienPodroznika.Core.Settings
{
    [Serializable]
    public class GameSettingsData
    {
        [Header("Graphics")]
        public int qualityLevel = 1;
        public bool fullscreen = true;
        public SerializableResolution resolution = new SerializableResolution(1920, 1080);
        public bool vsync = true;
        public int targetFrameRate = 60;

        [Header("Audio")]
        public float masterVolume = 1f;
        public float musicVolume = 0.8f;
        public float sfxVolume = 1f;
        public float voiceVolume = 1f;

        [Header("Controls")]
        public float mouseSensitivity = 1f;
        public bool invertYAxis = false;

        [Header("Gameplay")]
        public string language = "en";
        public bool enableSubtitles = true;
        public bool enableHints = true;
        public bool enableAutosave = true;
        public float autosaveInterval = 5f;

        [Header("Accessibility")]
        public bool colorBlindMode = false;
        public bool highContrast = false;
        public float uiScale = 1f;

        // Constructor for default values
        public GameSettingsData() { }

        // Constructor from ScriptableObject
        public GameSettingsData(GameSettings settings)
        {
            qualityLevel = settings.qualityLevel;
            fullscreen = settings.fullscreen;
            resolution = new SerializableResolution(settings.resolution.width, settings.resolution.height);
            vsync = settings.vsync;
            targetFrameRate = settings.targetFrameRate;

            masterVolume = settings.masterVolume;
            musicVolume = settings.musicVolume;
            sfxVolume = settings.sfxVolume;
            voiceVolume = settings.voiceVolume;

            mouseSensitivity = settings.mouseSensitivity;
            invertYAxis = settings.invertYAxis;

            language = settings.language;
            enableSubtitles = settings.enableSubtitles;
            enableHints = settings.enableHints;
            enableAutosave = settings.enableAutosave;
            autosaveInterval = settings.autosaveInterval;

            colorBlindMode = settings.colorBlindMode;
            highContrast = settings.highContrast;
            uiScale = settings.uiScale;
        }

        // Method to apply to ScriptableObject
        public void ApplyTo(GameSettings settings)
        {
            settings.qualityLevel = qualityLevel;
            settings.fullscreen = fullscreen;
            settings.resolution = new Resolution { width = resolution.width, height = resolution.height };
            settings.vsync = vsync;
            settings.targetFrameRate = targetFrameRate;

            settings.masterVolume = masterVolume;
            settings.musicVolume = musicVolume;
            settings.sfxVolume = sfxVolume;
            settings.voiceVolume = voiceVolume;

            settings.mouseSensitivity = mouseSensitivity;
            settings.invertYAxis = invertYAxis;

            settings.language = language;
            settings.enableSubtitles = enableSubtitles;
            settings.enableHints = enableHints;
            settings.enableAutosave = enableAutosave;
            settings.autosaveInterval = autosaveInterval;

            settings.colorBlindMode = colorBlindMode;
            settings.highContrast = highContrast;
            settings.uiScale = uiScale;
        }
    }

    [Serializable]
    public class SerializableResolution
    {
        public int width;
        public int height;

        public SerializableResolution() { }

        public SerializableResolution(int w, int h)
        {
            width = w;
            height = h;
        }
    }
}