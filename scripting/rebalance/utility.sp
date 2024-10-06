#if defined _bwa_utility__
  #endinput
#endif
#define _bwa_utility__

#include <sourcemod>

stock float GetMax(float a, float b)
{
	return a > b ? a : b;
}

stock float GetMin(float a, float b)
{
	return a < b ? a : b;
}

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/public/mathlib/mathlib.h#L98
stock float clamp(float val, float minVal, float maxVal)
{
	if (maxVal < minVal)
		return maxVal;
	else if (val < minVal)
		return minVal;
	else if (val > maxVal)
		return maxVal;
	else
		return val;
}

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/public/mathlib/mathlib.h#L648
stock float ValveRemapVal(float val, float A, float B, float C, float D)
{
	if (A == B)
		return ((val >= B) ? D : C);

	float cVal = (val - A) / (B - A);
	cVal = clamp(cVal, 0.00, 1.00);
	return C + (D - C) * cVal;
}

stock float CalcViewsOffset(float angle1[3], float angle2[3])
{
	float v1 = FloatAbs(angle1[0] - angle2[0]);
	float v2 = FloatAbs(angle1[1] - angle2[1]);
	v2 = ((v2 > 180.0) ? (v2 - 360.0) : v2);
	return SquareRoot(v1 * v1 + v2 * v2);
}

stock float getPlayerDistance(int clientA, int clientB)
{
	float clientAPos[3], clientBPos[3];
	GetEntPropVector(clientA, Prop_Send, "m_vecOrigin", clientAPos);
	GetEntPropVector(clientB, Prop_Send, "m_vecOrigin", clientBPos);
	return GetVectorDistance(clientAPos, clientBPos);
}