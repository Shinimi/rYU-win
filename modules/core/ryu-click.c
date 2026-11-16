/* ryu-click - instant "jump to app" for the bar.
   Reads the slot -> window id map that ryu-list writes (ryu-apps.cache, next to this exe)
   and asks GlazeWM to focus that window. Native and windowless, so it starts in a few ms. */
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <shellapi.h>

int WINAPI WinMain(HINSTANCE h, HINSTANCE p, LPSTR cmd, int show) {
    int argc; LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (argc < 3 || wcscmp(argv[1], L"--focus-slot") != 0) return 1;
    int slot = _wtoi(argv[2]);

    wchar_t dir[MAX_PATH]; GetModuleFileNameW(NULL, dir, MAX_PATH);
    wchar_t *slash = wcsrchr(dir, L'\\'); if (slash) *slash = 0;
    wchar_t cache[MAX_PATH]; swprintf(cache, MAX_PATH, L"%ls\\ryu-apps.cache", dir);

    FILE *f = _wfopen(cache, L"r"); if (!f) return 2;
    char line[256], id[64] = {0};
    while (fgets(line, sizeof line, f)) {
        int n; char buf[64];
        if (sscanf(line, "%d %63s", &n, buf) == 2 && n == slot) { strcpy(id, buf); break; }
    }
    fclose(f);
    if (!id[0]) return 3;
    for (char *c = id; *c; c++) if (!(isxdigit((unsigned char)*c) || *c == '-')) return 4;   /* only a uuid gets through */

    wchar_t cli[MAX_PATH]; ExpandEnvironmentStringsW(L"%ProgramFiles%\\glzr.io\\GlazeWM\\cli\\glazewm.exe", cli, MAX_PATH);
    wchar_t line2[512]; swprintf(line2, 512, L"\"%ls\" command focus --container-id %hs", cli, id);
    STARTUPINFOW si = { sizeof si }; PROCESS_INFORMATION pi;
    if (CreateProcessW(NULL, line2, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
        WaitForSingleObject(pi.hProcess, 3000);
        CloseHandle(pi.hThread); CloseHandle(pi.hProcess);
    }
    return 0;
}
