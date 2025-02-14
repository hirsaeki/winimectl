import { Denops } from "https://deno.land/x/denops_std@v5.2.0/mod.ts";

const lib = Deno.dlopen("imm32.dll", {
  ImmGetContext: {
    parameters: ["pointer"],
    result: "pointer",
  },
  ImmGetOpenStatus: {
    parameters: ["pointer"],
    result: "bool",
  },
  ImmSetOpenStatus: {
    parameters: ["pointer", "bool"],
    result: "bool",
  },
  ImmReleaseContext: {
    parameters: ["pointer", "pointer"],
    result: "bool",
  },
} as const);

export async function main(denops: Denops): Promise<void> {
  // Plugin initialization
  await denops.cmd(`let g:winimectl_loaded = 1`);

  denops.dispatcher = {
    async getImeStatus(): Promise<boolean> {
      const hwnd = await denops.call("winid") as number;
      const hIMC = lib.symbols.ImmGetContext(hwnd);
      const status = lib.symbols.ImmGetOpenStatus(hIMC);
      lib.symbols.ImmReleaseContext(hwnd, hIMC);
      return status;
    },

    async setImeStatus(status: boolean): Promise<void> {
      const hwnd = await denops.call("winid") as number;
      const hIMC = lib.symbols.ImmGetContext(hwnd);
      lib.symbols.ImmSetOpenStatus(hIMC, status);
      lib.symbols.ImmReleaseContext(hwnd, hIMC);
    },
  };
}