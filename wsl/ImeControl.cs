using System;
using System.Runtime.InteropServices;

class ImeControl {
    [DllImport("User32.dll")] static extern int GetForegroundWindow();
    [DllImport("Imm32.dll")] static extern int ImmGetDefaultIMEWnd(int hWnd);
    [DllImport("User32.dll")] static extern int SendMessage(int hWnd, int msg, int wParam, int lParam);

    const int WM_IME_CONTROL = 0x283;
    const int IMC_GETCONVERSIONMODE = 0x001;
    const int IMC_SETCONVERSIONMODE = 0x002;
    const int IMC_GETOPENSTATUS = 0x005;
    const int IMC_SETOPENSTATUS = 0x006;

    static void Main(string[] args) {
        // コンソール出力がバッファリングされないように設定（WSLから受け取りやすくする）
        Console.OutputEncoding = System.Text.Encoding.UTF8;

        int hwnd = ImmGetDefaultIMEWnd(GetForegroundWindow());
        if (args.Length == 0) return;

        string cmd = args[0];
        
        // 修正: SendMessageの最後の引数（タイムアウト等）は不要なので4引数で呼び出す
        if (cmd == "get_status") { 
            Console.WriteLine(SendMessage(hwnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0));
        } else if (cmd == "set_status") { 
            SendMessage(hwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, int.Parse(args[1]));
        } else if (cmd == "get_mode") { 
            Console.WriteLine(SendMessage(hwnd, WM_IME_CONTROL, IMC_GETCONVERSIONMODE, 0));
        } else if (cmd == "set_mode") { 
            SendMessage(hwnd, WM_IME_CONTROL, IMC_SETCONVERSIONMODE, int.Parse(args[1]));
        }
    }
}

