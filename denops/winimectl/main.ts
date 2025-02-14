import { Denops } from "https://deno.land/x/denops_std@v6.5.1/mod.ts";

const dllPath = "C:\\Windows\\System32\\imm32.dll";
const user32Path = "C:\\Windows\\System32\\user32.dll";
let immLib: Deno.DynamicLibrary<typeof immSymbols>;
let user32Lib: Deno.DynamicLibrary<typeof user32Symbols>;

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

// Helper function to report errors to Neovim
async function reportError(denops: Denops, error: unknown): Promise<void> {
  const errorMessage = error instanceof Error 
    ? `${error.name}: ${error.message}`
    : `Error: ${String(error)}`;
  await denops.call("nvim_err_writeln", `[winimectl] ${errorMessage}`);
}

// Win32ハンドルとDenoのポインタ型の変換ユーティリティ
function toPointer(handle: bigint | number): Deno.PointerValue {
  return Deno.UnsafePointer.create(BigInt(handle)) as Deno.PointerValue;
}

function fromPointer(ptr: Deno.PointerValue): bigint {
  return Deno.UnsafePointer.value(ptr as Deno.PointerObject<unknown>);
}

// Initialize FFI libraries with error handling
async function initializeLibraries(denops: Denops): Promise<boolean> {
  try {
    immLib = Deno.dlopen(dllPath, immSymbols);
    user32Lib = Deno.dlopen(user32Path, user32Symbols);
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
          throw new Error("Failed to get foreground window handle");
        }

        // ウィンドウハンドルを適切なポインタ型として扱う
        const hwndPtr = toPointer(fromPointer(hwnd));
        const hIMC = immLib.symbols.ImmGetContext(hwndPtr);
        if (!hIMC) {
          throw new Error("Failed to get IME context");
        }

        try {
          const status = immLib.symbols.ImmGetOpenStatus(hIMC);
          return status;
        } finally {
          immLib.symbols.ImmReleaseContext(hwndPtr, hIMC);
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
          throw new Error("Failed to get foreground window handle");
        }

        // ウィンドウハンドルを適切なポインタ型として扱う
        const hwndPtr = toPointer(fromPointer(hwnd));
        const hIMC = immLib.symbols.ImmGetContext(hwndPtr);
        if (!hIMC) {
          throw new Error("Failed to get IME context");
        }

        try {
          const result = immLib.symbols.ImmSetOpenStatus(hIMC, status);
          if (!result) {
            throw new Error("Failed to set IME status");
          }
        } finally {
          immLib.symbols.ImmReleaseContext(hwndPtr, hIMC);
        }
      } catch (error) {
        await reportError(denops, `Failed to set IME status: ${error}`);
      }
    },
  };
}