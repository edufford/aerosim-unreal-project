// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class AerosimUE5Target : TargetRules
{
	public AerosimUE5Target(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.AddRange(new string[] { "AerosimUE5" });

		// The global definition below is required to support Runtime USD loading in
		// packaged binaries, but setting it requires a source build of the Unreal
		// Engine to be able to package the binaries. Since we are currently using
		// Unreal native assets instead of USD assets, we can leave this commented
		// out for now.
		// GlobalDefinitions.Add("FORCE_ANSI_ALLOCATOR=1");
	}
}
