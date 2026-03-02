// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class AerosimUE5Target : TargetRules
{
	public AerosimUE5Target(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
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
		ExtraModuleNames.AddRange(new string[] { "AerosimUE5" });

		// The global definition below is required to support Runtime USD loading in
		// packaged binaries, but setting it requires a source build of the Unreal
		// Engine to be able to package the binaries. Since we are currently using
		// Unreal native assets instead of USD assets, we can leave this commented
		// out for now.
		// GlobalDefinitions.Add("FORCE_ANSI_ALLOCATOR=1");
	}
}
