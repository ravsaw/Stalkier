using System.Collections.Generic;
using UnityEngine;
using CienPodroznika.Core.Events;

namespace CienPodroznika.Core.Locations
{
    public abstract class Location : MonoBehaviour
    {
        [Header("Location Settings")]
        [SerializeField] protected string _locationID;
        [SerializeField] protected string _locationName;
        [SerializeField] protected LocationType _locationType;
        
        [Header("Spawn and Exits")]
        [SerializeField] protected Transform _defaultSpawnPoint;
        [SerializeField] protected List<LocationExit> _exits;
        
        [Header("Location Properties")]
        [SerializeField] protected int _maxNPCCount = 40;
        [SerializeField] protected bool _isPersistent = false;
        [SerializeField] protected bool _isLoaded = false;
        
        // Events
        public event System.Action<Location> OnLocationLoaded;
        public event System.Action<Location> OnLocationUnloaded;
        public event System.Action<Location, GameObject> OnPlayerEntered;
        public event System.Action<Location, GameObject> OnPlayerExited;
        
        // Properties
        public string LocationID => _locationID;
        public string LocationName => _locationName;
        public LocationType LocationType => _locationType;
        public Transform DefaultSpawnPoint => _defaultSpawnPoint;
        public List<LocationExit> Exits => _exits;
        public bool IsLoaded => _isLoaded;
        public bool IsPersistent => _isPersistent;
        
        // Currently present NPCs
        protected List<GameObject> _currentNPCs = new List<GameObject>();
        protected List<GameObject> _currentPlayers = new List<GameObject>();
        
        protected virtual void Awake()
        {
            if (string.IsNullOrEmpty(_locationID))
            {
                _locationID = gameObject.name;
            }
            
            // Find all exits if not assigned
            if (_exits == null || _exits.Count == 0)
            {
                _exits = new List<LocationExit>(GetComponentsInChildren<LocationExit>());
            }
            
            // Find default spawn point if not assigned
            if (_defaultSpawnPoint == null)
            {
                Transform spawnPoint = transform.Find("SpawnPoint");
                if (spawnPoint != null)
                {
                    _defaultSpawnPoint = spawnPoint;
                }
                else
                {
                    // Create a default spawn point
                    GameObject spawn = new GameObject("DefaultSpawnPoint");
                    spawn.transform.parent = transform;
                    spawn.transform.localPosition = Vector3.zero;
                    _defaultSpawnPoint = spawn.transform;
                }
            }
        }
        
        public virtual void LoadLocation()
        {
            if (_isLoaded) return;
            
            _isLoaded = true;
            gameObject.SetActive(true);
            
            OnLocationLoadedInternal();
            OnLocationLoaded?.Invoke(this);
            EventBus.Instance.Publish(new LocationLoadedEvent(location: this));
        }
        
        public virtual void UnloadLocation()
        {
            if (!_isLoaded || _isPersistent) return;
            
            // Remove all NPCs
            foreach (var npc in _currentNPCs.ToArray())
            {
                if (npc != null)
                {
                    RemoveNPC(npc);
                }
            }
            
            _isLoaded = false;
            gameObject.SetActive(false);
            
            OnLocationUnloadedInternal();
            OnLocationUnloaded?.Invoke(this);
            EventBus.Instance.Publish(new LocationUnloadedEvent(this));
        }
        
        public virtual Vector3 GetSpawnPosition(string specificSpawnPointName = null)
        {
            if (!string.IsNullOrEmpty(specificSpawnPointName))
            {
                Transform specificSpawn = transform.Find(specificSpawnPointName);
                if (specificSpawn != null)
                {
                    return specificSpawn.position;
                }
            }
            
            return _defaultSpawnPoint.position;
        }
        
        public virtual bool CanAddNPC()
        {
            return _currentNPCs.Count < _maxNPCCount;
        }
        
        public virtual void AddNPC(GameObject npc)
        {
            if (!_currentNPCs.Contains(npc) && CanAddNPC())
            {
                _currentNPCs.Add(npc);
                OnNPCAdded(npc);
            }
        }
        
        public virtual void RemoveNPC(GameObject npc)
        {
            if (_currentNPCs.Contains(npc))
            {
                _currentNPCs.Remove(npc);
                OnNPCRemoved(npc);
            }
        }
        
        public virtual void OnPlayerEnter(GameObject player)
        {
            if (!_currentPlayers.Contains(player))
            {
                _currentPlayers.Add(player);
                OnPlayerEntered?.Invoke(this, player);
                EventBus.Instance.Publish(new PlayerEnteredLocationEvent(this, player));
            }
        }
        
        public virtual void OnPlayerExit(GameObject player)
        {
            if (_currentPlayers.Contains(player))
            {
                _currentPlayers.Remove(player);
                OnPlayerExited?.Invoke(this, player);
                EventBus.Instance.Publish(new PlayerExitedLocationEvent(this, player));
            }
        }
        
        // Abstract/Virtual methods for subclasses
        protected virtual void OnLocationLoadedInternal() { }
        protected virtual void OnLocationUnloadedInternal() { }
        protected virtual void OnNPCAdded(GameObject npc) { }
        protected virtual void OnNPCRemoved(GameObject npc) { }
        
        // Editor helpers
        protected virtual void OnDrawGizmos()
        {
            if (_defaultSpawnPoint != null)
            {
                Gizmos.color = Color.green;
                Gizmos.DrawWireSphere(_defaultSpawnPoint.position, 1f);
            }
            
            foreach (var exit in _exits)
            {
                if (exit != null)
                {
                    Gizmos.color = Color.red;
                    Gizmos.DrawWireCube(exit.transform.position, Vector3.one);
                }
            }
        }
    }
    
    public enum LocationType
    {
        Zone,
        Building,
        Underground,
        Special
    }
}