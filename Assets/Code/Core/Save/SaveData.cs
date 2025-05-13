using System;
using System.Collections.Generic;
using CienPodroznika.Core.Settings;
using UnityEngine;

namespace CienPodroznika.Core.Save
{
    [Serializable]
    public class GameSaveData
    {
        public string saveName;
        public string saveVersion;
        public DateTime saveTimestamp;
        public float playTime;
        
        // Player data
        public PlayerSaveData playerData;
        
        // World data
        public WorldSaveData worldData;
        
        // Game progress
        public GameProgressData progressData;
        
        public GameSaveData()
        {
            saveVersion = Application.version;
            saveTimestamp = DateTime.Now;
            playTime = 0f;
            
            playerData = new PlayerSaveData();
            worldData = new WorldSaveData();
            progressData = new GameProgressData();
        }
    }
    
    [Serializable]
    public class PlayerSaveData
    {
        public Vector3Serializable position;
        public Vector3Serializable rotation;
        public string currentLocationId;
        public float health;
        public float radiation;
        public int money;
        public List<string> inventoryItems;
        
        public PlayerSaveData()
        {
            inventoryItems = new List<string>();
        }
    }
    
    [Serializable]
    public class WorldSaveData
    {
        public List<LocationSaveData> locations;
        public Dictionary<string, bool> discoveredLocations;
        public float gameTime;
        
        public WorldSaveData()
        {
            locations = new List<LocationSaveData>();
            discoveredLocations = new Dictionary<string, bool>();
        }
    }
    
    [Serializable]
    public class GameProgressData
    {
        public List<string> completedQuests;
        public List<string> activeQuests;
        public Dictionary<string, float> factionRelations;
        public Dictionary<string, bool> flags;
        
        public GameProgressData()
        {
            completedQuests = new List<string>();
            activeQuests = new List<string>();
            factionRelations = new Dictionary<string, float>();
            flags = new Dictionary<string, bool>();
        }
    }
    
    [Serializable]
    public class LocationSaveData
    {
        public string locationId;
        public List<string> changedObjects;
        public Dictionary<string, bool> discoveredAreas;
    }
    
    // Helper class for serializing Vector3
    [Serializable]
    public class Vector3Serializable
    {
        public float x, y, z;
        
        public Vector3Serializable(Vector3 vector)
        {
            x = vector.x;
            y = vector.y;
            z = vector.z;
        }
        
        public Vector3 ToVector3()
        {
            return new Vector3(x, y, z);
        }
    }
}