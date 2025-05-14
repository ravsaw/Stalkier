using CienPodroznika.Core.Settings;
using UnityEngine;
using System.Collections;
using CienPodroznika.Core.Locations;

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

    // Player movement events
    public class PlayerJumpedEvent
    {
        public Vector3 Position { get; }

        public PlayerJumpedEvent(Vector3 position)
        {
            Position = position;
        }
    }

    public class PlayerLandedEvent
    {
        public Vector3 Position { get; }
        public float FallSpeed { get; }

        public PlayerLandedEvent(Vector3 position, float fallSpeed)
        {
            Position = position;
            FallSpeed = fallSpeed;
        }
    }

    public class PlayerCrouchStateChangedEvent
    {
        public bool IsCrouching { get; }

        public PlayerCrouchStateChangedEvent(bool isCrouching)
        {
            IsCrouching = isCrouching;
        }
    }

    public class PlayerMovedEvent
    {
        public Vector3 Position { get; }
        public Vector3 Velocity { get; }
        public float Speed { get; }

        public PlayerMovedEvent(Vector3 position, Vector3 velocity, float speed)
        {
            Position = position;
            Velocity = velocity;
            Speed = speed;
        }
    }

    // Player lifecycle events
    public class PlayerSpawnedEvent
    {
        public GameObject Player { get; }
        public Vector3 SpawnPosition { get; }

        public PlayerSpawnedEvent(GameObject player, Vector3 spawnPosition)
        {
            Player = player;
            SpawnPosition = spawnPosition;
        }
    }

    public class PlayerTeleportedEvent
    {
        public Vector3 Position { get; }
        public Quaternion Rotation { get; }

        public PlayerTeleportedEvent(Vector3 position, Quaternion rotation)
        {
            Position = position;
            Rotation = rotation;
        }
    }
}