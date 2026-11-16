// rYuSwitch - Hyprland-style "slidefade" workspace animation for GlazeWM.
// Owns Win+1..9: screenshots the current workspace, puts the picture on top,
// tells GlazeWM to switch, then slides + fades the old picture away.
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Net.WebSockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

static class Cfg {
    public static int DurationMs = 230;      // animation length
    public static double SlidePct = 0.18;    // how far the old workspace slides (fraction of width)
    public static int SettleMs = 25;         // wait for new windows to paint before animating
}

class Overlay : Form {
    public Bitmap Shot;
    public Overlay() {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        StartPosition = FormStartPosition.Manual;
        BackColor = Color.Black;
        DoubleBuffered = true;
    }
    protected override CreateParams CreateParams {
        get {
            var cp = base.CreateParams;
            cp.ExStyle |= 0x80 | 0x20 | 0x80000 | 0x08000000 | 0x8; // TOOLWINDOW | TRANSPARENT | LAYERED | NOACTIVATE | TOPMOST
            return cp;
        }
    }
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override void OnPaintBackground(PaintEventArgs e) { }
    protected override void OnPaint(PaintEventArgs e) {
        if (Shot != null) e.Graphics.DrawImageUnscaled(Shot, 0, 0);
    }
}

class App : ApplicationContext {
    [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int id, HookProc cb, IntPtr hMod, uint tid);
    [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr h, int n, IntPtr w, IntPtr l);
    [DllImport("kernel32.dll")] static extern IntPtr GetModuleHandle(string n);
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int vk);
    [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hgt, uint f);
    [DllImport("user32.dll")] static extern bool SetLayeredWindowAttributes(IntPtr h, uint key, byte alpha, uint flags);
    [DllImport("dwmapi.dll")] static extern int DwmFlush();
    [DllImport("winmm.dll")] static extern uint timeBeginPeriod(uint p);
    delegate IntPtr HookProc(int n, IntPtr w, IntPtr l);
    [StructLayout(LayoutKind.Sequential)] struct KBD { public uint vk, scan, flags, time; public UIntPtr extra; }

    HookProc proc; IntPtr hook;
    Overlay ov = new Overlay();
    HashSet<uint> swallowedUp = new HashSet<uint>();
    System.Collections.Concurrent.BlockingCollection<int> queue = new System.Collections.Concurrent.BlockingCollection<int>();

    public App() {
        timeBeginPeriod(1);
        ov.Show(); ov.Hide();                       // create the window once, on the UI thread
        // keyboard hook lives on its own thread so input never waits on an animation
        var ht = new Thread(() => {
            proc = Hook;
            hook = SetWindowsHookEx(13, proc, GetModuleHandle(null), 0);
            Application.Run();
        });
        ht.IsBackground = true; ht.SetApartmentState(ApartmentState.STA); ht.Start();
        // switches + animations run one after another on a worker thread
        var wt = new Thread(() => { foreach (var t in queue.GetConsumingEnumerable()) Switch(t, queue.Count > 0); });
        wt.IsBackground = true; wt.Start();
    }

    IntPtr Hook(int n, IntPtr w, IntPtr l) {
        if (n >= 0) {
            var k = (KBD)Marshal.PtrToStructure(l, typeof(KBD));
            bool injected = (k.flags & 0x10) != 0;
            int msg = w.ToInt32();
            bool down = msg == 0x100 || msg == 0x104, up = msg == 0x101 || msg == 0x105;
            if (!injected && k.vk >= 0x31 && k.vk <= 0x39) {
                if (up && swallowedUp.Remove(k.vk)) return (IntPtr)1;
                bool win = (GetAsyncKeyState(0x5B) & 0x8000) != 0 || (GetAsyncKeyState(0x5C) & 0x8000) != 0;
                bool mod = (GetAsyncKeyState(0x10) & 0x8000) != 0 || (GetAsyncKeyState(0x11) & 0x8000) != 0 || (GetAsyncKeyState(0x12) & 0x8000) != 0;
                if (down && win && !mod) {
                    swallowedUp.Add(k.vk);
                    keybd_event(0xE8, 0, 0, UIntPtr.Zero); keybd_event(0xE8, 0, 2, UIntPtr.Zero); // stop Start menu on Win release
                    int target = (int)k.vk - 0x30;
                    queue.Add(target);
                    return (IntPtr)1;
                }
            }
        }
        return CallNextHookEx(hook, n, w, l);
    }

    // ---------- GlazeWM IPC ----------
    ClientWebSocket ws;
    string Ipc(string message) {
        for (int attempt = 0; attempt < 2; attempt++) {
            try {
                if (ws == null || ws.State != WebSocketState.Open) {
                    ws = new ClientWebSocket();
                    ws.ConnectAsync(new Uri("ws://127.0.0.1:6123"), CancellationToken.None).Wait(1500);
                }
                var bytes = Encoding.UTF8.GetBytes(message);
                ws.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None).Wait(1500);
                var deadline = Stopwatch.StartNew();
                while (deadline.ElapsedMilliseconds < 1500) {
                    var sb = new StringBuilder(); var buf = new byte[65536];
                    WebSocketReceiveResult r;
                    do {
                        var t = ws.ReceiveAsync(new ArraySegment<byte>(buf), CancellationToken.None);
                        if (!t.Wait(1500)) throw new TimeoutException();
                        r = t.Result; sb.Append(Encoding.UTF8.GetString(buf, 0, r.Count));
                    } while (!r.EndOfMessage);
                    string s = sb.ToString();
                    if (s.Contains("\"clientMessage\":\"" + message + "\"")) return s;
                }
            } catch { try { ws.Abort(); } catch { } ws = null; }
        }
        return null;
    }

    void Fallback(int target) {
        try {
            Process.Start(new ProcessStartInfo(@"C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe",
                "command focus --workspace " + target) { CreateNoWindow = true, UseShellExecute = false });
        } catch { }
    }

    // ---------- the animation ----------
    void Switch(int target, bool hurry) {
        if (hurry) { if (Ipc("command focus --workspace " + target) == null) Fallback(target); return; }
        try {
            Rectangle area = Rectangle.Empty; int current = -1;
            string q = Ipc("query workspaces");
            if (q == null) { Fallback(target); return; }
            var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
            var root = js.Deserialize<Dictionary<string, object>>(q);
            var data = root["data"] as Dictionary<string, object>;
            foreach (var o in (ArrayList)data["workspaces"]) {
                var wsd = (Dictionary<string, object>)o;
                int num; if (!int.TryParse((string)wsd["name"], out num) || num < 1 || num > 9) continue;
                if ((bool)wsd["isDisplayed"]) {
                    current = num;
                    area = new Rectangle(Convert.ToInt32(wsd["x"]), Convert.ToInt32(wsd["y"]),
                                         Convert.ToInt32(wsd["width"]), Convert.ToInt32(wsd["height"]));
                }
            }
            if (current == target || current < 0 || area.Width <= 0) { Ipc("command focus --workspace " + target); return; }

            // 1) freeze the current workspace as a picture on top
            var shot = new Bitmap(area.Width, area.Height);
            using (var g = Graphics.FromImage(shot)) g.CopyFromScreen(area.Location, Point.Empty, area.Size);
            ov.Invoke((Action)(() => {
                var old = ov.Shot; ov.Shot = shot; if (old != null) old.Dispose();
                SetLayeredWindowAttributes(ov.Handle, 0, 255, 2);
                ov.Bounds = area;
                ov.Show();
                SetWindowPos(ov.Handle, (IntPtr)(-1), area.X, area.Y, area.Width, area.Height, 0x10 | 0x40);
                ov.Refresh();
            }));
            DwmFlush();

            // 2) switch underneath it
            if (Ipc("command focus --workspace " + target) == null) Fallback(target);
            Thread.Sleep(Cfg.SettleMs);

            // 3) slide + fade the old workspace away
            int dir = target > current ? -1 : 1;
            var sw = Stopwatch.StartNew();
            while (true) {
                double t = Math.Min(1.0, sw.ElapsedMilliseconds / (double)Cfg.DurationMs);
                double e = 1 - Math.Pow(1 - t, 3); // ease-out cubic
                int dx = (int)(dir * e * Cfg.SlidePct * area.Width);
                SetWindowPos(ov.Handle, (IntPtr)(-1), area.X + dx, area.Y, 0, 0, 0x1 | 0x10);
                SetLayeredWindowAttributes(ov.Handle, 0, (byte)(255 * (1 - e)), 2);
                DwmFlush();
                if (t >= 1.0) break;
            }
            ov.Invoke((Action)(() => ov.Hide()));
        } catch {
            try { ov.Invoke((Action)(() => ov.Hide())); } catch { }
            Fallback(target);
        }
    }

    [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr v);
    [STAThread]
    static void Main() {
        bool fresh; var m = new Mutex(true, "rYuSwitch", out fresh);
        if (!fresh) return;
        try { SetProcessDpiAwarenessContext((IntPtr)(-4)); } catch { }
        Application.EnableVisualStyles();
        Application.Run(new App());
        GC.KeepAlive(m);
    }
}
