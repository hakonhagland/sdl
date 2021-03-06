package SDL2::SDL;

use strict;
use warnings;

use SDL2::Main;
use SDL2::Stdinc;
use SDL2::Assert;
use SDL2::Atomic;
use SDL2::Audio;
use SDL2::Clipboard;
use SDL2::Cpuinfo;
use SDL2::Endian;
use SDL2::Error;
use SDL2::Events;
use SDL2::Filesystem;
use SDL2::Gamecontroller;
use SDL2::Haptic;
use SDL2::Hints;
use SDL2::Joystick;
use SDL2::Loadso;
use SDL2::Log;
use SDL2::Messagebox;
use SDL2::Mutex;
use SDL2::Power;
use SDL2::Render;
use SDL2::Rwops;
use SDL2::Sensor;
use SDL2::Shape;
use SDL2::System;
use SDL2::Thread;
use SDL2::Timer;
use SDL2::Version;
use SDL2::Video;

# sub SDL_INIT_VIDEO {

# 	return 0x00000020;
# }

sub attach {
	my( $ffi ) =  @_;



	use constant SDL_INIT_TIMER            => 0x00000001;
	use constant SDL_INIT_AUDIO            => 0x00000010;
	#define SDL_INIT_VIDEO          0x00000020u
	use constant SDL_INIT_VIDEO            => 0x00000020;
	use constant SDL_INIT_JOYSTICK         => 0x00000200;
	use constant SDL_INIT_HAPTIC           => 0x00001000;
	use constant SDL_INIT_GAMECONTROLLER   => 0x00002000;
	use constant SDL_INIT_EVENTS           => 0x00004000;
	use constant SDL_INIT_SENSOR           => 0x00008000;
	use constant SDL_INIT_NOPARACHUTE      => 0x00100000;
	use constant SDL_INIT_EVERYTHING       => (
		SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS |
		SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER | SDL_INIT_SENSOR
	);

	SDL2::Main::attach( $ffi );
	SDL2::Stdinc::attach( $ffi );
	SDL2::Assert::attach( $ffi );
	SDL2::Atomic::attach( $ffi );
	SDL2::Audio::attach( $ffi );
	SDL2::Clipboard::attach( $ffi );
	SDL2::Cpuinfo::attach( $ffi );
	SDL2::Endian::attach( $ffi );
	SDL2::Error::attach( $ffi );
	SDL2::Events::attach( $ffi );
	SDL2::Filesystem::attach( $ffi );
	SDL2::Gamecontroller::attach( $ffi );
	SDL2::Haptic::attach( $ffi );
	SDL2::Hints::attach( $ffi );
	SDL2::Joystick::attach( $ffi );
	SDL2::Loadso::attach( $ffi );
	SDL2::Log::attach( $ffi );
	SDL2::Messagebox::attach( $ffi );
	SDL2::Mutex::attach( $ffi );
	SDL2::Power::attach( $ffi );
	SDL2::Render::attach( $ffi );
	SDL2::Rwops::attach( $ffi );
	SDL2::Sensor::attach( $ffi );
	SDL2::Shape::attach( $ffi );
	SDL2::System::attach( $ffi );
	SDL2::Thread::attach( $ffi );
	SDL2::Timer::attach( $ffi );
	SDL2::Version::attach( $ffi );
	SDL2::Video::attach( $ffi );

	# extern DECLSPEC int SDLCALL SDL_Init(Uint32 flags);
	# extern DECLSPEC int SDLCALL SDL_InitSubSystem(Uint32 flags);
	# extern DECLSPEC void SDLCALL SDL_QuitSubSystem(Uint32 flags);
	# extern DECLSPEC Uint32 SDLCALL SDL_WasInit(Uint32 flags);
	# extern DECLSPEC void SDLCALL SDL_Quit(void);
	$ffi->attach( SDL_Init          => [ 'uint32' ] => 'int'    );
	$ffi->attach( SDL_InitSubSystem => [ 'uint32' ] => 'int'    );
	$ffi->attach( SDL_QuitSubSystem => [ 'uint32' ] => 'void'   );
	$ffi->attach( SDL_WasInit       => [ 'uint32' ] => 'uint32' );
	$ffi->attach( SDL_Quit          => [ 'void'   ] => 'void'   );
}

1;
