using UnityEngine;
using CienPodroznika.Gameplay.Player;
using CienPodroznika.Core.Events;
using CienPodroznika.Core;

public class PlayerTestManager : MonoBehaviour
{
    private void Start()
    {
        // Subscribe to player events
        EventBus.Instance.Subscribe<PlayerJumpedEvent>(OnPlayerJumped);
        EventBus.Instance.Subscribe<PlayerLandedEvent>(OnPlayerLanded);
        EventBus.Instance.Subscribe<PlayerCrouchStateChangedEvent>(OnCrouchStateChanged);
    }

    private void Update()
    {
        // Debug sprawdzaj¹cy stan gry
        if (Input.GetKeyDown(KeyCode.F1))
        {
            Debug.Log($"Game State: {GameManager.Instance.CurrentState}");
        }

        // Jeœli gra nie jest w stanie Playing, zmieñ stan
        if (Input.GetKeyDown(KeyCode.F2))
        {
            GameManager.Instance.ChangeState(GameState.Playing);
        }

        // Test teleport
        if (Input.GetKeyDown(KeyCode.T))
        {
            Vector3 randomPos = new Vector3(
                Random.Range(-10f, 10f),
                5f,
                Random.Range(-10f, 10f)
            );
            PlayerManager.Instance.TeleportPlayer(randomPos);
        }

        // Debug info
        if (Input.GetKeyDown(KeyCode.I))
        {
            var player = PlayerManager.Instance.CurrentPlayer;
            if (player != null)
            {
                Debug.Log($"Player Position: {player.transform.position}");
                Debug.Log($"Player Velocity: {PlayerManager.Instance.PlayerController.Velocity}");
                Debug.Log($"Is Grounded: {PlayerManager.Instance.PlayerController.IsGrounded}");
                Debug.Log($"Is Running: {PlayerManager.Instance.PlayerController.IsRunning}");
                Debug.Log($"Is Crouching: {PlayerManager.Instance.PlayerController.IsCrouching}");
            }
        }

        // Test starego Input System
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Debug.Log("Old Input System - Space pressed!");
        }

        // Test czy Player istnieje
        if (PlayerManager.Instance.CurrentPlayer == null)
        {
            Debug.LogError("Player is null!");
        }
    }

    private void OnPlayerJumped(PlayerJumpedEvent eventData)
    {
        Debug.Log($"Player jumped at {eventData.Position}");
    }

    private void OnPlayerLanded(PlayerLandedEvent eventData)
    {
        Debug.Log($"Player landed at {eventData.Position} with speed {eventData.FallSpeed}");
    }

    private void OnCrouchStateChanged(PlayerCrouchStateChangedEvent eventData)
    {
        Debug.Log($"Player crouch state: {eventData.IsCrouching}");
    }

    private void OnDestroy()
    {
        EventBus.Instance.Unsubscribe<PlayerJumpedEvent>(OnPlayerJumped);
        EventBus.Instance.Unsubscribe<PlayerLandedEvent>(OnPlayerLanded);
        EventBus.Instance.Unsubscribe<PlayerCrouchStateChangedEvent>(OnCrouchStateChanged);
    }
}