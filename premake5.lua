require('vstudio')

if _ACTION ~= nil and _ACTION ~= "vs2026" then
	error("This premake script only supports the vs2026 action on Windows.")
end

if os.host() ~= "windows" then
	error("This premake script only supports Windows.")
end

premake.override(premake.vstudio.vc2010, "platformToolset", function(base, cfg)
	if _ACTION == "vs2026" then
		premake.vstudio.vc2010.element("PlatformToolset", nil, "ClangCL")
	else
		base(cfg)
	end
end)

MAIN_VER = '0'
SECONDARY_VER = '10'
PATCH_VER = '4'

function cbuildoptions()
	buildoptions { '-Wall', '-Wno-unused-parameter', '-Qunused-arguments' }
	filter { "platforms:x64" }
		buildoptions { '-Wshorten-64-to-32' }
	filter {}
end

function externcbuildoptions()
	buildoptions { '-Qunused-arguments', '-Wno-unused-const-variable' }
	filter {}
end

-- Premake 5 configurations
workspace "otfcc"
	configurations { "release", "debug" }
	platforms { "x64", "x86" }
	location "build/vs"
	includedirs { "include", "dep/polyfill-msvc" }
	staticruntime "Off"

	defines {
		'_CARYLL_USE_PRE_SERIALIZED',
		'_CRT_SECURE_NO_WARNINGS',
		'_CRT_NONSTDC_NO_DEPRECATE',
		('MAIN_VER=' .. MAIN_VER),
		("SECONDARY_VER=" .. SECONDARY_VER),
		("PATCH_VER=" .. PATCH_VER)
	}

	filter "platforms:x86"
		architecture "x86"
	filter "platforms:x64"
		architecture "x64"
	filter "configurations:Debug"
		defines { "DEBUG", "_DEBUG" }
		symbols "on"
	filter "configurations:Release"
		defines { "NDEBUG" }
		optimize "Full"
	filter {}

project "deps"
	kind "StaticLib"
	language "C"
	externcbuildoptions()
	includedirs { "include/dep" }
	files {
		"dep/extern/**.h",
		"dep/extern/**.c",
		"dep/polyfill-msvc/**.h",
		"dep/polyfill-msvc/**.c"
	}

project "libotfcc"
	kind "StaticLib"
	language "C"
	cbuildoptions()

	links { "deps" }
	includedirs { "lib" }

	files {
		"lib/**.h",
		"lib/**.c"
	}

project "otfccdump"
	kind "ConsoleApp"
	language "C"
	cbuildoptions()
	targetdir "bin/%{cfg.buildcfg}-%{cfg.platform}"

	links { "libotfcc", "deps" }

	files {
		"src/**.c",
		"src/**.h"
	}
	removefiles {
		"src/otfccbuild.c",
		"src/otfccdll.c"
	}

project "otfccbuild"
	kind "ConsoleApp"
	language "C"
	cbuildoptions()
	targetdir "bin/%{cfg.buildcfg}-%{cfg.platform}"

	links { "libotfcc", "deps" }

	files {
		"src/**.c",
		"src/**.h"
	}
	removefiles {
		"src/otfccdump.c",
		"src/otfccdll.c"
	}

project "otfccdll"
	kind "SharedLib"
	language "C"
	cbuildoptions()
	targetdir "bin/%{cfg.buildcfg}-%{cfg.platform}"

	links { "libotfcc", "deps" }

	files {
		"src/**.c",
		"src/**.h"
	}
	removefiles {
		"src/otfccdump.c",
		"src/otfccbuild.c"
	}
