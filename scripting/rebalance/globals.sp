#if defined _bwa_globals__
	#endinput
#endif
#define _bwa_globals__

#include "rebalance/utility.sp"

#define MAXENTITIES		2048

#define IRON_DETECT		80.0
#define PARACHUTE_TIME	6.0
#define FIRE_TIME		3.0
#define HAND_MAX		10.0
#define PRESSURE_TIME	6.0
#define PRESSURE_FORCE	2.8
#define HYPE_COST		19.2

#define IS_MVM			GameRules_GetProp("m_bPlayingMannVsMachine")
#define IS_MEDIEVAL		GameRules_GetProp("m_bPlayingMedieval")

// int CART = -1;
// float CARTSPEED = 200.0;

// entity effects
enum
{
	EF_BONEMERGE			= 0x001,	// Performs bone merge on client side
	EF_BRIGHTLIGHT 			= 0x002,	// DLIGHT centered at entity origin
	EF_DIMLIGHT 			= 0x004,	// player flashlight
	EF_NOINTERP				= 0x008,	// don't interpolate the next frame
	EF_NOSHADOW				= 0x010,	// Don't cast no shadow
	EF_NODRAW				= 0x020,	// don't draw entity
	EF_NORECEIVESHADOW		= 0x040,	// Don't receive no shadow
	EF_BONEMERGE_FASTCULL	= 0x080,	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
										// parent and uses the parent's bbox + the max extents of the aiment.
										// Otherwise, it sets up the parent's bones every frame to figure out where to place
										// the aiment, which is inefficient because it'll setup the parent's bones even if
										// the parent is not in the PVS.
	EF_ITEM_BLINK			= 0x100,	// blink an item so that the user notices it.
	EF_PARENT_ANIMATES		= 0x200,	// always assume that the parent entity is animating
	EF_MAX_BITS = 10
};

enum PlayerUpgrades_t
{
	UPGRADE_START = 0,

	UPGRADE_HEALTHREGEN	= 0,
	UPGRADE_SPEEDBONUS,
	UPGRADE_JUMPHEIGHT,
	UPGRADE_BULLETRESISTANCE,
	UPGRADE_BLASTRESISTANCE,
	UPGRADE_FIRERESISTANCE,
	UPGRADE_CRITRESISTANCE,
	UPGRADE_METALREGEN,

	MAX_UPGRADES
};

enum CondFlags_t
{
	CONDITION_START = 0,

	CONDITION_VACCMIN = 0,
	CONDITION_VACCMED,
	CONDITION_VACCMAX,
	CONDITION_VOLCANO,
	CONDITION_HEAT,
	CONDITION_HEATSPAWN,
	CONDITION_EATING,
	CONDITION_HEALSTEAL,
	CONDITION_HOVER,
	CONDITION_FAKE,
	CONDITION_INFIRE,
	CONDITION_INMELEE,
	CONDITION_QUICK,
	CONDITION_HEATER,
	CONDITION_FANHIT,
	CONDITION_FANFLY,
	CONDITION_BLJUMP,
	CONDITION_CAPPING,
	CONDITION_SPYTAUNT,
	CONDITION_UBERBOOST,
	CONDITION_INSPAWN,
	CONDITION_ALWAYS,
	CONDITION_BASED,
	CONDITION_CLEAVER,
	CONDITION_UPGRADE,
	CONDITION_NOGRADE,
	CONDITION_DIVE,

	CONDITION_MAX
}
#define CONDITION_ARRAY_SIZE ((view_as<int>(CONDITION_MAX) / 32) + 1)

/**
 * Calculate the offset of this flag in the player's flags array.
 */
static int cond_flag_index(CondFlags_t flag)
{
	return view_as<int>(flag) / 32;
}

/**
 * Calculate the value of this flag in respect to its offset.
 */
static int cond_flag_value(CondFlags_t flag)
{
    return (1 << (view_as<int>(flag) - (32 * cond_flag_index(flag))))
}

enum struct Upgrade
{
	char m_szName[64];
	float m_flMin;
	float m_flMax;
	float m_flDefault;
}
Upgrade g_PlayerUpgradeData[view_as<int>(MAX_UPGRADES)] = {
	{ "health regen", 0.00, -1.00, 0.00 },
	{ "major move speed bonus", 1.00, -1.00, 1.00 },
	{ "major increased jump height", 1.00, -1.00, 1.00 },
	{ "dmg taken from bullets reduced", -1.00, 1.00, 1.00 },
	{ "dmg taken from blast reduced", -1.00, 1.00, 1.00 },
	{ "dmg taken from fire reduced", -1.00, 1.00, 1.00 },
	{ "dmg taken from crit reduced", -1.00, 1.00, 1.00 },
	{ "metal regen", 0.00, -1.00, 0.00 },
};

enum struct Player
{
	float m_flLastHit;
	float m_flNextHit;
	float m_flLastFire;
	float m_flLastFlamed;
	float m_flTemperature;
	float m_flPlayerUpgrades[view_as<int>(MAX_UPGRADES)];
	float m_flSpyTauntTime;
	float m_flHolstering;
	float m_flHolsteringPrimary;
	float m_flHolsteringSecondary;
	float m_flHolsteringMelee;
	float m_flMeterPrimary;
	float m_flMeterSecondary;
	float m_flMeterMelee;
	float m_flLastVoice;
	float m_flLastVaccHeal;
	float m_flFlameDamage;
	float m_flSyringeHit;

	int m_fTrueLastButtons;
	int m_fLastButtons;
	int m_iConsecHits;
	int m_iFlameAttacker;
	int m_iFOV;
	int m_iSpawnPumpkin;
	int m_iSpyTauntSequence;
	int m_iEngyDispenser;

	int m_fCondFlags[CONDITION_ARRAY_SIZE];

	/**
	 * Return a player upgrade.
	 */
	float GetUpgrade(PlayerUpgrades_t flag)
	{
		return this.m_flPlayerUpgrades[flag];
	}

	/**
	 * Set a player upgrade.
	 */
	void SetUpgrade(PlayerUpgrades_t flag, float value)
	{
		if (g_PlayerUpgradeData[flag].m_flMin != -1.00)
			value = GetMax(g_PlayerUpgradeData[flag].m_flMin, value);
		if (g_PlayerUpgradeData[flag].m_flMax != -1.00)
			value = GetMin(g_PlayerUpgradeData[flag].m_flMax, value);
		this.m_flPlayerUpgrades[flag] = value;
	}

	/**
	 * Add a new condition to the player.
	 */
	void AddCond(CondFlags_t flag)
	{
		this.m_fCondFlags[cond_flag_index(flag)] |= cond_flag_value(flag);
	}

	/**
	 * Remove a new condition from the player.
	 */
	void RemoveCond(CondFlags_t flag)
	{
		this.m_fCondFlags[cond_flag_index(flag)] &= ~cond_flag_value(flag);
	}

	/**
	 * Does this player have a specified condition?
	 */
	bool HasCond(CondFlags_t flag)
	{
		return !!(this.m_fCondFlags[cond_flag_index(flag)] & cond_flag_value(flag));
	}

	/**
	 * Reset this player's conditions and directly set any new ones.
	 * Set use_internal = true to use AddCond()/RemoveCond() rather than directly
	 * manipulate this player's condition flags array. This will call any
	 * additional code present in those functions.
	 */
	void SetConditions(CondFlags_t[] flags, int maxlength, bool use_internal = false)
	{
		if (use_internal)
		{
			for (CondFlags_t flag = CONDITION_START; flag < CONDITION_MAX; ++flag)
			{
				if (this.HasCond(flag))
					this.RemoveCond(flag);
			}
			for (int i = 0; i < maxlength; ++i)
				this.AddCond(flags[i]);
		}
		else
		{
			for (int i = 0; i < CONDITION_ARRAY_SIZE; ++i)
				this.m_fCondFlags[i] = 0;
			for (int i = 0; i < maxlength; ++i)
				this.m_fCondFlags[cond_flag_index(flags[i])] |= cond_flag_value(flags[i]);
		}
    }
}

enum struct Entity
{
	float m_flMoneyFrames;
	float m_flFlameHit;
	float m_flFlagTime;
	float m_flGrenadeTime;
	float m_flBuildingHeal;

	int m_iBisonHit;
	int m_iGrenades;
	int m_iFlagHelpers;
	int m_iDispenserStatus;
	int m_iMoneyFrames;
}

Player g_PlayerData[MAXPLAYERS + 1];
Entity g_EntityData[MAXENTITIES];

ConVar g_bEnablePlugin; 				// Convar that enables plugin
ConVar g_bApplyClassChangesToBots;		// Convar that decides if attributes should apply to bots.
ConVar g_bApplyClassChangesToMvMBots;	// Convar that decides if attributes should apply to MvM bots.

Handle g_hSDKFinishBuilding;
Handle g_Maplist;

bool IS_HALLOWEEN = false;
bool IS_SAXTON = false;