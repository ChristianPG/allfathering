package yggdrasil

import "core:fmt"
import "core:os/os2"

main :: proc() {
   r, w, e := os2.pipe()

   p:os2.Process
   {
       defer os2.close(w)

       p, _ = os2.process_start({command = { "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh" }, stdout =w})
       // p, _ = os2.process_start({command = { "curl", "--proto", "'=https'", "--tlsv1.2", "-sSf", "https://sh.rustup.rs", "|", "sh" }, stdout =w})
   } 

   output, _ := os2.read_entire_file(r, context.temp_allocator)
   _, _ = os2.process_wait(p)
   fmt.print(string(output))
}
