using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Permissions;
using BepInEx;
using RoR2.ContentManagement;
using UnityEngine;
using RoR2;
using System.Linq;
using System.Security;
using BepInEx.Configuration;
using BepInEx.Bootstrap;
using System.Runtime.CompilerServices;

#pragma warning disable CS0618 // Type or member is obsolete
[assembly: SecurityPermission(SecurityAction.RequestMinimum, SkipVerification = true)]
#pragma warning restore CS0618 // Type or member is obsolete
[assembly: HG.Reflection.SearchableAttribute.OptIn]

namespace WaffleHouse
{
    [BepInPlugin(GUID, Name, Version)]
    public class WaffleHouseStage : BaseUnityPlugin
    {
        public const string Author = "JaceDaDorito";
        public const string Name = nameof(WaffleHouseStage);
        public const string Version = "1.0.0";
        public const string GUID = Author + "." + Name;

        public static WaffleHouseStage instance;

        private void Awake()
        {
            instance = this;

            Log.Init(Logger);

            ContentManager.collectContentPackProviders += GiveToRoR2OurContentPackProviders;
            Language.collectLanguageRootFolders += CollectLanguageRootFolders;
        }
        private void Destroy()
        {
            Language.collectLanguageRootFolders -= CollectLanguageRootFolders;
        }
        private void GiveToRoR2OurContentPackProviders(ContentManager.AddContentPackProviderDelegate addContentPackProvider)
        {
            addContentPackProvider(new Content.ContentProvider());
        }
        public void CollectLanguageRootFolders(List<string> folders)
        {
            folders.Add(System.IO.Path.Combine(System.IO.Path.GetDirectoryName(base.Info.Location), "Language"));
        }
    }
}
