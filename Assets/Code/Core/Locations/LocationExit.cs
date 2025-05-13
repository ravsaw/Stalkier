using UnityEngine;
using CienPodroznika.Core.Events;

namespace CienPodroznika.Core.Locations
{
    public class LocationExit : MonoBehaviour
    {
        [Header("Exit Settings")]
        [SerializeField] private string _exitID;
        [SerializeField] private string _targetLocationID;
        [SerializeField] private string _targetSpawnPointName;
        [SerializeField] private LoadingMethod _loadingMethod = LoadingMethod.Immediate;
        
        [Header("Trigger Settings")]
        [SerializeField] private TriggerType _triggerType = TriggerType.Automatic;
        [SerializeField] private float _triggerRadius = 2f;
        [SerializeField] private bool _requiresInteraction = false;
        [SerializeField] private string _interactionPrompt = "Press E to travel";
        
        // Properties
        public string ExitID => _exitID;
        public string TargetLocationID => _targetLocationID;
        public string TargetSpawnPointName => _targetSpawnPointName;
        public LoadingMethod LoadingMethod => _loadingMethod;
        public bool RequiresInteraction => _requiresInteraction;
        
        // Current state
        private bool _playerInRange = false;
        private Collider _trigger;
        private Location _parentLocation;
        
        // Events
        public event System.Action<LocationExit, GameObject> OnPlayerEntered;
        public event System.Action<LocationExit, GameObject> OnPlayerExited;
        public event System.Action<LocationExit, GameObject> OnTravelRequested;
        
        private void Awake()
        {
            if (string.IsNullOrEmpty(_exitID))
            {
                _exitID = $"{gameObject.name}_{GetInstanceID()}";
            }
            
            _parentLocation = GetComponentInParent<Location>();
            
            // Setup trigger collider
            SetupTrigger();
        }
        
        private void SetupTrigger()
        {
            _trigger = GetComponent<Collider>();
            if (_trigger == null)
            {
                _trigger = gameObject.AddComponent<SphereCollider>();
                ((SphereCollider)_trigger).radius = _triggerRadius;
            }
            
            _trigger.isTrigger = true;
            
            // Add Rigidbody if needed for trigger detection
            if (GetComponent<Rigidbody>() == null)
            {
                Rigidbody rb = gameObject.AddComponent<Rigidbody>();
                rb.isKinematic = true;
            }
        }
        
        private void OnTriggerEnter(Collider other)
        {
            if (other.CompareTag("Player"))
            {
                _playerInRange = true;
                OnPlayerEntered?.Invoke(this, other.gameObject);
                
                if (_triggerType == TriggerType.Automatic && !_requiresInteraction)
                {
                    RequestTravel(other.gameObject);
                }
            }
        }
        
        private void OnTriggerExit(Collider other)
        {
            if (other.CompareTag("Player"))
            {
                _playerInRange = false;
                OnPlayerExited?.Invoke(this, other.gameObject);
            }
        }
        
        private void Update()
        {
            if (_playerInRange && _requiresInteraction && Input.GetKeyDown(KeyCode.E))
            {
                // Find player in range
                Collider[] playersInRange = Physics.OverlapSphere(transform.position, _triggerRadius, 
                    1 << LayerMask.NameToLayer("Player"));
                
                if (playersInRange.Length > 0)
                {
                    RequestTravel(playersInRange[0].gameObject);
                }
            }
        }
        
        public void RequestTravel(GameObject player)
        {
            OnTravelRequested?.Invoke(this, player);
            
            EventBus.Instance.Publish(new LocationTransitionRequestedEvent(
                _parentLocation?.LocationID ?? "Unknown",
                _targetLocationID,
                _targetSpawnPointName,
                _loadingMethod,
                this,
                player
            ));
        }
        
        // Editor helpers
        private void OnDrawGizmos()
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(transform.position, _triggerRadius);
            
            if (!string.IsNullOrEmpty(_targetLocationID))
            {
                Gizmos.color = Color.cyan;
                Vector3 labelPos = transform.position + Vector3.up * 2f;
                
                // Draw arrow indicating exit direction
                Gizmos.DrawLine(transform.position, transform.position + transform.forward * 2f);
            }
        }
        
        private void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.green;
            Gizmos.DrawSphere(transform.position, _triggerRadius);
        }
    }
    
    public enum TriggerType
    {
        Automatic,
        PlayerProximity,
        Interaction
    }
    
    public enum LoadingMethod
    {
        Immediate,
        WithLoadingScreen,
        AsyncBackground
    }
}