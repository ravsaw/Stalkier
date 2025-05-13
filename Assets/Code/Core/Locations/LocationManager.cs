using System.Collections.Generic;
using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using CienPodroznika.Core.Events;

namespace CienPodroznika.Core.Locations
{
    public class LocationManager : MonoBehaviour
    {
        [Header("Settings")]
        [SerializeField] private int _maxLoadedLocations = 3;
        [SerializeField] private float _unloadDelay = 5f;
        [SerializeField] private bool _enableAsyncLoading = true;
        
        private static LocationManager _instance;
        public static LocationManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = FindObjectOfType<LocationManager>();
                }
                return _instance;
            }
        }
        
        // Currently loaded locations
        private Dictionary<string, Location> _loadedLocations = new Dictionary<string, Location>();
        
        // Location loading queue
        private Queue<LocationLoadRequest> _loadQueue = new Queue<LocationLoadRequest>();
        private Queue<string> _unloadQueue = new Queue<string>();
        
        // Current state
        private Location _currentLocation;
        private bool _isLoading = false;
        
        // Events
        public event System.Action<Location> OnLocationChanged;
        public event System.Action<float> OnLoadingProgress;
        public event System.Action OnLoadingStarted;
        public event System.Action OnLoadingCompleted;
        
        // Properties
        public Location CurrentLocation => _currentLocation;
        public bool IsLoading => _isLoading;
        public int LoadedLocationCount => _loadedLocations.Count;
        
        private void Awake()
        {
            if (_instance == null)
            {
                _instance = this;
                DontDestroyOnLoad(gameObject);
                Initialize();
            }
            else if (_instance != this)
            {
                Destroy(gameObject);
            }
        }
        
        private void Initialize()
        {
            // Subscribe to events
            EventBus.Instance.Subscribe<LocationTransitionRequestedEvent>(OnLocationTransitionRequested);
            EventBus.Instance.Subscribe<GameStateChangedEvent>(OnGameStateChanged);
            
            // Find initial location
            Location startLocation = FindObjectOfType<Location>();
            if (startLocation != null)
            {
                _currentLocation = startLocation;
                RegisterLocation(startLocation);
                startLocation.LoadLocation();
            }
        }
        
        private void Update()
        {
            ProcessLoadQueue();
            ProcessUnloadQueue();
        }
        
        public void RegisterLocation(Location location)
        {
            if (!_loadedLocations.ContainsKey(location.LocationID))
            {
                _loadedLocations[location.LocationID] = location;
                
                // Subscribe to location events
                location.OnLocationLoaded += OnLocationLoaded;
                location.OnLocationUnloaded += OnLocationUnloaded;
            }
        }
        
        public void UnregisterLocation(Location location)
        {
            if (_loadedLocations.ContainsKey(location.LocationID))
            {
                _loadedLocations.Remove(location.LocationID);
                
                // Unsubscribe from location events
                location.OnLocationLoaded -= OnLocationLoaded;
                location.OnLocationUnloaded -= OnLocationUnloaded;
            }
        }
        
        public Location GetLocation(string locationID)
        {
            _loadedLocations.TryGetValue(locationID, out Location location);
            return location;
        }
        
        public bool IsLocationLoaded(string locationID)
        {
            return _loadedLocations.ContainsKey(locationID) && _loadedLocations[locationID].IsLoaded;
        }
        
        public void LoadLocation(string locationID, string spawnPointName = null, 
            LoadingMethod method = LoadingMethod.Immediate)
        {
            var request = new LocationLoadRequest(locationID, spawnPointName, method);
            _loadQueue.Enqueue(request);
        }
        
        public void UnloadLocation(string locationID, float delay = 0f)
        {
            if (delay > 0f)
            {
                StartCoroutine(UnloadLocationDelayed(locationID, delay));
            }
            else
            {
                _unloadQueue.Enqueue(locationID);
            }
        }
        
        private IEnumerator UnloadLocationDelayed(string locationID, float delay)
        {
            yield return new WaitForSeconds(delay);
            _unloadQueue.Enqueue(locationID);
        }
        
        private void ProcessLoadQueue()
        {
            if (_loadQueue.Count > 0 && !_isLoading)
            {
                var request = _loadQueue.Dequeue();
                StartCoroutine(LoadLocationInternal(request));
            }
        }
        
        private void ProcessUnloadQueue()
        {
            if (_unloadQueue.Count > 0 && !_isLoading)
            {
                string locationID = _unloadQueue.Dequeue();
                Location location = GetLocation(locationID);
                
                if (location != null && location != _currentLocation)
                {
                    location.UnloadLocation();
                }
            }
        }
        
        private IEnumerator LoadLocationInternal(LocationLoadRequest request)
        {
            _isLoading = true;
            OnLoadingStarted?.Invoke();
            EventBus.Instance.Publish(new LocationLoadingStartedEvent(request.LocationID));
            
            // Check if we need to unload old locations first
            while (_loadedLocations.Count >= _maxLoadedLocations)
            {
                UnloadOldestLocation();
                yield return null; // Wait a frame
            }
            
            // Report progress
            OnLoadingProgress?.Invoke(0.3f);
            yield return new WaitForSeconds(0.1f);
            
            // Load the location
            Location targetLocation = GetLocation(request.LocationID);
            
            if (targetLocation == null)
            {
                // Try to find location in scene
                targetLocation = FindLocationInScene(request.LocationID);
                
                if (targetLocation == null)
                {
                    // Try to load location from scene file (if using addressables or scene management)
                    yield return LoadLocationFromAsset(request.LocationID);
                    targetLocation = GetLocation(request.LocationID);
                }
            }
            
            OnLoadingProgress?.Invoke(0.7f);
            yield return new WaitForSeconds(0.1f);
            
            if (targetLocation != null)
            {
                // Move to new location
                yield return TransitionToLocation(targetLocation, request.SpawnPointName);
            }
            else
            {
                Debug.LogError($"Failed to load location: {request.LocationID}");
            }
            
            OnLoadingProgress?.Invoke(1f);
            yield return new WaitForSeconds(0.1f);
            
            _isLoading = false;
            OnLoadingCompleted?.Invoke();
            EventBus.Instance.Publish(new LocationLoadingCompletedEvent(request.LocationID));
        }
        
        private IEnumerator TransitionToLocation(Location newLocation, string spawnPointName)
        {
            Location previousLocation = _currentLocation;
            
            // Load new location
            newLocation.LoadLocation();
            
            // Move player to new location
            GameObject player = GameObject.FindWithTag("Player");
            if (player != null)
            {
                Vector3 spawnPosition = newLocation.GetSpawnPosition(spawnPointName);
                player.transform.position = spawnPosition;
                
                // Notify locations about player movement
                if (previousLocation != null)
                {
                    previousLocation.OnPlayerExit(player);
                }
                newLocation.OnPlayerEnter(player);
            }
            
            // Update current location
            _currentLocation = newLocation;
            OnLocationChanged?.Invoke(newLocation);
            EventBus.Instance.Publish(new LocationChangedEvent(
                previousLocation?.LocationID ?? "Unknown",
                newLocation.LocationID
            ));
            
            // Schedule unload of previous location
            if (previousLocation != null && !previousLocation.IsPersistent)
            {
                UnloadLocation(previousLocation.LocationID, _unloadDelay);
            }
            
            yield return null;
        }
        
        private Location FindLocationInScene(string locationID)
        {
            Location[] locations = FindObjectsOfType<Location>();
            foreach (var location in locations)
            {
                if (location.LocationID == locationID)
                {
                    RegisterLocation(location);
                    return location;
                }
            }
            return null;
        }
        
        private IEnumerator LoadLocationFromAsset(string locationID)
        {
            // This would be implementation for loading from Addressables or Scenes
            // For now, we'll just try to find it in the current scene
            yield return null;
        }
        
        private void UnloadOldestLocation()
        {
            Location oldestLocation = null;
            float oldestTime = float.MaxValue;
            
            foreach (var kvp in _loadedLocations)
            {
                Location location = kvp.Value;
                if (location != _currentLocation && !location.IsPersistent)
                {
                    // For simplicity, we'll unload the first non-persistent location
                    oldestLocation = location;
                    break;
                }
            }
            
            if (oldestLocation != null)
            {
                oldestLocation.UnloadLocation();
            }
        }
        
        private void OnLocationLoaded(Location location)
        {
            Debug.Log($"Location loaded: {location.LocationID}");
        }
        
        private void OnLocationUnloaded(Location location)
        {
            Debug.Log($"Location unloaded: {location.LocationID}");
            UnregisterLocation(location);
        }
        
        private void OnLocationTransitionRequested(LocationTransitionRequestedEvent eventData)
        {
            LoadLocation(eventData.TargetLocationID, eventData.SpawnPointName, eventData.LoadingMethod);
        }
        
        private void OnGameStateChanged(GameStateChangedEvent eventData)
        {
            if (eventData.NewState == GameState.Loading)
            {
                // Handle game loading state if needed
            }
        }
        
        private void OnDestroy()
        {
            if (_instance == this)
            {
                EventBus.Instance.Unsubscribe<LocationTransitionRequestedEvent>(OnLocationTransitionRequested);
                EventBus.Instance.Unsubscribe<GameStateChangedEvent>(OnGameStateChanged);
                _instance = null;
            }
        }
    }
    
    // Helper classes
    public class LocationLoadRequest
    {
        public string LocationID { get; }
        public string SpawnPointName { get; }
        public LoadingMethod Method { get; }
        
        public LocationLoadRequest(string locationID, string spawnPointName = null, 
            LoadingMethod method = LoadingMethod.Immediate)
        {
            LocationID = locationID;
            SpawnPointName = spawnPointName;
            Method = method;
        }
    }
}