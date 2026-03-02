// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class AerosimUE5EditorTarget : TargetRules
{
	public AerosimUE5EditorTarget( TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		// Select build settings based on the engine version being compiled against.
		// Use Enum.TryParse for UE 5.7+ values to avoid compile errors on UE 5.3
		// where BuildSettingsVersion.V6 and EngineIncludeOrderVersion.Unreal5_7
		// are not defined in UnrealBuildTool.dll.
		if (Target.Version.MinorVersion == 3)
		{
			DefaultBuildSettings = BuildSettingsVersion.V4;
			IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_3;
		}
		else if (Target.Version.MinorVersion == 7)
		{
			if (Enum.TryParse("V6", out BuildSettingsVersion v6))
				DefaultBuildSettings = v6;
			if (Enum.TryParse("Unreal5_7", out EngineIncludeOrderVersion ue57))
				IncludeOrderVersion = ue57;
		}
		else
		{
			System.Console.Error.WriteLine("ERROR: Unsupported Unreal Engine minor version: " + Target.Version.MinorVersion + ". Supported versions: 5.3, 5.7.");
		}
		ExtraModuleNames.AddRange( new string[] { "AerosimUE5" } );
	}
}
