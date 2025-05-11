package yggdrasil

import "core:fmt"
import "core:os/os2"

main :: proc() {
	r, w, e := os2.pipe()

	p: os2.Process
	{
		defer os2.close(w)

		// Rust-related apps
		p, _ = os2.process_start({command = {"cargo", "install", "bob-nvim"}, stdout = w})
		p, _ = os2.process_start({command = {"bob", "install", "stable"}, stdout = w})
		p, _ = os2.process_start({command = {"bob", "use", "stable"}, stdout = w})

		// TODO: Conditionally execute the programs based on the OS
		// Random CLI tools
		// Linux
		p, _ = os2.process_start({command = {"sudo", "apt-get", "install", "ripgrep"}, stdout = w})
		// Mac
		p, _ = os2.process_start({command = {"brew", "install", "ripgrep"}, stdout = w})
	}

	output, _ := os2.read_entire_file(r, context.temp_allocator)
	_, _ = os2.process_wait(p)
	fmt.print(string(output))
}
