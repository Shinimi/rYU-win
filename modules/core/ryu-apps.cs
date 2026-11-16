// ryu-apps - prints every app open in GlazeWM (all workspaces) as JSON for a YASB custom widget.
// {"apps": "Firefox   Discord   Steam", "count": 3}
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net.WebSockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

static class RyuApps {
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("kernel32.dll")] static extern IntPtr OpenProcess(uint access, bool inherit, uint pid);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern bool QueryFullProcessImageName(IntPtr h, int flags, StringBuilder name, ref int size);

    // nicer names for apps whose process / file description is ugly
    static readonly Dictionary<string, string> Names = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
        {"msedge","Edge"}, {"chrome","Chrome"}, {"firefox","Firefox"}, {"waterfox","Waterfox"}, {"helium","Helium"},
        {"vivaldi","Vivaldi"}, {"brave","Brave"}, {"steamwebhelper","Steam"}, {"steam","Steam"}, {"explorer","Explorer"},
        {"WindowsTerminal","Terminal"}, {"Code","VS Code"}, {"vesktop","Discord"}, {"Discord","Discord"},
        {"Spotify","Spotify"}, {"Telegram","Telegram"}, {"obs64","OBS"}, {"notepad","Notepad"}, {"powershell","PowerShell"},
        {"cmd","cmd"}, {"devenv","Visual Studio"}, {"EpicGamesLauncher","Epic"}, {"heroic","Heroic"},
        {"Flow.Launcher","Flow"}, {"Taskmgr","Task Manager"}, {"mpv","mpv"}, {"vlc","VLC"}, {"qbittorrent","qBittorrent"}
    };

    static string Pretty(Dictionary<string, object> w) {
        string proc = (w["processName"] as string) ?? "";
        string n;
        if (Names.TryGetValue(proc, out n)) return n;
        try {
            uint pid; GetWindowThreadProcessId((IntPtr)Convert.ToInt64(w["handle"]), out pid);
            IntPtr h = OpenProcess(0x1000, false, pid);
            if (h != IntPtr.Zero) {
                var sb = new StringBuilder(1024); int size = sb.Capacity;
                bool ok = QueryFullProcessImageName(h, 0, sb, ref size);
                CloseHandle(h);
                if (ok) {
                    string d = FileVersionInfo.GetVersionInfo(sb.ToString()).FileDescription;
                    if (!string.IsNullOrWhiteSpace(d) && d.Length <= 22) return d.Trim();
                }
            }
        } catch { }
        return proc.Length > 0 ? char.ToUpper(proc[0]) + proc.Substring(1) : "?";
    }

    static void Walk(object node, List<Dictionary<string, object>> found) {
        var d = node as Dictionary<string, object>;
        if (d == null) return;
        object t; d.TryGetValue("type", out t);
        if ((t as string) == "window") { found.Add(d); return; }
        object kids;
        if (d.TryGetValue("children", out kids) && kids is ArrayList)
            foreach (var k in (ArrayList)kids) Walk(k, found);
    }

    static string Query() {
        using (var ws = new ClientWebSocket()) {
            if (!ws.ConnectAsync(new Uri("ws://127.0.0.1:6123"), CancellationToken.None).Wait(800)) return null;
            var msg = Encoding.UTF8.GetBytes("query workspaces");
            ws.SendAsync(new ArraySegment<byte>(msg), WebSocketMessageType.Text, true, CancellationToken.None).Wait(800);
            var watch = Stopwatch.StartNew();
            while (watch.ElapsedMilliseconds < 1500) {
                var sb = new StringBuilder(); var buf = new byte[65536]; WebSocketReceiveResult r;
                do {
                    var task = ws.ReceiveAsync(new ArraySegment<byte>(buf), CancellationToken.None);
                    if (!task.Wait(1500)) return null;
                    r = task.Result; sb.Append(Encoding.UTF8.GetString(buf, 0, r.Count));
                } while (!r.EndOfMessage);
                string s = sb.ToString();
                if (s.Contains("\"clientMessage\":\"query workspaces\"")) return s;
            }
        }
        return null;
    }

    static void Main() {
        Console.OutputEncoding = new UTF8Encoding(false);
        var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        var names = new List<string>();
        string focused = "";
        try {
            string q = Query();
            if (q != null) {
                var root = js.Deserialize<Dictionary<string, object>>(q);
                var data = root["data"] as Dictionary<string, object>;
                var wss = new List<Dictionary<string, object>>();
                foreach (var o in (ArrayList)data["workspaces"]) wss.Add((Dictionary<string, object>)o);
                // workspace order: 1, 2, ... 9, then the rest
                wss.Sort((a, b) => {
                    int x, y;
                    bool xa = int.TryParse((string)a["name"], out x), yb = int.TryParse((string)b["name"], out y);
                    if (!xa) x = 999; if (!yb) y = 999;
                    return x.CompareTo(y);
                });
                foreach (var w in wss) {
                    var wins = new List<Dictionary<string, object>>();
                    Walk(w, wins);
                    foreach (var win in wins) {
                        string n = Pretty(win);
                        if ((bool)win["hasFocus"]) focused = n;
                        if (!names.Contains(n)) names.Add(n);
                    }
                }
            }
        } catch { }
        var parts = new List<string>();
        foreach (var n in names) parts.Add(n == focused ? "• " + n : n);
        var outObj = new Dictionary<string, object> {
            {"apps", string.Join("    ", parts)}, {"count", names.Count}, {"focused", focused}
        };
        Console.Write(js.Serialize(outObj));
    }
}
