
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/SpatialMath }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
npc_attack_device := class(creative_device):

    @editable TeleportProp : creative_prop = creative_prop{}
    @editable AttackAnim : cinematic_sequence_device = cinematic_sequence_device{}
    @editable Roster : Enemy_Roster = Enemy_Roster{}
    @editable Projectile : creative_prop = creative_prop{}
    @editable VFX : vfx_creator_device = vfx_creator_device{}
    @editable Speed : float = 3.0
    @editable AttackDMG : float = 10.0
    @editable AttackInterval : float = 1.0
    @editable AttackLocOffset : vector3 = vector3{ X := 0.0, Y := -75.0, Z := 75.0 }

    var IsAttacking : logic = false
    var IsEquipped : logic = false #if NPC IsEquipped as a Follower
    var NPC : Follower = Follower{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        VFX.Disable()
        spawn{StayAtNPC()}
        for (Player : GetPlayspace().GetPlayers(), FortChar := Player.GetFortCharacter[]):
            FortChar.DamagedEvent().Subscribe(OnPlayerDamaged)

    StayAtNPC()<suspends> : void =
        if (not IsAttacking?):
            if:
                Projectile.TeleportTo[TeleportProp.GetTransform()]

    Activate(Pet : Follower) : void =
        set IsEquipped = true
        set NPC = Pet        

    Deactivate() : void =
        set IsEquipped = false
    
    OnPlayerDamaged(Result : damage_result) : void =
        if (IsEquipped?):
            if (not IsAttacking?):
                for (Enemy : Roster.Enemies):
                    if (Enemy.IsAttacking?):
                        if:
                            Projectile.TeleportTo[TeleportProp.GetTransform()]
                        set IsAttacking = true
                        AttackAnim.Play()
                        NPC.SetRotateTarget(Enemy.Model.GetTransform())
                        spawn{Attacking(Enemy)}
                        return
                    else:
                        Print("no enemy attacking")

    Attacking(Enemy : custom_enemy_device)<suspends> : void =
        loop:
            result := race:
                block:
                    VFX.Enable()
                    Projectile.MoveTo(Enemy.Model.GetTransform().Translation, Enemy.Model.GetTransform().Rotation, Speed)
                    VFX.Disable()
                    Print("HIT")
                    Enemy.TakeDamage(20.0)
                    if:
                        Projectile.TeleportTo[TeleportProp.GetTransform()]
                    Sleep(AttackInterval)
                    true
                block:
                    Enemy.DespawnEvent.Await()
                    false
            if(not result?):
                set IsAttacking = false
                AttackAnim.Stop()
                NPC.UsePlayerRotation()
                break       