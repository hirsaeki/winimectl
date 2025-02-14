import { Denops } from "https://deno.land/x/denops_std@v6.5.1/mod.ts";
import { FFI } from "https://deno.land/x/ffi@0.4.0/mod.ts";

const lib = new FFI({
  ImmGetContext: { parameters: ["pointer"], result: "pointer" },
  ImmGetOpenStatus: { parameters: ["pointer"], result: "bool" },
  ImmSetOpenStatus: { parameters: ["pointer", "bool"], result: "bool" },
  ImmReleaseContext: { parameters: ["pointer", "pointer"], result: "bool" },
});

export async function main(denops: Denops): Promise<void> {
  // Plugin initialization
  await denops.cmd(`let g:winimectl_loaded = 1`);

  denops.dispatcher = {
    async getImeStatus(): Promise<boolean> {
      const hwnd = await denops.call("winid") as number;
      const hIMC = lib.ImmGetContext(hwnd);
      const status = lib.ImmGetOpenStatus(hIMC);
      lib.ImmReleaseContext(hwnd, hIMC);
      return status;
    },

    async setImeStatus(status: boolean): Promise<void> {
      const hwnd = await denops.call("winid") as number;
      const hIMC = lib.ImmGetContext(hwnd);
      lib.ImmSetOpenStatus(hIMC, status);
      lib.ImmReleaseContext(hwnd, hIMC);
    },
  };
}