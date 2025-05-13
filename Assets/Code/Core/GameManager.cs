using System;
using UnityEngine;
using CienPodroznika.Core.Events;

namespace CienPodroznika.Core
{
    public class GameManager : MonoBehaviour
    {
        [SerializeField] private GameState _initialState = GameState.MainMenu;
        
        private static GameManager _instance;
        public static GameManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = FindObjectOfType<GameManager>();
                }
                return _instance;
            }
        }

        private GameState _currentState;
        public GameState CurrentState => _currentState;

        // Events
        public event Action<GameState> OnStateChanged;
        public event Action OnGameStarted;
        public event Action OnGamePaused;
        public event Action OnGameResumed;
        public event Action OnGameEnded;

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
            ChangeState(_initialState);
        }

        public void ChangeState(GameState newState)
        {
            if (_currentState == newState) return;

            GameState previousState = _currentState;
            _currentState = newState;

            // Publish event through EventBus
            EventBus.Instance.Publish(new GameStateChangedEvent(previousState, newState));
            
            // Invoke local event
            OnStateChanged?.Invoke(newState);

            // Handle specific state transitions
            HandleStateChange(previousState, newState);
        }

        private void HandleStateChange(GameState fromState, GameState toState)
        {
            switch (toState)
            {
                case GameState.Playing:
                    if (fromState == GameState.MainMenu || fromState == GameState.Loading)
                    {
                        OnGameStarted?.Invoke();
                    }
                    else if (fromState == GameState.Paused)
                    {
                        OnGameResumed?.Invoke();
                    }
                    Time.timeScale = 1f;
                    break;

                case GameState.Paused:
                    OnGamePaused?.Invoke();
                    Time.timeScale = 0f;
                    break;

                case GameState.GameOver:
                    OnGameEnded?.Invoke();
                    Time.timeScale = 0f;
                    break;

                default:
                    Time.timeScale = 1f;
                    break;
            }
        }

        public void StartGame()
        {
            ChangeState(GameState.Loading);
            // Tutaj później będzie ładowanie pierwszej sceny
        }

        public void PauseGame()
        {
            if (_currentState == GameState.Playing)
            {
                ChangeState(GameState.Paused);
            }
        }

        public void ResumeGame()
        {
            if (_currentState == GameState.Paused)
            {
                ChangeState(GameState.Playing);
            }
        }

        public void EndGame()
        {
            ChangeState(GameState.GameOver);
        }

        public void ReturnToMainMenu()
        {
            ChangeState(GameState.MainMenu);
        }

        private void OnDestroy()
        {
            if (_instance == this)
            {
                _instance = null;
            }
        }
    }
}