constexpr uintptr_t Process_Event = 0x9ae522c;
constexpr uintptr_t LuaLoadBuffer = 0xACC8218;
constexpr uintptr_t LuaPCall = 0xACA4A08;
constexpr uintptr_t LuaLoad = 0xACA4C04;

static int processEventCounter = 0;
static bool isInjected = false;
static int64_t G_LuaState = 0;

struct LuaFunctions
{
    int64_t (*load)(int64_t, int64_t, int64_t, const char *, const char *);
    int64_t (*loadBuffer)(int64_t, const char *, size_t, const char *, const char *);
    int64_t (*pcall)(int64_t, int, int, int);
} lua;

void (*Orig_ProcessEvent)(UObject *, UFunction *, void *);

bool ExecuteScript(int64_t state)
{
    if (!state || !lua.loadBuffer || !lua.pcall)
    {
        LOGI("Invalid parameters - State: %p, loadBuffer: %p, pcall: %p",
             (void *)state, (void *)lua.loadBuffer, (void *)lua.pcall);
        return false;
    }
    const char *pubg_script = R"lua(

// add ur custom lua here
  
    )lua";
    int mainStatus = lua.loadBuffer(state, pubg_script, strlen(pubg_script), "@main", "t");
    if (mainStatus != 0)
    {
        LOGI("Main load failed: %d", mainStatus);
        return false;
    }
    int execStatus = lua.pcall(state, 0, 0, 0);
    if (execStatus != 0)
    {
        LOGI("Execution failed: %d", execStatus);
        return false;
    }
    LOGI("Injection completed");
    return true;
}

int64_t (*orig_lua_loadbufferx)(int64_t L, const char *buff, size_t sz, const char *name, const char *mode) = nullptr;
int64_t hooked_lua_loadbufferx(int64_t L, const char *buff, size_t sz, const char *name, const char *mode)
{
    if (!G_LuaState)
    {
        G_LuaState = L;
        LOGI("✅ Captured LuaState from lua_loadbufferx: %p", (void *)L);
    }
    return orig_lua_loadbufferx(L, buff, sz, name, mode);
}

void Hook_ProcessEvent(UObject *object, UFunction *function, void *params)
{
    static bool injectionAttempted = false;
    if (!injectionAttempted && ++processEventCounter >= 12 && G_LuaState)
    {
        injectionAttempted = true;
        isInjected = ExecuteScript(G_LuaState);
    }
    Orig_ProcessEvent(object, function, params);
}

void start_thread(){
    void *loadBufferAddr = reinterpret_cast<void *>(g_Bvars.Ue4Base.BaseAddr + Offset::LuaLoadBuffer);
    A64HookFunction(loadBufferAddr, (void *)hooked_lua_loadbufferx, (void **)&orig_lua_loadbufferx);

    void *loadBufAddr = reinterpret_cast<void *>(g_Bvars.Ue4Base.BaseAddr + Offset::LuaLoadBuffer);
    void *pcallAddr = reinterpret_cast<void *>(g_Bvars.Ue4Base.BaseAddr + Offset::LuaPCall);
    void *loadAddr = reinterpret_cast<void *>(g_Bvars.Ue4Base.BaseAddr + Offset::LuaLoad);

    LOGI("loadBuffer @ %p | pcall @ %p | load @ %p", loadBufAddr, pcallAddr, loadAddr);

    lua.loadBuffer = reinterpret_cast<decltype(lua.loadBuffer)>(loadBufAddr);
    lua.pcall = reinterpret_cast<decltype(lua.pcall)>(pcallAddr);
    lua.load = reinterpret_cast<decltype(lua.load)>(loadAddr);

    void *processEventAddr = reinterpret_cast<void *>(g_Bvars.Ue4Base.BaseAddr + Offset::Process_Event);
    A64HookFunction(processEventAddr, (void *)Hook_ProcessEvent, (void **)&Orig_ProcessEvent);
}
