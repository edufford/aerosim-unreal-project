// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class AerosimUE5EditorTarget : TargetRules
{
	public AerosimUE5EditorTarget( TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		// Select build settings based on the engine version being compiled against
		if (Target.Version.MinorVersion == 3)
		{
			DefaultBuildSettings = BuildSettingsVersion.V4;
			IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_3;
		}
		else if (Target.Version.MinorVersion == 7)
		{
			DefaultBuildSettings = BuildSettingsVersion.V6;
			IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_7;
		}
		else
		{
			System.Console.Error.WriteLine("ERROR: Unsupported Unreal Engine minor version: " + Target.Version.MinorVersion + ". Supported versions: 5.3, 5.7.");
		}
		ExtraModuleNames.AddRange( new string[] { "AerosimUE5" } );
	}
}
