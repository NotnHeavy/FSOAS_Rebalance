#if defined _bwa_filters__
  #endinput
#endif
#define _bwa_filters__

#include <sourcemod>

bool TraceFilter(int entity, int contentsmask, any data)
{
	if (entity == data)
		return false;
	if (entity <= MaxClients)
		return false;

	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	if (StrContains(class, "obj_") == 0 || StrContains(class, "tf_projectile_") == 0)
		return false;
	return true;
}

bool SimpleTraceFilter(int entity, int contentsMask, any data)
{
	if (entity != data)
		return false;
	return true;
}

bool PlayerTraceFilter(int entity, int contentsMask, any data)
{
	if (entity == data)
		return false;
	if (IsValidClient(entity))
		return false;
	return true;
}