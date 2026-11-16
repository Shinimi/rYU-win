/* ryu-click - instant "jump to app" for the bar.
   Reads the slot -> window id map that ryu-list writes (ryu-apps.cache, next to this exe)
   and sends GlazeWM "command focus --container-id <id>" over its local websocket (127.0.0.1:6123).
   Native, windowless, no extra processes, so a click lands in a few milliseconds. */
#include <winsock2.h>
#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

static int send_all(SOCKET s, const char *b, int n) {
    while (n > 0) { int k = send(s, b, n, 0); if (k <= 0) return 0; b += k; n -= k; }
    return 1;
}

static int glaze_command(const char *cmd) {
    WSADATA w; if (WSAStartup(MAKEWORD(2, 2), &w)) return 0;
    SOCKET s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_SOCKET) return 0;
    DWORD to = 1500; setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, (char *)&to, sizeof to);
    struct sockaddr_in a = {0}; a.sin_family = AF_INET; a.sin_port = htons(6123); a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (connect(s, (struct sockaddr *)&a, sizeof a)) { closesocket(s); return 0; }

    const char *hs = "GET / HTTP/1.1\r\nHost: 127.0.0.1:6123\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                     "Sec-WebSocket-Key: cnl1LWNsaWNrLWtleS0wMQ==\r\nSec-WebSocket-Version: 13\r\n\r\n";
    if (!send_all(s, hs, (int)strlen(hs))) { closesocket(s); return 0; }
    char buf[4096]; int got = 0;
    while (got < (int)sizeof buf - 1) {                         /* read the handshake reply */
        int k = recv(s, buf + got, sizeof buf - 1 - got, 0); if (k <= 0) break; got += k; buf[got] = 0;
        if (strstr(buf, "\r\n\r\n")) break;
    }
    if (!strstr(buf, " 101")) { closesocket(s); return 0; }

    int n = (int)strlen(cmd); unsigned char f[8 + 512]; int p = 0;   /* one masked text frame */
    if (n > 500) { closesocket(s); return 0; }
    f[p++] = 0x81;
    if (n < 126) f[p++] = 0x80 | n; else { f[p++] = 0x80 | 126; f[p++] = (n >> 8) & 0xff; f[p++] = n & 0xff; }
    unsigned char m[4] = {0x12, 0x34, 0x56, 0x78}; memcpy(f + p, m, 4); p += 4;
    for (int i = 0; i < n; i++) f[p++] = cmd[i] ^ m[i & 3];
    send_all(s, (char *)f, p);
    recv(s, buf, sizeof buf, 0);                                 /* wait for GlazeWM to answer */
    closesocket(s); WSACleanup();
    return 1;
}

int WINAPI WinMain(HINSTANCE h, HINSTANCE prev, LPSTR cl, int show) {
    int argc; LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (argc < 3 || wcscmp(argv[1], L"--focus-slot") != 0) return 1;
    int slot = _wtoi(argv[2]);

    wchar_t dir[MAX_PATH]; GetModuleFileNameW(NULL, dir, MAX_PATH);
    wchar_t *slash = wcsrchr(dir, L'\\'); if (slash) *slash = 0;
    wchar_t cache[MAX_PATH]; swprintf(cache, MAX_PATH, L"%ls\\ryu-apps.cache", dir);
    FILE *fp = _wfopen(cache, L"r"); if (!fp) return 2;
    char line[256], id[64] = {0};
    while (fgets(line, sizeof line, fp)) {
        int n; char b[64];
        if (sscanf(line, "%d %63s", &n, b) == 2 && n == slot) { strcpy(id, b); break; }
    }
    fclose(fp);
    if (!id[0]) return 3;
    for (char *c = id; *c; c++) if (!(isxdigit((unsigned char)*c) || *c == '-')) return 4;   /* only a uuid gets through */

    char cmd[160]; snprintf(cmd, sizeof cmd, "command focus --container-id %s", id);
    return glaze_command(cmd) ? 0 : 5;
}
