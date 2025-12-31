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


void MainThread2()
{
    UGameLuaEnv *LuaEnv = (UGameLuaEnv *)GetObjectByClass(UGameLuaEnv::StaticClass(), false);
    while (!LuaEnv)
    {
        sleep(1);
        LuaEnv = (UGameLuaEnv *)GetObjectByClass(UGameLuaEnv::StaticClass(), false);
    }

    if (LuaEnv)
    {
        FString luaScript = R"(

//your custom lua here
      
    )";


        LuaEnv->LuaDoString(luaScript);
    }
}
