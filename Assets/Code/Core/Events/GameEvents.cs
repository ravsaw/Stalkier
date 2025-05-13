using CienPodroznika.Core.Settings;
using UnityEngine;
using System.Collections;

namespace CienPodroznika.Core.Events
{
    // Event wywoływany przy zmianie stanu gry
    public class GameStateChangedEvent
    {
        public GameState PreviousState { get; }
        public GameState NewState { get; }
        
        public GameStateChangedEvent(GameState previousState, GameState newState)
        {
            PreviousState = previousState;
            NewState = newState;
        }
    }
    
    // Event wywoływany przy zmianie lokacji
    public class LocationChangedEvent
    {
        public string PreviousLocationId { get; }
        public string NewLocationId { get; }
        
        public LocationChangedEvent(string previousLocationId, string newLocationId)
        {
            PreviousLocationId = previousLocationId;
            NewLocationId = newLocationId;
        }
    }
    
    // Event wywoływany przy zapisie gry
    public class GameSavedEvent
    {
        public string SaveName { get; }
        public bool Success { get; }
        
        public GameSavedEvent(string saveName, bool success)
        {
            SaveName = saveName;
            Success = success;
        }
    }

    // Event wywoływany przy zmianie ustawień
    public class SettingsChangedEvent
    {
        public GameSettings Settings { get; }
        
        public SettingsChangedEvent(GameSettings settings)
        {
            Settings = settings;
        }
    }

    public class LocationLoadedEvent
    {
        public Location Location { get; }
        
        public LocationLoadedEvent(Location location)
        {
            Location = location;
        }
    }

    public class LocationUnloadedEvent
    {
        public Location Location { get; }
        
        public LocationUnloadedEvent(Location location)
        {
            Location = location;
        }
    }

    public class PlayerEnteredLocationEvent
    {
        public Location Location { get; }
        public GameObject Player { get; }
        
        public PlayerEnteredLocationEvent(Location location, GameObject player)
        {
            Location = location;
            Player = player;
        }
    }

    public class PlayerExitedLocationEvent
    {
        public Location Location { get; }
        public GameObject Player { get; }
        
        public PlayerExitedLocationEvent(Location location, GameObject player)
        {
            Location = location;
            Player = player;
        }
    }

    public class LocationTransitionRequestedEvent
    {
        public string FromLocationID { get; }
        public string ToLocationID { get; }
        public string SpawnPointName { get; }
        public LoadingMethod LoadingMethod { get; }
        public LocationExit Exit { get; }
        public GameObject Player { get; }
        
        public LocationTransitionRequestedEvent(string fromLocationID, string toLocationID, 
            string spawnPointName, LoadingMethod loadingMethod, LocationExit exit, GameObject player)
        {
            FromLocationID = fromLocationID;
            ToLocationID = toLocationID;
            SpawnPointName = spawnPointName;
            LoadingMethod = loadingMethod;
            Exit = exit;
            Player = player;
        }
    }

    public class LocationLoadingStartedEvent
    {
        public string LocationID { get; }
        
        public LocationLoadingStartedEvent(string locationID)
        {
            LocationID = locationID;
        }
    }

    public class LocationLoadingCompletedEvent
    {
        public string LocationID { get; }
        
        public LocationLoadingCompletedEvent(string locationID)
        {
            LocationID = locationID;
        }
    }
}