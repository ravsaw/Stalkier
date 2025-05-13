using UnityEngine;
using CienPodroznika.Core.AI;

namespace CienPodroznika.Core.Locations
{
    public class SafeZoneLocation : Location
    {
        [Header("Safe Zone Settings")]
        [SerializeField] private bool _enableTrading = true;
        [SerializeField] private bool _enableHealing = true;
        [SerializeField] private bool _enableRepairs = true;
        [SerializeField] private FactionType _controllingFaction = FactionType.Government;
        
        public bool EnableTrading => _enableTrading;
        public bool EnableHealing => _enableHealing;
        public bool EnableRepairs => _enableRepairs;
        public FactionType ControllingFaction => _controllingFaction;
        
        protected override void OnLocationLoadedInternal()
        {
            base.OnLocationLoadedInternal();
            
            // Activate safe zone features
            EnableSafeZoneFeatures();
        }
        
        protected override void OnLocationUnloadedInternal()
        {
            base.OnLocationUnloadedInternal();
            
            // Disable safe zone features
            DisableSafeZoneFeatures();
        }
        
        protected override void OnNPCAdded(GameObject npc)
        {
            base.OnNPCAdded(npc);
            
            // Set NPC behavior for safe zone
            var npcBehavior = npc.GetComponent<INPCBehavior>();
            if (npcBehavior != null)
            {
                npcBehavior.SetAggression(0f); // Non-aggressive in safe zone
            }
        }
        
        private void EnableSafeZoneFeatures()
        {
            // Implement safe zone logic
            Debug.Log($"Safe zone features enabled for {LocationName}");
        }
        
        private void DisableSafeZoneFeatures()
        {
            // Cleanup safe zone logic
            Debug.Log($"Safe zone features disabled for {LocationName}");
        }
    }
    
    public enum FactionType
    {
        Government,
        FreeStalkers,
        Cultists,
        Bandits,
        Scientists
    }
}