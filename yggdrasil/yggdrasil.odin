package yggdrasil

import "core:fmt"
import "core:os/os2"

main :: proc() {
	r, w, e := os2.pipe()

	p: os2.Process
	{
		defer os2.close(w)

		// Rust-related apps
		fmt.println("Installing Rust apps...")
		p, _ = os2.process_start({command = {"cargo", "install", "bob-nvim"}, stdout = w})
		p, _ = os2.process_start({command = {"bob", "install", "stable"}, stdout = w})
		p, _ = os2.process_start({command = {"bob", "use", "stable"}, stdout = w})

		// Install other apps based on the OS used
		fmt.println("Installing", ODIN_OS, "apps...")
		_install_apps()
	}

	output, _ := os2.read_entire_file(r, context.temp_allocator)
	_, _ = os2.process_wait(p)
	fmt.print(string(output))

}
