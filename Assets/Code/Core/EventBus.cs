using System;
using System.Collections.Generic;
using UnityEngine;

namespace CienPodroznika.Core.Events
{
    public class EventBus : MonoBehaviour, IEventBus
    {
        private static EventBus _instance;
        public static EventBus Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = FindObjectOfType<EventBus>();
                    if (_instance == null)
                    {
                        GameObject eventBusObject = new GameObject("EventBus");
                        _instance = eventBusObject.AddComponent<EventBus>();
                        DontDestroyOnLoad(eventBusObject);
                    }
                }
                return _instance;
            }
        }

        private Dictionary<Type, List<Delegate>> _eventHandlers = new Dictionary<Type, List<Delegate>>();

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

        public void Subscribe<T>(Action<T> handler) where T : class
        {
            Type eventType = typeof(T);
            
            if (!_eventHandlers.ContainsKey(eventType))
            {
                _eventHandlers[eventType] = new List<Delegate>();
            }
            
            _eventHandlers[eventType].Add(handler);
        }

        public void Unsubscribe<T>(Action<T> handler) where T : class
        {
            Type eventType = typeof(T);
            
            if (_eventHandlers.ContainsKey(eventType))
            {
                _eventHandlers[eventType].Remove(handler);
                
                if (_eventHandlers[eventType].Count == 0)
                {
                    _eventHandlers.Remove(eventType);
                }
            }
        }

        public void Publish<T>(T eventData) where T : class
        {
            Type eventType = typeof(T);
            
            if (_eventHandlers.ContainsKey(eventType))
            {
                foreach (Delegate handler in _eventHandlers[eventType])
                {
                    try
                    {
                        ((Action<T>)handler).Invoke(eventData);
                    }
                    catch (Exception ex)
                    {
                        Debug.LogError($"Error executing event handler for {eventType.Name}: {ex.Message}");
                    }
                }
            }
        }

        public void Clear()
        {
            _eventHandlers.Clear();
        }

        private void OnDestroy()
        {
            Clear();
        }
    }
}