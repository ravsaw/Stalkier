using UnityEngine;
using CienPodroznika.Core;
using CienPodroznika.Core.Events;
using CienPodroznika.Core.Locations;

namespace CienPodroznika.Gameplay.Player
{
    public class PlayerManager : MonoBehaviour
    {
        [Header("Player Prefab")]
        [SerializeField] private GameObject _playerPrefab;

        private static PlayerManager _instance;
        public static PlayerManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = FindObjectOfType<PlayerManager>();
                }
                return _instance;
            }
        }

        // Current player instance
        private GameObject _currentPlayer;
        private FirstPersonController _playerController;
        private FirstPersonCameraController _cameraController;

        // Properties
        public GameObject CurrentPlayer => _currentPlayer;
        public FirstPersonController PlayerController => _playerController;
        public Vector3 PlayerPosition => _currentPlayer != null ? _currentPlayer.transform.position : Vector3.zero;

        // Events  
        public event System.Action<GameObject> OnPlayerSpawned;
        public event System.Action<GameObject> OnPlayerDestroyed;

        private void Awake()
        {
            if (_instance == null)
            {
                _instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else if (_instance != this)
            {
                Destroy(gameObject);
            }
        }

        private void Start()
        {
            // Subscribe to location events
            EventBus.Instance.Subscribe<LocationChangedEvent>(OnLocationChanged);
            EventBus.Instance.Subscribe<GameStateChangedEvent>(OnGameStateChanged);

            // Find existing player or spawn new one
            if (_currentPlayer == null)
            {
                _currentPlayer = GameObject.FindWithTag("Player");
                if (_currentPlayer == null)
                {
                    SpawnPlayer();
                }
                else
                {
                    InitializeExistingPlayer();
                }
            }
        }

        public void SpawnPlayer(Vector3? position = null)
        {
            if (_playerPrefab == null)
            {
                Debug.LogError("Player prefab is not assigned!");
                return;
            }

            // Destroy existing player if any
            if (_currentPlayer != null)
            {
                DestroyPlayer();
            }

            // Determine spawn position
            Vector3 spawnPos = position ?? GetDefaultSpawnPosition();

            // Spawn player
            _currentPlayer = Instantiate(_playerPrefab, spawnPos, Quaternion.identity);
            _currentPlayer.name = "Player";
            _currentPlayer.tag = "Player";

            // Get components
            InitializePlayer();

            OnPlayerSpawned?.Invoke(_currentPlayer);
            EventBus.Instance.Publish(new PlayerSpawnedEvent(_currentPlayer, spawnPos));
        }

        private void InitializePlayer()
        {
            _playerController = _currentPlayer.GetComponent<FirstPersonController>();
            _cameraController = _currentPlayer.GetComponentInChildren<FirstPersonCameraController>();

            if (_playerController == null)
            {
                Debug.LogError("Player prefab is missing FirstPersonController component!");
            }

            if (_cameraController == null)
            {
                Debug.LogError("Player prefab is missing FirstPersonCameraController component!");
            }
        }

        private void InitializeExistingPlayer()
        {
            InitializePlayer();
            OnPlayerSpawned?.Invoke(_currentPlayer);
        }

        public void DestroyPlayer()
        {
            if (_currentPlayer != null)
            {
                OnPlayerDestroyed?.Invoke(_currentPlayer);
                Destroy(_currentPlayer);
                _currentPlayer = null;
                _playerController = null;
                _cameraController = null;
            }
        }

        public void TeleportPlayer(Vector3 position, Quaternion? rotation = null)
        {
            if (_currentPlayer != null)
            {
                // Disable controller temporarily to prevent issues
                if (_playerController != null)
                {
                    _playerController.enabled = false;
                }

                // Set position and rotation
                _currentPlayer.transform.position = position;
                if (rotation.HasValue)
                {
                    _currentPlayer.transform.rotation = rotation.Value;
                }

                // Re-enable controller
                if (_playerController != null)
                {
                    _playerController.enabled = true;
                }

                EventBus.Instance.Publish(new PlayerTeleportedEvent(position, rotation ?? _currentPlayer.transform.rotation));
            }
        }

        public void SetPlayerEnabled(bool enabled)
        {
            if (_currentPlayer != null)
            {
                _currentPlayer.SetActive(enabled);
            }
        }

        private Vector3 GetDefaultSpawnPosition()
        {
            // Try to get spawn position from current location
            Location currentLocation = LocationManager.Instance?.CurrentLocation;
            if (currentLocation != null)
            {
                return currentLocation.GetSpawnPosition();
            }

            // Default position
            return Vector3.zero;
        }

        private void OnLocationChanged(LocationChangedEvent eventData)
        {
            // Player position is managed by LocationManager, no action needed here
        }

        private void OnGameStateChanged(GameStateChangedEvent eventData)
        {
            switch (eventData.NewState)
            {
                case GameState.Playing:
                    SetPlayerEnabled(true);
                    break;
                case GameState.Paused:
                case GameState.InDialog:
                case GameState.InInventory:
                    // Player remains enabled but input might be disabled
                    break;
                case GameState.GameOver:
                    // Don't disable player immediately, let game handle it
                    break;
            }
        }

        private void OnDestroy()
        {
            if (_instance == this)
            {
                EventBus.Instance.Unsubscribe<LocationChangedEvent>(OnLocationChanged);
                EventBus.Instance.Unsubscribe<GameStateChangedEvent>(OnGameStateChanged);
                _instance = null;
            }
        }
    }
}