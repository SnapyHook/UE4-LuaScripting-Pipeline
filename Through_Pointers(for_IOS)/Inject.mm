#include <string.h>
#include <mach-o/dyld.h>
#include "SDK.hpp"
#include <thread>
#import <dlfcn.h>

//==========BGMI===========
#define gName 0x1044bd208
#define gObject 0x109b2b4f0
#define LuaLoadBuffer 0x12E6FA4
#define LuaPCall 0x12E46A0
#define LuaLoad 0x12E4878
//=========================

////==========GLOBAL==========
//#define gName 0x104B4449C
//#define gObject 0x10A5DF0F0
//#define LuaLoadBuffer 0x15A88E8
//#define LuaPCall 0x15A5FE4
//#define LuaLoad 0x15A61BC
////==========================

using namespace SDK;
typedef uintptr_t kaddr;
kaddr module= (unsigned long)_dyld_get_image_vmaddr_slide(0);
static bool injectionAttempted = false;

static NSTimer *crashTimer = nil;

@implementation X_PROJECT

uintptr_t getShadowTrackerBase() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *image_name = _dyld_get_image_name(i);
        if (strstr(image_name, "ShadowTrackerExtra")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

kaddr getRealOffset(kaddr offset){
    return (unsigned long)_dyld_get_image_vmaddr_slide(0)+offset;
}
long obbbbl() {

    return getRealOffset(gObject);
};

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
    REProtectGl = 0;
    if (!state || !lua.loadBuffer || !lua.pcall)
    {
//        NSLog(@"Invalid parameters - State: %p, loadBuffer: %p, pcall: %p",
//              (void *)state, (void *)lua.loadBuffer, (void *)lua.pcall);
        return false;
    }
        
        int mainStatus = lua.loadBuffer(state, (const char*)Y_arr, dec_size, "@main", "t");
        if (mainStatus != 0)
        {
            NSLog(@"Main load failed: %d", mainStatus);
            return false;
        }
        int execStatus = lua.pcall(state, 0, 0, 0);
        if (execStatus != 0)
        {
            NSLog(@"Execution failed: %d", execStatus);
            return false;
        }
        NSLog(@"Injection completed");
        return true;
    }
    return false;
}

UObject *GetObjectByClass(UClass *Class, bool Default)
{
    auto objects = UObject::GetGlobalObjects();
    const std::string defaultStr = "Default";

    for (int i = 0; i < objects.Num(); i++)
    {
        auto object = objects.GetByIndex(i);
        if (!object || !object->IsA(Class))
        {
            continue;
        }

        auto objectName = object->GetFullName();
        bool hasDefault = objectName.find(defaultStr) != std::string::npos;

        if ((Default && hasDefault) || (!Default && !hasDefault))
        {
            return object;
        }
    }
    return nullptr;
}

static int findLuaStateAttempts = 0;

void FindLuaState()
{
    findLuaStateAttempts++;
    UClass *envClass = UObject::FindClass("Class ShadowTrackerExtra.GameLuaEnv");
    if (!envClass)
    {
//        NSLog(@"[LuaFinder] UGameLuaEnv class not found");
        return;
    }

    UObject *envObj = GetObjectByClass(envClass, false);
    if (!envObj)
    {
//        NSLog(@"[LuaFinder] No GameLuaEnv instance found yet");
        return;
    }

    uint8_t *env = (uint8_t *)envObj;
    ULuaStateWrapper *wrapper = *(ULuaStateWrapper **)(env + 0x98);
    if (!wrapper)
    {
//        NSLog(@"[LuaFinder] LuaStateWrapper not set yet");
        return;
    }

    uint64_t luaState = *(uint64_t *)((uint8_t *)wrapper + 0x30);
//    NSLog(@"[LuaFinder] GameLuaEnv=%p  LuaStateWrapper=%p  lua_State=%p", envObj, wrapper, (void *)luaState);

    if (luaState > 0x100000000 && luaState < 0x700000000) // typical iOS heap range
    {
//        NSLog(@"[LuaFinder] Valid lua_State pointer ✅");
        G_LuaState = luaState;
    }
    else
    {
//        NSLog(@"[LuaFinder] lua_State looks invalid, maybe wrong offset (try 0x38)");
    }
}

void *(*oProcessEvent)(UObject *pObj, UFunction *pFunc, void *pArgs);
void *hkProcessEvent(UObject *pObj, UFunction *pFunc, void *pArgs) {
    
    auto fnc = pFunc->GetFullName();
    
    if(!G_LuaState){
        FindLuaState();
        if(findLuaStateAttempts > 10){
            crash_with_sigsegv("not injected baby!!!");
        }
    }
    
    if(findLuaStateAttempts > 10){
        crash_with_sigsegv("not injected baby!!!");
    }
    
    if (!injectionAttempted && ++processEventCounter >= 12 && G_LuaState)
    {
        injectionAttempted = true;
        isInjected = ExecuteScript(G_LuaState);
    }
    
    return oProcessEvent(pObj, pFunc, pArgs);
}

void  *Process_Event(){
    
    auto MAIN =(FUObjectArray *) (obbbbl());
    auto gobjects = MAIN->ObjObjects;
    for (int i=0;i< gobjects.Num(); i++)
        if (auto obj = gobjects.GetByIndex(i)) {
            
            if(obj->IsA(AHUD::StaticClass())) {
                auto HUD = (AHUD *) obj;
                int its = 76;
                auto VTable = (void**)HUD->VTable;
                if (VTable && ( VTable[its] != hkProcessEvent)) {
                    oProcessEvent = decltype(oProcessEvent)(VTable[its]);
                    VTable[its] = (void *) hkProcessEvent;
                }
            }
          if(obj->IsA(ASTExtraPlayerController::StaticClass())) {
                auto HUD = (ASTExtraPlayerController *) obj;
                int its = 76;
                auto VTable = (void**)HUD->VTable;
                if (VTable && ( VTable[its] != hkProcessEvent)) {
                    oProcessEvent = decltype(oProcessEvent)(VTable[its]);
                    VTable[its] = (void *) hkProcessEvent;
                }
            }
        }
    return 0;
}

TNameEntryArray *GetGNames() {

    return ((TNameEntryArray * (*)())(
        (unsigned long)_dyld_get_image_vmaddr_slide(0) + gName))();
}

// Crash function
+ (void)crashGame {
    NSLog(@"[X_PROJECT] Crashing game as requested...");
    // Force crash
    volatile int *p = nullptr;
    *p = 0xDEADBEEF;
}

+ (void)load
{
    FName::GNames = GetGNames();
    while (!FName::GNames) {
    FName::GNames = GetGNames();
        sleep(1);
    }
        
    UObject::GUObjectArray = (FUObjectArray *) (obbbbl());
        
    while (!UObject::GUObjectArray) {
    UObject::GUObjectArray = (FUObjectArray *) (obbbbl());
        sleep(1);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //start load but not means language
        [self load1];
    });
}

static void crash_with_sigsegv(const char *msg) {
    if (msg) NSLog(@"[simple_server] crashing: %s", msg);
    else NSLog(@"[simple_server] crashing (SIGSEGV)");
    // Try to raise SIGSEGV
    raise(SIGSEGV);
    // If intercepted, force a write to null (volatile to avoid optimization)
    volatile int *p = nullptr;
    *p = 0xdeadbeef;
}
/* ----------------------------------------- */

+ (void)load1
{
retry:

        uintptr_t Base = getShadowTrackerBase();
    
    if(Base == 0){
        [NSThread sleepForTimeInterval:0.5];
        goto retry;
    }

        void *loadBufAddr = reinterpret_cast<void *>(Base + LuaLoadBuffer);
        void *pcallAddr = reinterpret_cast<void *>(Base + LuaPCall);
        void *loadAddr = reinterpret_cast<void *>(Base + LuaLoad);
        
//        NSLog(@"loadBuffer @ %p | pcall @ %p | load @ %p", loadBufAddr, pcallAddr, loadAddr);
        
        lua.loadBuffer = reinterpret_cast<decltype(lua.loadBuffer)>(loadBufAddr);
        lua.pcall = reinterpret_cast<decltype(lua.pcall)>(pcallAddr);
        lua.load = reinterpret_cast<decltype(lua.load)>(loadAddr);
        Process_Event();
}

__attribute__((constructor))
static void initialize() {

}

@end
