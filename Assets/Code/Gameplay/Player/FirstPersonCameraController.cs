using UnityEngine;
using Cinemachine;
using CienPodroznika.Core.Settings;
using CienPodroznika.Core.Events;

namespace CienPodroznika.Gameplay.Player
{
    public class FirstPersonCameraController : MonoBehaviour
    {
        [Header("Camera Settings")]
        [SerializeField] private float _mouseSensitivity = 100f;
        [SerializeField] private float _lookUpLimit = 80f;
        [SerializeField] private float _lookDownLimit = -80f;
        [SerializeField] private bool _invertYAxis = false;

        [Header("Camera Bob")]
        [SerializeField] private bool _enableHeadBob = true;
        [SerializeField] private float _bobSpeed = 14f;
        [SerializeField] private float _bobAmount = 0.05f;
        [SerializeField] private float _runBobMultiplier = 1.5f;

        [Header("Camera Sway")]
        [SerializeField] private bool _enableSway = true;
        [SerializeField] private float _swayIntensity = 1f;
        [SerializeField] private float _maxSway = 5f;
        [SerializeField] private float _swaySmooth = 1f;

        // Components
        private CinemachineVirtualCamera _virtualCamera;
        private PlayerInputHandler _inputHandler;
        private FirstPersonController _playerController;

        // Camera state
        private float _xRotation = 0f;
        private float _bobTimer = 0f;
        private Vector3 _initialCameraPosition;

        // Sway
        private Vector3 _swayTarget;
        private Vector3 _currentSway;

        // Settings
        private float _currentSensitivity;

        private void Awake()
        {
            _virtualCamera = GetComponent<CinemachineVirtualCamera>();
            _inputHandler = FindObjectOfType<PlayerInputHandler>();
            _playerController = FindObjectOfType<FirstPersonController>();

            _initialCameraPosition = transform.localPosition;

            // Lock cursor
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }

        private void Start()
        {
            // Subscribe to input events
            if (_inputHandler != null)
            {
                _inputHandler.OnLookInput += HandleLookInput;
            }

            // Subscribe to player movement events
            if (_playerController != null)
            {
                _playerController.OnMoved += HandlePlayerMovement;
            }

            // Subscribe to settings changes
            EventBus.Instance.Subscribe<SettingsChangedEvent>(OnSettingsChanged);

            // Apply initial settings
            ApplySettings();

            Debug.Log($"Cursor lock state: {Cursor.lockState}");
            Debug.Log($"Cursor visible: {Cursor.visible}");
        }

        private void Update()
        {
            if (_enableHeadBob)
            {
                UpdateHeadBob();
            }

            if (_enableSway)
            {
                UpdateCameraSway();
            }
        }

        private void HandleLookInput(Vector2 lookInput)
        {
            // Apply sensitivity and frame rate independence
            float mouseX = lookInput.x * _currentSensitivity * Time.deltaTime;
            float mouseY = lookInput.y * _currentSensitivity * Time.deltaTime;

            // Apply Y-axis inversion if enabled
            if (_invertYAxis)
            {
                mouseY = -mouseY;
            }

            // Rotate the player body on Y axis
            transform.parent.Rotate(Vector3.up * mouseX);

            // Rotate the camera on X axis (look up/down)
            _xRotation -= mouseY;
            _xRotation = Mathf.Clamp(_xRotation, _lookDownLimit, _lookUpLimit);
            transform.localRotation = Quaternion.Euler(_xRotation, 0f, 0f);
        }

        private void HandlePlayerMovement(Vector3 movement)
        {
            // Update head bob timer based on movement
            if (movement.magnitude > 0.1f && _playerController.IsGrounded)
            {
                _bobTimer += Time.deltaTime * _bobSpeed;

                if (_playerController.IsRunning)
                {
                    _bobTimer *= _runBobMultiplier;
                }
            }
        }

        private void UpdateHeadBob()
        {
            if (!_playerController.IsGrounded)
            {
                return;
            }

            Vector3 bobOffset = Vector3.zero;

            if (_playerController.CurrentSpeed > 0.1f)
            {
                float bobMultiplier = _playerController.IsRunning ? _runBobMultiplier : 1f;

                bobOffset.y = Mathf.Sin(_bobTimer) * _bobAmount * bobMultiplier;
                bobOffset.x = Mathf.Cos(_bobTimer * 0.5f) * _bobAmount * 0.5f * bobMultiplier;
            }
            else
            {
                // Smoothly return to rest position
                _bobTimer = 0;
            }

            transform.localPosition = _initialCameraPosition + bobOffset;
        }

        private void UpdateCameraSway()
        {
            Vector2 lookInput = _inputHandler.LookInput;

            // Calculate sway target based on mouse input
            _swayTarget.x = -lookInput.y * _swayIntensity;
            _swayTarget.y = lookInput.x * _swayIntensity;
            _swayTarget.z = lookInput.x * _swayIntensity;

            // Clamp sway
            _swayTarget.x = Mathf.Clamp(_swayTarget.x, -_maxSway, _maxSway);
            _swayTarget.y = Mathf.Clamp(_swayTarget.y, -_maxSway, _maxSway);
            _swayTarget.z = Mathf.Clamp(_swayTarget.z, -_maxSway, _maxSway);

            // Smoothly move towards target
            _currentSway = Vector3.Lerp(_currentSway, _swayTarget, _swaySmooth * Time.deltaTime);

            // Apply sway to camera rotation
            transform.localRotation = Quaternion.Euler(_xRotation + _currentSway.x, _currentSway.y, _currentSway.z);
        }

        private void OnSettingsChanged(SettingsChangedEvent eventData)
        {
            ApplySettings();
        }

        private void ApplySettings()
        {
            var settings = SettingsManager.Instance?.CurrentSettings;
            if (settings != null)
            {
                _currentSensitivity = settings.mouseSensitivity * _mouseSensitivity;
                _invertYAxis = settings.invertYAxis;
            }
            else
            {
                _currentSensitivity = _mouseSensitivity;
            }
        }

        public void SetCameraEnabled(bool enabled)
        {
            _virtualCamera.enabled = enabled;
        }

        public void ResetCameraRotation()
        {
            _xRotation = 0f;
            transform.localRotation = Quaternion.identity;
            _swayTarget = Vector3.zero;
            _currentSway = Vector3.zero;
        }

        private void OnDestroy()
        {
            if (_inputHandler != null)
            {
                _inputHandler.OnLookInput -= HandleLookInput;
            }

            if (_playerController != null)
            {
                _playerController.OnMoved -= HandlePlayerMovement;
            }

            EventBus.Instance.Unsubscribe<SettingsChangedEvent>(OnSettingsChanged);
        }
    }
}