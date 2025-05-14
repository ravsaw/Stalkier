using UnityEngine;
using CienPodroznika.Core;
using CienPodroznika.Core.Events;

namespace CienPodroznika.Gameplay.Player
{
    [RequireComponent(typeof(CharacterController))]
    [RequireComponent(typeof(PlayerInputHandler))]
    public class FirstPersonController : MonoBehaviour
    {
        [Header("Movement")]
        [SerializeField] private float _walkSpeed = 5f;
        [SerializeField] private float _runSpeed = 10f;
        [SerializeField] private float _crouchSpeed = 2f;
        [SerializeField] private float _jumpForce = 10f;
        [SerializeField] private float _gravity = 9.81f;
        [SerializeField] private float _airControl = 0.5f;

        [Header("Physics")]
        [SerializeField] private float _groundCheckDistance = 0.1f;
        [SerializeField] private LayerMask _groundMask = 1;
        [SerializeField] private float _coyoteTime = 0.15f;
        [SerializeField] private float _jumpBufferTime = 0.1f;

        [Header("Crouch")]
        [SerializeField] private float _standingHeight = 2f;
        [SerializeField] private float _crouchHeight = 1f;
        [SerializeField] private float _crouchTransitionSpeed = 5f;

        // Components
        private CharacterController _controller;
        private PlayerInputHandler _inputHandler;
        private Transform _cameraTransform;

        // Movement state
        private Vector3 _velocity;
        private bool _isGrounded;
        private bool _wasGrounded;
        private bool _isRunning;
        private bool _isCrouching;
        private bool _wantsToJump;

        // Timing
        private float _coyoteTimeCounter;
        private float _jumpBufferCounter;
        private float _currentCrouchHeight;

        // Events
        public event System.Action<Vector3> OnMoved;
        public event System.Action<float> OnSpeedChanged;
        public event System.Action OnJumped;
        public event System.Action OnLanded;
        public event System.Action OnStartedCrouching;
        public event System.Action OnStoppedCrouching;

        private void Awake()
        {
            _controller = GetComponent<CharacterController>();
            _inputHandler = GetComponent<PlayerInputHandler>();
            _cameraTransform = Camera.main.transform;

            _currentCrouchHeight = _standingHeight;
        }

        private void Start()
        {
            // Subscribe to input events
            _inputHandler.OnMoveInput += HandleMoveInput;
            _inputHandler.OnJumpInput += HandleJumpInput;
            _inputHandler.OnRunInput += HandleRunInput;
            _inputHandler.OnCrouchInput += HandleCrouchInput;

            // Subscribe to game state changes
            EventBus.Instance.Subscribe<GameStateChangedEvent>(OnGameStateChanged);
        }

        private void Update()
        {
            CheckGrounded();
            UpdateCrouchHeight();
            HandleMovement();
            HandleJumping();
            ApplyGravity();
            UpdateTimers();
        }

        private void CheckGrounded()
        {
            _wasGrounded = _isGrounded;

            // Check if grounded using a sphere at the bottom of the controller
            Vector3 checkPosition = transform.position;
            checkPosition.y -= _controller.height * 0.5f - _controller.radius;

            _isGrounded = Physics.CheckSphere(checkPosition, _controller.radius + _groundCheckDistance, _groundMask);

            // Handle landing
            if (_isGrounded && !_wasGrounded)
            {
                OnLanded?.Invoke();
                EventBus.Instance.Publish(new PlayerLandedEvent(transform.position, _velocity.y));
            }
        }

        private void UpdateCrouchHeight()
        {
            float targetHeight = _isCrouching ? _crouchHeight : _standingHeight;

            if (!Mathf.Approximately(_currentCrouchHeight, targetHeight))
            {
                _currentCrouchHeight = Mathf.Lerp(_currentCrouchHeight, targetHeight, _crouchTransitionSpeed * Time.deltaTime);
                _controller.height = _currentCrouchHeight;

                // Adjust controller center
                _controller.center = new Vector3(0, _currentCrouchHeight * 0.5f, 0);
            }
        }

        private void HandleMovement()
        {
            Vector3 moveInput = _inputHandler.MoveInput;

            // Calculate movement direction relative to camera
            Vector3 forward = _cameraTransform.forward;
            Vector3 right = _cameraTransform.right;

            // Remove vertical component
            forward.y = 0f;
            right.y = 0f;

            forward.Normalize();
            right.Normalize();

            // Calculate desired movement
            Vector3 desiredMove = (forward * moveInput.y + right * moveInput.x);

            // Apply appropriate speed
            float currentSpeed = _walkSpeed;
            if (_isRunning && !_isCrouching)
                currentSpeed = _runSpeed;
            else if (_isCrouching)
                currentSpeed = _crouchSpeed;

            // Apply air control if not grounded
            if (!_isGrounded)
            {
                desiredMove *= _airControl;
            }

            // Move the controller
            Vector3 movement = desiredMove * currentSpeed * Time.deltaTime;
            movement.y = _velocity.y * Time.deltaTime;

            _controller.Move(movement);

            // Notify about movement
            if (movement.sqrMagnitude > 0.01f)
            {
                OnMoved?.Invoke(movement);
            }

            // Notify about speed changes
            float currentMagnitude = new Vector3(movement.x, 0, movement.z).magnitude / Time.deltaTime;
            OnSpeedChanged?.Invoke(currentMagnitude);
        }

        private void HandleJumping()
        {
            // Coyote time - allow jumping shortly after leaving ground
            if (_isGrounded)
            {
                _coyoteTimeCounter = _coyoteTime;
            }
            else
            {
                _coyoteTimeCounter -= Time.deltaTime;
            }

            // Jump buffer - remember jump input for a short time
            if (_wantsToJump)
            {
                _jumpBufferCounter = _jumpBufferTime;
            }
            else
            {
                _jumpBufferCounter -= Time.deltaTime;
            }

            // Perform jump if conditions are met
            if (_jumpBufferCounter > 0f && _coyoteTimeCounter > 0f && !_isCrouching)
            {
                Jump();
                _jumpBufferCounter = 0f;
                _coyoteTimeCounter = 0f;
            }

            // Reset jump input
            _wantsToJump = false;
        }

        private void Jump()
        {
            _velocity.y = _jumpForce;
            OnJumped?.Invoke();
            EventBus.Instance.Publish(new PlayerJumpedEvent(transform.position));
        }

        private void ApplyGravity()
        {
            if (_isGrounded && _velocity.y < 0)
            {
                _velocity.y = -2f; // Small negative value to keep grounded
            }
            else
            {
                _velocity.y -= _gravity * Time.deltaTime;
            }
        }

        private void UpdateTimers()
        {
            _coyoteTimeCounter -= Time.deltaTime;
            _jumpBufferCounter -= Time.deltaTime;
        }

        // Input handlers
        private void HandleMoveInput(Vector2 input)
        {
            // Movement is handled in Update
        }

        private void HandleJumpInput(bool pressed)
        {
            if (pressed)
            {
                _wantsToJump = true;
            }
        }

        private void HandleRunInput(bool pressed)
        {
            _isRunning = pressed;
        }

        private void HandleCrouchInput(bool pressed)
        {
            if (pressed && !_isCrouching)
            {
                StartCrouch();
            }
            else if (!pressed && _isCrouching)
            {
                StopCrouch();
            }
        }

        private void StartCrouch()
        {
            // Check if there's room to stand up later
            _isCrouching = true;
            OnStartedCrouching?.Invoke();
            EventBus.Instance.Publish(new PlayerCrouchStateChangedEvent(true));
        }

        private void StopCrouch()
        {
            // Check if there's room above
            Vector3 checkPos = transform.position + Vector3.up * (_standingHeight - _controller.height);
            float checkRadius = _controller.radius * 0.9f;

            if (!Physics.CheckSphere(checkPos, checkRadius, _groundMask))
            {
                _isCrouching = false;
                OnStoppedCrouching?.Invoke();
                EventBus.Instance.Publish(new PlayerCrouchStateChangedEvent(false));
            }
        }

        private void OnGameStateChanged(GameStateChangedEvent eventData)
        {
            // Freeze movement when not in playing state
            enabled = eventData.NewState == GameState.Playing;
        }

        // Public getters
        public bool IsGrounded => _isGrounded;
        public bool IsRunning => _isRunning;
        public bool IsCrouching => _isCrouching;
        public float CurrentSpeed => _controller.velocity.magnitude;
        public Vector3 Velocity => _controller.velocity;

        private void OnDestroy()
        {
            // Unsubscribe from events
            if (_inputHandler != null)
            {
                _inputHandler.OnMoveInput -= HandleMoveInput;
                _inputHandler.OnJumpInput -= HandleJumpInput;
                _inputHandler.OnRunInput -= HandleRunInput;
                _inputHandler.OnCrouchInput -= HandleCrouchInput;
            }

            EventBus.Instance.Unsubscribe<GameStateChangedEvent>(OnGameStateChanged);
        }

        // Debug helpers
        private void OnDrawGizmos()
        {
            if (_controller == null) return;

            // Draw ground check
            Gizmos.color = _isGrounded ? Color.green : Color.red;
            Vector3 checkPos = transform.position;
            checkPos.y -= _controller.height * 0.5f - _controller.radius;
            Gizmos.DrawWireSphere(checkPos, _controller.radius + _groundCheckDistance);
        }
    }
}