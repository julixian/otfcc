require('vstudio')

premake.override(premake.vstudio.vc2010, "platformToolset", function(base, cfg)
    if _ACTION == "vs2022" then
        premake.vstudio.vc2010.element("PlatformToolset", nil, "ClangCL")
    else
        base(cfg)
    end
end)

require "dep/premake-modules/xcode-alt"
require "dep/premake-modules/ninja"

MAIN_VER = '0'
SECONDARY_VER = '10'
PATCH_VER = '4'

function cbuildoptions()
	-- Windows
	filter "action:vs2022"
        buildoptions { '-Wall', '-Wno-unused-parameter', '-Qunused-arguments' }
    filter { "action:vs2022", "platforms:x64" }
        buildoptions { '-Wshorten-64-to-32' }
	filter {"system:windows", "action:ninja"}
		buildoptions { '-Wall', '-Wextra', '-Wno-unused-parameter', '-Qunused-arguments' }
	-- Linux / OSX
	filter "action:gmake or action:xcode4"
		buildoptions { '-std=gnu11', '-Wall', '-Wno-multichar', '-fPIC' }
		linkoptions  { '-fPIC' }
		links "m"
	filter {"system:not windows", "action:ninja"}
		buildoptions { '-std=gnu11', '-Wall', '-Wno-multichar', '-fPIC' }
		linkoptions  { '-fPIC' }
		links "m"
	filter {}
end

function externcbuildoptions()
	filter "action:vs2022"
        buildoptions { '-Qunused-arguments', '-Wno-unused-const-variable' }
	filter {"system:windows", "action:ninja"}
		buildoptions { '-Wno-unused-parameter', '-Qunused-arguments' }
	filter "action:gmake or action:xcode4"
		buildoptions { '-std=gnu11', '-Wno-unused-const-variable', '-Wno-shorten-64-to-32', '-fPIC' }
		linkoptions  { '-fPIC' }
	filter {"system:not windows", "action:ninja"}
		buildoptions { '-std=gnu11', '-Wno-unused-const-variable', '-Wno-shorten-64-to-32', '-fPIC' }
		linkoptions  { '-fPIC' }
	filter {}
end

-- Premake 5 configurations
workspace "otfcc"
	configurations { "release", "debug" }
	
	platforms { "x64", "x86" }
	filter "action:xcode4"
		platforms { "x64" }
	filter {}
	
	location "build"
	includedirs { "include" }
	
	defines {
		'_CARYLL_USE_PRE_SERIALIZED',
		('MAIN_VER=' .. MAIN_VER),
		("SECONDARY_VER=" .. SECONDARY_VER),
		("PATCH_VER=" .. PATCH_VER)
	}
	filter "platforms:x86"
		architecture "x86"
	filter "platforms:x64"
		architecture "x64"
	filter {}
	
	filter "action:vs2022"
		location "build/vs"
		defines { '_CRT_SECURE_NO_WARNINGS', '_CRT_NONSTDC_NO_DEPRECATE' }
		staticruntime "On"
		includedirs { "dep/polyfill-msvc" }
	filter "action:ninja"
		location "build/ninja"
	filter {"system:windows", "action:ninja"}
		defines { '_CRT_SECURE_NO_WARNINGS', '_CRT_NONSTDC_NO_DEPRECATE' }
		staticruntime "On"
		includedirs { "dep/polyfill-msvc" }
	filter {}
	
	filter "configurations:Debug"
		defines { "DEBUG", "_DEBUG" }
		symbols "on"
	filter "configurations:Release"
		defines { "NDEBUG" }
		optimize "Full"

project "deps"
	kind "StaticLib"
	language "C"
	externcbuildoptions()
	includedirs { "include/dep" }
	files {
		"dep/extern/**.h",
		"dep/extern/**.c"
	}
	filter "action:vs*"
	files {
		"dep/polyfill-msvc/**.h",
		"dep/polyfill-msvc/**.c"
	}
	filter {"system:windows", "action:ninja"}
	files {
		"dep/polyfill-msvc/**.h",
		"dep/polyfill-msvc/**.c"
	}
	filter {}

project "libotfcc"
	kind "StaticLib"
	language "C"
	cbuildoptions()

	links { "deps" }
	includedirs{ "lib" }

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
