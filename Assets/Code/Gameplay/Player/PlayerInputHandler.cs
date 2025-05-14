using UnityEngine;
using UnityEngine.InputSystem;

namespace CienPodroznika.Gameplay.Player
{
    public class PlayerInputHandler : MonoBehaviour
    {
        private PlayerInputActions _inputActions;

        // Input values
        private Vector2 _moveInput;
        private Vector2 _lookInput;

        // Events
        public event System.Action<Vector2> OnMoveInput;
        public event System.Action<Vector2> OnLookInput;
        public event System.Action<bool> OnJumpInput;
        public event System.Action<bool> OnRunInput;
        public event System.Action<bool> OnCrouchInput;
        public event System.Action<bool> OnInteractInput;

        // Properties
        public Vector2 MoveInput => _moveInput;
        public Vector2 LookInput => _lookInput;

        private void Awake()
        {
            _inputActions = new PlayerInputActions();
        }

        private void OnEnable()
        {
            _inputActions.Enable();

            // Bind movement actions
            _inputActions.Player.Move.performed += OnMove;
            _inputActions.Player.Move.canceled += OnMove;

            _inputActions.Player.Look.performed += OnLook;

            // Bind button actions
            _inputActions.Player.Jump.started += OnJump;
            _inputActions.Player.Jump.canceled += OnJump;

            _inputActions.Player.Run.started += OnRun;
            _inputActions.Player.Run.canceled += OnRun;

            _inputActions.Player.Crouch.started += OnCrouch;
            _inputActions.Player.Crouch.canceled += OnCrouch;

            _inputActions.Player.Interact.started += OnInteract;
            _inputActions.Player.Interact.canceled += OnInteract;
        }

        private void OnDisable()
        {
            _inputActions.Disable();
        }

        private void OnMove(InputAction.CallbackContext context)
        {
            Debug.Log($"Move input received: {context.ReadValue<Vector2>()}"); // Dodaj tê liniê
            _moveInput = context.ReadValue<Vector2>();
            OnMoveInput?.Invoke(_moveInput);
        }

        private void OnLook(InputAction.CallbackContext context)
        {
            Debug.Log($"Look input received: {context.ReadValue<Vector2>()}"); // Dodaj tê liniê
            _lookInput = context.ReadValue<Vector2>();
            OnLookInput?.Invoke(_lookInput);
        }

        private void OnJump(InputAction.CallbackContext context)
        {
            Debug.Log($"Jump input received: {context.performed}"); // Dodaj tê liniê
            OnJumpInput?.Invoke(context.performed);
        }

        private void OnRun(InputAction.CallbackContext context)
        {
            OnRunInput?.Invoke(context.performed);
        }

        private void OnCrouch(InputAction.CallbackContext context)
        {
            OnCrouchInput?.Invoke(context.performed);
        }

        private void OnInteract(InputAction.CallbackContext context)
        {
            OnInteractInput?.Invoke(context.performed);
        }

        // Input enable/disable methods
        public void EnableInput()
        {
            _inputActions.Enable();
        }

        public void DisableInput()
        {
            _inputActions.Disable();
        }

        public void SetMoveInputEnabled(bool enabled)
        {
            if (enabled)
                _inputActions.Player.Move.Enable();
            else
                _inputActions.Player.Move.Disable();
        }

        public void SetLookInputEnabled(bool enabled)
        {
            if (enabled)
                _inputActions.Player.Look.Enable();
            else
                _inputActions.Player.Look.Disable();
        }
    }
}