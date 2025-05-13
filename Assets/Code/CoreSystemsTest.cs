using UnityEngine;
using CienPodroznika.Core;
using CienPodroznika.Core.Events;

public class CoreSystemsTest : MonoBehaviour
{
    private void Start()
    {
        // Test EventBus
        EventBus.Instance.Subscribe<GameStateChangedEvent>(OnGameStateChanged);
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            GameManager.Instance.ChangeState(GameState.Playing);
        }

        if (Input.GetKeyDown(KeyCode.P))
        {
            GameManager.Instance.PauseGame();
        }

        if (Input.GetKeyDown(KeyCode.R))
        {
            GameManager.Instance.ResumeGame();
        }
    }

    private void OnGameStateChanged(GameStateChangedEvent eventData)
    {
        Debug.Log($"Game state changed from {eventData.PreviousState} to {eventData.NewState}");
    }

    private void OnDestroy()
    {
        EventBus.Instance.Unsubscribe<GameStateChangedEvent>(OnGameStateChanged);
    }
}