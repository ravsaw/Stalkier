using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using Newtonsoft.Json;
using CienPodroznika.Core.Events;

namespace CienPodroznika.Core.Save
{
    public static class SaveSystem
    {
        private const string SAVE_FOLDER = "Saves";
        private const string SAVE_EXTENSION = ".json";
        
        private static readonly JsonSerializerSettings JsonSettings = new JsonSerializerSettings
        {
            Formatting = Formatting.Indented,
            ReferenceLoopHandling = ReferenceLoopHandling.Ignore
        };
        
        public static string SavePath => Path.Combine(Application.persistentDataPath, SAVE_FOLDER);
        
        static SaveSystem()
        {
            if (!Directory.Exists(SavePath))
            {
                Directory.CreateDirectory(SavePath);
            }
        }
        
        public static bool SaveGame(GameSaveData saveData, string slotName = "quicksave")
        {
            try
            {
                saveData.saveName = slotName;
                saveData.saveTimestamp = DateTime.Now;
                
                string filePath = Path.Combine(SavePath, $"{slotName}{SAVE_EXTENSION}");
                string json = JsonConvert.SerializeObject(saveData, JsonSettings);
                
                File.WriteAllText(filePath, json);
                
                EventBus.Instance.Publish(new GameSavedEvent(slotName, true));
                Debug.Log($"Game saved successfully to {filePath}");
                return true;
            }
            catch (Exception ex)
            {
                Debug.LogError($"Failed to save game: {ex.Message}");
                EventBus.Instance.Publish(new GameSavedEvent(slotName, false));
                return false;
            }
        }
        
        public static GameSaveData LoadGame(string slotName = "quicksave")
        {
            try
            {
                string filePath = Path.Combine(SavePath, $"{slotName}{SAVE_EXTENSION}");
                
                if (!File.Exists(filePath))
                {
                    Debug.LogWarning($"Save file not found: {filePath}");
                    return null;
                }
                
                string json = File.ReadAllText(filePath);
                GameSaveData saveData = JsonConvert.DeserializeObject<GameSaveData>(json, JsonSettings);
                
                Debug.Log($"Game loaded successfully from {filePath}");
                return saveData;
            }
            catch (Exception ex)
            {
                Debug.LogError($"Failed to load game: {ex.Message}");
                return null;
            }
        }
        
        public static bool DeleteSave(string slotName)
        {
            try
            {
                string filePath = Path.Combine(SavePath, $"{slotName}{SAVE_EXTENSION}");
                
                if (File.Exists(filePath))
                {
                    File.Delete(filePath);
                    Debug.Log($"Save deleted: {filePath}");
                    return true;
                }
                
                return false;
            }
            catch (Exception ex)
            {
                Debug.LogError($"Failed to delete save: {ex.Message}");
                return false;
            }
        }
        
        public static List<string> GetSaveSlots()
        {
            List<string> saveSlots = new List<string>();
            
            try
            {
                string[] files = Directory.GetFiles(SavePath, $"*{SAVE_EXTENSION}");
                
                foreach (string file in files)
                {
                    string fileName = Path.GetFileNameWithoutExtension(file);
                    saveSlots.Add(fileName);
                }
            }
            catch (Exception ex)
            {
                Debug.LogError($"Failed to get save slots: {ex.Message}");
            }
            
            return saveSlots;
        }
        
        public static bool SaveExists(string slotName)
        {
            string filePath = Path.Combine(SavePath, $"{slotName}{SAVE_EXTENSION}");
            return File.Exists(filePath);
        }
    }
}