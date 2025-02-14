import { Denops } from "https://deno.land/x/denops_std@v6.5.1/mod.ts";

const dllPath = "C:\\Windows\\System32\\imm32.dll";
const user32Path = "C:\\Windows\\System32\\user32.dll";
const kernel32Path = "C:\\Windows\\System32\\kernel32.dll";

let immLib: Deno.DynamicLibrary<typeof immSymbols>;
let user32Lib: Deno.DynamicLibrary<typeof user32Symbols>;
let kernel32Lib: Deno.DynamicLibrary<typeof kernel32Symbols>;

// FFI function signatures
const immSymbols = {
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
} as const;

const user32Symbols = {
  GetForegroundWindow: {
    parameters: [],
    result: "pointer",
  },
} as const;

const kernel32Symbols = {
  GetLastError: {
    parameters: [],
    result: "u32",
  },
} as const;

// Helper function to report errors to Neovim
async function reportError(denops: Denops, error: unknown): Promise<void> {
  const errorMessage = error instanceof Error 
    ? `${error.name}: ${error.message}`
    : `Error: ${String(error)}`;
  await denops.cmd(`echomsg "[winimectl] ${errorMessage}"`);
}

// Initialize FFI libraries with error handling
async function initializeLibraries(denops: Denops): Promise<boolean> {
  try {
    immLib = Deno.dlopen(dllPath, immSymbols);
    user32Lib = Deno.dlopen(user32Path, user32Symbols);
    kernel32Lib = Deno.dlopen(kernel32Path, kernel32Symbols);
    return true;
  } catch (error) {
    await reportError(denops, `Failed to load required libraries: ${error}`);
    return false;
  }
}

export async function main(denops: Denops): Promise<void> {
  // Initialize plugin with error handling
  try {
    if (!await initializeLibraries(denops)) {
      return;
    }
    await denops.cmd(`let g:winimectl_loaded = 1`);
  } catch (error) {
    await reportError(denops, `Failed to initialize plugin: ${error}`);
    return;
  }

  denops.dispatcher = {
    async getImeStatus(..._args: unknown[]): Promise<boolean | null> {
      try {
        const hwnd = user32Lib.symbols.GetForegroundWindow();
        if (!hwnd) {
          throw new Error(`Failed to get foreground window handle (GetLastError: ${kernel32Lib.symbols.GetLastError()})`);
        }

        // デバッグ情報を出力
        await denops.cmd(`echomsg "[winimectl] Debug: Got window handle: 0x${Number(Deno.UnsafePointer.value(hwnd as Deno.PointerObject<unknown>)).toString(16)}"`);

        const hIMC = immLib.symbols.ImmGetContext(hwnd);
        if (!hIMC) {
          throw new Error(`Failed to get IME context (GetLastError: ${kernel32Lib.symbols.GetLastError()})`);
        }

        try {
          const status = immLib.symbols.ImmGetOpenStatus(hIMC);
          return status;
        } finally {
          immLib.symbols.ImmReleaseContext(hwnd, hIMC);
        }
      } catch (error) {
        await reportError(denops, `Failed to get IME status: ${error}`);
        return null;
      }
    },

    async setImeStatus(...args: unknown[]): Promise<void> {
      const status = args[0] as boolean;
      try {
        const hwnd = user32Lib.symbols.GetForegroundWindow();
        if (!hwnd) {
          throw new Error(`Failed to get foreground window handle (GetLastError: ${kernel32Lib.symbols.GetLastError()})`);
        }

        const hIMC = immLib.symbols.ImmGetContext(hwnd);
        if (!hIMC) {
          throw new Error(`Failed to get IME context (GetLastError: ${kernel32Lib.symbols.GetLastError()})`);
        }

        try {
          const result = immLib.symbols.ImmSetOpenStatus(hIMC, status);
          if (!result) {
            throw new Error(`Failed to set IME status (GetLastError: ${kernel32Lib.symbols.GetLastError()})`);
          }
        } finally {
          immLib.symbols.ImmReleaseContext(hwnd, hIMC);
        }
      } catch (error) {
        await reportError(denops, `Failed to set IME status: ${error}`);
      }
    },
  };
}