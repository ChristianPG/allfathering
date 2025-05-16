#+build linux
package yggdrasil

import "core:fmt"
import "core:os/os2"

_install_apps :: proc() {
	r, w, e := os2.pipe()

	p: os2.Process
	{
		defer os2.close(w)

		// Random CLI tools
		p, _ = os2.process_start({command = {"sudo", "apt", "update"}, stdout = w})
		p, _ = os2.process_start(
			{
				command = {"sudo", "apt", "install", "ripgrep", "fzf", "jq", "tmux", "stow", "-y"},
				stdout = w,
			},
		)
	}

	output, _ := os2.read_entire_file(r, context.temp_allocator)
	_, _ = os2.process_wait(p)
	fmt.print(string(output))
}
